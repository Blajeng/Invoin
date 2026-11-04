import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../services/receipt_service.dart';
import '../models/transaction.dart';
import '../widgets/loading_indicator.dart';

/// Receipt Upload Screen
///
/// Screen 2:
/// - Image picker / camera entry
/// - Preview gambar
/// - Action untuk menganalisis
///
/// State flow:
/// idle → image_selected → analyzing → navigate to review
///                                   → error (retry)
class ReceiptUploadScreen extends StatefulWidget {
  final ReceiptService receiptService;

  const ReceiptUploadScreen({
    super.key,
    required this.receiptService,
  });

  @override
  State<ReceiptUploadScreen> createState() => _ReceiptUploadScreenState();
}

class _ReceiptUploadScreenState extends State<ReceiptUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil gambar. Silakan coba lagi.';
      });
    }
  }

  Future<void> _analyzeReceipt() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final Transaction draft =
          await widget.receiptService.analyzeReceipt(_selectedImage!.path);

      if (!mounted) return;

      final result = await Navigator.pushNamed(
        context,
        '/transaction-review',
        arguments: draft,
      );

      // Review mengembalikan ID transaksi yang baru disimpan.
      //
      // post-save navigation: setelah konfirmasi & simpan, user
      // dibawa ke Transaction Detail dari transaksi yang baru saja disimpan
      // "Then navigate to Transaction Detail"; keputusan produk
      // `pushReplacementNamed` dipakai supaya langkah Scan
      // Struk tidak menyisakan diri di stack: tombol Back dari Detail
      // langsung kembali ke layar asal, sesuai alur
      // Review --> Detail di UI/UX §5.3.
      //
      // Kalau user menekan Batal, `result` bernilai `false` dan user tetap
      // berada di layar ini — perilaku lama tidak berubah.
      if (result is String && result.isNotEmpty && mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/transaction-detail',
          arguments: result,
        );
      }
    } catch (e) {
      // Error handling — AI request gagal
      setState(() {
        _errorMessage = 'Gagal menganalisis struk. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Scan Struk'),
        backgroundColor: Colors.white,
        foregroundColor: textPrimaryColor,
        elevation: 0,
      ),
      body: _isAnalyzing
          // loading state receipt adalah dua baris — aksi yang sedang
          // berjalan dan apa yang sedang dilakukan. Tanpa baris kedua user
          // hanya melihat spinner tanpa tahu proses apa yang jalan.
          ? const LoadingIndicator(
              message: 'Menganalisis struk...',
              secondaryMessage: 'Mengekstrak informasi transaksi dari struk.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedImage != null
                            ? primaryColor.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.contain,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: textSecondaryColor.withValues(
                                    alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Pilih atau ambil foto struk',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Pastikan struk terlihat jelas',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Error message + aksi pemulihan
                  //
                  // Error state yang bisa ditindaklanjuti =
                  // ("[ Try Again ]" / "[ Choose Another Image ]")
                  // menganggap "gambar tidak tersedia/invalid" serta "AI request
                  // gagal" sebagai kasus yang harus punya state sendiri. Aksi di
                  // bawah ini bukan infrastruktur baru keduanya memanggil
                  // handler yang sudah ada di layar ini.
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: errorColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: errorColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: errorColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // "Coba Lagi" hanya bermakna kalau ada gambar
                              // untuk dianalisis ulang.
                              if (_selectedImage != null) ...[
                                _buildErrorAction(
                                  label: 'Coba Lagi',
                                  onPressed: _analyzeReceipt,
                                ),
                                const SizedBox(width: 4),
                              ],
                              _buildErrorAction(
                                label: 'Ganti Gambar',
                                onPressed: () =>
                                    _pickImage(ImageSource.gallery),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Kamera'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galeri'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedImage != null ? _analyzeReceipt : null,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text(
                        'Analisis Struk',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Tombol pemulihan di dalam banner error.
  ///
  /// Menggunakan TextButton  agar banner error tetap ringan dan tidak
  /// mengambil alih fokus dari aksi utama di bawahnya.
  Widget _buildErrorAction({
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: errorColor,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(label),
    );
  }
}
