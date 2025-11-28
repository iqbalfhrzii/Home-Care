# API Integration Architecture - Home Care Mobile

## Overview Struktur

Aplikasi ini menggunakan **Clean Architecture** dengan 4 navigasi utama:

1. **Home** - Dashboard
2. **Schedule** - Daftar registrasi pasien yang perlu dikunjungi + input anamnesa
3. **Patients** - CRUD pasien + registrasi pasien baru
4. **Billing** - Daftar tagihan + kirim tagihan via WA

## Flow Aplikasi

### 1. Patient Management Flow

```
Patient List Page
├── Tampilkan status: Total, Disetujui, Pending
├── CRUD Pasien (tambah, edit, hapus, detail)
└── Tombol "Registrasikan Pasien" → Registrasi Form
```

### 2. Registration Flow

```
Registration Form
├── Pilih Pasien (dropdown/search)
├── Input: No Reg, Tgl/Jam Reg, Jenis Kunjungan, Tipe Pasien
├── Input Data Penanggung: Nama, No Pegawai, Alamat, Telepon, ID, Eselon
└── Submit → Status pasien berubah "Disetujui" → Masuk Schedule List
```

### 3. Schedule/Visit Flow

```
Schedule List Page (Daftar Registrasi)
├── Tampilkan registrasi dengan status
├── Klik pasien → Input Anamnesa
    ├── Keluhan Utama
    ├── Vital Signs (Tekanan Darah, Nadi, Suhu, Pernapasan)
    ├── Body Measurements (BB, TB, IMT, Lingkar Kepala)
    ├── Diagnosis
    ├── Rencana & Terapi
    ├── Jenis Perawatan
    ├── Attach ICD (diagnosa penyakit)
    └── Attach Tindakan (medical procedures)
└── Setelah anamnesa selesai → Generate Tagihan
```

### 4. Billing Flow

```
Billing List Page
├── Tampilkan daftar tagihan
├── Status: Sudah Dibayar / Belum Dibayar
├── Detail Tagihan:
    ├── No Invoice, Pasien Info
    ├── Items (Tindakan, Obat, dll)
    ├── Total Biaya, Deposit, Yang Harus Dibayar
    └── Tombol "Kirim ke WA" → Share tagihan via WhatsApp
└── Update Status Pembayaran
```

## API Endpoints & Models

### Patients API

- `GET /api/v1/pasien` - List semua pasien
- `GET /api/v1/pasien/{id}` - Detail pasien
- `POST /api/v1/pasien` - Tambah pasien baru
- `PUT /api/v1/pasien/{id}` - Update pasien
- `DELETE /api/v1/pasien/{id}` - Hapus pasien

**Model:** `Pasien` (id, mrn, nama, alamat, telepon, tanggal_lahir, jenis_kelamin)

### Registrations API

- `GET /api/v1/registrasi` - List registrasi
- `GET /api/v1/registrasi/{id}` - Detail registrasi
- `POST /api/v1/registrasi` - Buat registrasi baru
- `PUT /api/v1/registrasi/{id}` - Update registrasi
- `PATCH /api/v1/registrasi/{id}/status` - Update status registrasi

**Model:** `Registrasi` (id, no_reg, pasien, tgl_jam_reg, jenis_kunjungan, tipe_pasien, penanggung, status)

### Anamnesa API

- `GET /api/v1/anamnesa/{id}` - Detail anamnesa
- `POST /api/v1/anamnesa` - Create anamnesa
- `PUT /api/v1/anamnesa/{id}` - Update anamnesa

**Model:** `Anamnesa` (keluhan, vital_signs, body_measurements, diagnosis, rencana_dan_terapi)

### ICD API (Diagnosa)

- `GET /api/v1/icd` - List ICD codes
- `GET /api/v1/icd/{id}` - Detail ICD
- `POST /api/v1/registrasi/{id}/icd` - Attach ICD ke registrasi

**Model:** `Icd` (kode, nama_penyakit, deskripsi, is_primary)

### Tindakan API (Medical Procedures)

- `GET /api/v1/tindakan` - List tindakan
- `GET /api/v1/tindakan/{id}` - Detail tindakan
- `POST /api/v1/registrasi/{id}/tindakan` - Attach tindakan ke registrasi

**Model:** `Tindakan` (kode, nama_tindakan, kategori, harga, pivot)

### Billing API

- `GET /api/v1/tagihan` - List tagihan
- `GET /api/v1/tagihan/{id}` - Detail tagihan
- `POST /api/v1/tagihan/{id}/bayar` - Update status pembayaran

**Model:** `Tagihan` (no_invoice, registrasi, total_biaya, status_pembayaran, items)

## Halaman yang Perlu Dibuat

### ✅ Sudah Ada (Perlu Update)

- [x] Patient List Page - **Perlu add status counters + connect API**
- [x] Patient Detail Page - **Perlu connect API**
- [x] Add/Edit Patient Page - **Perlu connect API**
- [x] Home Page - **Dashboard OK**

### ❌ Belum Dibuat

- [ ] **Registration Form Page** - Form registrasi pasien baru
- [ ] **Schedule List Page** - List pasien teregistrasi (PRIORITAS TINGGI)
- [ ] **Anamnesa Form Page** - Input anamnesa + vital signs + ICD + Tindakan
- [ ] **Billing List Page** - List tagihan dengan status pembayaran
- [ ] **Billing Detail Page** - Detail tagihan + kirim WA

## Next Steps

### Phase 1: Patient Management (Update)

1. Update Patient List dengan status counters (Total, Disetujui, Pending)
2. Connect Patient CRUD dengan API
3. Tambahkan tombol "Registrasikan Pasien"

### Phase 2: Registration (New)

1. Buat Registration Form Page
2. Integrate dengan Pasien API (dropdown/search pasien)
3. Submit registrasi → update status pasien

### Phase 3: Schedule & Anamnesa (New)

1. Buat Schedule List Page (list registrasi)
2. Buat Anamnesa Form Page
3. Integrate ICD selection
4. Integrate Tindakan selection
5. Submit → generate tagihan

### Phase 4: Billing (New)

1. Buat Billing List Page
2. Buat Billing Detail Page
3. Implement "Kirim ke WA" feature
4. Update status pembayaran

## State Management Strategy

Setiap feature akan memiliki BLoC/Cubit:

- `PatientBloc` - Manage patient CRUD & status
- `RegistrationBloc` - Manage registrations
- `AnamnesaBloc` - Manage anamnesa forms
- `BillingBloc` - Manage tagihan & payments

## Tech Stack Reminder

- **Networking:** Dio
- **State Management:** flutter_bloc
- **Routing:** go_router
- **JSON:** json_serializable + build_runner
- **Storage:** flutter_secure_storage (untuk token)
