import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';

// --- Palet Warna (dari desain Anda) ---
const Color kPrimaryColor = Color(0xFF002F67);
const Color kScaffoldBg = Color(0xFFF8F9FA);
const Color kWhiteColor = Colors.white;
const Color kCardBorder = Color(0xFFE2E8F0);
const Color kIconBg = Color(0xFFEFF6FF); // Latar belakang ikon
const Color kTextTitle = Color(0xFF002F67); // Warna teks judul section
const Color kTextLabel = Color(0xFF6B7280); // Warna label abu-abu
const Color kTextValue = Color(0xFF1F2937); // Warna nilai
const Color kButtonGreen = Color(0xFF16A34A);
const Color kButtonRed = Color(0xFFDC2626);

// --- Model Data (Contoh) ---
// Anda harus mengganti ini dengan model data asli Anda
class PatientRegistration {
  final String namaLengkap;
  final String noRekamMedis;
  final String noRegistrasi;
  final String noTelepon;
  final String alamat;
  final DateTime tanggalRegistrasi;
  final TimeOfDay jamRegistrasi;
  final String jenisKunjungan;
  final String kodeIcd;
  final String noInvoice;
  final DateTime tanggalInvoice;
  final String namaPenanggung;
  final String noPegawai;
  final String eselon;
  final String noTeleponPenanggung;
  final String alamatPenanggung;
  final String statusPersetujuan; // 'Menunggu Persetujuan', 'Disetujui'

  PatientRegistration({
    required this.namaLengkap,
    required this.noRekamMedis,
    required this.noRegistrasi,
    required this.noTelepon,
    required this.alamat,
    required this.tanggalRegistrasi,
    required this.jamRegistrasi,
    required this.jenisKunjungan,
    required this.kodeIcd,
    required this.noInvoice,
    required this.tanggalInvoice,
    required this.namaPenanggung,
    required this.noPegawai,
    required this.eselon,
    required this.noTeleponPenanggung,
    required this.alamatPenanggung,
    required this.statusPersetujuan,
  });
}
// ---------------------------------------------

class PatientDetailPage extends StatefulWidget {
  // Optional patient id passed from list (routing compatibility)
  final int? patientId;
  // Accept a minimal map for patient data when navigating from list
  final Map<String, String>? patientData;

  const PatientDetailPage({super.key, this.patientId, this.patientData});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  late PatientRegistration patient;
  bool _statusChanged = false;
  late String _originalStatus;

  @override
  void initState() {
    super.initState();
    // default dummy patient
    patient = PatientRegistration(
      namaLengkap: 'Dewi Lestari',
      noRekamMedis: 'MRN001237',
      noRegistrasi: 'R09254414',
      noTelepon: '081445566778',
      alamat: 'Jl. Kuningan No. 22, Jakarta Selatan',
      tanggalRegistrasi: DateTime(2025, 11, 11),
      jamRegistrasi: const TimeOfDay(hour: 11, minute: 30),
      jenisKunjungan: 'IGD',
      kodeIcd: 'S06',
      noInvoice: 'INV-2025-004',
      tanggalInvoice: DateTime(2025, 11, 11),
      namaPenanggung: 'Allianz',
      noPegawai: 'PEG004',
      eselon: 'Eselon III',
      noTeleponPenanggung: '02133445566',
      alamatPenanggung: 'Jl. Gatot Subroto No. 111, Jakarta',
      statusPersetujuan: 'Menunggu Persetujuan',
    );

    // override with passed data if any
    final pd = widget.patientData;
    if (pd != null) {
      patient = PatientRegistration(
        namaLengkap: pd['name'] ?? patient.namaLengkap,
        noRekamMedis: pd['mrn'] ?? patient.noRekamMedis,
        noRegistrasi: patient.noRegistrasi,
        noTelepon: pd['phone'] ?? patient.noTelepon,
        alamat: pd['address'] ?? patient.alamat,
        tanggalRegistrasi: patient.tanggalRegistrasi,
        jamRegistrasi: patient.jamRegistrasi,
        jenisKunjungan: patient.jenisKunjungan,
        kodeIcd: patient.kodeIcd,
        noInvoice: patient.noInvoice,
        tanggalInvoice: patient.tanggalInvoice,
        namaPenanggung: patient.namaPenanggung,
        noPegawai: patient.noPegawai,
        eselon: patient.eselon,
        noTeleponPenanggung: patient.noTeleponPenanggung,
        alamatPenanggung: patient.alamatPenanggung,
        statusPersetujuan: patient.statusPersetujuan,
      );
    }
    _originalStatus = patient.statusPersetujuan;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_statusChanged) {
          // return the changed status to caller when popping with back
          if (!mounted) return true;
          Navigator.pop(context, {
            'action': 'status_changed',
            'status': patient.statusPersetujuan,
          });
          return false; // we already popped
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          title: const Text(
            'Detail Pasien',
            style: TextStyle(color: kWhiteColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kPrimaryColor,
          iconTheme: const IconThemeData(color: kWhiteColor),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20.0),
            child: Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Informasi lengkap pasien',
                  style: TextStyle(color: kWhiteColor, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildStatusHeader(patient.statusPersetujuan),
            const SizedBox(height: 16),
            _buildPatientDataCard(),
            const SizedBox(height: 16),
            _buildVisitDataCard(context),
            const SizedBox(height: 16),
            _buildInvoiceDataCard(),
            const SizedBox(height: 16),
            _buildGuarantorDataCard(),
            const SizedBox(height: 16),
            _buildNotesCard(),
          ],
        ),
        bottomNavigationBar: _buildBottomButtons(context),
      ),
    );
  }

  // --- WIDGET HEADER STATUS ---
  Widget _buildStatusHeader(String status) {
    bool isPending = status == 'Menunggu Persetujuan';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled_outlined, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Persetujuan',
                  style: TextStyle(color: kTextLabel, fontSize: 12),
                ),
                Text(
                  status,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kTextValue,
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  patient = PatientRegistration(
                    namaLengkap: patient.namaLengkap,
                    noRekamMedis: patient.noRekamMedis,
                    noRegistrasi: patient.noRegistrasi,
                    noTelepon: patient.noTelepon,
                    alamat: patient.alamat,
                    tanggalRegistrasi: patient.tanggalRegistrasi,
                    jamRegistrasi: patient.jamRegistrasi,
                    jenisKunjungan: patient.jenisKunjungan,
                    kodeIcd: patient.kodeIcd,
                    noInvoice: patient.noInvoice,
                    tanggalInvoice: patient.tanggalInvoice,
                    namaPenanggung: patient.namaPenanggung,
                    noPegawai: patient.noPegawai,
                    eselon: patient.eselon,
                    noTeleponPenanggung: patient.noTeleponPenanggung,
                    alamatPenanggung: patient.alamatPenanggung,
                    statusPersetujuan: 'Disetujui',
                  );
                  _statusChanged = patient.statusPersetujuan != _originalStatus;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status: Disetujui')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonGreen,
                foregroundColor: kWhiteColor,
              ),
              child: const Text('Setujui'),
            )
          else
            OutlinedButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Batalkan Persetujuan'),
                    content: const Text('Yakin ingin membatalkan persetujuan?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, true),
                        child: const Text('Ya'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (!mounted) return;
                  setState(() {
                    patient = PatientRegistration(
                      namaLengkap: patient.namaLengkap,
                      noRekamMedis: patient.noRekamMedis,
                      noRegistrasi: patient.noRegistrasi,
                      noTelepon: patient.noTelepon,
                      alamat: patient.alamat,
                      tanggalRegistrasi: patient.tanggalRegistrasi,
                      jamRegistrasi: patient.jamRegistrasi,
                      jenisKunjungan: patient.jenisKunjungan,
                      kodeIcd: patient.kodeIcd,
                      noInvoice: patient.noInvoice,
                      tanggalInvoice: patient.tanggalInvoice,
                      namaPenanggung: patient.namaPenanggung,
                      noPegawai: patient.noPegawai,
                      eselon: patient.eselon,
                      noTeleponPenanggung: patient.noTeleponPenanggung,
                      alamatPenanggung: patient.alamatPenanggung,
                      statusPersetujuan: 'Menunggu Persetujuan',
                    );
                    _statusChanged =
                        patient.statusPersetujuan != _originalStatus;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Persetujuan dibatalkan')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: kButtonRed,
                side: const BorderSide(color: kButtonRed),
              ),
              child: const Text('Batalkan Persetujuan'),
            ),
        ],
      ),
    );
  }

  // --- SECTION WIDGETS ---

  Widget _buildPatientDataCard() {
    return _buildSectionCard(
      title: 'Data Pasien',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _buildInfoEntry(label: 'Nama Lengkap', value: patient.namaLengkap),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoEntry(
                  label: 'No. Rekam Medis',
                  value: patient.noRekamMedis,
                ),
              ),
              Expanded(
                child: _buildInfoEntry(
                  label: 'No. Registrasi',
                  value: patient.noRegistrasi,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoEntry(
            label: 'No. Telepon',
            value: patient.noTelepon,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),
          _buildInfoEntry(
            label: 'Alamat',
            value: patient.alamat,
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitDataCard(BuildContext context) {
    return _buildSectionCard(
      title: 'Data Kunjungan',
      icon: Icons.file_present_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoEntry(
                  label: 'Tanggal Registrasi',
                  value: DateFormat(
                    'y-MM-dd',
                  ).format(patient.tanggalRegistrasi),
                ),
              ),
              Expanded(
                child: _buildInfoEntry(
                  label: 'Jam Registrasi',
                  value: patient.jamRegistrasi.format(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoEntry(
                  label: 'Jenis Kunjungan',
                  value: '', // Kosongkan value, akan diganti chip
                  customChild: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(patient.jenisKunjungan),
                      backgroundColor: const Color.fromRGBO(0, 47, 103, 0.1),
                      labelStyle: const TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildInfoEntry(
                  label: 'Kode ICD',
                  value: patient.kodeIcd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDataCard() {
    return _buildSectionCard(
      title: 'Data Invoice',
      icon: Icons.receipt_long_outlined,
      child: Row(
        children: [
          Expanded(
            child: _buildInfoEntry(
              label: 'No. Invoice',
              value: patient.noInvoice,
            ),
          ),
          Expanded(
            child: _buildInfoEntry(
              label: 'Tanggal Invoice',
              value: DateFormat('y-MM-dd').format(patient.tanggalInvoice),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantorDataCard() {
    return _buildSectionCard(
      title: 'Data Penanggung',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          _buildInfoEntry(
            label: 'Nama Penanggung',
            value: patient.namaPenanggung,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoEntry(
                  label: 'No. Pegawai',
                  value: patient.noPegawai,
                ),
              ),
              Expanded(
                child: _buildInfoEntry(label: 'Eselon', value: patient.eselon),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoEntry(
            label: 'No. Telepon',
            value: patient.noTeleponPenanggung,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),
          _buildInfoEntry(
            label: 'Alamat',
            value: patient.alamatPenanggung,
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _buildSectionCard(
      title: 'Catatan',
      icon: Icons.description_outlined,
      child: const Text(
        'Pastikan semua data telah terverifikasi sebelum menyetujui pendaftaran pasien. Status persetujuan dapat diubah kapan saja sesuai kebutuhan.',
        style: TextStyle(color: kTextLabel, fontSize: 13, height: 1.5),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      color: kWhiteColor,
      padding: const EdgeInsets.all(
        16.0,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              // Return a 'delete' action to caller
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Hapus Pasien'),
                  content: const Text('Yakin ingin menghapus data pasien ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                if (!mounted) return;
                Navigator.pop(context, {'action': 'delete'});
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus Data Pasien'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kButtonRed,
              side: const BorderSide(color: kButtonRed),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              // Open AddPatientRegistrationPage in edit mode using go_router
              final id = widget.patientId ?? 1;
              final result = await context.push<Map<String, String>>(
                '${AppRouter.patients}/$id/edit',
                extra: {
                  'name': patient.namaLengkap,
                  'mrn': patient.noRekamMedis,
                  'phone': patient.noTelepon,
                  'address': patient.alamat,
                },
              );
              // If result returned, update local state
              if (result != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Data ${result['name']} diupdate')),
                );
                // Optionally pop with updated data
                if (!mounted) return;
                Navigator.pop(context, {'action': 'edit', 'data': result});
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Data Pasien'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kWhiteColor,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: kWhiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kCardBorder),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kIconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: kTextTitle, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextTitle,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoEntry({
    required String label,
    required String value,
    IconData? icon,
    Widget? customChild,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kTextLabel, fontSize: 12)),
        const SizedBox(height: 4),
        if (customChild != null)
          customChild
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Icon(icon, color: kTextLabel, size: 16)
              else
                const SizedBox(width: 16), // Placeholder for alignment
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: kTextValue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
