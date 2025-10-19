import 'package:flutter/material.dart';
import 'package:homecare_mobile/features/patients/data/datasources/patient_remote_datasource.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pasien'),
        backgroundColor: const Color(0xFF002F67),
      ),
      body: FutureBuilder<Patient>(
        future: _patientFuture,
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

          final patient = snapshot.data;
          if (patient == null) {
            return const Center(child: Text('Data pasien tidak ditemukan.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF002F67),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nama Pasien: ${patient.namaPasien}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('No. RM: ${patient.noRM}'),
                    const SizedBox(height: 8),
                    Text('Tanggal Lahir: ${patient.tanggalLahir ?? "-"}'),
                    const SizedBox(height: 8),
                    Text('Alamat: ${patient.alamat ?? "-"}'),
                    const SizedBox(height: 8),
                    Text('Status Rujukan: ${patient.statusRujukan}'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
