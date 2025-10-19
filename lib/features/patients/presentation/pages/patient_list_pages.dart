import 'package:flutter/material.dart';
import 'package:homecare_mobile/features/patients/data/datasources/patient_remote_datasource.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';
import 'package:homecare_mobile/features/patients/presentation/pages/patient_pages.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  late Future<List<Patient>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _patientsFuture = PatientRemoteDataSource().getAllPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pasien'),
        backgroundColor: const Color(0xFF002F67),
      ),
      body: FutureBuilder<List<Patient>>(
        future: _patientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final patients = snapshot.data ?? [];
          if (patients.isEmpty) {
            return const Center(child: Text('Belum ada data pasien.'));
          }

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final p = patients[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, color: Color(0xFF002F67)),
                  ),
                  title: Text(p.namaPasien),
                  subtitle: Text(
                    'No RM: ${p.noRM}\nStatus: ${p.statusRujukan}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PatientDetailPage(patientId: p.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
