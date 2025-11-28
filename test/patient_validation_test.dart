import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validasi Form Pasien', () {
    String? validateNama(String? value) {
      if (value == null || value.isEmpty) {
        return 'Nama tidak boleh kosong';
      }
      if (value.length < 3) {
        return 'Nama minimal 3 karakter';
      }
      return null;
    }

    String? validateNIK(String? value) {
      if (value == null || value.isEmpty) {
        return 'NIK tidak boleh kosong';
      }
      if (value.length != 16) {
        return 'NIK harus 16 digit';
      }
      if (!RegExp(r'^\d+$').hasMatch(value)) {
        return 'NIK harus berupa angka';
      }
      return null;
    }

    String? validateNoTelp(String? value) {
      if (value == null || value.isEmpty) {
        return 'Nomor telepon tidak boleh kosong';
      }
      if (!value.startsWith('08')) {
        return 'Nomor telepon harus diawali 08';
      }
      if (value.length < 10 || value.length > 13) {
        return 'Nomor telepon harus 10-13 digit';
      }
      return null;
    }

    String? validateAlamat(String? value) {
      if (value == null || value.isEmpty) {
        return 'Alamat tidak boleh kosong';
      }
      if (value.length < 10) {
        return 'Alamat minimal 10 karakter';
      }
      return null;
    }

    test('nama kosong harus error', () {
      String nama = '';
      String? hasil = validateNama(nama);
      expect(hasil, 'Nama tidak boleh kosong');
    });

    test('nama kurang dari 3 karakter ditolak', () {
      String nama = 'Iq';
      String? hasil = validateNama(nama);
      expect(hasil, 'Nama minimal 3 karakter');
    });

    test('nama valid diterima', () {
      String nama = 'Iqbal Fahrozi';
      String? hasil = validateNama(nama);
      expect(hasil, null);
    });

    test('NIK harus 16 digit', () {
      String nik = '12345';
      String? hasil = validateNIK(nik);
      expect(hasil, 'NIK harus 16 digit');
    });

    test('NIK dengan huruf ditolak', () {
      String nik = '320101280199000A';
      String? hasil = validateNIK(nik);
      expect(hasil, 'NIK harus berupa angka');
    });

    test('NIK valid diterima', () {
      String nik = '3201012801990001';
      String? hasil = validateNIK(nik);
      expect(hasil, null);
    });

    test('nomor telepon harus diawali 08', () {
      String noTelp = '6281234567890';
      String? hasil = validateNoTelp(noTelp);
      expect(hasil, 'Nomor telepon harus diawali 08');
    });

    test('nomor telepon valid diterima', () {
      String noTelp = '081234567890';
      String? hasil = validateNoTelp(noTelp);
      expect(hasil, null);
    });

    test('alamat minimal 10 karakter', () {
      String alamat = 'Jl. ABC';
      String? hasil = validateAlamat(alamat);
      expect(hasil, 'Alamat minimal 10 karakter');
    });
  });
}
