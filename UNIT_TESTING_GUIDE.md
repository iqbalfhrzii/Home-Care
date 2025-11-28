# 📝 Unit Testing - HomeCare Mobile App

**Oleh: Iqbal Fahrozi**

---

## 📊 Ringkasan

- **Total Test Files:** 3
- **Total Test Cases:** 10
- **Success Rate:** 100% ✅

```
00:04 +10: All tests passed!
```

---

## 📁 File Test yang Dibuat

### 1️⃣ **validation_test.dart** (6 tests)

Testing fungsi validasi email dan password

**Test Cases:**

- ✅ Email kosong ga boleh
- ✅ Email tanpa @ ditolak
- ✅ Email yang valid diterima
- ✅ Password kosong harus error
- ✅ Password kurang dari 6 karakter ditolak
- ✅ Password valid diterima

**Cara Jalankan:**

```bash
flutter test test/validation_test.dart
```

---

### 2️⃣ **login_widget_test.dart** (2 tests)

Testing widget form login

**Test Cases:**

- ✅ Field email ada label dan icon
- ✅ Tombol login bisa diklik

**Cara Jalankan:**

```bash
flutter test test/login_widget_test.dart
```

---

### 3️⃣ **math_test.dart** (2 tests)

Testing fungsi matematika sederhana

**Test Cases:**

- ✅ Penjumlahan angka
- ✅ Pengurangan angka

**Cara Jalankan:**

```bash
flutter test test/math_test.dart
```

---

## 🎯 Konsep yang Diterapkan

### AAA Pattern (Arrange-Act-Assert)

Semua test menggunakan struktur:

1. **Arrange** - Persiapan data
2. **Act** - Jalankan fungsi
3. **Assert** - Cek hasil

**Contoh:**

```dart
test('email kosong ga boleh', () {
  // Arrange - persiapkan data
  String? email;

  // Act - jalankan fungsi
  final result = validateEmail(email);

  // Assert - cek hasil
  expect(result, 'Valid email required');
});
```

---

## 🚀 Cara Menjalankan Test

### Semua Test Sekaligus

```bash
flutter test
```

### Test Spesifik

```bash
flutter test test/validation_test.dart
flutter test test/login_widget_test.dart
flutter test test/math_test.dart
```

---

## 📖 Penjelasan per Test File

### **1. validation_test.dart**

#### Test: "email kosong ga boleh"

```dart
test('email kosong ga boleh', () {
  String? email;  // email = null
  final result = validateEmail(email);
  expect(result, 'Valid email required');  // harus error
});
```

**Penjelasan:** Test ini memastikan kalau email kosong/null akan ditolak.

#### Test: "email tanpa @ ditolak"

```dart
test('email tanpa @ ditolak', () {
  const email = 'iqbalfahrozi.com';  // tanpa @
  final result = validateEmail(email);
  expect(result, 'Valid email required');  // harus error
});
```

**Penjelasan:** Email harus ada simbol @ untuk valid.

#### Test: "email yang valid diterima"

```dart
test('email yang valid diterima', () {
  const email = 'homecare@test.com';  // format benar
  final result = validateEmail(email);
  expect(result, null);  // ga ada error = valid
});
```

**Penjelasan:** Email dengan format benar diterima sistem.

---

### **2. login_widget_test.dart**

#### Test: "field email ada label dan icon"

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

**Penjelasan:** Test ini cek apakah text field email punya label "Email Address" dan icon email.

---

### **3. math_test.dart**

#### Test: "penjumlahan angka"

```dart
test('penjumlahan angka', () {
  const a = 10;
  const b = 5;
  const hasil = a + b;
  expect(hasil, 15);  // 10 + 5 = 15
});
```

**Penjelasan:** Test sederhana untuk operasi penjumlahan.

---

## 💡 Kenapa Unit Testing Penting?

1. **Cegah Bug** - Deteksi error sebelum masuk production
2. **Dokumentasi** - Test jadi dokumentasi cara pakai fungsi
3. **Confidence** - Yakin kode bekerja sesuai ekspektasi
4. **Maintenance** - Mudah refactor tanpa takut rusak

---

## ✅ Kesimpulan

Unit testing yang saya buat mencakup:

- ✅ **Unit Test** untuk validasi email & password
- ✅ **Widget Test** untuk komponen UI login
- ✅ **Basic Test** untuk fungsi matematika

Semua test berhasil 100% dan mudah dipahami!

---

**Terima kasih! 🙏**
