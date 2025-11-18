import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart' as db;
import 'package:drift/drift.dart' as drift;

// --- Palet Warna ---
const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kSecondaryColor = Color(0xFF8BC43E);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);
const Color kInfoColor = Color(0xFF3B82F6);

class ScheduleDetailPage extends StatefulWidget {
  final int registrationId;

  const ScheduleDetailPage({super.key, required this.registrationId});

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late final db.AppDatabase _database;
  db.Registrasi? _registration;
  db.Pasien? _patient;
  db.Kunjungan? _visit;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _database = getIt<db.AppDatabase>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final registration = await _database.getRegistrasiById(
        widget.registrationId,
      );
      if (registration == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi tidak ditemukan')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      final patient = await _database.getPasienById(registration.pasienId);
      db.Kunjungan? visit = await _database.getKunjunganByRegistrasiId(
        widget.registrationId,
      );

      if (visit == null) {
        final noKunjungan =
            'VST-${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        final visitId = await _database.insertKunjungan(
          db.KunjungansCompanion(
            noKunjungan: drift.Value(noKunjungan),
            registrasiId: drift.Value(widget.registrationId),
            pasienId: drift.Value(registration.pasienId),
            tanggalKunjungan: drift.Value(registration.tanggalKunjungan),
            status: const drift.Value('terjadwal'),
            anamnesaDone: const drift.Value(false),
            tindakanDone: const drift.Value(false),
            icdDone: const drift.Value(false),
            progressStep: const drift.Value(0),
          ),
        );
        visit = await _database.getKunjunganById(visitId);
      }

      debugPrint(
        '✅ Loaded visit data: anamnesaDone=${visit?.anamnesaDone}, tindakanDone=${visit?.tindakanDone}, icdDone=${visit?.icdDone}, progressStep=${visit?.progressStep}',
      );

      if (mounted) {
        setState(() {
          _registration = registration;
          _patient = patient;
          _visit = visit;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading schedule detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          title: const Text('Detail Jadwal'),
          backgroundColor: kPrimaryColor,
          foregroundColor: kWhite,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    if (_registration == null || _patient == null) {
      return Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          title: const Text('Detail Jadwal'),
          backgroundColor: kPrimaryColor,
          foregroundColor: kWhite,
        ),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPatientCard(),
                  const SizedBox(height: 16),
                  _buildScheduleCard(),
                  const SizedBox(height: 16),
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final progress = _visit?.progressStep ?? 0;
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: kPrimaryColor,
      foregroundColor: kWhite,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Kunjungan ${_patient!.nama}',
          style: const TextStyle(fontSize: 16, color: kWhite),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor, kPrimaryLight],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kWhite.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: progress / 3,
                        backgroundColor: kWhite.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(kWhite),
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                      '$progress/3',
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard() {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pasien',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person, 'Nama', _patient!.nama),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.badge, 'No. RM', _patient!.noRm),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, 'Telepon', _patient!.noTelp),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Alamat', _patient!.alamat),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kInfoColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwal Kunjungan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_today,
            'Tanggal',
            _formatDate(_registration!.tanggalKunjungan),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, 'Jam', _registration!.jamKunjungan),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.medical_services,
            'Jenis',
            _registration!.jenisKunjungan,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.category,
            'Tipe Pasien',
            _registration!.tipePasien,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final anamnesaDone = _visit?.anamnesaDone ?? false;
    final tindakanDone = _visit?.tindakanDone ?? false;
    final icdDone = _visit?.icdDone ?? false;

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kSuccessColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Kunjungan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressItem(
            'Anamnesa',
            'Keluhan dan riwayat pasien',
            anamnesaDone,
            Icons.description,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            'Tindakan Medis',
            'Prosedur yang dilakukan',
            tindakanDone,
            Icons.medical_information,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            'Diagnosa ICD',
            'Kode diagnosis penyakit',
            icdDone,
            Icons.health_and_safety,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    String title,
    String subtitle,
    bool isDone,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDone
                ? kSuccessColor.withOpacity(0.1)
                : kTextGrey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDone ? Icons.check_circle : icon,
            color: isDone ? kSuccessColor : kTextGrey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDone ? kSuccessColor : kTextDark,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: kTextGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final anamnesaDone = _visit?.anamnesaDone ?? false;
    final tindakanDone = _visit?.tindakanDone ?? false;
    final icdDone = _visit?.icdDone ?? false;

    return Column(
      children: [
        _buildActionButton(
          'Isi Anamnesa',
          'Keluhan dan pemeriksaan fisik',
          Icons.description,
          kInfoColor,
          anamnesaDone,
          () {
            context
                .push(
                  '/schedules/detail/${widget.registrationId}/anamnesa',
                  extra: _visit,
                )
                .then((_) => _loadData());
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Isi Tindakan',
          'Prosedur medis yang dilakukan',
          Icons.medical_information,
          const Color(0xFF8B5CF6),
          tindakanDone,
          () {
            context
                .push(
                  '/schedules/detail/${widget.registrationId}/tindakan',
                  extra: _visit,
                )
                .then((_) => _loadData());
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Isi Diagnosa ICD',
          'Kode diagnosis penyakit',
          Icons.health_and_safety,
          kSuccessColor,
          icdDone,
          () {
            context
                .push(
                  '/schedules/detail/${widget.registrationId}/icd',
                  extra: _visit,
                )
                .then((_) => _loadData());
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isDone,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDone
              ? [kSuccessColor, kSuccessColor.withOpacity(0.8)]
              : [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDone ? kSuccessColor : color).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDone ? Icons.check_circle : icon,
                    color: kWhite,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: kWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: kWhite.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isDone ? Icons.edit : Icons.arrow_forward_ios,
                  color: kWhite,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: kPrimaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: kTextGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: kTextDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
