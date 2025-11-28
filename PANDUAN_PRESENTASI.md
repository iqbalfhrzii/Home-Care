# 🎤 Panduan Presentasi Unit Testing ke Dosen

**Untuk: Iqbal Fahrozi**

---

## 📋 PEMBUKAAN (1 menit)

**Ucapan:**

> "Selamat pagi/siang Pak/Bu. Saya Iqbal Fahrozi akan mempresentasikan tugas unit testing untuk aplikasi HomeCare Mobile."
>
> "Saya sudah membuat **10 unit test cases** yang semuanya berhasil passed 100%."

**Action:**

1. Buka terminal
2. Jalankan: `flutter test`
3. Tunjukkan output: `00:04 +10: All tests passed! ✅`

**Jelaskan:**

> "Ini hasil running semua test. Angka +10 artinya 10 test semuanya passed."

---

## 📂 STRUKTUR FILE (30 detik)

**Ucapkan:**

> "Saya buat 3 file test yang dibagi berdasarkan fungsinya."

**Tunjukkan folder test:**

```
test/
├── validation_test.dart      (6 tests)
├── login_widget_test.dart    (2 tests)
└── math_test.dart            (2 tests)
```

---

## 🧪 DEMO 1: Test Validasi (3 menit)

**Ucapkan:**

> "Pertama saya tunjukkan test paling sederhana, yaitu test validasi email dan password."

**Action:**

1. Buka file: `test/validation_test.dart`
2. Scroll ke test pertama

**Tunjukkan kode:**

```dart
test('email kosong ga boleh', () {
  String? email;
  final result = validateEmail(email);
  expect(result, 'Valid email required');
});
```

**Jelaskan:**

> "Ini adalah unit test sederhana dengan 3 langkah:"
>
> **1. Arrange (Persiapan):**
>
> - Saya bikin variable email dengan value null
>
> **2. Act (Aksi):**
>
> - Saya panggil fungsi validateEmail dengan email null
>
> **3. Assert (Cek):**
>
> - Saya expect hasilnya harus error 'Valid email required'

**Tunjukkan test kedua:**

```dart
test('email tanpa @ ditolak', () {
  const email = 'iqbalfahrozi.com';
  final result = validateEmail(email);
  expect(result, 'Valid email required');
});
```

**Jelaskan:**

> "Test ini cek email tanpa simbol @, harusnya ditolak."

**Tunjukkan test ketiga:**

```dart
test('email yang valid diterima', () {
  const email = 'homecare@test.com';
  final result = validateEmail(email);
  expect(result, null);  // null = tidak ada error
});
```

**Jelaskan:**

> "Kalau emailnya valid dengan format benar, harusnya return null yang artinya tidak ada error."

**Action:**
Jalankan test: `flutter test test/validation_test.dart`

**Jelaskan hasil:**

> "Ada 6 test di file ini: 3 untuk validasi email, 3 untuk validasi password. Semuanya passed."

---

## 🎨 DEMO 2: Test Widget (2 menit)

**Ucapkan:**

> "Sekarang saya tunjukkan widget test untuk test tampilan UI."

**Action:**

1. Buka file: `test/login_widget_test.dart`

**Tunjukkan kode:**

```dart
testWidgets('field email ada label dan icon', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextFormField(
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email),
          ),
        ),
      ),
    ),
  );

  expect(find.text('Email Address'), findsOneWidget);
  expect(find.byIcon(Icons.email), findsOneWidget);
});
```

**Jelaskan:**

> "Widget test ini lebih kompleks karena test komponen UI:"
>
> **Arrange:**
>
> - Saya bikin TextFormField dengan label dan icon
>
> **Act:**
>
> - Saya render widget pakai `tester.pumpWidget()`
>
> **Assert:**
>
> - Saya cek apakah text 'Email Address' muncul
> - Saya cek apakah icon email muncul
> - `findsOneWidget` artinya harus ketemu tepat 1 widget

**Action:**
Jalankan: `flutter test test/login_widget_test.dart`

---

## 🔢 DEMO 3: Test Matematika (1 menit)

**Ucapkan:**

> "Terakhir, test sederhana untuk operasi matematika."

**Action:**

1. Buka file: `test/math_test.dart`

**Tunjukkan kode:**

```dart
test('penjumlahan angka', () {
  const a = 10;
  const b = 5;
  const hasil = a + b;
  expect(hasil, 15);
});
```

**Jelaskan:**

> "Test ini sangat simple, cuma cek 10 + 5 = 15. Ini untuk tunjukkan konsep dasar testing."

---

## 🎯 PENJELASAN KONSEP (2 menit)

**Ucapkan:**

> "Izinkan saya jelaskan konsep penting yang saya terapkan."

**Jelaskan:**

### 1. AAA Pattern

> "Semua test saya pakai pola AAA:"
>
> - **Arrange**: Setup data
> - **Act**: Jalankan fungsi
> - **Assert**: Cek hasil
>
> "Ini bikin test mudah dibaca dan dipahami."

### 2. Test yang Jelas

> "Nama test saya buat jelas dalam Bahasa Indonesia:"
>
> - ❌ Buruk: `test1()`, `testValidation()`
> - ✅ Baik: `email kosong ga boleh`, `password kurang dari 6 karakter ditolak`

### 3. Coverage yang Lengkap

> "Saya test berbagai kondisi:"
>
> - Input **kosong/null**
> - Input **tidak valid** (email tanpa @)
> - Input **valid**

---

## 📊 DEMO FINAL (1 menit)

**Ucapkan:**

> "Sekarang saya jalankan semua test sekaligus."

**Action:**

```bash
flutter test
```

**Tunjukkan output:**

```
00:04 +10: All tests passed!
```

**Jelaskan:**

> "Semua 10 test cases berhasil dalam 4 detik. Tidak ada yang failed."

---

## 🎬 PENUTUP (1 menit)

**Ucapkan:**

> "Jadi kesimpulannya, saya sudah membuat unit testing yang mencakup:"
>
> ✅ **Unit Test** - untuk test fungsi validasi (6 tests)
> ✅ **Widget Test** - untuk test komponen UI (2 tests)
> ✅ **Basic Test** - untuk test fungsi dasar (2 tests)
>
> "Total 10 test cases, semuanya passed 100%."
>
> "Unit testing ini penting untuk:"
>
> 1. **Mencegah bug** sebelum masuk production
> 2. **Dokumentasi** cara pakai fungsi
> 3. **Confidence** bahwa kode bekerja dengan baik
>
> "Sekian presentasi saya, terima kasih. Apakah ada pertanyaan?"

---

## 💡 TIPS PENTING

### ✅ DO

1. Bicara **pelan dan jelas**
2. **Jalankan test live** di depan dosen
3. **Tunjukkan kode** sambil dijelaskan
4. **Percaya diri** - kode Anda sudah bekerja
5. Siap **jawab pertanyaan**

### ❌ DON'T

1. Jangan baca kode baris per baris
2. Jangan cuma tunjukkan screenshot
3. Jangan terburu-buru
4. Jangan panik kalau ada pertanyaan

---

## ❓ ANTISIPASI PERTANYAAN

### Q: "Apa bedanya unit test dan widget test?"

**Jawab:**

> "Unit test untuk test fungsi/logic tanpa UI, contohnya validasi email. Widget test untuk test tampilan UI, contohnya apakah tombol muncul atau tidak."

### Q: "Kenapa pakai Flutter Test?"

**Jawab:**

> "Flutter Test adalah framework testing resmi dari Flutter yang sudah built-in. Mudah digunakan dan support untuk unit test dan widget test."

### Q: "Kenapa penting bikin unit test?"

**Jawab:**

> "Untuk memastikan kode bekerja sesuai ekspektasi, mencegah bug ketika ada perubahan kode, dan sebagai dokumentasi."

### Q: "Berapa lama bikin semua test ini?"

**Jawab:**

> "Sekitar 2-3 jam. Saya mulai dari test sederhana dulu (matematika), lalu validasi, baru widget test."

### Q: "Apa challenge nya?"

**Jawab:**

> "Challenge nya di widget test karena harus setup MaterialApp dan Scaffold. Tapi saya ikuti dokumentasi Flutter dan berhasil."

---

## ⏱️ TIME BREAKDOWN

**Total: ~12 menit**

1. Pembukaan - 1 menit
2. Struktur file - 30 detik
3. Demo validation test - 3 menit
4. Demo widget test - 2 menit
5. Demo math test - 1 menit
6. Penjelasan konsep - 2 menit
7. Demo final - 1 menit
8. Penutup - 1 menit
9. Q&A - sisanya

---

## 🎯 CHECKLIST SEBELUM PRESENTASI

- [ ] Pastikan semua test passed (`flutter test`)
- [ ] Buka semua file test di VS Code tabs
- [ ] Siapkan terminal
- [ ] Baca panduan ini 2-3 kali
- [ ] Latihan presentasi sekali
- [ ] Percaya diri! 💪

---

**Good luck, Iqbal! 🚀**
