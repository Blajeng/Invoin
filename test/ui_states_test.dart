import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:invoin/models/receipt_item.dart';
import 'package:invoin/models/transaction.dart';
import 'package:invoin/repositories/transaction_repository.dart';
import 'package:invoin/screens/chat_screen.dart';
import 'package:invoin/screens/receipt_upload_screen.dart';
import 'package:invoin/screens/transaction_detail_screen.dart';
import 'package:invoin/screens/transaction_review_screen.dart';
import 'package:invoin/services/chat_service.dart';
import 'package:invoin/services/receipt_service.dart';
import 'package:invoin/services/transaction_service.dart';
import 'package:invoin/utils/app_theme.dart';
import 'package:invoin/widgets/chat_bubble.dart';
class _FakeImagePicker extends ImagePickerPlatform {
  _FakeImagePicker({this.imagePath, this.shouldFail = false});

  final String? imagePath;
  final bool shouldFail;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    if (shouldFail) {
      throw Exception('image picker gagal');
    }
    return XFile(imagePath!);
  }
}

const String _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  initializeDateFormatting('id_ID');

  late ImagePickerPlatform originalPicker;
  late Directory tempDir;
  late String imagePath;

  setUp(() {
    originalPicker = ImagePickerPlatform.instance;
    tempDir = Directory.systemTemp.createTempSync('invoin_slice5');
    imagePath = '${tempDir.path}${Platform.pathSeparator}receipt.png';
    File(imagePath).writeAsBytesSync(base64Decode(_onePixelPng));
  });

  tearDown(() {
    ImagePickerPlatform.instance = originalPicker;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ReceiptUploadScreen buildUploadScreen(TransactionRepository repository) {
    return ReceiptUploadScreen(receiptService: ReceiptService(repository));
  }

  testWidgets('Upload menampilkan error dengan aksi pemulihan', (tester) async {
    // Platform picker gagal — kondisi nyata PRD §FR-10 "gambar tidak
    // tersedia/invalid".
    ImagePickerPlatform.instance = _FakeImagePicker(shouldFail: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: buildUploadScreen(TransactionRepository()),
      ),
    );
    await tester.pumpAndSettle();

    // Sebelum ada kegagalan, banner error dan aksi pemulihannya belum tampil.
    expect(find.text('Pilih atau ambil foto struk'), findsOneWidget);
    expect(find.text('Ganti Gambar'), findsNothing);

    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();

    // Kegagalan dikomunikasikan dengan jelas...
    expect(
      find.text('Gagal mengambil gambar. Silakan coba lagi.'),
      findsOneWidget,
    );
    // ...dan ada jalan keluar, bukan sekadar pesan tanpa aksi.
    expect(find.text('Ganti Gambar'), findsOneWidget);
    // Tidak ada gambar terpilih, jadi mengulang analisis tidak bermakna dan
    // "Coba Lagi" sengaja tidak ditampilkan.
    expect(find.text('Coba Lagi'), findsNothing);

    // Kegagalan picker ditangani di dalam layar, tidak dilempar keluar.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gambar terpilih dianalisis lalu transisi ke Review',
      (tester) async {
    ImagePickerPlatform.instance = _FakeImagePicker(imagePath: imagePath);

    final repository = TransactionRepository();
    final receiptService = ReceiptService(repository);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: (settings) {
          if (settings.name == '/transaction-review') {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => TransactionReviewScreen(
                receiptService: receiptService,
              ),
            );
          }
          return null;
        },
        home: buildUploadScreen(repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();

    // Preview gambar terpilih.
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.text('Analisis Struk'));
    await tester.pump();

    // State `analyzing` harus menjelaskan apa yang sedang terjadi, bukan
    // hanya menampilkan spinner (UI/UX §8).
    expect(find.text('Menganalisis struk...'), findsOneWidget);
    expect(
      find.text('Mengekstrak informasi transaksi dari struk.'),
      findsOneWidget,
    );
    // Aksi tidak tersedia saat proses berjalan, sehingga Analisis tidak
    // bisa dijalankan dua kali.
    expect(find.text('Analisis Struk'), findsNothing);
    expect(find.text('Galeri'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Berhasil --> Review, dan draft belum apa-apa tersimpan.
    expect(find.text('Review Transaksi'), findsOneWidget);
    expect(repository.getAll(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Detail memberi tahu saat penyimpanan gagal', (tester) async {
    final repository = TransactionRepository();
    final date = DateTime(2026, 9, 24);

    // Transaksi awal ada, sehingga layar detail bisa dibuka.
    repository.add(
      Transaction(
        id: 'trx-1',
        storeName: 'Indomaret',
        transactionDate: date,
        total: 48000,
        items: const [
          ReceiptItem(name: 'Air Mineral', quantity: 2, price: 5000),
        ],
        createdAt: date,
        updatedAt: date,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionDetailScreen(
            transactionService: TransactionService(repository),
          ),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/transaction-detail',
                  arguments: 'trx-1',
                ),
                child: const Text('buka detail'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka detail'));
    await tester.pumpAndSettle();
    expect(find.text('Indomaret'), findsOneWidget);

    // Masuk mode edit lalu ubah data.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Superindo');
    await tester.pumpAndSettle();

    // Transaksi dihapus dari repository sehingga `updateTransaction`
    // mengembalikan false. Ini kegagalan yang memang bisa terjadi pada
    // arsitektur sekarang — bukan skenario yang dikarang.
    repository.delete('trx-1');

    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    // User diberi tahu kegagalan, bukan dibiarkan tanpa kabar.
    expect(
      find.text('Gagal menyimpan perubahan. Silakan coba lagi.'),
      findsOneWidget,
    );
    // Success message tidak boleh muncul bersamaan dengan kegagalan.
    expect(find.text('Transaksi berhasil diperbarui!'), findsNothing);
    // Tetap di mode edit supaya user bisa mencoba lagi.
    expect(find.text('Simpan Perubahan'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('AI Chat tidak mengirim dua pertanyaan bersamaan',
      (tester) async {
    final chatService =
        ChatService(TransactionService(TransactionRepository()));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ChatScreen(chatService: chatService),
      ),
    );
    await tester.pumpAndSettle();

    // Pertanyaan pertama dikirim lewat tombol send.
    await tester.enterText(
      find.byType(TextField),
      'Berapa pengeluaran bulan ini?',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Selagi jawaban pertama diproses, user mengetik pertanyaan kedua lalu
    // menekan Enter. Tombol send sudah nonaktif, jadi kedua jalur harus
    // berperilaku sama: tidak mengirim request kedua.
    await tester.enterText(find.byType(TextField), 'Transaksi terbesar?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Hanya satu percakapan yang terjadi: 1 user + 1 AI.
    expect(find.byType(ChatBubble), findsNWidgets(2));
    // Pertanyaan kedua tidak hilang — masih bisa dikirim setelah selesai.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Transaksi terbesar?',
    );

    // Kontrol positif: setelah loading selesai, pertanyaan kedua benar-benar
    // terkirim. Ini memastikan test di atas tidak lolos karena alasan salah
    // (misalnya aksi Enter memang tidak pernah bekerja sejak awal).
    //
    // `performAction` menutup koneksi input, jadi field perlu difokuskan ulang
    // sebelum Enter ditekan untuk kedua kalinya.
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(ChatBubble), findsNWidgets(4));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
