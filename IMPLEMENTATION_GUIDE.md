# Quick Implementation Guide - Home Care Mobile

## 🚀 Langkah-langkah Implementasi

### 1. Generate JSON Serialization Code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 2. Update App Router

Tambahkan route untuk Registration Form:

```dart
// Di app_router.dart, tambahkan di dalam ShellRoute patients
GoRoute(
  path: 'register/:id',
  name: 'patientRegister',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    final name = (state.extra as Map?)?['name'] as String?;
    return RegistrationFormPage(pasienId: id, pasienNama: name);
  },
),
```

### 3. Update Patient List Page

Tambahkan status counters di header dan tombol "Registrasikan":

#### Di bagian \_buildHeader():

```dart
// Tambahkan di bawah title
const SizedBox(height: 20),
Row(
  children: [
    _buildStatusCounter('Total', _allPatients.length.toString(), const Color(0xFF3B82F6)),
    const SizedBox(width: 12),
    _buildStatusCounter('Disetujui', '3', const Color(0xFF22C55E)),
    const SizedBox(width: 12),
    _buildStatusCounter('Pending', '2', const Color(0xFFF59E0B)),
  ],
),

// Helper method
Widget _buildStatusCounter(String label, String count, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
```

#### Di bagian patient card, tambahkan tombol Registrasi:

```dart
// Di dalam _buildMobileList, di setiap card tambahkan:
// Setelah tombol Edit, tambahkan:
const SizedBox(height: 8),
ElevatedButton.icon(
  onPressed: () {
    context.push(
      '${AppRouter.patients}/register/${patient.id}',
      extra: {'name': patient.nama},
    );
  },
  icon: const Icon(Icons.app_registration, size: 16),
  label: const Text('Registrasikan'),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF8B5CF6),
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 36),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
),
```

### 4. Update Schedule List Page

File: `lib/features/schedules/presentation/pages/schedule_list_page.dart`

Ganti konten menjadi list registrasi:

```dart
// Model untuk dummy registrasi
class RegistrasiItem {
  final String id;
  final String noReg;
  final String pasienNama;
  final String pasienMrn;
  final String tglJamReg;
  final String jenisKunjungan;
  final String status;

  RegistrasiItem({
    required this.id,
    required this.noReg,
    required this.pasienNama,
    required this.pasienMrn,
    required this.tglJamReg,
    required this.jenisKunjungan,
    required this.status,
  });
}

// Di build:
ListView.builder(
  itemCount: registrasiList.length,
  itemBuilder: (context, index) {
    final reg = registrasiList[index];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kPrimaryColor,
          child: Text(reg.pasienNama[0]),
        ),
        title: Text(reg.pasienNama),
        subtitle: Text('${reg.noReg} • ${reg.jenisKunjungan}'),
        trailing: Chip(
          label: Text(reg.status),
          backgroundColor: reg.status == 'Selesai'
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        ),
        onTap: () {
          // Navigate ke anamnesa form
          context.push('/schedules/${reg.id}/anamnesa');
        },
      ),
    );
  },
)
```

### 5. Buat Anamnesa Form Page

File: `lib/features/schedules/presentation/pages/anamnesa_form_page.dart`

Form lengkap untuk input:

- Keluhan
- Vital Signs (Tekanan Darah, Nadi, Suhu, Pernapasan)
- Body Measurements (BB, TB, IMT, Lingkar Kepala)
- Diagnosis
- Rencana & Terapi
- Jenis Perawatan
- List ICD (diagnosa)
- List Tindakan

### 6. Buat Billing Pages

File: `lib/features/billing/presentation/pages/billing_list_page.dart`
File: `lib/features/billing/presentation/pages/billing_detail_page.dart`

#### Billing List:

- Tampilkan list tagihan dengan status
- Filter berdasarkan status pembayaran
- Navigate ke detail

#### Billing Detail:

- Info pasien
- List items tagihan
- Total, deposit, yang harus dibayar
- Tombol "Kirim ke WA"
- Update status pembayaran

### 7. Implementasi BLoC untuk setiap feature

```dart
// PatientBloc
class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final PatientRepository repository;

  PatientBloc(this.repository) : super(PatientInitial()) {
    on<LoadPatients>(_onLoadPatients);
    on<CreatePatient>(_onCreatePatient);
    // dst...
  }
}

// RegistrationBloc
// AnamnesaBloc
// BillingBloc
```

### 8. API Integration Checklist

#### Patient API

- [ ] GET /api/v1/pasien - List patients
- [ ] GET /api/v1/pasien/{id} - Get patient detail
- [ ] POST /api/v1/pasien - Create patient
- [ ] PUT /api/v1/pasien/{id} - Update patient
- [ ] DELETE /api/v1/pasien/{id} - Delete patient

#### Registration API

- [ ] GET /api/v1/registrasi - List registrations
- [ ] POST /api/v1/registrasi - Create registration
- [ ] PATCH /api/v1/registrasi/{id}/status - Update status

#### Anamnesa API

- [ ] POST /api/v1/anamnesa - Create anamnesa
- [ ] POST /api/v1/registrasi/{id}/icd - Attach ICD
- [ ] POST /api/v1/registrasi/{id}/tindakan - Attach tindakan

#### Billing API

- [ ] GET /api/v1/tagihan - List tagihan
- [ ] GET /api/v1/tagihan/{id} - Detail tagihan
- [ ] POST /api/v1/tagihan/{id}/bayar - Update payment status

### 9. WhatsApp Integration

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> sendInvoiceViaWhatsApp(String phoneNumber, String message) async {
  final phone = phoneNumber.startsWith('0')
    ? '62${phoneNumber.substring(1)}'
    : phoneNumber;

  final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// Message format:
String buildInvoiceMessage(Tagihan tagihan) {
  return '''
🏥 *TAGIHAN HOMECARE*

No. Invoice: ${tagihan.noInvoice}
Pasien: ${tagihan.registrasi.pasien.nama}
MRN: ${tagihan.registrasi.pasien.mrn}

---
Total Biaya: Rp ${tagihan.totalBiaya}
Deposit: Rp ${tagihan.deposit}
Yang Harus Dibayar: Rp ${tagihan.biayaYangHarusDibayar}

Terbilang: ${tagihan.terbilang}

Status: ${tagihan.statusPembayaran}
---

Terima kasih atas kepercayaan Anda.
''';
}
```

### 10. Testing Flow

1. **Patient Management**

   - Buat pasien baru
   - Edit data pasien
   - Lihat detail pasien
   - Registrasikan pasien

2. **Schedule**

   - Lihat daftar registrasi
   - Klik pasien → input anamnesa
   - Tambah ICD
   - Tambah tindakan
   - Submit

3. **Billing**
   - Lihat daftar tagihan
   - Klik detail
   - Kirim via WA
   - Update status pembayaran

## 📝 Notes

- Semua models sudah dibuat di folder `lib/features/patients/domain/models/`
- Registration form sudah jadi di `registration_form_page.dart`
- Perlu run `build_runner` untuk generate `.g.dart` files
- Perlu implementasi BLoC untuk state management yang proper
- Perlu update Dio baseURL sesuai backend API Anda
- Add dependency `url_launcher` untuk WhatsApp integration

## 🎯 Priority Order

1. **Generate code** → Run build_runner
2. **Update Patient List** → Add status counters + register button
3. **Test Registration** → Form sudah bisa digunakan
4. **Update Schedule** → Show registrasi list + navigate to anamnesa
5. **Create Anamnesa Form** → Full form with ICD & Tindakan selection
6. **Create Billing Pages** → List & Detail with WhatsApp
7. **API Integration** → Connect all endpoints with BLoC
8. **Testing** → Full flow testing

Apakah Anda ingin saya lanjutkan implementasi salah satu halaman tertentu secara detail?
