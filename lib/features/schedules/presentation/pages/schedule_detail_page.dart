// TEMPORARILY DISABLED - Needs refactoring for schema v7
// Kunjungan table removed, use Registrasi directly

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/tagihan_repository.dart';
import 'package:homecare_mobile/features/schedules/domain/models/registrasi.dart'
    as db;
import 'package:homecare_mobile/features/patients/data/repositories/pasien_repository.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart'
    as db;

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
  db.Registrasi? _registration;
  db.Pasien? _patient;

  // Track progress without Kunjungan table
  bool _anamnesaDone = false;
  bool _tindakanDone = false;
  bool _icdDone = false;
  int _progressStep = 0;
  Map<String, dynamic>? _rawRegistrasi;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final regRepo = getIt<RegistrasiRepository>();
      final pasienRepo = getIt<PasienRepository>();
      final reg = await regRepo.getRegistrasiById(widget.registrationId);
      final raw = await regRepo.getRegistrasiRawById(widget.registrationId);
      final patients = await pasienRepo.getAllPasien();
      final patient = patients.firstWhere(
        (p) => p.id == (reg?.pasienId ?? 0),
        orElse: () => patients.isNotEmpty
            ? patients.first
            : db.Pasien(
                id: 0,
                mrn: 'MRN-NA',
                nama: 'Tidak diketahui',
                alamat: '-',
                tanggalLahir: '',
                jenisKelamin: '',
                telepon: '',
                createdAt: '',
                updatedAt: '',
                registrasi: const [],
              ),
      );

      // Derive progress flags from raw registrasi includes
      final hasAnamnesa = raw != null && raw['anamnesa'] != null;
      final icdList = raw != null && raw['icd'] is List ? (raw['icd'] as List) : const [];
      final tindakanList = raw != null && raw['tindakan'] is List ? (raw['tindakan'] as List) : const [];
      _anamnesaDone = hasAnamnesa;
      _icdDone = icdList.isNotEmpty;
      _tindakanDone = tindakanList.isNotEmpty;
      _progressStep = (_anamnesaDone ? 1 : 0) + (_tindakanDone ? 1 : 0) + (_icdDone ? 1 : 0);
      // consider completed when all steps done (used for filters elsewhere)

      _registration = reg;
      _rawRegistrasi = raw;
      _patient = patient;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Keep user on Schedules; use list filters to show selesai
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

  Future<void> _resetAnamnesa() async {
    try {
      final repo = getIt<RegistrasiRepository>();
      await repo.deleteAnamnesaByRegistrasiId(widget.registrationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anamnesa direset')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal reset anamnesa: $e')));
    }
  }

  Future<void> _resetTindakan() async {
    try {
      final repo = getIt<RegistrasiRepository>();
      await repo.detachAllTindakan(widget.registrationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tindakan direset')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal reset tindakan: $e')));
    }
  }

  Future<void> _resetIcd() async {
    try {
      final repo = getIt<RegistrasiRepository>();
      await repo.detachAllIcd(widget.registrationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ICD direset')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal reset ICD: $e')));
    }
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
    final progress = _progressStep;
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
                  color: kWhite.withValues(alpha: 0.2),
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
                        backgroundColor: kWhite.withValues(alpha: 0.2),
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
            color: kPrimaryColor.withValues(alpha: 0.08),
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
          _buildInfoRow(Icons.badge, 'No. RM', _patient!.mrn),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, 'Telepon', _patient!.telepon),
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
            color: kInfoColor.withValues(alpha: 0.08),
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
            _formatDate(DateTime.parse(_registration!.tglJamReg!)),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time,
            'Jam',
            DateFormat(
              'HH:mm',
            ).format(DateTime.parse(_registration!.tglJamReg!)),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.medical_services,
            'Jenis',
            _registration!.jenisKunjungan ?? '-',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.category,
            'Tipe Pasien',
            _registration!.tipePasien ?? '-',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final anamnesaDone = _anamnesaDone;
    final tindakanDone = _tindakanDone;
    final icdDone = _icdDone;

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kSuccessColor.withValues(alpha: 0.08),
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
                ? kSuccessColor.withValues(alpha: 0.1)
                : kTextGrey.withValues(alpha: 0.1),
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
    final anamnesaDone = _anamnesaDone;
    final tindakanDone = _tindakanDone;
    final icdDone = _icdDone;

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
                .push('/schedules/detail/${widget.registrationId}/anamnesa')
                .then((_) => _loadData());
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Isi Tindakan',
          'Prosedur medis yang dilakukan',
          Icons.medical_information,
          kInfoColor,
          tindakanDone,
          () {
            context
                .push('/schedules/detail/${widget.registrationId}/tindakan')
                .then((_) => _loadData());
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Isi Diagnosa ICD',
          'Kode diagnosis penyakit',
          Icons.health_and_safety,
          kInfoColor,
          icdDone,
          () {
            context
                .push('/schedules/detail/${widget.registrationId}/icd')
                .then((_) => _loadData());
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Simpan Tagihan',
          'Buat invoice dari tindakan + ICD',
          Icons.receipt_long,
          kSecondaryColor,
          _tindakanDone && _icdDone, // done indicator when both exist
          _createTagihan,
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
              ? [kSuccessColor, kSuccessColor.withValues(alpha: 0.8)]
              : [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDone ? kSuccessColor : color).withValues(alpha: 0.3),
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
                    color: kWhite.withValues(alpha: 0.2),
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
                          color: kWhite.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetAnamnesa,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Anamnesa'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetTindakan,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Tindakan'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetIcd,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset ICD'),
            ),
          ),
        ],
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

  Future<void> _createTagihan() async {
    try {
      final raw = _rawRegistrasi ?? await getIt<RegistrasiRepository>()
          .getRegistrasiRawById(widget.registrationId);
      if (raw == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data registrasi tidak ditemukan')),
        );
        return;
      }

      // Extract ICD (primary) and tindakan selections from raw
      final icdList = raw['icd'] is List ? (raw['icd'] as List) : const [];
      if (icdList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih ICD terlebih dahulu')),
        );
        return;
      }
      final String primaryIcd = (icdList.first['kode'] ?? icdList.first.toString()).toString();

      final tindakanList = raw['tindakan'] is List ? (raw['tindakan'] as List) : const [];
      if (tindakanList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambah tindakan terlebih dahulu')),
        );
        return;
      }

      final nowIso = DateTime.now().toIso8601String();
      final items = tindakanList.map<Map<String, dynamic>>((t) {
        final num qty = (t['jumlah'] ?? 1) is num ? t['jumlah'] as num : 1;
        final num harga = (t['tarif'] ?? 0) is num ? t['tarif'] as num : num.tryParse('${t['tarif']}') ?? 0;
        final num diskon = (t['diskon'] ?? 0) is num ? t['diskon'] as num : num.tryParse('${t['diskon']}') ?? 0;
        final subtotal = qty * harga - diskon;
        return {
          'kategori_layanan_id': t['kategori_layanan_id'] ?? 0,
          'tanggal_layanan': nowIso,
          'deskripsi': (t['deskripsi'] ?? t['kode'] ?? 'Tindakan'),
          'jumlah': qty,
          'harga_satuan': harga,
          'diskon': diskon,
          'subtotal': subtotal,
        };
      }).toList();

      final repo = getIt<TagihanRepository>();
      final res = await repo.createTagihan(
        registrasiId: widget.registrationId,
        primaryIcd: primaryIcd,
        items: items,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tagihan berhasil dibuat')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat tagihan: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal membuat tagihan: $e')));
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
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
