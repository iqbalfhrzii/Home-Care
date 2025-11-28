import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart' as db;
import 'package:drift/drift.dart' as drift;

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);
const Color kCardBg = Color(0xFFFAFAFA);

class ScheduleAnamnesaPage extends StatefulWidget {
  final int registrationId;
  final VoidCallback? onCompleted;

  const ScheduleAnamnesaPage({
    super.key,
    required this.registrationId,
    this.onCompleted,
  });

  @override
  State<ScheduleAnamnesaPage> createState() => _ScheduleAnamnesaPageState();
}

class _ScheduleAnamnesaPageState extends State<ScheduleAnamnesaPage> {
  late final db.AppDatabase _database;
  late final Dio _dio;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  int _currentStep = 0; // 0: Keperawatan, 1: Medis, 2: Perawat

  // FORMULIR PENGKAJIAN KEPERAWATAN
  final _tekananDarahController = TextEditingController();
  final _frekuensiNadiController = TextEditingController();
  final _suhuController = TextEditingController();
  final _frekuensiPernapasanController = TextEditingController();
  String _riwayatAlergi = 'Tidak';

  final _beratBadanController = TextEditingController();
  final _tinggiBadanController = TextEditingController();
  final _imtController = TextEditingController();
  final _lingkarKepalaController = TextEditingController();
  final _asupMakanController = TextEditingController();
  final _nutrisiBbController = TextEditingController();

  final _alatBantuController = TextEditingController();
  final _prothesaController = TextEditingController();
  final _cacatTubuhController = TextEditingController();
  String _adl = 'Mandiri';
  String _resikoJatuh = 'Ada';
  final _riwayatPenyakitDahuluController = TextEditingController();

  final _keluhanPasienController = TextEditingController();

  final List<String> _masalahKeperawatan = [];
  final Map<String, bool> _masalahKeperawatanOptions = {
    'Bersihan jalan nafas': false,
    'Pola nafas tidak efektif': false,
    'Hipertermia': false,
    'Nyeri akut': false,
    'Nyeri kronik': false,
    'Mual': false,
    'Gangguan perfusi jaringan serebral': false,
    'Gangguan keseimbangan cairan': false,
    'Lainnya': false,
  };
  final _masalahKeperawatanLainnyaController = TextEditingController();

  // FORMULIR PENGKAJIAN MEDIS
  final _pemeriksaanFisikController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _rencanaTerapiController = TextEditingController();
  final _pemeriksaanPenunjangController = TextEditingController();
  final _kontrolController = TextEditingController();
  String _jenisPerawatan = 'Preventif';
  final _rujukanController = TextEditingController();

  // DIISI KHUSUS PERAWAT
  final _intervensiTimeUpGoController = TextEditingController();
  final List<String> _intervensiTimeUpGoResults = [];
  final Map<String, bool> _intervensiTimeUpGoOptions = {
    'Tidak seimbang/sempoyongan/limbung': false,
    'Jalan dengan menggunakan alat bantu (huk, tripot, kursi, orang bantu/pendamping)':
        false,
    'Mengangkat saat akan duduk, tampak menopang/pegang kursi atau meja/benda lain sebagai penyangga saat akan duduk':
        false,
  };

  final _skriningNutrisiMstController = TextEditingController();
  final List<String> _skriningNutrisiMstResults = [];
  final Map<String, String> _skriningNutrisiMstAnswers = {
    'penurunan_berat': '',
    'makan_menurun': '',
  };

  final _skriningNutrisiStrongkidsController = TextEditingController();
  final List<String> _skriningNutrisiStrongkidsResults = [];
  final Map<String, String> _skriningNutrisiStrongkidsAnswers = {
    'penyakit_malnutrisi': '',
    'tampak_kurus': '',
    'tindakan_khusus': '',
    'nyeri': '',
  };

  final _edukasiPasienController = TextEditingController();
  final Map<String, bool> _edukasiPasienOptions = {
    'diagnosa': false,
    'rencana_tindak_lanjut': false,
  };

  final _penerimaPulangPasienController = TextEditingController();
  final _hambatanMobilisasiController = TextEditingController();
  final Map<String, bool> _hambatanMobilisasiOptions = {
    'lanjut_usia': false,
    'tidak_ada': false,
  };
  final _urutanPelayananController = TextEditingController();

  // Perencanaan pulang (sesuai schema)
  bool _rencUsiaLanjut = false;
  bool _rencHambatanMobil = false;
  bool _rencLayananMedis = false;
  bool _rencTergantungOrg = false;

  db.Anamnesa? _existingAnamnesa;
  int? _remoteAnamnesaId; // existing server anamnesa id for this registrasi

  @override
  void initState() {
    super.initState();
    _database = getIt<db.AppDatabase>();
    _dio = getIt<Dio>();
    _loadExistingAnamnesa();
  }

  @override
  void dispose() {
    _tekananDarahController.dispose();
    _frekuensiNadiController.dispose();
    _suhuController.dispose();
    _frekuensiPernapasanController.dispose();
    _beratBadanController.dispose();
    _tinggiBadanController.dispose();
    _imtController.dispose();
    _lingkarKepalaController.dispose();
    _asupMakanController.dispose();
    _nutrisiBbController.dispose();
    _alatBantuController.dispose();
    _prothesaController.dispose();
    _cacatTubuhController.dispose();
    _riwayatPenyakitDahuluController.dispose();
    _keluhanPasienController.dispose();
    _masalahKeperawatanLainnyaController.dispose();
    _pemeriksaanFisikController.dispose();
    _diagnosisController.dispose();
    _rencanaTerapiController.dispose();
    _pemeriksaanPenunjangController.dispose();
    _kontrolController.dispose();
    _rujukanController.dispose();
    _intervensiTimeUpGoController.dispose();
    _skriningNutrisiMstController.dispose();
    _skriningNutrisiStrongkidsController.dispose();
    _edukasiPasienController.dispose();
    _penerimaPulangPasienController.dispose();
    _hambatanMobilisasiController.dispose();
    _urutanPelayananController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAnamnesa() async {
    setState(() => _isLoading = true);
    try {
      // Try to load from API first
      db.Anamnesa? anamnesa;
      try {
        // Use server registrasi_id when available
        final reg = await _database.getRegistrasiById(widget.registrationId);
        final queryRegId = reg?.serverId ?? widget.registrationId;
        debugPrint(
          '🔍 Fetching anamnesa from /anamnesa API for registrasi_id: $queryRegId',
        );
        final response = await _dio.get(
          '/anamnesa',
          queryParameters: {'registrasi_id': queryRegId},
        );

        debugPrint('✅ GET /anamnesa - Status: ${response.statusCode}');
        if (response.statusCode == 200 && response.data != null) {
          final list = response.data is Map && response.data['data'] is List
              ? (response.data['data'] as List)
              : (response.data is List ? (response.data as List) : <dynamic>[]);

          if (list.isNotEmpty && list.first is Map) {
            final map = list.first as Map<String, dynamic>;
            _remoteAnamnesaId = map['id'] as int?;
            debugPrint(
              '✅ Found existing anamnesa on server, id=$_remoteAnamnesaId',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ API error, trying local database: $e');
      }

      // Load from local database (either synced from API or just local)
      anamnesa = await _database.getAnamnesaByRegistrasiId(
        widget.registrationId,
      );

      if (anamnesa != null && mounted) {
        setState(() {
          _existingAnamnesa = anamnesa;

          // Parse pengkajianKeperawatan JSON
          if (anamnesa?.pengkajianKeperawatan != null) {
            try {
              final data =
                  jsonDecode(anamnesa?.pengkajianKeperawatan ?? '{}')
                      as Map<String, dynamic>;
              _tekananDarahController.text = data['tekanan_darah'] ?? '';
              _frekuensiNadiController.text = data['frekuensi_nadi'] ?? '';
              _suhuController.text = data['suhu'] ?? '';
              _frekuensiPernapasanController.text =
                  data['frekuensi_pernapasan'] ?? '';
              _riwayatAlergi = data['riwayat_alergi'] ?? 'Tidak';
              _beratBadanController.text = data['berat_badan'] ?? '';
              _tinggiBadanController.text = data['tinggi_badan'] ?? '';
              _imtController.text = data['imt'] ?? '';
              _lingkarKepalaController.text = data['lingkar_kepala'] ?? '';
              _asupMakanController.text = data['asup_makan'] ?? '';
              _nutrisiBbController.text = data['nutrisi_bb'] ?? '';
              _alatBantuController.text = data['alat_bantu'] ?? '';
              _prothesaController.text = data['prothesa'] ?? '';
              _cacatTubuhController.text = data['cacat_tubuh'] ?? '';
              _adl = data['adl'] ?? 'Mandiri';
              _resikoJatuh = data['resiko_jatuh'] ?? 'Ada';
              _riwayatPenyakitDahuluController.text =
                  data['riwayat_penyakit_dahulu'] ?? '';
              _keluhanPasienController.text = data['keluhan_pasien'] ?? '';

              if (data['masalah_keperawatan'] is List) {
                _masalahKeperawatan.clear();
                _masalahKeperawatan.addAll(
                  (data['masalah_keperawatan'] as List).cast<String>(),
                );
                for (var item in _masalahKeperawatan) {
                  if (_masalahKeperawatanOptions.containsKey(item)) {
                    _masalahKeperawatanOptions[item] = true;
                  }
                }
              }
              _masalahKeperawatanLainnyaController.text =
                  data['masalah_keperawatan_lainnya'] ?? '';
            } catch (e) {
              debugPrint('❌ Error parsing pengkajianKeperawatan: $e');
            }
          }

          // Parse pengkajianMedis JSON
          if (anamnesa?.pengkajianMedis != null) {
            try {
              final data =
                  jsonDecode(anamnesa?.pengkajianMedis ?? '{}')
                      as Map<String, dynamic>;
              _pemeriksaanFisikController.text =
                  data['pemeriksaan_fisik'] ?? '';
              _diagnosisController.text = data['diagnosis'] ?? '';
              _rencanaTerapiController.text = data['rencana_terapi'] ?? '';
              _pemeriksaanPenunjangController.text =
                  data['pemeriksaan_penunjang'] ?? '';
              _kontrolController.text = data['kontrol'] ?? '';
              _jenisPerawatan = data['jenis_perawatan'] ?? 'Preventif';
              _rujukanController.text = data['rujukan'] ?? '';
            } catch (e) {
              debugPrint('❌ Error parsing pengkajianMedis: $e');
            }
          }

          // Parse khususPerawat JSON
          if (anamnesa?.khususPerawat != null) {
            try {
              final data =
                  jsonDecode(anamnesa?.khususPerawat ?? '{}')
                      as Map<String, dynamic>;

              if (data['intervensi_time_up_go'] is List) {
                _intervensiTimeUpGoResults.clear();
                _intervensiTimeUpGoResults.addAll(
                  (data['intervensi_time_up_go'] as List).cast<String>(),
                );
                for (var item in _intervensiTimeUpGoResults) {
                  if (_intervensiTimeUpGoOptions.containsKey(item)) {
                    _intervensiTimeUpGoOptions[item] = true;
                  }
                }
              }

              if (data['skrining_nutrisi_mst'] is Map) {
                final mst =
                    data['skrining_nutrisi_mst'] as Map<String, dynamic>;
                _skriningNutrisiMstAnswers['penurunan_berat'] =
                    mst['penurunan_berat'] ?? '';
                _skriningNutrisiMstAnswers['makan_menurun'] =
                    mst['makan_menurun'] ?? '';
              }

              if (data['skrining_nutrisi_strongkids'] is Map) {
                final strongkids =
                    data['skrining_nutrisi_strongkids'] as Map<String, dynamic>;
                _skriningNutrisiStrongkidsAnswers['penyakit_malnutrisi'] =
                    strongkids['penyakit_malnutrisi'] ?? '';
                _skriningNutrisiStrongkidsAnswers['tampak_kurus'] =
                    strongkids['tampak_kurus'] ?? '';
                _skriningNutrisiStrongkidsAnswers['tindakan_khusus'] =
                    strongkids['tindakan_khusus'] ?? '';
                _skriningNutrisiStrongkidsAnswers['nyeri'] =
                    strongkids['nyeri'] ?? '';
              }

              if (data['edukasi_pasien'] is List) {
                final edukasi = (data['edukasi_pasien'] as List).cast<String>();
                _edukasiPasienOptions['diagnosa'] = edukasi.contains(
                  'diagnosa',
                );
                _edukasiPasienOptions['rencana_tindak_lanjut'] = edukasi
                    .contains('rencana_tindak_lanjut');
              }

              _penerimaPulangPasienController.text =
                  data['penerima_pulang_pasien'] ?? '';

              if (data['hambatan_mobilisasi'] is List) {
                final hambatan = (data['hambatan_mobilisasi'] as List)
                    .cast<String>();
                _hambatanMobilisasiOptions['lanjut_usia'] = hambatan.contains(
                  'lanjut_usia',
                );
                _hambatanMobilisasiOptions['tidak_ada'] = hambatan.contains(
                  'tidak_ada',
                );
              }

              _urutanPelayananController.text = data['urutan_pelayanan'] ?? '';
              _rencUsiaLanjut = (data['renc_usia_lanjut'] == true);
              _rencHambatanMobil = (data['renc_hmbtn_mobil'] == true);
              _rencLayananMedis = (data['renc_layanan_medis'] == true);
              _rencTergantungOrg = (data['renc_tergnt_org'] == true);
            } catch (e) {
              debugPrint('❌ Error parsing khususPerawat: $e');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading anamnesa: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _computeMstScore() {
    int score = 0;
    final penurunanBerat = _skriningNutrisiMstAnswers['penurunan_berat'] ?? '';
    if (penurunanBerat.contains('(1)')) score += 1;
    if (penurunanBerat.contains('(2)')) score += 2;
    if (penurunanBerat.contains('(3)')) score += 3;
    if (penurunanBerat.contains('(4)')) score += 4;
    final makanMenurun = _skriningNutrisiMstAnswers['makan_menurun'] ?? '';
    if (makanMenurun.contains('(1)')) score += 1;
    return score;
  }

  int _computeStrongkidsScore() {
    int score = 0;
    for (var answer in _skriningNutrisiStrongkidsAnswers.values) {
      if (answer.contains('(1)')) score += 1;
      if (answer.contains('(2)')) score += 2;
    }
    return score;
  }

  Future<void> _saveAnamnesa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Build pengkajianKeperawatan JSON in nested structure expected by API
      final masalahMap = {
        'jalan_nafas':
            _masalahKeperawatanOptions['Bersihan jalan nafas'] == true,
        'pola_nafas':
            _masalahKeperawatanOptions['Pola nafas tidak efektif'] == true,
        'hipertermia': _masalahKeperawatanOptions['Hipertermia'] == true,
        'nyeri_kronik': _masalahKeperawatanOptions['Nyeri kronik'] == true,
        'nyeri_akut': _masalahKeperawatanOptions['Nyeri akut'] == true,
        'mual': _masalahKeperawatanOptions['Mual'] == true,
        'gangguan_perfusi':
            _masalahKeperawatanOptions['Gangguan perfusi jaringan serebral'] ==
            true,
        'gangguan_cairan':
            _masalahKeperawatanOptions['Gangguan keseimbangan cairan'] == true,
        'lainnya': _masalahKeperawatanLainnyaController.text,
      };

      final pengkajianKeperawatanMap = {
        'tanda_vital': {
          'tekanan_darah': _tekananDarahController.text,
          'nadi': int.tryParse(_frekuensiNadiController.text),
          'suhu': double.tryParse(_suhuController.text),
          'pernapasan': int.tryParse(_frekuensiPernapasanController.text),
          'riwayat_alergi': _riwayatAlergi == 'Ya',
        },
        'nutrisi': {
          'berat_badan': double.tryParse(_beratBadanController.text),
          'tinggi_badan': double.tryParse(_tinggiBadanController.text),
          'imt': double.tryParse(_imtController.text),
          'lingkar_kepala': double.tryParse(_lingkarKepalaController.text),
        },
        'fungsional': {
          'alat_bantu': _alatBantuController.text,
          'prothesa': _prothesaController.text,
          'cacat_tubuh': _cacatTubuhController.text,
          'adl': _adl == 'Mandiri',
          'resiko_jatuh': _resikoJatuh == 'Ada',
          'riwayat': _riwayatPenyakitDahuluController.text,
        },
        'keluhan': {'keluhan': _keluhanPasienController.text},
        'masalah_keperawatan': masalahMap,
      };

      final pengkajianKeperawatan = jsonEncode(pengkajianKeperawatanMap);

      // Build pengkajianMedis JSON
      final pengkajianMedis = jsonEncode({
        'pemeriksaan_fisik': _pemeriksaanFisikController.text,
        'diagnosis': _diagnosisController.text,
        'rencana_terapi': _rencanaTerapiController.text,
        'pemeriksaan_penunjang': _pemeriksaanPenunjangController.text,
        'kontrol': _kontrolController.text,
        'jenis_perawatan': _jenisPerawatan,
        'rujukan': _rujukanController.text,
      });

      // Build khususPerawat JSON (for local storage only)
      final selectedIntervensiTimeUpGo = _intervensiTimeUpGoOptions.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final selectedEdukasiPasien = _edukasiPasienOptions.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final selectedHambatanMobilisasi = _hambatanMobilisasiOptions.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final khususPerawat = jsonEncode({
        'intervensi_time_up_go': selectedIntervensiTimeUpGo,
        'skrining_nutrisi_mst': _skriningNutrisiMstAnswers,
        'skrining_nutrisi_strongkids': _skriningNutrisiStrongkidsAnswers,
        'edukasi_pasien': selectedEdukasiPasien,
        'penerima_pulang_pasien': _penerimaPulangPasienController.text,
        'hambatan_mobilisasi': selectedHambatanMobilisasi,
        'urutan_pelayanan': _urutanPelayananController.text,
        'renc_usia_lanjut': _rencUsiaLanjut,
        'renc_hmbtn_mobil': _rencHambatanMobil,
        'renc_layanan_medis': _rencLayananMedis,
        'renc_tergnt_org': _rencTergantungOrg,
      });

      final companion = db.AnamnesasCompanion(
        registrasiId: drift.Value(widget.registrationId),
        pengkajianKeperawatan: drift.Value(pengkajianKeperawatan),
        pengkajianMedis: drift.Value(pengkajianMedis),
        khususPerawat: drift.Value(khususPerawat),
        tanggal: drift.Value(DateTime.now().toIso8601String()),
        updatedAt: drift.Value(DateTime.now()),
        isSynced: const drift.Value(false), // Will be synced automatically
      );

      int anamnesaId;
      if (_existingAnamnesa != null) {
        await _database.updateAnamnesa(_existingAnamnesa!.id, companion);
        anamnesaId = _existingAnamnesa!.id;
      } else {
        anamnesaId = await _database.insertAnamnesa(companion);
      }

      debugPrint('✅ Anamnesa saved to local database');

      // Now POST/PUT to API using flat schema (per backend contract)
      try {
        final reg = await _database.getRegistrasiById(widget.registrationId);
        final registrasiServerId = reg?.serverId;

        if (registrasiServerId == null) {
          debugPrint(
            '⚠️ Registrasi belum tersinkron. Lewati POST anamnesa, akan disinkronkan nanti.',
          );
        } else {
          // Build flat payload matching server schema exactly
          final edukasiSelected = _edukasiPasienOptions.values.any((v) => v);
          final caraBerjalan =
              _intervensiTimeUpGoOptions['Tidak seimbang/sempoyongan/limbung'] ==
              true;
          final caraBerjalan2 =
              _intervensiTimeUpGoOptions['Jalan dengan menggunakan alat bantu (huk, tripot, kursi, orang bantu/pendamping)'] ==
              true;
          final menopang =
              _intervensiTimeUpGoOptions['Mengangkat saat akan duduk, tampak menopang/pegang kursi atau meja/benda lain sebagai penyangga saat akan duduk'] ==
              true;

          final strong1 =
              (_skriningNutrisiStrongkidsAnswers['penyakit_malnutrisi'] ?? '')
                  .startsWith('Ya');
          final strong2 =
              (_skriningNutrisiStrongkidsAnswers['tampak_kurus'] ?? '')
                  .startsWith('Ya');
          final strong3 =
              (_skriningNutrisiStrongkidsAnswers['tindakan_khusus'] ?? '')
                  .startsWith('Ya');
          final strong4 = (_skriningNutrisiStrongkidsAnswers['nyeri'] ?? '')
              .startsWith('Ya');

          final apiData = <String, dynamic>{
            'registrasi_id': registrasiServerId,
            // Keep date-only to avoid known 422s in this API
            'tanggal': DateTime.now().toIso8601String().substring(0, 10),

            // Keluhan / Riwayat
            'keluhan': _keluhanPasienController.text,
            'riwayat': _riwayatPenyakitDahuluController.text,
            'riwayat_alergi': _riwayatAlergi == 'Ya',

            // Pemeriksaan Medis
            'pemeriksaan_fisik': _pemeriksaanFisikController.text,
            'pemeriksaan_penunjang': _pemeriksaanPenunjangController.text,
            'diagnosis': _diagnosisController.text,
            'rencana_dan_terapi': _rencanaTerapiController.text,
            'kontrol': _kontrolController.text,

            // Edukasi
            'edukasi': edukasiSelected,
            'edukasi_ket': _edukasiPasienController.text,

            // Tanda vital / nutrisi / fungsional
            'tekanan_darah': _tekananDarahController.text,
            'nadi': _frekuensiNadiController.text,
            'suhu': double.tryParse(_suhuController.text),
            'pernapasan': _frekuensiPernapasanController.text,
            'berat_badan': double.tryParse(_beratBadanController.text),
            'tinggi_badan': double.tryParse(_tinggiBadanController.text),
            'imt': double.tryParse(_imtController.text),
            'lingkar_kepala': double.tryParse(_lingkarKepalaController.text),
            'adl': _adl == 'Mandiri',
            'resiko_jatuh': _resikoJatuh == 'Ada',

            // Masalah keperawatan (checkboxes)
            'jalan_nafas':
                _masalahKeperawatanOptions['Bersihan jalan nafas'] == true,
            'pola_nafas':
                _masalahKeperawatanOptions['Pola nafas tidak efektif'] == true,
            'hipertermia': _masalahKeperawatanOptions['Hipertermia'] == true,
            'nyeri_kronik': _masalahKeperawatanOptions['Nyeri kronik'] == true,
            'nyeri_akut': _masalahKeperawatanOptions['Nyeri akut'] == true,
            'mual': _masalahKeperawatanOptions['Mual'] == true,
            'gangguan_perfusi':
                _masalahKeperawatanOptions['Gangguan perfusi jaringan serebral'] ==
                true,
            'gangguan_cairan':
                _masalahKeperawatanOptions['Gangguan keseimbangan cairan'] ==
                true,
            'lainnya': _masalahKeperawatanLainnyaController.text,

            // Intervensi time up & go
            'cara_berjalan': caraBerjalan,
            'cara_berjalan2': caraBerjalan2,
            'menopang': menopang,

            // STRONGkids flags
            'strong_kids1': strong1,
            'strong_kids2': strong2,
            'strong_kids3': strong3,
            'strong_kids4': strong4,

            // Rencana pulang checklist
            'renc_usia_lanjut': _rencUsiaLanjut,
            'renc_hmbtn_mobil': _rencHambatanMobil,
            'renc_layanan_medis': _rencLayananMedis,
            'renc_tergnt_org': _rencTergantungOrg,

            // Risiko summary + jenis perawatan
            'risiko':
                'MST:${_computeMstScore()};STRONGKIDS:${_computeStrongkidsScore()}',
            'jenis_perawatan': _jenisPerawatan,

            // Lain-lain
            'alat_bantu': _alatBantuController.text,
            'asup_makan': _asupMakanController.text,
            'cacat_tubuh': _cacatTubuhController.text,
            'prothesa': _prothesaController.text,
            'nutrisi_bb': _nutrisiBbController.text,
          };

          // Conditionally add dokter_id if parseable to int
          final parsedDokterId = int.tryParse(reg?.dokterId ?? '');
          if (parsedDokterId != null) {
            apiData['dokter_id'] = parsedDokterId;
          }

          // Conditionally add poli_id only if numeric-like
          final kodePoli = reg?.kodePoli;
          if (kodePoli != null && RegExp(r'^\d+$').hasMatch(kodePoli)) {
            final parsedPoli = int.tryParse(kodePoli);
            if (parsedPoli != null) apiData['poli_id'] = parsedPoli;
          }

          // Prefer updating existing record on server to avoid duplicates
          int? targetId = _existingAnamnesa?.serverId ?? _remoteAnamnesaId;

          // If we still don't know, query once before deciding
          if (targetId == null) {
            try {
              final check = await _dio.get(
                '/anamnesa',
                queryParameters: {'registrasi_id': registrasiServerId},
              );
              final list = check.data is Map && check.data['data'] is List
                  ? (check.data['data'] as List)
                  : (check.data is List ? (check.data as List) : <dynamic>[]);
              if (list.isNotEmpty && list.first is Map) {
                targetId = (list.first as Map<String, dynamic>)['id'] as int?;
                _remoteAnamnesaId = targetId;
              }
            } catch (e) {
              debugPrint('ℹ️ Unable to check existing anamnesa: $e');
            }
          }

          Response response;
          if (targetId != null) {
            debugPrint('📤 Updating anamnesa PUT /anamnesa/$targetId ...');
            response = await _dio.put('/anamnesa/$targetId', data: apiData);
          } else {
            debugPrint('📤 Creating anamnesa POST /anamnesa ...');
            response = await _dio.post('/anamnesa', data: apiData);
          }

          debugPrint('✅ Anamnesa API status: ${response.statusCode}');
          if (response.statusCode == 200 || response.statusCode == 201) {
            // Try capture remote id
            final body = response.data;
            int? remoteId;
            if (body is Map &&
                body['data'] is Map &&
                (body['data']['id'] is int)) {
              remoteId = body['data']['id'] as int;
            } else if (body is Map && body['id'] is int) {
              remoteId = body['id'] as int;
            }

            await _database.updateAnamnesa(
              anamnesaId,
              db.AnamnesasCompanion(
                isSynced: const drift.Value(true),
                serverId: drift.Value(remoteId),
                dokterId: drift.Value(int.tryParse(reg?.dokterId ?? '')),
                poliId: drift.Value(reg?.kodePoli),
                tanggal: drift.Value(DateTime.now().toIso8601String()),
              ),
            );
            debugPrint('✅ Anamnesa synced to API successfully');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Failed to sync anamnesa to API (will retry later): $e');
        // Keep isSynced = false, background service will retry
      }

      debugPrint('✅ Anamnesa saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anamnesa berhasil disimpan'),
            backgroundColor: kSuccessColor,
          ),
        );

        if (widget.onCompleted != null) {
          widget.onCompleted!();
        }

        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Error saving anamnesa: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kDangerColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          title: const Text('Anamnesa Pasien'),
          backgroundColor: kPrimaryColor,
          foregroundColor: kWhite,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStepIndicator(),
                    const SizedBox(height: 16),
                    if (_currentStep == 0) _buildPengkajianKeperawatanSection(),
                    if (_currentStep == 1) _buildPengkajianMedisSection(),
                    if (_currentStep == 2) _buildKhususPerawatSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: kPrimaryColor,
      foregroundColor: kWhite,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Anamnesa Pasien', style: TextStyle(fontSize: 16)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor, kPrimaryLight],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final titles = const ['Keperawatan', 'Medis', 'Khusus Perawat'];
    return Row(
      children: List.generate(3, (index) {
        final active = _currentStep == index;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: active ? kPrimaryColor : kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? kPrimaryColor : kTextGrey.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: active ? kWhite : kPrimaryColor,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? kPrimaryColor : kWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  titles[index],
                  style: TextStyle(
                    color: active ? kWhite : kTextDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // SECTION 1: PENGKAJIAN KEPERAWATAN
  Widget _buildPengkajianKeperawatanSection() {
    return _buildSectionCard(
      title: 'Formulir Pengkajian Keperawatan',
      icon: Icons.medical_services,
      color: kPrimaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanda Vital
          _buildSubsection('Tanda Vital', Icons.monitor_heart),
          _buildTextField(
            controller: _tekananDarahController,
            label: 'Tekanan Darah (mmHg)',
            hint: '120/80',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _frekuensiNadiController,
            label: 'Frekuensi Nadi (x/mnt)',
            hint: '80',
            isNumber: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _suhuController,
            label: 'Suhu (°C)',
            hint: '36.5',
            isNumber: true,
            isDecimal: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _frekuensiPernapasanController,
            label: 'Frekuensi Pernapasan (x/menit)',
            hint: '20',
            isNumber: true,
          ),
          const SizedBox(height: 12),
          _buildRadioGroup(
            label: 'Riwayat Alergi',
            value: _riwayatAlergi,
            options: ['Ya', 'Tidak'],
            onChanged: (val) => setState(() => _riwayatAlergi = val!),
          ),
          const SizedBox(height: 20),

          // Nutrisi
          _buildSubsection('Nutrisi', Icons.restaurant),
          _buildTextField(
            controller: _beratBadanController,
            label: 'Berat Badan (kg)',
            hint: '60',
            isNumber: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _tinggiBadanController,
            label: 'Tinggi Badan (cm)',
            hint: '170',
            isNumber: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _imtController,
            label: 'IMT',
            hint: '20.8',
            isNumber: true,
            isDecimal: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _lingkarKepalaController,
            label: 'Khusus Pediatri: Lingkaran Kepala (cm)',
            hint: '',
          ),
          const SizedBox(height: 20),

          // Fungsional
          _buildSubsection('Fungsional', Icons.accessibility),
          _buildTextField(
            controller: _alatBantuController,
            label: 'Alat Bantu',
            hint: 'Tongkat, kursi roda, dll.',
            multiline: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _prothesaController,
            label: 'Prothesa',
            hint: 'Jenis prothesa',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _cacatTubuhController,
            label: 'Cacat Tubuh',
            hint: 'Keterangan cacat tubuh',
            multiline: true,
          ),
          const SizedBox(height: 12),
          _buildRadioGroup(
            label: 'ADL (Activities of Daily Living)',
            value: _adl,
            options: ['Mandiri', 'Dibantu'],
            onChanged: (val) => setState(() => _adl = val!),
          ),
          const SizedBox(height: 12),
          _buildRadioGroup(
            label: 'Resiko Jatuh',
            value: _resikoJatuh,
            options: ['Ada', 'Tidak Ada'],
            onChanged: (val) => setState(() => _resikoJatuh = val!),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _riwayatPenyakitDahuluController,
            label: 'Riwayat Penyakit Dahulu',
            hint: 'Masukkan riwayat penyakit dahulu...',
            multiline: true,
          ),
          const SizedBox(height: 20),

          // Keluhan
          _buildSubsection('Keluhan', Icons.chat_bubble_outline),
          _buildTextField(
            controller: _keluhanPasienController,
            label: 'Keluhan Pasien',
            hint: 'Masukkan keluhan pasien...',
            multiline: true,
            required: true,
          ),
          const SizedBox(height: 20),

          // Masalah Keperawatan
          _buildSubsection('Masalah Keperawatan', Icons.healing),
          ..._masalahKeperawatanOptions.entries.map((e) {
            return CheckboxListTile(
              title: Text(e.key, style: const TextStyle(fontSize: 13)),
              value: e.value,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _masalahKeperawatanOptions[e.key] = val!);
              },
            );
          }),
          if (_masalahKeperawatanOptions['Lainnya'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildTextField(
                controller: _masalahKeperawatanLainnyaController,
                label: 'Sebutkan masalah keperawatan lainnya',
                hint: '',
              ),
            ),
        ],
      ),
    );
  }

  // SECTION 2: PENGKAJIAN MEDIS
  Widget _buildPengkajianMedisSection() {
    return _buildSectionCard(
      title: 'Formulir Pengkajian Medis',
      icon: Icons.medical_information,
      color: kPrimaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubsection('Anamnesa Pemeriksaan Fisik', Icons.person_search),
          _buildTextField(
            controller: _pemeriksaanFisikController,
            label: 'Pemeriksaan Fisik',
            hint: 'Masukkan hasil pemeriksaan fisik...',
            multiline: true,
          ),
          const SizedBox(height: 20),
          _buildSubsection('Diagnosis', Icons.assignment),
          _buildTextField(
            controller: _diagnosisController,
            label: 'Diagnosis',
            hint: 'Masukkan diagnosis...',
            multiline: true,
          ),
          const SizedBox(height: 20),
          _buildSubsection('Rencana dan Terapi', Icons.medical_services),
          _buildTextField(
            controller: _rencanaTerapiController,
            label: 'Rencana dan Terapi',
            hint: 'Masukkan rencana dan terapi...',
            multiline: true,
          ),
          const SizedBox(height: 20),
          _buildSubsection('Pemeriksaan Penunjang', Icons.science),
          _buildTextField(
            controller: _pemeriksaanPenunjangController,
            label: 'Pemeriksaan Penunjang',
            hint: 'Masukkan pemeriksaan penunjang...',
            multiline: true,
          ),
          const SizedBox(height: 20),
          _buildSubsection('Kontrol', Icons.schedule),
          _buildTextField(
            controller: _kontrolController,
            label: 'Kontrol',
            hint: 'Masukkan jadwal/rencana kontrol...',
            multiline: true,
          ),
          const SizedBox(height: 20),
          _buildSubsection('Jenis Perawatan', Icons.local_hospital),
          _buildRadioGroup(
            label: 'Pilih Jenis Perawatan',
            value: _jenisPerawatan,
            options: ['Preventif', 'Paliatif', 'Kuratif', 'Rehabilitatif'],
            onChanged: (val) => setState(() => _jenisPerawatan = val!),
          ),
          const SizedBox(height: 20),
          _buildSubsection('Rujukan', Icons.arrow_forward),
          _buildTextField(
            controller: _rujukanController,
            label: 'Dirujuk Ke',
            hint: 'Masukkan tujuan rujukan...',
            multiline: true,
          ),
        ],
      ),
    );
  }

  // SECTION 3: KHUSUS PERAWAT
  Widget _buildKhususPerawatSection() {
    return _buildSectionCard(
      title: 'Diisi Khusus Perawat',
      icon: Icons.local_hospital,
      color: kSuccessColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubsection(
            'Intervensi Time Up & Go - Pasien Rawat Jalan yang Beresiko Jatuh',
            Icons.accessibility_new,
          ),
          Text(
            'Cara Benar : jalan lurus (tidak ada istilah)',
            style: TextStyle(fontSize: 12, color: kTextGrey),
          ),
          const SizedBox(height: 8),
          ..._intervensiTimeUpGoOptions.entries.map((e) {
            return CheckboxListTile(
              title: Text(e.key, style: const TextStyle(fontSize: 12)),
              value: e.value,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _intervensiTimeUpGoOptions[e.key] = val!);
              },
            );
          }),
          const SizedBox(height: 20),

          // Skrining Nutrisi - MST
          _buildSubsection(
            'Skrining Nutrisi - MST untuk Pasien Dewasa',
            Icons.restaurant_menu,
          ),
          _buildMstQuestion(
            '1. Apakah ada penurunan berat badan yang tidak diinginkan dalam 6 bulan terakhir?',
            'penurunan_berat',
            [
              'Tidak (0)',
              'Ya 1-5 kg (1)',
              'Ya 6-10 kg (2)',
              'Ya 11-15 kg (3)',
              'Ya >15 kg (4)',
              'Tidak yakin (2)',
            ],
          ),
          const SizedBox(height: 12),
          _buildMstQuestion(
            '2. Apakah asupan makan menurun karena tidak ada nafsu makan/kesulitan menerima makanan?',
            'makan_menurun',
            ['Ya (1)', 'Tidak (0)'],
          ),
          const SizedBox(height: 12),
          _buildMstScoreDisplay(),
          const SizedBox(height: 20),

          // Skrining Nutrisi - STRONGkids
          _buildSubsection(
            'Skrining Nutrisi - STRONGkids untuk Pasien Anak',
            Icons.child_care,
          ),
          _buildStrongkidsQuestion(
            '1. Apakah ada penyakit beresiko malnutrisi (seperti kelainan jantung, bawaan, metabolisme, cacat mental, keganasan)?',
            'penyakit_malnutrisi',
            ['Ya (2)', 'Tidak (0)'],
          ),
          const SizedBox(height: 12),
          _buildStrongkidsQuestion(
            '2. Apakah pasien tampak kurus?',
            'tampak_kurus',
            ['Ya (1)', 'Tidak (0)'],
          ),
          const SizedBox(height: 12),
          _buildStrongkidsQuestion(
            '3. Apakah terdapat salah satu dari kondisi berikut (bukan hanya minum saja atau diare >5 kali/hari)?',
            'tindakan_khusus',
            ['Ya (1)', 'Tidak (0)'],
          ),
          const SizedBox(height: 12),
          _buildStrongkidsQuestion(
            '4. Apakah terjadi penurunan berat badan atau berat badan menetap (pada bayi <1 tahun) selama ≥3 bulan terakhir? Atau apakah pasien menggunakan tabung nasogastrik/ suntikan intravena, apakah pasien makan dengan sedikit atau kesulitan makan?',
            'nyeri',
            ['Ya (1)', 'Tidak (0)'],
          ),
          const SizedBox(height: 12),
          _buildStrongkidsScoreDisplay(),
          const SizedBox(height: 20),

          // Edukasi Pasien
          _buildSubsection('Edukasi Pasien', Icons.school),
          Text(
            'Ya (diberikan di formulir M2)',
            style: TextStyle(
              fontSize: 12,
              color: kTextGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
          CheckboxListTile(
            title: const Text('Diagnosis', style: TextStyle(fontSize: 13)),
            value: _edukasiPasienOptions['diagnosa'],
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() => _edukasiPasienOptions['diagnosa'] = val!);
            },
          ),
          CheckboxListTile(
            title: const Text(
              'Rencana tindak lanjut terapi',
              style: TextStyle(fontSize: 13),
            ),
            value: _edukasiPasienOptions['rencana_tindak_lanjut'],
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(
                () => _edukasiPasienOptions['rencana_tindak_lanjut'] = val!,
              );
            },
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _edukasiPasienController,
            label: 'Alasan tidak dilakukan edukasi',
            hint: 'Masukkan alasan...',
            multiline: true,
          ),
          const SizedBox(height: 20),

          // Penerimaan Pulang Pasien
          _buildSubsection('Perencanaan/Penerimaan Pulang Pasien', Icons.home),
          _buildTextField(
            controller: _penerimaPulangPasienController,
            label:
                'Jika salah satu sewa terpenuhi, tergolong dalam home care dengan formula penerimaan pulang pasien',
            hint: '',
            multiline: true,
          ),
          const SizedBox(height: 20),

          // Hambatan Mobilisasi
          _buildSubsection('Hambatan Mobilisasi', Icons.accessible),
          CheckboxListTile(
            title: const Text(
              'Ya (lanjut usia (>60 tahun) dan alat)',
              style: TextStyle(fontSize: 13),
            ),
            value: _hambatanMobilisasiOptions['lanjut_usia'],
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() => _hambatanMobilisasiOptions['lanjut_usia'] = val!);
            },
          ),
          CheckboxListTile(
            title: const Text('Tidak', style: TextStyle(fontSize: 13)),
            value: _hambatanMobilisasiOptions['tidak_ada'],
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() => _hambatanMobilisasiOptions['tidak_ada'] = val!);
            },
          ),
          const SizedBox(height: 12),
          // Rencana pulang sesuai schema
          _buildSubsection('Rencana Pulang (Checklist)', Icons.check_circle),
          CheckboxListTile(
            title: const Text(
              'Usia lanjut (≥65 tahun atau lebih)',
              style: TextStyle(fontSize: 13),
            ),
            value: _rencUsiaLanjut,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _rencUsiaLanjut = val ?? false),
          ),
          CheckboxListTile(
            title: const Text(
              'Hambatan mobilisasi',
              style: TextStyle(fontSize: 13),
            ),
            value: _rencHambatanMobil,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) =>
                setState(() => _rencHambatanMobil = val ?? false),
          ),
          CheckboxListTile(
            title: const Text(
              'Membutuhkan layanan medis/perawatan berkelanjutan',
              style: TextStyle(fontSize: 13),
            ),
            value: _rencLayananMedis,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) =>
                setState(() => _rencLayananMedis = val ?? false),
          ),
          CheckboxListTile(
            title: const Text(
              'Tergantung orang lain untuk aktivitas harian',
              style: TextStyle(fontSize: 13),
            ),
            value: _rencTergantungOrg,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) =>
                setState(() => _rencTergantungOrg = val ?? false),
          ),
          const SizedBox(height: 12),
          Text(
            'Tergantung dengan orang lain untuk aktivitas harian seperti mandi, berpakaian, ketoilet, berpindah tempat, dan juga konsulensi pelayanan medis dan perawatan berkelanjutan',
            style: TextStyle(
              fontSize: 12,
              color: kTextGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          // Urutan Pelayanan
          _buildTextField(
            controller: _urutanPelayananController,
            label: 'Urutan Pelayanan',
            hint: 'Masukkan urutan pelayanan...',
            multiline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMstQuestion(String question, String key, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...options.map((option) {
          return RadioListTile<String>(
            title: Text(option, style: const TextStyle(fontSize: 12)),
            value: option,
            groupValue: _skriningNutrisiMstAnswers[key],
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() => _skriningNutrisiMstAnswers[key] = val!);
            },
          );
        }),
      ],
    );
  }

  Widget _buildMstScoreDisplay() {
    final score = _computeMstScore();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWarningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kWarningColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Skor: $score',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            score >= 2
                ? 'Skor ≥ 2: berisiko malnutrisi dan gizi'
                : 'Skor 0-1: berisiko rendah',
            style: TextStyle(fontSize: 12, color: kTextGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildStrongkidsQuestion(
    String question,
    String key,
    List<String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...options.map((option) {
          return RadioListTile<String>(
            title: Text(option, style: const TextStyle(fontSize: 12)),
            value: option,
            groupValue: _skriningNutrisiStrongkidsAnswers[key],
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() => _skriningNutrisiStrongkidsAnswers[key] = val!);
            },
          );
        }),
      ],
    );
  }

  Widget _buildStrongkidsScoreDisplay() {
    final score = _computeStrongkidsScore();

    String riskLevel = '';
    if (score >= 4) {
      riskLevel = 'Skor ≥ 4: resiko tinggi';
    } else if (score >= 1) {
      riskLevel = 'Skor 1-3: risiko sedang';
    } else {
      riskLevel = 'Skor 0: risiko rendah';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSuccessColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kSuccessColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Skor: $score',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(riskLevel, style: TextStyle(fontSize: 12, color: kTextGrey)),
        ],
      ),
    );
  }

  Widget _buildSubsection(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kWhite, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool multiline = false,
    int maxLines = 3,
    bool isNumber = false,
    bool isDecimal = false,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: kDangerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber
              ? (isDecimal
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number)
              : (multiline ? TextInputType.multiline : TextInputType.text),
          inputFormatters: isNumber
              ? (isDecimal
                    ? [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ]
                    : [FilteringTextInputFormatter.digitsOnly])
              : null,
          maxLines: multiline ? maxLines : 1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: kTextGrey.withOpacity(0.5),
              fontSize: 12,
            ),
            filled: true,
            fillColor: kCardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: kTextGrey.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kDangerColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$label harus diisi';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildRadioGroup({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: options.map((option) {
            return Expanded(
              child: RadioListTile<String>(
                title: Text(option, style: const TextStyle(fontSize: 12)),
                value: option,
                groupValue: value,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: onChanged,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      color: kWhite,
      padding: const EdgeInsets.all(
        16,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => setState(
                        () => _currentStep = (_currentStep - 1).clamp(0, 2),
                      ),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Sebelumnya'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(color: kPrimaryColor.withOpacity(0.4)),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (_currentStep < 2) {
                        // validate current step minimal required
                        if (_currentStep == 0 &&
                            !_formKey.currentState!.validate()) {
                          return;
                        }
                        setState(() => _currentStep += 1);
                      } else {
                        await _saveAnamnesa();
                      }
                    },
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kWhite,
                      ),
                    )
                  : Icon(_currentStep < 2 ? Icons.navigate_next : Icons.save),
              label: Text(
                _isSaving
                    ? 'Menyimpan...'
                    : (_currentStep < 2 ? 'Selanjutnya' : 'Simpan'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kWhite,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
