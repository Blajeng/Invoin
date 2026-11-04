import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:invoin/models/receipt_item.dart';
import 'package:invoin/models/transaction.dart';
import 'package:invoin/repositories/transaction_repository.dart';
import 'package:invoin/screens/receipt_upload_screen.dart';
import 'package:invoin/screens/transaction_detail_screen.dart';
import 'package:invoin/screens/transaction_review_screen.dart';
import 'package:invoin/services/receipt_service.dart';
import 'package:invoin/services/transaction_service.dart';
import 'package:invoin/utils/app_theme.dart';

class _FakeImagePicker extends ImagePickerPlatform {
  _FakeImagePicker(this.imagePath);

  final String imagePath;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return XFile(imagePath);
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
    tempDir = Directory.systemTemp.createTempSync('invoin_slice6');
    imagePath = '${tempDir.path}${Platform.pathSeparator}receipt.png';
    File(imagePath).writeAsBytesSync(base64Decode(_onePixelPng));
  });

  tearDown(() {
    ImagePickerPlatform.instance = originalPicker;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget buildApp(TransactionRepository repository) {
    final receiptService = ReceiptService(repository);
    final transactionService = TransactionService(repository);

    return MaterialApp(
      theme: AppTheme.light(),
      routes: {
        '/transaction-review': (_) =>
            TransactionReviewScreen(receiptService: receiptService),
        '/transaction-detail': (_) =>
            TransactionDetailScreen(transactionService: transactionService),
      },
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
      home: ReceiptUploadScreen(receiptService: receiptService),
    );
  }

  Future<void> runReceiptFlow(
    WidgetTester tester, {
    required String storeName,
  }) async {
    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analisis Struk'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Review Transaksi'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      storeName,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Konfirmasi & Simpan'));
    await tester.tap(find.text('Konfirmasi & Simpan'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Konfirmasi & simpan membuka Detail dari transaksi yang baru disimpan',
      (tester) async {
    ImagePickerPlatform.instance = _FakeImagePicker(imagePath);

    final repository = TransactionRepository();

    repository.add(
      Transaction(
        id: 'trx-sebelumnya',
        storeName: 'Transaksi Lama',
        transactionDate: DateTime(2020, 1, 1),
        total: 111,
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime(2020, 1, 1),
      ),
    );

    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Detail Transaksi'), findsNothing);
    expect(repository.getAll(), hasLength(1));

    await runReceiptFlow(tester, storeName: 'Toko Baru Disimpan');

    final saved = repository.getAll();
    expect(saved, hasLength(2));
    final confirmed =
        saved.firstWhere((t) => t.storeName == 'Toko Baru Disimpan');

    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('Scan Struk'), findsNothing);

    expect(find.text('Toko Baru Disimpan'), findsOneWidget);
    expect(find.text('Transaksi Lama'), findsNothing);

    expect(find.text('Rp 85.000'), findsOneWidget);
    expect(find.text('Nasi Goreng'), findsOneWidget);

    expect(find.text('Struk'), findsOneWidget);
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, hasLength(1));
    expect((images.single.image as FileImage).file.path, imagePath);

    expect(confirmed.receiptImagePath, imagePath);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Detail menampilkan gambar struk yang tersimpan', (tester) async {
    final repository = TransactionRepository();
    final date = DateTime(2026, 9, 24);

    repository.add(
      Transaction(
        id: 'trx-1',
        storeName: 'Indomaret',
        transactionDate: date,
        total: 48000,
        items: const [
          ReceiptItem(name: 'Air Mineral', quantity: 2, price: 5000),
        ],
        receiptImagePath: imagePath,
        createdAt: date,
        updatedAt: date,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        routes: {
          '/transaction-detail': (_) => TransactionDetailScreen(
            transactionService: TransactionService(repository),
          ),
        },
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
    expect(find.text('Struk'), findsOneWidget);

    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, hasLength(1));
    expect((images.single.image as FileImage).file.path, imagePath);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Struk'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Detail tetap valid tanpa gambar struk', (tester) async {
    final repository = TransactionRepository();
    final date = DateTime(2026, 9, 24);

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
        routes: {
          '/transaction-detail': (_) => TransactionDetailScreen(
            transactionService: TransactionService(repository),
          ),
        },
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

    expect(find.text('Struk'), findsNothing);
    expect(find.byType(Image), findsNothing);

    expect(find.text('Indomaret'), findsOneWidget);
    expect(find.text('Rp 48.000'), findsOneWidget);
    expect(find.text('Air Mineral'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Detail tetap valid saat file gambar sudah tidak ada',
      (tester) async {
    final repository = TransactionRepository();
    final date = DateTime(2026, 9, 24);

    final missingPath =
        '${tempDir.path}${Platform.pathSeparator}hilang.png';

    repository.add(
      Transaction(
        id: 'trx-1',
        storeName: 'Indomaret',
        transactionDate: date,
        total: 48000,
        items: const [
          ReceiptItem(name: 'Air Mineral', quantity: 2, price: 5000),
        ],
        receiptImagePath: missingPath,
        createdAt: date,
        updatedAt: date,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        routes: {
          '/transaction-detail': (_) => TransactionDetailScreen(
            transactionService: TransactionService(repository),
          ),
        },
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

    expect(find.text('Struk'), findsOneWidget);
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, hasLength(1));
    expect((images.single.image as FileImage).file.path, missingPath);

    expect(images.single.errorBuilder, isNotNull);

    expect(find.text('Indomaret'), findsOneWidget);
    expect(find.text('Rp 48.000'), findsOneWidget);
    expect(find.text('Air Mineral'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Batal dari Review tidak mengarahkan user ke Detail',
      (tester) async {
    ImagePickerPlatform.instance = _FakeImagePicker(imagePath);

    final repository = TransactionRepository();

    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Galeri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analisis Struk'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Review Transaksi'), findsOneWidget);

    await tester.ensureVisible(find.text('Batal'));
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Scan Struk'), findsOneWidget);
    expect(find.text('Detail Transaksi'), findsNothing);
    expect(repository.getAll(), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
