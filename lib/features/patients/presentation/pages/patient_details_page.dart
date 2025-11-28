import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/features/patients/presentation/bloc/patient_bloc.dart';

class PatientDetailsPage extends StatelessWidget {
  const PatientDetailsPage({super.key, required this.patientId});
  final int patientId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pasien'), centerTitle: true),
      body: const PatientDetailsView(),
    );
  }
}

class PatientDetailsView extends StatelessWidget {
  const PatientDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientDetailsBloc, PatientState>(
      builder: (context, state) {
        if (state is PatientLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PatientReadSuccess) {
          final patient = state.patient;
          return RefreshIndicator(
            // ✅ Allow refresh
            onRefresh: () async {
              context.read<PatientDetailsBloc>().add(
                ReadPatientEvent(patient.id),
              );
              await context.read<PatientDetailsBloc>().stream.firstWhere(
                (state) => state is! PatientLoading,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildInfoCard(
                  title: 'Informasi Dasar',
                  children: [
                    _buildInfoRow('Nama', patient.namaPasien),
                    _buildInfoRow('No. Rekam Medis', patient.noRekamMedis),
                    _buildInfoRow('Tanggal Lahir', patient.tanggalLahir),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Alamat',
                  children: [_buildInfoRow('Alamat', patient.alamat)],
                ),
              ],
            ),
          );
        }

        if (state is PatientError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
