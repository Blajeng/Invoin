///
/// Validation minimum sebelum save:
/// - store name tidak kosong
/// - transaction date valid
/// - total valid dan tidak negatif
/// - item quantity/price valid jika item tersedia
/// - user melakukan explicit confirmation
library;

/// Validasi store name — tidak boleh kosong.
String? validateStoreName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Nama toko tidak boleh kosong';
  }
  return null;
}

/// Validasi total — harus angka valid dan tidak negatif.
String? validateTotal(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Total tidak boleh kosong';
  }
  final parsed = double.tryParse(value);
  if (parsed == null) {
    return 'Total harus berupa angka';
  }
  if (parsed < 0) {
    return 'Total tidak boleh negatif';
  }
  return null;
}

/// Validasi quantity item — harus angka bulat positif.
String? validateQuantity(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Jumlah tidak boleh kosong';
  }
  final parsed = int.tryParse(value);
  if (parsed == null) {
    return 'Jumlah harus berupa angka bulat';
  }
  if (parsed <= 0) {
    return 'Jumlah harus lebih dari 0';
  }
  return null;
}

/// Validasi harga item — harus angka valid dan tidak negatif.
String? validatePrice(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Harga tidak boleh kosong';
  }
  final parsed = double.tryParse(value);
  if (parsed == null) {
    return 'Harga harus berupa angka';
  }
  if (parsed < 0) {
    return 'Harga tidak boleh negatif';
  }
  return null;
}

/// Validasi tanggal — tidak boleh null.
String? validateDate(DateTime? value) {
  if (value == null) {
    return 'Tanggal transaksi harus diisi';
  }
  return null;
}
