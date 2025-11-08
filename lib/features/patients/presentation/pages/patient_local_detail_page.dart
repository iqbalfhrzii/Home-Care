import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';
import 'package:homecare_mobile/features/patients/data/datasources/patient_local_datasource.dart';
import 'package:homecare_mobile/features/patients/presentation/pages/add_patient_page.dart';
import 'package:homecare_mobile/shared/local_db/db_provider.dart';

const Color _kPrimaryColor = Color(0xFF002F67);
const Color _kAccentColor = Color(0xFF3F51B5);
const Color _kDangerColor = Color(0xFFD32F2F);
const Color _kWhiteColor = Colors.white;
const double _kSpacing = 16.0;

class PatientLocalDetailPage extends StatelessWidget {
  final Patient patient;
  static const int _localIdBase = 100000;

  const PatientLocalDetailPage({super.key, required this.patient});

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dateTime = DateTime.parse(isoDate);
      return DateFormat('d MMMM yyyy', 'id_ID').format(dateTime);
    } catch (_) {
      return isoDate;
    }
  }

  int _getDbId() {
    return patient.id >= _localIdBase ? patient.id - _localIdBase : patient.id;
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Hapus pasien lokal?'),
        content: const Text(
          'Data pasien akan dihapus dari penyimpanan lokal dan tidak akan disinkronkan ke server. Aksi ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _kDangerColor),
            child: const Text('Hapus', style: TextStyle(color: _kWhiteColor)),
          ),
        ],
      ),
    );
  }

  void _deletePatient(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirm = await _showDeleteConfirmation(context);

    if (confirm == true) {
      try {
        final ds = PatientLocalDataSource(provideDb());
        await ds.deletePatientByLocalId(_getDbId());
        // Signal deletion/refresh to caller and pop
        navigator.pop(true);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus data: $e'),
              backgroundColor: _kDangerColor,
            ),
          );
        }
      }
    }
  }

  void _editPatient(BuildContext context) async {
    final navigator = Navigator.of(context);
    // Buka AddPatientPage dalam mode edit
    final edited = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => AddPatientPage(patientToEdit: patient)),
    );

    if (edited == true) {
      navigator.pop(true);
    }
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline, color: _kAccentColor, size: 20),
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
          'Detail Pasien Lokal',
          style: TextStyle(color: _kWhiteColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kPrimaryColor,
        iconTheme: const IconThemeData(color: _kWhiteColor),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_kSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.orange.shade300, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(_kSpacing),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_problem,
                      color: Colors.orange.shade700,
                      size: 30,
                    ),
                    const SizedBox(width: _kSpacing),
                    Expanded(
                      child: Text(
                        'Data ini tersimpan **LOKAL** dan belum disinkronkan ke server.',
                        style: TextStyle(color: Colors.orange.shade800),
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
                    Text(
                      patient.namaPasien,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _kPrimaryColor,
                      ),
                    ),
                    const Divider(height: 30, thickness: 1),
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

            const SizedBox(height: _kSpacing * 2),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _editPatient(context),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text('Edit Data Lokal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccentColor,
                  foregroundColor: _kWhiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: _kSpacing),

            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _deletePatient(context),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Hapus Data Lokal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kDangerColor,
                  side: const BorderSide(color: _kDangerColor, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
