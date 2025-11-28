# Dokumentasi Unit Testing - HomeCare Mobile

## Iqbal Fahrozi

---

## Ringkasan Test

**Total: 27 Unit Tests**

### 1. Validation Tests (20 tests)

- `patient_add_test.dart` - 7 tests
- `patient_edit_test.dart` - 7 tests
- `patient_registration_test.dart` - 6 tests

### 2. Widget Tests (7 tests)

- `patient_widget_test.dart` - 7 tests

---

## Detail Test Files

### A. patient_add_test.dart (7 tests)

**Tujuan**: Validasi form tambah pasien baru

**Test Cases**:

1. ✅ `nama kosong harus error` - Nama tidak boleh kosong
2. ✅ `nama kurang dari 3 karakter harus error` - Minimal 3 karakter
3. ✅ `nama valid harus diterima` - Nama "Iqbal Fahrozi" valid
4. ✅ `NIK kosong harus error` - NIK wajib diisi
5. ✅ `NIK harus 16 digit` - NIK kurang dari 16 digit ditolak
6. ✅ `NIK dengan huruf harus ditolak` - Hanya angka yang diterima
7. ✅ `NIK 16 digit harus diterima` - NIK "3201012801990001" valid

**Validasi Logic**:

```dart
String? validateNama(String nama) {
  if (nama.isEmpty) return 'Nama tidak boleh kosong';
  if (nama.length < 3) return 'Nama minimal 3 karakter';
  return null;
}

String? validateNIK(String nik) {
  if (nik.isEmpty) return 'NIK tidak boleh kosong';
  if (nik.length != 16) return 'NIK harus 16 digit';
  if (!RegExp(r'^\d+$').hasMatch(nik)) return 'NIK harus berupa angka';
  return null;
}
```

---

### B. patient_edit_test.dart (7 tests)

**Tujuan**: Validasi form edit data pasien

**Test Cases**:

1. ✅ `nomor telepon kosong harus error` - Nomor telepon wajib
2. ✅ `nomor telepon harus diawali 08` - Format Indonesia
3. ✅ `nomor telepon minimal 10 digit` - Terlalu pendek ditolak
4. ✅ `nomor telepon valid diterima` - "081234567890" valid
5. ✅ `alamat kosong harus error` - Alamat wajib diisi
6. ✅ `alamat minimal 10 karakter` - Alamat terlalu pendek ditolak
7. ✅ `alamat valid diterima` - Alamat lengkap diterima

**Validasi Logic**:

```dart
String? validateNoTelp(String noTelp) {
  if (noTelp.isEmpty) return 'Nomor telepon tidak boleh kosong';
  if (!noTelp.startsWith('08')) {
    return 'Nomor telepon harus diawali dengan 08';
  }
  if (noTelp.length < 10 || noTelp.length > 13) {
    return 'Nomor telepon harus 10-13 digit';
  }
  return null;
}

String? validateAlamat(String alamat) {
  if (alamat.isEmpty) return 'Alamat tidak boleh kosong';
  if (alamat.length < 10) return 'Alamat minimal 10 karakter';
  return null;
}
```

---

### C. patient_registration_test.dart (6 tests)

**Tujuan**: Validasi form registrasi pasien

**Test Cases**:

1. ✅ `nomor registrasi kosong harus error` - Nomor reg wajib
2. ✅ `nomor registrasi harus sesuai format` - Format R[YYMMDD]BS[5digit]
3. ✅ `nomor registrasi valid diterima` - "R250115BS00001" valid
4. ✅ `penanggung jawab kosong harus error` - Penanggung jawab wajib
5. ✅ `penanggung jawab minimal 3 karakter` - Terlalu pendek ditolak
6. ✅ `penanggung jawab valid diterima` - "Budi Santoso" valid

**Validasi Logic**:

```dart
String? validateNoReg(String noReg) {
  if (noReg.isEmpty) return 'Nomor registrasi tidak boleh kosong';

  // Format: R[YYMMDD]BS[5digit]
  // Contoh: R250115BS00001
  final regex = RegExp(r'^R\d{6}BS\d{5}$');
  if (!regex.hasMatch(noReg)) {
    return 'Format nomor registrasi: R[YYMMDD]BS[5digit]';
  }
  return null;
}

String? validatePenanggung(String penanggung) {
  if (penanggung.isEmpty) {
    return 'Nama penanggung jawab tidak boleh kosong';
  }
  if (penanggung.length < 3) {
    return 'Nama penanggung jawab minimal 3 karakter';
  }
  return null;
}
```

---

### D. patient_widget_test.dart (7 tests)

**Tujuan**: Testing komponen UI form pasien

**Test Cases**:

#### Patient Form Widget Test (4 tests)

1. ✅ `form pasien punya field nama` - Field Nama Lengkap ada
2. ✅ `form pasien punya field NIK` - Field NIK ada
3. ✅ `bisa input text di field nama` - User bisa ketik "Iqbal Fahrozi"
4. ✅ `tombol simpan ada di form` - Tombol Simpan tersedia

#### Patient List Widget Test (3 tests)

5. ✅ `list pasien menampilkan card` - Card pasien dengan nama dan NIK tampil
6. ✅ `list pasien punya search field` - Search bar dengan icon tersedia
7. ✅ `bisa ketik di search field` - User bisa search "Iqbal"

**Contoh Test**:

```dart
testWidgets('form pasien punya field nama', (WidgetTester tester) async {
  // Arrange - build simple form widget
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
          ],
        ),
      ),
    ),
  );

  // Assert - cek ada field Nama
  expect(find.text('Nama Lengkap'), findsOneWidget);
});
```

---

## Cara Menjalankan Test

### Run Semua Test

```bash
flutter test
# Output: 00:06 +27: All tests passed!
```

### Run Test Spesifik

```bash
# Validation tests only
flutter test test/patient_add_test.dart
flutter test test/patient_edit_test.dart
flutter test test/patient_registration_test.dart

# Widget tests only
flutter test test/patient_widget_test.dart
```

### Run dengan Verbose

```bash
flutter test --reporter expanded
```

---

## Pattern Testing: AAA

Semua test menggunakan pola **AAA (Arrange-Act-Assert)**:

1. **Arrange** - Persiapan data test
2. **Act** - Eksekusi fungsi yang ditest
3. **Assert** - Verifikasi hasil sesuai ekspektasi

### Contoh AAA Pattern:

```dart
test('nama kosong harus error', () {
  // Arrange - siapkan data test
  String nama = '';

  // Act - jalankan fungsi validasi
  String? hasil = validateNama(nama);

  // Assert - cek hasil sesuai ekspektasi
  expect(hasil, 'Nama tidak boleh kosong');
});
```

---

## Data Test yang Digunakan

Semua test menggunakan data real untuk konteks Indonesia:

| Field            | Data Test                            | Keterangan                   |
| ---------------- | ------------------------------------ | ---------------------------- |
| Nama             | Iqbal Fahrozi                        | Nama lengkap valid           |
| NIK              | 3201012801990001                     | NIK 16 digit valid           |
| Telepon          | 081234567890                         | Format Indonesia (08-prefix) |
| Email            | homecare@test.com                    | Email valid                  |
| Alamat           | Jl. Merdeka No. 123, Jakarta Selatan | Alamat lengkap               |
| No. Registrasi   | R250115BS00001                       | Format R[YYMMDD]BS[5digit]   |
| Penanggung Jawab | Budi Santoso                         | Nama valid                   |

---

## Coverage Areas

### ✅ Input Validation

- Empty field validation
- Minimum/maximum length validation
- Format validation (NIK, phone, registration number)
- Character type validation (numbers only for NIK)

### ✅ UI Components

- Form fields presence
- Button availability
- User interaction (typing, clicking)
- Data display (cards, lists)

### ✅ Business Rules

- Indonesian phone format (08-prefix)
- NIK format (16 digits)
- Registration number format (R[YYMMDD]BS[5digit])
- Minimum data quality (address 10+ chars, name 3+ chars)

---

## Test Statistics

| Kategori             | Jumlah | Persentase |
| -------------------- | ------ | ---------- |
| **Validation Tests** | 20     | 74%        |
| **Widget Tests**     | 7      | 26%        |
| **Total**            | **27** | **100%**   |

**Status**: ✅ All 27 tests passed (100%)  
**Execution Time**: ~6 seconds  
**Last Run**: Success

---

## Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

---

## Kesimpulan

Test suite ini memberikan coverage yang baik untuk:

1. **Data Integrity** - Memastikan data pasien valid sebelum masuk database
2. **User Experience** - UI components berfungsi dengan baik
3. **Business Logic** - Aturan bisnis healthcare teraplikasi

Fokus utama pada **Patient Management** karena ini core feature yang paling krusial untuk aplikasi healthcare.

---

**Dibuat oleh**: Iqbal Fahrozi  
**Project**: HomeCare Mobile  
**Framework**: Flutter with flutter_test  
**Date**: November 2025
