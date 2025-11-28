# Panduan Presentasi Unit Testing ke Dosen

## 1. Persiapan (Sebelum Presentasi)

### Setup yang Perlu Dicek:

```bash
# Pastikan semua test berjalan
flutter test

# Harusnya muncul: 00:03 +20: All tests passed!
```

### File yang Perlu Dibuka di VS Code:

1. `test/patient_add_test.dart` - Test validasi tambah pasien
2. `test/patient_edit_test.dart` - Test validasi edit pasien
3. `test/patient_registration_test.dart` - Test validasi registrasi pasien
4. Terminal untuk run test

---

## 2. Script Presentasi (15-20 Menit)

### Pembukaan (1 menit)

**Ucapkan:**

> "Selamat pagi/siang Pak/Bu. Saya Iqbal Fahrozi, hari ini saya akan mempresentasikan implementasi unit testing pada aplikasi HomeCare Mobile yang saya kembangkan. Saya fokus membuat testing untuk fitur Patient Management yang merupakan core feature dari aplikasi ini. Total ada 20 unit test yang mencakup validasi form tambah pasien, edit pasien, dan registrasi pasien."

### Bagian 1: Penjelasan Struktur (2 menit)

**Tunjukkan folder structure di VS Code:**

```
test/
  ├── patient_add_test.dart            (7 tests)
  ├── patient_edit_test.dart           (7 tests)
  └── patient_registration_test.dart   (6 tests)
```

**Jelaskan:**

> "Saya membagi test menjadi 3 kategori sesuai dengan halaman fitur pasien:
>
> 1. Patient Add Test - untuk validasi saat tambah pasien baru (NIK, nama)
> 2. Patient Edit Test - untuk validasi saat edit data pasien (nomor telepon, alamat)
> 3. Patient Registration Test - untuk validasi form registrasi pasien (nomor registrasi, penanggung jawab)"

---

### Bagian 2: Demo Patient Add Test (5 menit)

**Buka file `patient_add_test.dart` dan scroll ke test pertama:**

**Jelaskan:**

> "Mari saya jelaskan test untuk fitur tambah pasien. Di sini saya test 2 field utama: Nama dan NIK."

**Tunjuk kode test nama:**

```dart
test('nama kosong harus error', () {
  // Arrange - siapkan nama kosong
  String nama = '';

  // Act - validasi
  String? hasil = validateNama(nama);

  // Assert - harus ada error
  expect(hasil, 'Nama tidak boleh kosong');
});
```

**Penjelasan detail:**

> "Di sini saya menggunakan pola AAA - Arrange, Act, Assert:
>
> - **Arrange**: Saya siapkan data test, dalam hal ini nama kosong
> - **Act**: Saya jalankan fungsi validateNama
> - **Assert**: Saya cek hasilnya harus muncul error 'Nama tidak boleh kosong'"

**Scroll ke test NIK dan jelaskan:**

```dart
test('NIK harus 16 digit', () {
  String nik = '12345'; // kurang dari 16 digit
  String? hasil = validateNIK(nik);
  expect(hasil, 'NIK harus 16 digit');
});
```

**Jelaskan:**

> "Untuk NIK saya test lebih kompleks:
>
> - NIK kosong harus error
> - NIK kurang dari 16 digit harus ditolak
> - NIK yang mengandung huruf harus ditolak
> - NIK yang benar (16 digit angka) seperti 3201012801990001 harus diterima"

---

### Bagian 3: Demo Patient Edit Test (4 menit)

**Buka file `patient_edit_test.dart`:**

**Jelaskan:**

> "Di halaman edit pasien, saya fokus test nomor telepon dan alamat karena ini field yang sering diupdate."

**Tunjuk kode nomor telepon:**

```dart
test('nomor telepon harus diawali 08', () {
  String noTelp = '6281234567890'; // tidak diawali 08
  String? hasil = validateNoTelp(noTelp);
  expect(hasil, 'Nomor telepon harus diawali dengan 08');
});
```

**Penjelasan:**

> "Nomor telepon di Indonesia harus:
>
> - Diawali dengan 08
> - Minimal 10 digit, maksimal 13 digit
> - Saya test semua skenario ini untuk memastikan data telepon valid"

**Scroll ke test alamat:**

```dart
test('alamat minimal 10 karakter', () {
  String alamat = 'Jl. ABC'; // kurang dari 10 karakter
  String? hasil = validateAlamat(alamat);
  expect(hasil, 'Alamat minimal 10 karakter');
});
```

**Jelaskan:**

> "Untuk alamat saya pastikan minimal 10 karakter supaya data alamat cukup detail dan berguna."

---

### Bagian 4: Demo Patient Registration Test (4 menit)

**Buka file `patient_registration_test.dart`:**

**Jelaskan:**

> "Ini yang paling menarik - test untuk nomor registrasi pasien yang punya format khusus."

**Tunjuk kode:**

```dart
test('nomor registrasi harus sesuai format', () {
  String noReg = 'ABC123'; // format salah
  String? hasil = validateNoReg(noReg);
  expect(hasil, 'Format nomor registrasi: R[YYMMDD]BS[5digit]');
});
```

**Penjelasan:**

> "Nomor registrasi di HomeCare punya format spesifik: R[YYMMDD]BS[5digit]
>
> - Contoh valid: R250115BS00001
> - R = prefix
> - 250115 = tanggal registrasi (25 Januari 2015)
> - BS = kode
> - 00001 = nomor urut
>
> Saya test untuk memastikan format ini selalu konsisten di database."

---

### Bagian 5: Running Tests (3 menit)

**Jalankan test di terminal:**

```bash
flutter test
```

**Sambil menunggu, jelaskan:**

> "Sekarang saya jalankan semua test. Flutter akan:
>
> 1. Compile semua test file
> 2. Menjalankan 20 test secara sequential
> 3. Menampilkan hasil pass/fail untuk setiap test"

**Ketika muncul hasil:**

```
00:03 +20: All tests passed!
```

**Jelaskan:**

> "Alhamdulillah, semua 20 test berhasil pass. Angka +20 menunjukkan 20 test yang saya buat semuanya berhasil. Waktu eksekusi hanya 3 detik karena ini unit test yang tidak bergantung ke database atau network."

**Jika ada yang fail (untuk jaga-jaga):**

> "Jika ada yang fail, Flutter akan menunjukkan detail error di line mana, expected value apa, dan actual value apa, sehingga saya bisa perbaiki dengan cepat."

---

### Bagian 6: Running Specific Test (2 menit)

**Tunjukkan cara run test spesifik:**

```bash
# Run hanya patient add test
flutter test test/patient_add_test.dart
```

**Jelaskan:**

> "Kita juga bisa run test tertentu saja, misalnya hanya test tambah pasien. Ini berguna ketika development untuk testing spesifik fitur yang sedang dikerjakan, tanpa perlu tunggu semua test selesai."

---

### Penutup (1 menit)

**Ringkasan:**

> "Jadi untuk kesimpulan:
>
> - Saya sudah implementasi 20 unit test untuk Patient Management
> - Mencakup validasi nama, NIK, nomor telepon, alamat, nomor registrasi, dan penanggung jawab
> - Semua test menggunakan pola AAA yang jelas dan mudah dipahami
> - Menggunakan data real dari aplikasi HomeCare seperti NIK 3201012801990001, nomor telepon 081234567890
> - Test ini memastikan data pasien yang masuk ke database selalu valid dan konsisten
>
> Terima kasih atas perhatiannya, Pak/Bu. Apakah ada pertanyaan?"

---

## 3. Antisipasi Pertanyaan Dosen

### Q1: "Kenapa fokus ke Patient Management saja?"

**Jawaban:**

> "Patient Management adalah core feature paling krusial di HomeCare, Pak/Bu. Data pasien harus akurat karena berhubungan dengan kesehatan. Kalau NIK salah atau nomor telepon salah, bisa fatal untuk komunikasi. Jadi saya prioritaskan test di fitur ini dulu. Untuk fitur lain seperti schedule dan reports akan saya tambahkan bertahap."

### Q2: "Kenapa NIK harus 16 digit?"

**Jawaban:**

> "NIK Indonesia standarnya 16 digit, Pak/Bu, sesuai dengan format KTP elektronik. Ini penting untuk validasi identitas pasien dan integrasi dengan sistem pemerintah kalau diperlukan. Saya pastikan formatnya benar sejak input."

### Q3: "Bagaimana test fitur yang butuh database?"

**Jawaban:**

> "Test yang saya buat ini adalah unit test murni, Pak/Bu - hanya test logic validasi tanpa database. Untuk test yang butuh database, kita bisa pakai integration test atau mock database dengan package seperti mocktail atau sqflite_common_ffi. Tapi untuk validasi form seperti ini, unit test sudah cukup."

### Q4: "Apa bedanya test ini dengan manual testing?"

**Jawaban:**

> "Manual testing Pak/Bu harus buka app, isi form, tekan submit, cek hasilnya - setiap kali ada perubahan. Unit test ini otomatis, cukup run `flutter test` dan dalam 3 detik sudah test 20 skenario. Jauh lebih cepat dan reliable, Pak/Bu. Plus, kalau ada orang lain ubah code dan break validasi, test akan langsung detect."

### Q5: "Coverage berapa persen?"

**Jawaban:**

> "Untuk calculate coverage saya bisa jalankan:
>
> ```bash
> flutter test --coverage
> ```
>
> Tapi untuk Patient Management ini saya fokus ke critical path dulu Pak/Bu - field-field yang paling penting dan sering error. Quality over quantity."

### Q6: "Kenapa format nomor registrasi begitu kompleks?"

**Jawaban:**

> "Format R[YYMMDD]BS[5digit] itu Pak/Bu biar mudah tracking:
>
> - Langsung keliatan tanggal registrasi dari nomor
> - BS adalah kode branch/lokasi
> - 5 digit terakhir adalah nomor urut
>   Dengan format ini kita bisa sort dan filter registrasi dengan mudah. Makanya saya test formatnya ketat supaya konsisten."

### Q7: "Apakah ini sudah production ready?"

**Jawaban:**

> "Untuk Patient Management validation sudah production ready, Pak/Bu. Tapi untuk keseluruhan aplikasi masih perlu test tambahan di fitur schedule, reports, authentication, dll. Ini adalah bagian dari continuous testing process dalam agile development."

---

## 4. Tips Presentasi

### Do's ✅

- Bicara dengan pace yang jelas dan tidak terburu-buru
- Tunjukkan confidence dengan explain setiap line code
- Hubungkan dengan real-world use case (kenapa NIK penting, dll)
- Pastikan terminal dan code editor sudah dibuka sebelum mulai
- Siapkan backup plan jika test fail (explain why bisa fail)
- Interaksi dengan dosen, eye contact

### Don'ts ❌

- Jangan baca slide/code mentah-mentah
- Jangan terlalu teknis kalau dosen tidak technical
- Jangan panik kalau ada error, stay calm
- Jangan bilang "ini template umum" - emphasize customization untuk HomeCare
- Jangan lupa ucap salam pembuka dan penutup

---

## 5. Backup Plan

### Jika Test Fail Saat Demo:

1. **Stay calm**, jangan panik
2. Baca error message dengan teliti
3. Jelaskan ke dosen: "Ini expected behavior, saya jelaskan kenapa..."
4. Tunjukkan screenshot test yang pass sebelumnya

### Jika VS Code Crash:

1. Siapkan backup: screenshot test results
2. Bisa switch ke command line terminal saja
3. Code bisa dibuka di notepad sebagai backup

### Jika Dosen Minta Tambah Test Live:

- Pakai template simpel:

```dart
test('test baru untuk email', () {
  // Arrange
  String email = 'homecare@test.com';

  // Act
  bool result = validateEmail(email);

  // Assert
  expect(result, true);
});
```

---

## 6. Checklist Sehari Sebelum Presentasi

- [ ] Run `flutter test` pastikan semua 20 test pass
- [ ] Charging laptop minimal 80%
- [ ] Install flutter doctor, pastikan semua ✓
- [ ] Backup code di USB/cloud
- [ ] Screenshot test results sebagai backup
- [ ] Print/save dokumentasi ini
- [ ] Latihan presentasi minimal 2x, focus ke timing
- [ ] Siapkan mental dan doa 🤲
- [ ] Baca lagi dokumentasi test untuk refresh

---

## 7. Timing Detail

| Bagian                    | Durasi       | Catatan                            |
| ------------------------- | ------------ | ---------------------------------- |
| Pembukaan                 | 1 menit      | Salam & intro                      |
| Struktur                  | 2 menit      | Show folder structure              |
| Patient Add Test          | 5 menit      | Deep dive NIK & nama validation    |
| Patient Edit Test         | 4 menit      | Explain phone & address validation |
| Patient Registration Test | 4 menit      | Complex format validation          |
| Running Tests             | 3 menit      | Live demo                          |
| Specific Test             | 2 menit      | Show flexibility                   |
| Penutup                   | 1 menit      | Summary & terima kasih             |
| **Total**                 | **22 menit** | Bisa adjust sesuai waktu           |

---

## 8. Key Points to Emphasize

1. **Real-world relevance**: Data pasien harus akurat untuk healthcare
2. **Indonesian context**: NIK 16 digit, phone 08-prefix, format registrasi
3. **AAA pattern**: Clear, maintainable test structure
4. **Fast execution**: 20 tests dalam 3 detik
5. **Comprehensive coverage**: Semua input validation covered

---

## Good Luck! 🚀

Ingat: Dosen mau lihat **pemahaman** kamu tentang:

1. Kenapa testing penting di healthcare app
2. Konsep AAA dan implementasinya
3. Validasi data yang comprehensive
4. Best practices Flutter testing

**Kamu pasti bisa!** 💪 Testing ini solid dan real-world applicable.
