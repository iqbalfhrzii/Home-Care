import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homecare_mobile/features/patients/data/datasources/patient_remote_datasource.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';

const Color _kPrimaryColor = Color(0xFF002F67);
const Color _kAccentColor = Color(0xFF3F51B5);
const Color _kWhiteColor = Colors.white;
const double _kSpacing = 16.0;

class PatientDetailPage extends StatefulWidget {
  final int patientId;

  const PatientDetailPage({super.key, required this.patientId});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  late Future<Patient> _patientFuture;

  @override
  void initState() {
    super.initState();
    _patientFuture = PatientRemoteDataSource().getPatientById(widget.patientId);
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dateTime = DateTime.parse(isoDate);
      // Menggunakan 'id_ID' untuk format Bahasa Indonesia
      return DateFormat('d MMMM yyyy', 'id_ID').format(dateTime);
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kAccentColor, size: 20),
          const SizedBox(width: _kSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Pasien',
          style: TextStyle(color: _kWhiteColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kPrimaryColor,
        iconTheme: const IconThemeData(color: _kWhiteColor),
        elevation: 4,
      ),
      body: FutureBuilder<Patient>(
        future: _patientFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(_kSpacing * 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.red, size: 50),
                    const SizedBox(height: _kSpacing),
                    Text(
                      'Gagal mengambil data dari server.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Detail error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          final patient = snapshot.data;
          if (patient == null) {
            return const Center(
              child: Text(
                'Data pasien tidak ditemukan di server.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(_kSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Info Card (Indikasi Remote)
                Card(
                  elevation: 2,
                  color: Colors.lightGreen.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Colors.lightGreen.shade300,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(_kSpacing),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_done,
                          color: Colors.lightGreen.shade700,
                          size: 30,
                        ),
                        const SizedBox(width: _kSpacing),
                        Expanded(
                          child: Text(
                            'Data ini tersimpan di **SERVER** dan sudah disinkronkan.',
                            style: TextStyle(color: Colors.lightGreen.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: _kSpacing),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(_kSpacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: _kPrimaryColor.withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: _kPrimaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: _kSpacing),
                        Center(
                          child: Text(
                            patient.namaPasien,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _kPrimaryColor,
                            ),
                          ),
                        ),
                        const Divider(height: 30, thickness: 1),

                        _buildDetailRow(
                          label: 'ID Pasien (Server)',
                          value: patient.id.toString(),
                          icon: Icons.vpn_key_outlined,
                        ),
                        _buildDetailRow(
                          label: 'No. Rekam Medis (RM)',
                          value: patient.noRM,
                          icon: Icons.assignment_ind_outlined,
                        ),
                        _buildDetailRow(
                          label: 'Tanggal Lahir',
                          value: _formatDate(patient.tanggalLahir),
                          icon: Icons.cake_outlined,
                        ),
                        _buildDetailRow(
                          label: 'Alamat',
                          value: patient.alamat ?? '-',
                          icon: Icons.location_on_outlined,
                        ),
                        _buildDetailRow(
                          label: 'Status Rujukan',
                          value: patient.statusRujukan.toUpperCase(),
                          icon: Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
