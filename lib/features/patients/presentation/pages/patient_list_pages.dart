import 'package:flutter/material.dart';
import 'package:homecare_mobile/features/patients/data/datasources/patient_remote_datasource.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';
import 'package:homecare_mobile/features/patients/presentation/pages/patient_pages.dart';
import 'package:homecare_mobile/shared/local_db/db_provider.dart';
import 'package:homecare_mobile/features/patients/data/datasources/patient_local_datasource.dart';
import 'package:homecare_mobile/features/patients/presentation/pages/add_patient_page.dart';
import 'package:homecare_mobile/features/patients/presentation/pages/patient_local_detail_page.dart';

const Color _kPrimaryColor = Color(0xFF002F67);
const Color _kAccentColor = Color(0xFF3F51B5);
const Color _kWhiteColor = Colors.white;
const double _kSpacing = 16.0;

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  late Future<List<Patient>> _patientsFuture;
  late PatientLocalDataSource _local;
  static const int _localIdBase = 100000;

  @override
  void initState() {
    super.initState();
    _local = PatientLocalDataSource(provideDb());
    _patientsFuture = _loadLocalThenRemote();
  }

  Future<List<Patient>> _loadLocalThenRemote() async {
    // 1. Load local first
    final localRows = await _local.getAllPatients();
    final localPatients = localRows
        .map(
          (e) => Patient(
            id: _localIdBase + e.id,
            noRM: e.noRm,
            namaPasien: e.namaPasien,
            tanggalLahir: e.tanggalLahir?.toIso8601String(),
            alamat: e.alamat,
            statusRujukan: e.statusRujukan,
          ),
        )
        .toList();

    _fetchRemoteAndMerge(localPatients);

    return localPatients;
  }

  void _fetchRemoteAndMerge(List<Patient> localPatients) {
    PatientRemoteDataSource()
        .getAllPatients()
        .then((remote) {
          final merged = _mergeRemoteAndLocal(remote, localPatients);
          if (mounted) {
            setState(() {
              _patientsFuture = Future.value(merged);
            });
            if (remote.isNotEmpty) {
              _showSnackbar(
                'Data Pasien Diperbarui (Lokal & Server Dimuat)',
                Colors.green,
              );
            }
          }
        })
        .catchError((e) {
          debugPrint('Gagal mengambil data remote: $e');
          if (mounted) {
            _showSnackbar(
              'Gagal sinkronisasi data server. Menampilkan data lokal.',
              Colors.orange,
            );
          }
        });
  }

  List<Patient> _mergeRemoteAndLocal(
    List<Patient> remote,
    List<Patient> local,
  ) {
    final map = <String, Patient>{for (final l in local) l.noRM: l};

    // Remote takes precedence
    for (final r in remote) {
      map[r.noRM] = r;
    }

    final merged = <Patient>[];
    final processedNoRMs = <String>{};

    for (final r in remote) {
      // Pastikan hanya remote yang terupdate atau lokal yang belum ada di remote
      if (map.containsKey(r.noRM) && !processedNoRMs.contains(r.noRM)) {
        merged.add(map[r.noRM]!);
        processedNoRMs.add(r.noRM);
      }
    }
    for (final l in local) {
      if (!processedNoRMs.contains(l.noRM)) {
        merged.add(l);
        processedNoRMs.add(l.noRM);
      }
    }

    return merged;
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Pasien',
          style: TextStyle(color: _kWhiteColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kPrimaryColor,
        iconTheme: const IconThemeData(color: _kWhiteColor),
        elevation: 4,
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: FutureBuilder<List<Patient>>(
        future: _patientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimaryColor),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final patients = snapshot.data ?? [];
          if (patients.isEmpty) {
            return _buildEmptyState();
          }

          return _buildPatientList(patients);
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      heroTag: 'addPatient',
      onPressed: () async {
        final shouldReload = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const AddPatientPage()),
        );

        if (shouldReload == true && mounted) {
          setState(() {
            _patientsFuture = _loadLocalThenRemote();
          });
        }
      },
      backgroundColor: _kAccentColor,
      foregroundColor: _kWhiteColor,
      elevation: 6,
      child: const Icon(Icons.person_add),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_kSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: _kSpacing),
            Text(
              'Gagal memuat data utama.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detail: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_kSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Colors.grey.shade400, size: 64),
            const SizedBox(height: _kSpacing),
            const Text(
              'Data Pasien Kosong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Silakan tambahkan pasien baru melalui tombol tambah (+).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList(List<Patient> patients) {
    return ListView.builder(
      itemCount: patients.length,
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ), // Padding atas dan bawah
      itemBuilder: (context, index) {
        final p = patients[index];
        final isLocal = p.id >= _localIdBase;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _kSpacing,
            vertical: 6,
          ),
          child: Card(
            elevation: 4, // Bayangan yang lebih jelas
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _handlePatientTap(p),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLocal
                      ? Colors.orange.shade100
                      : _kPrimaryColor,
                  child: Icon(
                    isLocal ? Icons.cloud_off : Icons.person,
                    color: isLocal ? Colors.orange.shade700 : _kWhiteColor,
                  ),
                ),
                title: Text(
                  p.namaPasien,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No RM: ${p.noRM}'),
                    Row(
                      children: [
                        Text('Status: ${p.statusRujukan.toUpperCase()}'),
                        const SizedBox(width: 8),
                        if (isLocal)
                          const Tooltip(
                            message: 'Pasien lokal (belum disinkronkan)',
                            child: Icon(
                              Icons.sync_problem,
                              color: Colors.orange,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePatientTap(Patient p) async {
    final isLocal = p.id >= _localIdBase;

    if (isLocal) {
      final shouldReload = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PatientLocalDetailPage(patient: p),
        ),
      );

      if (shouldReload == true && mounted) {
        setState(() {
          _patientsFuture = _loadLocalThenRemote();
        });
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientDetailPage(patientId: p.id),
        ),
      );
    }
  }
}
