# API to Database Mapping

Dokumentasi ini menjelaskan mapping antara JSON API Registrasi dengan tabel database lokal.

## Overview Struktur

API mengembalikan satu object registrasi yang mencakup semua relasi:

- Pasien
- Penanggung (embedded dalam registrasi)
- Anamnesa
- ICD (many-to-many)
- Tindakan (many-to-many dengan pivot data)
- Tagihan dan Tagihan Items
- Dokter
- Poli
- User (dalam tagihan)
- Kategori Layanan (dalam tagihan items)

## Table Mapping

### 1. Pasiens Table

**API Path:** `data.pasien`

| Database Column | API Field            | Type     | Notes                       |
| --------------- | -------------------- | -------- | --------------------------- |
| id              | -                    | int      | Auto increment (local only) |
| mrn             | pasien.mrn           | string   | Medical Record Number       |
| nama            | pasien.nama          | string   |                             |
| tanggalLahir    | pasien.tanggal_lahir | datetime | Parse dari string           |
| jenisKelamin    | pasien.jenis_kelamin | string   | L/P                         |
| alamat          | pasien.alamat        | string   |                             |
| telepon         | pasien.telepon       | string   |                             |
| createdAt       | pasien.created_at    | datetime |                             |
| updatedAt       | pasien.updated_at    | datetime |                             |

**Notes:**

- Field `pasien.id` dari API akan disimpan sebagai reference eksternal jika diperlukan
- Field `pasien.registrasi[]` tidak perlu disimpan karena redundan

---

### 2. Dokters Table

**API Path:** `data.anamnesa.dokter`

| Database Column | API Field              | Type     | Notes                       |
| --------------- | ---------------------- | -------- | --------------------------- |
| id              | -                      | int      | Auto increment (local only) |
| dokterId        | dokter.dokter_id       | string   | Kode dokter (unique)        |
| namaDokter      | dokter.nama_dokter     | string   |                             |
| bidangKeahlian  | dokter.bidang_keahlian | string   | Nullable                    |
| isActive        | dokter.is_active       | bool     |                             |
| createdAt       | dokter.created_at      | datetime |                             |
| updatedAt       | dokter.updated_at      | datetime |                             |

**Notes:**

- Dokter bisa di-sync dari berbagai endpoint anamnesa
- `dokter.id` dari API adalah reference eksternal

---

### 3. Polis Table

**API Path:** `data.anamnesa.poli[]`

| Database Column | API Field       | Type     | Notes                       |
| --------------- | --------------- | -------- | --------------------------- |
| id              | -               | int      | Auto increment (local only) |
| kodePoli        | poli.kode_poli  | string   | Unique identifier           |
| namaPoli        | poli.nama_poli  | string   |                             |
| createdAt       | poli.created_at | datetime |                             |
| updatedAt       | poli.updated_at | datetime |                             |

**Notes:**

- API mengembalikan array poli (multiple poli entries possible)
- `poli.id` dari API adalah reference eksternal
- `poli.anamnesa[]` tidak disimpan (redundant)

---

### 4. Icds Table (Master Data)

**API Path:** `data.icd[]`

| Database Column | API Field      | Type     | Notes                       |
| --------------- | -------------- | -------- | --------------------------- |
| id              | -              | int      | Auto increment (local only) |
| kode            | icd.kode       | string   | ICD-10 code                 |
| deskripsi       | icd.deskripsi  | string   |                             |
| katIcd          | icd.kat_icd    | string   | Kategori ICD, nullable      |
| isActive        | icd.is_active  | bool     |                             |
| createdAt       | icd.created_at | datetime |                             |
| updatedAt       | icd.updated_at | datetime |                             |

**Notes:**

- `icd.id` dari API adalah reference eksternal
- `icd.registrasi[]` tidak disimpan (many-to-many via junction table)

---

### 5. Tindakans Table (Master Data)

**API Path:** `data.tindakan[]`

| Database Column | API Field           | Type     | Notes                       |
| --------------- | ------------------- | -------- | --------------------------- |
| id              | -                   | int      | Auto increment (local only) |
| kode            | tindakan.kode       | string   | Kode tindakan               |
| deskripsi       | tindakan.deskripsi  | string   |                             |
| tarif           | tindakan.tarif      | string   | Currency string             |
| isActive        | tindakan.is_active  | bool     |                             |
| createdAt       | tindakan.created_at | datetime |                             |
| updatedAt       | tindakan.updated_at | datetime |                             |

**Notes:**

- `tindakan.id` dari API adalah reference eksternal
- `tindakan.pivot` disimpan di junction table `RegistrasiTindakans`
- `tindakan.registrasi[]` tidak disimpan

---

### 6. Users Table

**API Path:** `data.tagihan.user`

| Database Column        | API Field                      | Type     | Notes                       |
| ---------------------- | ------------------------------ | -------- | --------------------------- |
| id                     | -                              | int      | Auto increment (local only) |
| name                   | user.name                      | string   |                             |
| email                  | user.email                     | string   |                             |
| emailVerifiedAt        | user.email_verified_at         | datetime | Nullable                    |
| twoFactorSecret        | user.two_factor_secret         | string   | Nullable                    |
| twoFactorRecoveryCodes | user.two_factor_recovery_codes | string   | Nullable                    |
| twoFactorConfirmedAt   | user.two_factor_confirmed_at   | string   | Nullable                    |
| createdAt              | user.created_at                | datetime |                             |
| updatedAt              | user.updated_at                | datetime |                             |

**Notes:**

- `user.id` dari API adalah reference eksternal
- User info dari tagihan (siapa yang mencetak)

---

### 7. KategoriLayanans Table

**API Path:** `data.tagihan.items[].kategori_layanan`

| Database Column | API Field                   | Type     | Notes                       |
| --------------- | --------------------------- | -------- | --------------------------- |
| id              | -                           | int      | Auto increment (local only) |
| kode            | kategori_layanan.kode       | string   |                             |
| nama            | kategori_layanan.nama       | string   |                             |
| urutan          | kategori_layanan.urutan     | int      | Display order               |
| createdAt       | kategori_layanan.created_at | datetime |                             |
| updatedAt       | kategori_layanan.updated_at | datetime |                             |

**Notes:**

- `kategori_layanan.id` dari API adalah reference eksternal
- `kategori_layanan.tagihan_items[]` tidak disimpan (redundant)

---

### 8. Registrasis Table (Main Transaction)

**API Path:** `data` (root level)

| Database Column     | API Field                  | Type     | Notes                       |
| ------------------- | -------------------------- | -------- | --------------------------- |
| id                  | -                          | int      | Auto increment (local only) |
| noReg               | data.no_reg                | string   | Registration number         |
| noUrut              | data.no_urut               | string   | Queue number, nullable      |
| pasienId            | -                          | int      | FK to Pasiens.id (local)    |
| tglJamReg           | data.tgl_jam_reg           | string   | Registration datetime       |
| kodePoli            | data.kode_poli             | string   | Nullable                    |
| dokterId            | data.dokter_id             | string   | Nullable                    |
| jenisKunjungan      | data.jenis_kunjungan       | string   | Kunjungan Pertama/Ulang     |
| asalPasien          | data.asal_pasien           | string   | Nullable                    |
| tipePasien          | data.tipe_pasien           | string   | Umum/BPJS/Asuransi          |
| pasienBaru          | data.pasien_baru           | int      | 0 atau 1                    |
| pagiSore            | data.pagi_sore             | string   | pagi/sore, nullable         |
| isCash              | data.is_cash               | int      | 0 atau 1                    |
| isPribadi           | data.is_pribadi            | int      | 0 atau 1                    |
| eselon              | data.eselon                | string   | Nullable                    |
| status              | data.status                | string   | Nullable                    |
| penanggungId        | data.penanggung.id         | string   | Nullable                    |
| penanggungNama      | data.penanggung.nama       | string   | Nullable                    |
| penanggungNoPegawai | data.penanggung.no_pegawai | string   | Nullable                    |
| penanggungAlamat    | data.penanggung.alamat     | string   | Nullable                    |
| penanggungTelepon   | data.penanggung.telepon    | string   | Nullable                    |
| createdAt           | data.created_at            | datetime |                             |
| updatedAt           | data.updated_at            | datetime |                             |

**Notes:**

- `data.id` dari API adalah reference eksternal
- `data.pasien_id` dari API digunakan untuk lookup Pasien
- Penanggung embedded dalam Registrasi (denormalized)
- `data.pasien`, `data.anamnesa`, `data.icd[]`, `data.tindakan[]`, `data.tagihan` disimpan di table terpisah

---

### 9. Anamnesas Table

**API Path:** `data.anamnesa`

| Database Column       | API Field                       | Type        | Notes                              |
| --------------------- | ------------------------------- | ----------- | ---------------------------------- |
| id                    | -                               | int         | Auto increment (local only)        |
| registrasiId          | -                               | int         | FK to Registrasis.id (local)       |
| dokterId              | -                               | int         | FK to Dokters.id (local), nullable |
| poliId                | anamnesa.poli_id                | string      | Kode poli, nullable                |
| tanggal               | anamnesa.tanggal                | string      | Nullable                           |
| pengkajianKeperawatan | anamnesa.pengkajian_keperawatan | JSON string | Complex nested object              |
| pengkajianMedis       | anamnesa.pengkajian_medis       | JSON string | Complex nested object              |
| khususPerawat         | anamnesa.khusus_perawat         | JSON string | Complex nested object              |
| createdAt             | anamnesa.created_at             | datetime    |                                    |
| updatedAt             | anamnesa.updated_at             | datetime    |                                    |

**Notes:**

- `anamnesa.id` dari API adalah reference eksternal
- `anamnesa.registrasi_id` dari API digunakan untuk link ke Registrasi
- `anamnesa.dokter_id` dari API digunakan untuk lookup Dokter
- Complex nested objects (pengkajian_keperawatan, pengkajian_medis, khusus_perawat) disimpan sebagai JSON string
- `anamnesa.registrasi`, `anamnesa.dokter`, `anamnesa.poli[]` tidak disimpan (redundant dengan relasi)

#### Pengkajian Keperawatan Structure (JSON):

```json
{
  "tanda_vital": {
    "tekanan_darah": "string",
    "nadi": 0,
    "suhu": 0,
    "pernapasan": 0,
    "riwayat_alergi": true
  },
  "nutrisi": {
    "berat_badan": "string",
    "tinggi_badan": "string",
    "imt": 0,
    "lingkar_kepala": "string"
  },
  "fungsional": {
    "alat_bantu": "string",
    "prothesa": "string",
    "cacat_tubuh": "string",
    "adl": true,
    "resiko_jatuh": true,
    "riwayat": "string"
  },
  "keluhan": {
    "keluhan": "string"
  },
  "masalah_keperawatan": {
    "jalan_nafas": true,
    "pola_nafas": true,
    "hipertermia": true,
    "nyeri_akut": true,
    "nyeri_kronik": true,
    "mual": true,
    "gangguan_perfusi": true,
    "gangguan_cairan": true,
    "lainnya": "string"
  }
}
```

#### Pengkajian Medis Structure (JSON):

```json
{
  "pemeriksaan_fisik": "string",
  "diagnosis": "string",
  "rencana_dan_terapi": "string",
  "pemeriksaan_penunjang": "string",
  "kontrol": "string",
  "jenis_perawatan": "string",
  "rujukan": {
    "tujuan": "string"
  }
}
```

#### Khusus Perawat Structure (JSON):

```json
{
  "intervensi_time_up_go": {
    "cara_berjalan": true,
    "cara_berjalan2": true,
    "menopang": true,
    "risiko": "string"
  },
  "skrining_mst_dewasa": {
    "nutrisi_bb": "string",
    "asup_makan": "string"
  },
  "skrining_strongkids": {
    "strong_kids1": true,
    "strong_kids2": true,
    "strong_kids3": true,
    "strong_kids4": true
  },
  "edukasi": {
    "edukasi": true,
    "edukasi_ket": "string"
  },
  "rencana_pulang": {
    "renc_usia_lanjut": true,
    "renc_hmbtn_mobil": true,
    "renc_layanan_medis": true,
    "renc_tergnt_org": true
  }
}
```

---

### 10. RegistrasiIcds Table (Junction)

**API Path:** `data.icd[]` (many-to-many relationship)

| Database Column | API Field | Type     | Notes                        |
| --------------- | --------- | -------- | ---------------------------- |
| id              | -         | int      | Auto increment               |
| registrasiId    | -         | int      | FK to Registrasis.id (local) |
| icdId           | -         | int      | FK to Icds.id (local)        |
| createdAt       | -         | datetime | Local timestamp              |

**Notes:**

- Satu registrasi bisa punya banyak ICD codes
- `data.icd[]` adalah array, perlu loop untuk insert ke junction table
- Lookup ICD by `kode` untuk mendapatkan `icdId` lokal

---

### 11. RegistrasiTindakans Table (Junction dengan Pivot)

**API Path:** `data.tindakan[]` (many-to-many with pivot data)

| Database Column | API Field                      | Type     | Notes                        |
| --------------- | ------------------------------ | -------- | ---------------------------- |
| id              | -                              | int      | Auto increment               |
| registrasiId    | -                              | int      | FK to Registrasis.id (local) |
| tindakanId      | -                              | int      | FK to Tindakans.id (local)   |
| jumlah          | tindakan.pivot.jumlah          | string   | Nullable                     |
| hargaSatuan     | tindakan.pivot.harga_satuan    | string   | Nullable                     |
| diskon          | tindakan.pivot.diskon          | string   | Nullable                     |
| subtotal        | tindakan.pivot.subtotal        | string   | Nullable                     |
| petugasNama     | tindakan.pivot.petugas_nama    | string   | Nullable                     |
| keterangan      | tindakan.pivot.keterangan      | string   | Nullable                     |
| kunjunganKe     | tindakan.pivot.kunjungan_ke    | string   | Nullable                     |
| isFree          | tindakan.pivot.is_free         | string   | Nullable                     |
| dokterId        | tindakan.pivot.dokter_id       | string   | Nullable                     |
| poliId          | tindakan.pivot.poli_id         | string   | Nullable                     |
| tanggalLayanan  | tindakan.pivot.tanggal_layanan | string   | Nullable                     |
| createdAt       | -                              | datetime | Local timestamp              |

**Notes:**

- Pivot data menyimpan informasi spesifik untuk tindakan pada registrasi ini
- `data.tindakan[]` adalah array, perlu loop untuk insert
- Lookup Tindakan by `kode` untuk mendapatkan `tindakanId` lokal

---

### 12. Tagihans Table

**API Path:** `data.tagihan`

| Database Column       | API Field                        | Type     | Notes                            |
| --------------------- | -------------------------------- | -------- | -------------------------------- |
| id                    | -                                | int      | Auto increment (local only)      |
| registrasiId          | -                                | int      | FK to Registrasis.id (local)     |
| noInvoice             | tagihan.no_invoice               | string   |                                  |
| tanggalInvoice        | tagihan.tanggal_invoice          | string   | Nullable                         |
| totalBiaya            | tagihan.total_biaya              | string   | Currency string                  |
| deposit               | tagihan.deposit                  | string   | Nullable                         |
| biayaYangHarusDibayar | tagihan.biaya_yang_harus_dibayar | string   | Nullable                         |
| terbilang             | tagihan.terbilang                | string   | Nullable                         |
| primaryIcd            | tagihan.primary_icd              | string   | Nullable                         |
| statusPembayaran      | tagihan.status_pembayaran        | string   | belum_bayar/lunas                |
| dicetakOleh           | tagihan.dicetak_oleh             | string   | Nullable                         |
| tanggalCetak          | tagihan.tanggal_cetak            | string   | Nullable                         |
| printLocation         | tagihan.print_location           | string   | Nullable                         |
| serverTime            | tagihan.server_time              | string   | Nullable                         |
| computerTime          | tagihan.computer_time            | string   | Nullable                         |
| userId                | -                                | int      | FK to Users.id (local), nullable |
| createdAt             | tagihan.created_at               | datetime |                                  |
| updatedAt             | tagihan.updated_at               | datetime |                                  |

**Notes:**

- `tagihan.id` dari API adalah reference eksternal
- `tagihan.registrasi_id` dari API digunakan untuk link ke Registrasi
- `tagihan.user` disimpan di table Users terpisah
- `tagihan.items[]` disimpan di table TagihanItems
- `tagihan.registrasi` tidak disimpan (redundant)

---

### 13. TagihanItems Table

**API Path:** `data.tagihan.items[]`

| Database Column   | API Field             | Type     | Notes                                       |
| ----------------- | --------------------- | -------- | ------------------------------------------- |
| id                | -                     | int      | Auto increment (local only)                 |
| tagihanId         | -                     | int      | FK to Tagihans.id (local)                   |
| kategoriLayananId | -                     | int      | FK to KategoriLayanans.id (local), nullable |
| kodeLayanan       | items.kode_layanan    | string   | Nullable                                    |
| deskripsi         | items.deskripsi       | string   | Nullable                                    |
| jumlah            | items.jumlah          | int      |                                             |
| hargaSatuan       | items.harga_satuan    | string   | Nullable                                    |
| diskon            | items.diskon          | string   | Nullable                                    |
| subtotal          | items.subtotal        | string   | Nullable                                    |
| tanggalLayanan    | items.tanggal_layanan | string   | Nullable                                    |
| urutan            | items.urutan          | int      | Display order                               |
| createdAt         | items.created_at      | datetime |                                             |
| updatedAt         | items.updated_at      | datetime |                                             |

**Notes:**

- `items.id` dari API adalah reference eksternal
- `items.tagihan_id` dari API digunakan untuk link ke Tagihan
- `items.kategori_layanan_id` dari API digunakan untuk lookup KategoriLayanan
- `items.tagihan` dan `items.kategori_layanan` tidak disimpan (redundant dengan relasi)
- Array items perlu di-loop untuk insert semua items

---

## Sync Strategy

### 1. Master Data (Sync First)

Sync master data terlebih dahulu sebelum transaksi:

- Dokters
- Polis
- Icds
- Tindakans
- Users
- KategoriLayanans

### 2. Transaction Data (Sync dengan Dependencies)

```
1. Pasiens (check by MRN, insert/update)
2. Registrasis (insert, get local ID)
3. Anamnesas (insert dengan registrasiId lokal)
4. RegistrasiIcds (loop icd[], insert junction)
5. RegistrasiTindakans (loop tindakan[], insert junction dengan pivot)
6. Tagihans (insert dengan registrasiId lokal, userId lokal)
7. TagihanItems (loop items[], insert dengan tagihanId lokal)
```

### 3. ID Mapping

Karena database lokal menggunakan auto-increment, perlu mapping:

- Simpan `external_id` (ID dari API) sebagai field terpisah jika perlu sync 2-way
- Atau gunakan lookup by unique identifier (MRN, no_reg, kode, dll)

## Example Sync Code Pattern

```dart
Future<void> syncRegistrasiFromApi(Map<String, dynamic> apiData) async {
  final db = getIt<AppDatabase>();

  // 1. Sync Pasien
  final pasienData = apiData['pasien'];
  Pasien? pasien = await db.getPasienByMrn(pasienData['mrn']);

  if (pasien == null) {
    // Insert new patient
    final pasienId = await db.insertPasien(
      PasiensCompanion.insert(
        mrn: pasienData['mrn'],
        nama: pasienData['nama'],
        tanggalLahir: DateTime.parse(pasienData['tanggal_lahir']),
        jenisKelamin: pasienData['jenis_kelamin'],
        alamat: pasienData['alamat'],
        telepon: pasienData['telepon'],
        createdAt: Value(DateTime.parse(pasienData['created_at'])),
        updatedAt: Value(DateTime.parse(pasienData['updated_at'])),
      ),
    );
    pasien = await db.getPasienById(pasienId);
  }

  // 2. Sync Registrasi
  final registrasiId = await db.insertRegistrasi(
    RegistrasisCompanion.insert(
      noReg: apiData['no_reg'],
      noUrut: Value(apiData['no_urut']),
      pasienId: pasien!.id,
      tglJamReg: apiData['tgl_jam_reg'],
      kodePoli: Value(apiData['kode_poli']),
      dokterId: Value(apiData['dokter_id']),
      jenisKunjungan: apiData['jenis_kunjungan'],
      asalPasien: Value(apiData['asal_pasien']),
      tipePasien: apiData['tipe_pasien'],
      pasienBaru: Value(apiData['pasien_baru']),
      pagiSore: Value(apiData['pagi_sore']),
      isCash: Value(apiData['is_cash']),
      isPribadi: Value(apiData['is_pribadi']),
      eselon: Value(apiData['eselon']),
      status: Value(apiData['status']),
      penanggungId: Value(apiData['penanggung']['id']),
      penanggungNama: Value(apiData['penanggung']['nama']),
      penanggungNoPegawai: Value(apiData['penanggung']['no_pegawai']),
      penanggungAlamat: Value(apiData['penanggung']['alamat']),
      penanggungTelepon: Value(apiData['penanggung']['telepon']),
      createdAt: Value(DateTime.parse(apiData['created_at'])),
      updatedAt: Value(DateTime.parse(apiData['updated_at'])),
    ),
  );

  // 3. Sync Anamnesa
  if (apiData['anamnesa'] != null) {
    final anamnesaData = apiData['anamnesa'];

    // Lookup dokter by dokter_id
    Dokter? dokter;
    if (anamnesaData['dokter_id'] != null) {
      dokter = await db.getDokterById(anamnesaData['dokter_id']);
    }

    await db.insertAnamnesa(
      AnamnesasCompanion.insert(
        registrasiId: registrasiId,
        dokterId: Value(dokter?.id),
        poliId: Value(anamnesaData['poli_id']),
        tanggal: Value(anamnesaData['tanggal']),
        pengkajianKeperawatan: Value(
          jsonEncode(anamnesaData['pengkajian_keperawatan']),
        ),
        pengkajianMedis: Value(
          jsonEncode(anamnesaData['pengkajian_medis']),
        ),
        khususPerawat: Value(
          jsonEncode(anamnesaData['khusus_perawat']),
        ),
        createdAt: Value(DateTime.parse(anamnesaData['created_at'])),
        updatedAt: Value(DateTime.parse(anamnesaData['updated_at'])),
      ),
    );
  }

  // 4. Sync ICD (many-to-many)
  if (apiData['icd'] != null) {
    for (var icdData in apiData['icd']) {
      // Lookup ICD by kode
      final icd = await db.getIcdByKode(icdData['kode']);

      if (icd != null) {
        await db.insertRegistrasiIcd(
          RegistrasiIcdsCompanion.insert(
            registrasiId: registrasiId,
            icdId: icd.id,
          ),
        );
      }
    }
  }

  // 5. Sync Tindakan (many-to-many with pivot)
  if (apiData['tindakan'] != null) {
    for (var tindakanData in apiData['tindakan']) {
      // Lookup Tindakan by kode
      final tindakan = await db.getTindakanByKode(tindakanData['kode']);

      if (tindakan != null) {
        final pivot = tindakanData['pivot'];
        await db.insertRegistrasiTindakan(
          RegistrasiTindakansCompanion.insert(
            registrasiId: registrasiId,
            tindakanId: tindakan.id,
            jumlah: Value(pivot['jumlah']),
            hargaSatuan: Value(pivot['harga_satuan']),
            diskon: Value(pivot['diskon']),
            subtotal: Value(pivot['subtotal']),
            petugasNama: Value(pivot['petugas_nama']),
            keterangan: Value(pivot['keterangan']),
            kunjunganKe: Value(pivot['kunjungan_ke']),
            isFree: Value(pivot['is_free']),
            dokterId: Value(pivot['dokter_id']),
            poliId: Value(pivot['poli_id']),
            tanggalLayanan: Value(pivot['tanggal_layanan']),
          ),
        );
      }
    }
  }

  // 6. Sync Tagihan
  if (apiData['tagihan'] != null) {
    final tagihanData = apiData['tagihan'];

    // Lookup user if exists
    User? user;
    if (tagihanData['user'] != null) {
      user = await db.getUserByEmail(tagihanData['user']['email']);
    }

    final tagihanId = await db.insertTagihan(
      TagihansCompanion.insert(
        registrasiId: registrasiId,
        noInvoice: tagihanData['no_invoice'],
        tanggalInvoice: Value(tagihanData['tanggal_invoice']),
        totalBiaya: Value(tagihanData['total_biaya']),
        deposit: Value(tagihanData['deposit']),
        biayaYangHarusDibayar: Value(tagihanData['biaya_yang_harus_dibayar']),
        terbilang: Value(tagihanData['terbilang']),
        primaryIcd: Value(tagihanData['primary_icd']),
        statusPembayaran: Value(tagihanData['status_pembayaran']),
        dicetakOleh: Value(tagihanData['dicetak_oleh']),
        tanggalCetak: Value(tagihanData['tanggal_cetak']),
        printLocation: Value(tagihanData['print_location']),
        serverTime: Value(tagihanData['server_time']),
        computerTime: Value(tagihanData['computer_time']),
        userId: Value(user?.id),
        createdAt: Value(DateTime.parse(tagihanData['created_at'])),
        updatedAt: Value(DateTime.parse(tagihanData['updated_at'])),
      ),
    );

    // 7. Sync Tagihan Items
    if (tagihanData['items'] != null) {
      for (var itemData in tagihanData['items']) {
        // Lookup kategori layanan
        KategoriLayanan? kategori;
        if (itemData['kategori_layanan'] != null) {
          // Assuming you have a method to get by kode or sync it first
          // kategori = await db.getKategoriLayananByKode(...);
        }

        await db.insertTagihanItem(
          TagihanItemsCompanion.insert(
            tagihanId: tagihanId,
            kategoriLayananId: Value(kategori?.id),
            kodeLayanan: Value(itemData['kode_layanan']),
            deskripsi: Value(itemData['deskripsi']),
            jumlah: Value(itemData['jumlah']),
            hargaSatuan: Value(itemData['harga_satuan']),
            diskon: Value(itemData['diskon']),
            subtotal: Value(itemData['subtotal']),
            tanggalLayanan: Value(itemData['tanggal_layanan']),
            urutan: Value(itemData['urutan']),
            createdAt: Value(DateTime.parse(itemData['created_at'])),
            updatedAt: Value(DateTime.parse(itemData['updated_at'])),
          ),
        );
      }
    }
  }
}
```

## Notes

1. **JSON Fields**: Anamnesa menggunakan JSON string untuk menyimpan struktur kompleks. Gunakan `dart:convert` untuk encode/decode:

   ```dart
   import 'dart:convert';

   // Encode to JSON string
   final jsonString = jsonEncode(complexObject);

   // Decode from JSON string
   final Map<String, dynamic> object = jsonDecode(jsonString);
   ```

2. **Date Parsing**: API mengembalikan ISO 8601 format. Parse dengan:

   ```dart
   DateTime.parse(apiDateString)
   ```

3. **Nullable Fields**: Banyak field nullable di API. Gunakan `Value()` wrapper di Drift:

   ```dart
   fieldName: Value(apiData['field'] ?? 'default'),
   fieldName: Value(apiData['field']), // null jika tidak ada
   ```

4. **Currency Fields**: Disimpan sebagai string untuk menghindari precision loss. Parse saat display:

   ```dart
   final amount = double.tryParse(currencyString) ?? 0.0;
   ```

5. **Primary ICD**: Field `tagihan.primary_icd` menyimpan kode ICD utama sebagai string untuk referensi cepat.

6. **Migration**: SchemaVersion 7 akan drop semua old tables. Backup data penting sebelum upgrade!
