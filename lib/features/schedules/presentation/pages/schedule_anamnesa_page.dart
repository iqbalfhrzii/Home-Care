import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/anamnesa_repository.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';

// --- Palet Warna Baru (Futuristic/Modern Clean) ---
const Color kPrimaryColor = Color(0xFF004B8C); // Deep Blue
const Color kPrimaryLight = Color(0xFF0063B2); // Lighter Blue for Gradient
const Color kSecondaryColor = Color(0xFF8BC43E); // Lime Green (Action Color)
const Color kScaffoldBg = Color(0xFFF5F7FA); // Cool White Background
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E); // Green for success/nurse
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);
const Color kCardBg = Color(0xFFFAFAFA); // Lighter card background for contrast
const Color kHeaderNurseColor = kSuccessColor;

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
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0; // 0: Keperawatan, 1: Medis, 2: Khusus Perawat
  final PageController _pageController = PageController();
  bool _isSaving = false;
  bool _isLoadingData = false;

  // FORMULIR PENGKAJIAN KEPERAWATAN
  final _tekananDarahController = TextEditingController(text: '120/80');
  final _frekuensiNadiController = TextEditingController(text: '80');
  final _suhuController = TextEditingController(text: '36.5');
  final _frekuensiPernapasanController = TextEditingController(text: '20');
  String _riwayatAlergi = 'Tidak';

  final _beratBadanController = TextEditingController(text: '60');
  final _tinggiBadanController = TextEditingController(text: '170');
  final _imtController = TextEditingController(text: '20.8');
  final _lingkarKepalaController = TextEditingController();

  final _alatBantuController = TextEditingController();
  final _prothesaController = TextEditingController();
  final _cacatTubuhController = TextEditingController();
  String _adl = 'Mandiri';
  String _resikoJatuh = 'Ada';
  final _riwayatPenyakitDahuluController = TextEditingController();

  final _keluhanPasienController = TextEditingController();

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
  final Map<String, bool> _intervensiTimeUpGoOptions = {
    'Tidak seimbang/sempoyongan/limbung': false,
    'Jalan dengan menggunakan alat bantu (huk, tripot, kursi, orang bantu/pendamping)':
        false,
    'Mengangkat saat akan duduk, tampak menopang/pegang kursi atau meja/benda lain sebagai penyangga saat akan duduk':
        false,
  };

  final Map<String, String> _skriningNutrisiMstAnswers = {
    'penurunan_berat': 'Tidak (0)',
    'makan_menurun': 'Tidak (0)',
  };

  final Map<String, String> _skriningNutrisiStrongkidsAnswers = {
    'penyakit_malnutrisi': 'Tidak (0)',
    'tampak_kurus': 'Tidak (0)',
    'tindakan_khusus': 'Tidak (0)',
    'nyeri': 'Tidak (0)',
  };

  final Map<String, bool> _edukasiPasienOptions = {
    'diagnosa': false,
    'rencana_tindak_lanjut': false,
  };

  final _penerimaPulangPasienController = TextEditingController();
  final Map<String, bool> _hambatanMobilisasiOptions = {
    'lanjut_usia': false,
    'tidak_ada': true,
  };
  final _urutanPelayananController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sinkronkan controller IMT
    _calculateIMT();
    _beratBadanController.addListener(_calculateIMT);
    _tinggiBadanController.addListener(_calculateIMT);
    _fetchExistingAnamnesa();
  }

  Future<void> _fetchExistingAnamnesa() async {
    setState(() => _isLoadingData = true);
    try {
      final regRepo = getIt<RegistrasiRepository>();
      // Assume Registrasi raw includes flat `anamnesa` object with fields
      final registrasi = await regRepo.getRegistrasiRawById(widget.registrationId);
      final Map<String, dynamic> root = (registrasi ?? const {});
      // Prefer explicit nested anamnesa object if present; else treat root as anamnesa
      final data = (root['anamnesa'] ?? root);
      if (data != null) {
        // Vital & keluhan
        Map<String, dynamic> pk = (data['pengkajian_keperawatan'] ?? const {});
        Map<String, dynamic> tv = (pk['tanda_vital'] ?? const {});
        Map<String, dynamic> nutr = (pk['nutrisi'] ?? const {});
        Map<String, dynamic> fungs = (pk['fungsional'] ?? const {});
        Map<String, dynamic> kel = (pk['keluhan'] ?? const {});
        Map<String, dynamic> mk = (pk['masalah_keperawatan'] ?? const {});

        _keluhanPasienController.text = (kel['keluhan'] ?? data['keluhan'] ?? '').toString();
        _tekananDarahController.text = (tv['tekanan_darah'] ?? data['tekanan_darah'] ?? '').toString();
        _frekuensiNadiController.text = ((tv['nadi'] ?? data['nadi']) ?? '').toString();
        _suhuController.text = ((tv['suhu'] ?? data['suhu']) ?? '').toString();
        _frekuensiPernapasanController.text = ((tv['pernapasan'] ?? data['pernapasan']) ?? '').toString();

        // Nutrisi
        _beratBadanController.text = (nutr['berat_badan'] ?? data['berat_badan'] ?? '').toString();
        _tinggiBadanController.text = (nutr['tinggi_badan'] ?? data['tinggi_badan'] ?? '').toString();
        _imtController.text = ((nutr['imt'] ?? data['imt']) ?? '').toString();
        _lingkarKepalaController.text = (nutr['lingkar_kepala'] ?? data['lingkar_kepala'] ?? '').toString();

        // Fungsional
        _alatBantuController.text = (fungs['alat_bantu'] ?? data['alat_bantu'] ?? '').toString();
        _prothesaController.text = (fungs['prothesa'] ?? data['prothesa'] ?? '').toString();
        _cacatTubuhController.text = (fungs['cacat_tubuh'] ?? data['cacat_tubuh'] ?? '').toString();
        _adl = (((fungs['adl'] ?? data['adl'] ?? 0)) == 1) ? 'Mandiri' : 'Dibantu';
        _resikoJatuh = (((fungs['resiko_jatuh'] ?? data['resiko_jatuh'] ?? 0)) == 1) ? 'Ada' : 'Tidak Ada';
        _riwayatPenyakitDahuluController.text = (fungs['riwayat'] ?? data['riwayat'] ?? '').toString();
        _riwayatAlergi = (((tv['riwayat_alergi'] ?? data['riwayat_alergi'] ?? 0)) == 1) ? 'Ya' : 'Tidak';

        // Masalah keperawatan flags
        void setFlag(String key, String label) {
          final v = (mk[key] ?? data[key] ?? 0) == 1;
          _masalahKeperawatanOptions[label] = v;
        }
        setFlag('jalan_nafas', 'Bersihan jalan nafas');
        setFlag('pola_nafas', 'Pola nafas tidak efektif');
        setFlag('hipertermia', 'Hipertermia');
        setFlag('nyeri_akut', 'Nyeri akut');
        setFlag('nyeri_kronik', 'Nyeri kronik');
        setFlag('mual', 'Mual');
        setFlag('gangguan_perfusi', 'Gangguan perfusi jaringan serebral');
        setFlag('gangguan_cairan', 'Gangguan keseimbangan cairan');
        _masalahKeperawatanLainnyaController.text = (mk['lainnya'] ?? data['lainnya'] ?? '').toString();

        // Medis
        Map<String, dynamic> pm = (data['pengkajian_medis'] ?? const {});
        _pemeriksaanFisikController.text = (pm['pemeriksaan_fisik'] ?? data['pemeriksaan_fisik'] ?? '').toString();
        _diagnosisController.text = (pm['diagnosis'] ?? data['diagnosis'] ?? '').toString();
        _rencanaTerapiController.text = (pm['rencana_dan_terapi'] ?? data['rencana_dan_terapi'] ?? '').toString();
        _pemeriksaanPenunjangController.text = (pm['pemeriksaan_penunjang'] ?? data['pemeriksaan_penunjang'] ?? '').toString();
        _kontrolController.text = (pm['kontrol'] ?? data['kontrol'] ?? '').toString();
        final jp = (pm['jenis_perawatan'] ?? data['jenis_perawatan'] ?? '').toString();
        if (jp.isNotEmpty) {
          // Normalize to title case option if present
          final normalized = jp[0].toUpperCase() + jp.substring(1);
          _jenisPerawatan = normalized;
        }

        // Khusus perawat
        Map<String, dynamic> kp = (data['khusus_perawat'] ?? const {});
        Map<String, dynamic> tug = (kp['intervensi_time_up_go'] ?? const {});
        bool toBoolIntFrom(Map<String, dynamic> m, String key) => (m[key] ?? data[key] ?? 0) == 1;
        _intervensiTimeUpGoOptions.update(_intervensiTimeUpGoOptions.keys.elementAt(0), (_) => toBoolIntFrom(tug, 'cara_berjalan'));
        _intervensiTimeUpGoOptions.update(_intervensiTimeUpGoOptions.keys.elementAt(1), (_) => toBoolIntFrom(tug, 'cara_berjalan2'));
        _intervensiTimeUpGoOptions.update(_intervensiTimeUpGoOptions.keys.elementAt(2), (_) => toBoolIntFrom(tug, 'menopang'));

        final nutrisiBb = ((kp['skrining_mst_dewasa'] ?? const {})['nutrisi_bb'] ?? data['nutrisi_bb'] ?? '').toString();
        _skriningNutrisiMstAnswers['penurunan_berat'] = nutrisiBb == 'Normal' ? 'Tidak (0)' : 'Tidak yakin (2)';
        final asupMakan = ((kp['skrining_mst_dewasa'] ?? const {})['asup_makan'] ?? data['asup_makan'] ?? '').toString();
        _skriningNutrisiMstAnswers['makan_menurun'] = asupMakan == 'Cukup' ? 'Tidak (0)' : 'Ya (1)';

        final sk = (kp['skrining_strongkids'] ?? const {});
        void setStrongKids(String key, String mapKey) {
          final isOne = (sk[key] ?? data[key] ?? 0) == 1;
          _skriningNutrisiStrongkidsAnswers[mapKey] = isOne ? 'Ya (1)' : 'Tidak (0)';
        }
        setStrongKids('strong_kids1', 'penyakit_malnutrisi');
        setStrongKids('strong_kids2', 'tampak_kurus');
        setStrongKids('strong_kids3', 'tindakan_khusus');
        setStrongKids('strong_kids4', 'nyeri');

        // Edukasi
        final edk = (kp['edukasi'] ?? const {});
        final edukasiFlag = (edk['edukasi'] ?? data['edukasi'] ?? 0) == 1;
        _edukasiPasienOptions['diagnosa'] = edukasiFlag;
        _edukasiPasienOptions['rencana_tindak_lanjut'] = edukasiFlag;
        // We keep `edukasi_ket` informational only; not mapped to specific checkboxes.

        // Hambatan mobilisasi
        final rencana = (kp['rencana_pulang'] ?? const {});
        _hambatanMobilisasiOptions['lanjut_usia'] = (rencana['renc_usia_lanjut'] ?? data['renc_usia_lanjut'] ?? 0) == 1;
        _hambatanMobilisasiOptions['tidak_ada'] = (rencana['renc_hmbtn_mobil'] ?? data['renc_hmbtn_mobil'] ?? 0) == 0;

        // Urutan layanan (no exact backend field provided; keep local only)
      }
    } catch (_) {
      // Silent fail; keep defaults for new entry
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _calculateIMT() {
    // BB (kg) / (TB (m) * TB (m))
    final bb = double.tryParse(_beratBadanController.text) ?? 0;
    final tbCm = double.tryParse(_tinggiBadanController.text) ?? 0;

    if (bb > 0 && tbCm > 0) {
      final tbM = tbCm / 100;
      final imt = bb / (tbM * tbM);
      // Update IMT controller, 1 digit di belakang koma
      _imtController.text = imt.toStringAsFixed(1);
    } else {
      _imtController.text = '';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _beratBadanController.removeListener(_calculateIMT);
    _tinggiBadanController.removeListener(_calculateIMT);
    _tekananDarahController.dispose();
    _frekuensiNadiController.dispose();
    _suhuController.dispose();
    _frekuensiPernapasanController.dispose();
    _beratBadanController.dispose();
    _tinggiBadanController.dispose();
    _imtController.dispose();
    _lingkarKepalaController.dispose();
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
    _penerimaPulangPasienController.dispose();
    _urutanPelayananController.dispose();
    super.dispose();
  }

  // Fungsi navigasi halaman
  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _saveAnamnesa() async {
    // Pastikan validasi dilakukan di halaman terakhir sebelum simpan
    if (!_formKey.currentState!.validate() || !_validateRequiredFields()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = getIt<AnamnesaRepository>();
      // Build flat payload per backend schema (confirmed working)
      final bool riwayatAlergiBool = _riwayatAlergi.toLowerCase() == 'ya';
      final bool adlBool = _adl.toLowerCase() == 'mandiri';
      final bool resikoJatuhBool = _resikoJatuh.toLowerCase().contains('ada');

      num? parseNum(String s) => s.isEmpty ? null : num.tryParse(s);
      int asFlag(bool v) => v ? 1 : 0;

      final Map<String, dynamic> payload = {
        // ids
        'registrasi_id': widget.registrationId,
        // flat fields
        'keluhan': _keluhanPasienController.text,
        'tekanan_darah': _tekananDarahController.text,
        'nadi': parseNum(_frekuensiNadiController.text) ?? 0,
        'suhu': parseNum(_suhuController.text) ?? 0,
        'pernapasan': parseNum(_frekuensiPernapasanController.text) ?? 0,

        'berat_badan': _beratBadanController.text,
        'tinggi_badan': _tinggiBadanController.text,
        'imt': parseNum(_imtController.text) ?? 0,
        'lingkar_kepala': _lingkarKepalaController.text,

        'alat_bantu': _alatBantuController.text,
        'prothesa': _prothesaController.text,
        'cacat_tubuh': _cacatTubuhController.text,

        'adl': adlBool ? 1 : 0,
        'resiko_jatuh': resikoJatuhBool ? 1 : 0,

        'riwayat': _riwayatPenyakitDahuluController.text,
        'riwayat_alergi': riwayatAlergiBool ? 1 : 0,

        'jalan_nafas': asFlag(_masalahKeperawatanOptions['Bersihan jalan nafas'] == true),
        'pola_nafas': asFlag(_masalahKeperawatanOptions['Pola nafas tidak efektif'] == true),
        'hipertermia': asFlag(_masalahKeperawatanOptions['Hipertermia'] == true),
        'nyeri_kronik': asFlag(_masalahKeperawatanOptions['Nyeri kronik'] == true),
        'nyeri_akut': asFlag(_masalahKeperawatanOptions['Nyeri akut'] == true),
        'mual': asFlag(_masalahKeperawatanOptions['Mual'] == true),
        'gangguan_perfusi': asFlag(_masalahKeperawatanOptions['Gangguan perfusi jaringan serebral'] == true),
        'gangguan_cairan': asFlag(_masalahKeperawatanOptions['Gangguan keseimbangan cairan'] == true),
        'lainnya': _masalahKeperawatanLainnyaController.text,

        'pemeriksaan_fisik': _pemeriksaanFisikController.text,
        'diagnosis': _diagnosisController.text,
        'rencana_dan_terapi': _rencanaTerapiController.text,
        'pemeriksaan_penunjang': _pemeriksaanPenunjangController.text,

        'cara_berjalan': asFlag(_intervensiTimeUpGoOptions.values.elementAt(0)),
        'cara_berjalan2': asFlag(_intervensiTimeUpGoOptions.values.elementAt(1)),
        'menopang': asFlag(_intervensiTimeUpGoOptions.values.elementAt(2)),
        'risiko': 'tidak_berisiko',

        'nutrisi_bb': _skriningNutrisiMstAnswers['penurunan_berat'] == 'Tidak (0)' ? 'Normal' : 'Perlu evaluasi',
        'asup_makan': _skriningNutrisiMstAnswers['makan_menurun'] == 'Tidak (0)' ? 'Cukup' : 'Kurang',
        'strong_kids1': (_skriningNutrisiStrongkidsAnswers['penyakit_malnutrisi'] ?? '').contains('(1)') ? 1 : 0,
        'strong_kids2': (_skriningNutrisiStrongkidsAnswers['tampak_kurus'] ?? '').contains('(1)') ? 1 : 0,
        'strong_kids3': (_skriningNutrisiStrongkidsAnswers['tindakan_khusus'] ?? '').contains('(1)') ? 1 : 0,
        'strong_kids4': (_skriningNutrisiStrongkidsAnswers['nyeri'] ?? '').contains('(1)') ? 1 : 0,

        'kontrol': _kontrolController.text,
        'jenis_perawatan': _jenisPerawatan.toLowerCase(),

        'edukasi': _edukasiPasienOptions.values.any((v) => v == true) ? 1 : 0,
        'edukasi_ket': _edukasiPasienOptions.entries.where((e) => e.value).map((e) => e.key).join(', '),

        'renc_usia_lanjut': _hambatanMobilisasiOptions['lanjut_usia'] == true ? 1 : 0,
        'renc_hmbtn_mobil': _hambatanMobilisasiOptions['tidak_ada'] == true ? 0 : 1,
        'renc_layanan_medis': 0,
        'renc_tergnt_org': 0,

        'tanggal': DateTime.now().toIso8601String().split('T').first,
      };

      await repo.upsertAnamnesa(
        registrasiId: widget.registrationId,
        data: payload,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anamnesa berhasil disimpan!'),
          backgroundColor: kSuccessColor,
        ),
      );
      widget.onCompleted?.call();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan anamnesa: $e'),
          backgroundColor: kDangerColor,
        ),
      );
    }
  }

  bool _validateRequiredFields() {
    // Minimal payload requirements to avoid backend 422/500
    final List<String> missing = [];
    if (_keluhanPasienController.text.trim().isEmpty) {
      missing.add('Keluhan Pasien');
    }
    if (_pemeriksaanFisikController.text.trim().isEmpty) {
      missing.add('Pemeriksaan Fisik');
    }
    if (_diagnosisController.text.trim().isEmpty) {
      missing.add('Diagnosis');
    }
    // Ensure vital signs present (nadi/suhu/pernapasan and tekanan_darah)
    if (_tekananDarahController.text.trim().isEmpty) {
      missing.add('Tekanan Darah');
    }
    if (_frekuensiNadiController.text.trim().isEmpty) {
      missing.add('Frekuensi Nadi');
    }
    if (_suhuController.text.trim().isEmpty) {
      missing.add('Suhu');
    }
    if (_frekuensiPernapasanController.text.trim().isEmpty) {
      missing.add('Frekuensi Pernapasan');
    }
    // Jenis perawatan
    if (_jenisPerawatan.trim().isEmpty) {
      missing.add('Jenis Perawatan');
    }

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harus diisi: ${missing.join(', ')}'),
          backgroundColor: kWarningColor,
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = '';
    Color appBarColor = kPrimaryColor;
    Color headerBgColor = kPrimaryColor;

    switch (_currentPage) {
      case 0:
        appBarTitle = '1/3 Pengkajian Keperawatan';
        appBarColor = kPrimaryColor;
        headerBgColor = kPrimaryColor;
        break;
      case 1:
        appBarTitle = '2/3 Pengkajian Medis';
        appBarColor = kPrimaryColor;
        headerBgColor = kPrimaryColor;
        break;
      case 2:
        appBarTitle = '3/3 Khusus Perawat';
        appBarColor = kHeaderNurseColor;
        headerBgColor = kHeaderNurseColor;
        break;
    }

    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: Column(
        children: [
          _buildHeaderAppBar(appBarTitle, appBarColor, headerBgColor),
          Expanded(
            child: Form(
              key: _formKey,
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildPengkajianKeperawatanContent(),
                  _buildPengkajianMedisContent(),
                  _buildKhususPerawatContent(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButton(appBarColor),
    );
  }

  // --- HEADER WIDGETS ---

  Widget _buildHeaderAppBar(String title, Color color, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, bgColor.withOpacity(0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: kWhite, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 40), // Placeholder for back button width
          ],
        ),
      ),
    );
  }

  // --- CONTENT PAGES ---

  Widget _buildContentWrapper({
    required Widget child,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            title: title,
            icon: icon,
            color: color,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: child,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // SECTION 1: PENGKAJIAN KEPERAWATAN CONTENT
  Widget _buildPengkajianKeperawatanContent() {
    return _buildContentWrapper(
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
            label: 'IMT (Otomatis)',
            hint: '20.8',
            isNumber: true,
            isDecimal: true,
            enabled: false, // IMT should be auto-calculated
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _lingkarKepalaController,
            label: 'Khusus Pediatri: Lingkaran Kepala (cm)',
            hint: 'Contoh: 35',
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
            return _buildCheckboxRow(
              label: e.key,
              value: e.value,
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
                hint: 'Masalah lainnya...',
              ),
            ),
        ],
      ),
    );
  }

  // SECTION 2: PENGKAJIAN MEDIS CONTENT
  Widget _buildPengkajianMedisContent() {
    return _buildContentWrapper(
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
            required: true,
          ),
          const SizedBox(height: 20),
          _buildSubsection('Diagnosis', Icons.assignment),
          _buildTextField(
            controller: _diagnosisController,
            label: 'Diagnosis',
            hint: 'Masukkan diagnosis...',
            multiline: true,
            required: true,
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

  // SECTION 3: KHUSUS PERAWAT CONTENT
  Widget _buildKhususPerawatContent() {
    return _buildContentWrapper(
      title: 'Diisi Khusus Perawat',
      icon: Icons.local_hospital,
      color: kHeaderNurseColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Up & Go
          _buildSubsection(
            'Intervensi Time Up & Go',
            Icons.accessibility_new,
            color: kHeaderNurseColor,
          ),
          const Text(
            'Pasien Rawat Jalan yang Beresiko Jatuh',
            style: TextStyle(fontSize: 12, color: kTextGrey),
          ),
          const SizedBox(height: 8),
          ..._intervensiTimeUpGoOptions.entries.map((e) {
            return _buildCheckboxRow(
              label: e.key,
              value: e.value,
              onChanged: (val) {
                setState(() => _intervensiTimeUpGoOptions[e.key] = val!);
              },
            );
          }),
          const SizedBox(height: 20),

          // Skrining Nutrisi - MST
          _buildSubsection(
            'Skrining Nutrisi - MST (Dewasa)',
            Icons.restaurant_menu,
            color: kHeaderNurseColor,
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
            'Skrining Nutrisi - STRONGkids (Anak)',
            Icons.child_care,
            color: kHeaderNurseColor,
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
          _buildSubsection(
            'Edukasi Pasien',
            Icons.school,
            color: kHeaderNurseColor,
          ),
          const Text(
            'Ya (diberikan di formulir M2)',
            style: TextStyle(
              fontSize: 12,
              color: kTextGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
          _buildCheckboxRow(
            label: 'Diagnosis',
            value: _edukasiPasienOptions['diagnosa']!,
            onChanged: (val) {
              setState(() => _edukasiPasienOptions['diagnosa'] = val!);
            },
          ),
          _buildCheckboxRow(
            label: 'Rencana tindak lanjut terapi',
            value: _edukasiPasienOptions['rencana_tindak_lanjut']!,
            onChanged: (val) {
              setState(
                () => _edukasiPasienOptions['rencana_tindak_lanjut'] = val!,
              );
            },
          ),
          const SizedBox(height: 20),

          // Penerimaan Pulang Pasien
          _buildSubsection(
            'Penerimaan Pulang Pasien',
            Icons.home,
            color: kHeaderNurseColor,
          ),
          _buildTextField(
            controller: _penerimaPulangPasienController,
            label:
                'Jika salah satu sewa terpenuhi, tergolong dalam home care dengan formula penerimaan pulang pasien',
            hint: 'Masukkan keterangan pulang pasien...',
            multiline: true,
          ),
          const SizedBox(height: 20),

          // Hambatan Mobilisasi
          _buildSubsection(
            'Hambatan Mobilisasi',
            Icons.accessible,
            color: kHeaderNurseColor,
          ),
          _buildCheckboxRow(
            label: 'Ya (lanjut usia (>60 tahun) dan alat)',
            value: _hambatanMobilisasiOptions['lanjut_usia']!,
            onChanged: (val) {
              setState(() => _hambatanMobilisasiOptions['lanjut_usia'] = val!);
            },
          ),
          _buildCheckboxRow(
            label: 'Tidak',
            value: _hambatanMobilisasiOptions['tidak_ada']!,
            onChanged: (val) {
              setState(() => _hambatanMobilisasiOptions['tidak_ada'] = val!);
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Tergantung dengan orang lain untuk aktivitas harian seperti mandi, berpakaian, ketoilet, berpindah tempat, dan juga konsulensi pelayanan medis dan perawatan berkelanjutan',
            style: TextStyle(
              fontSize: 11,
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

  // --- REUSABLE WIDGETS ---

  Widget _buildMstQuestion(String question, String key, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 4),
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
    int score = 0;
    final penurunanBerat = _skriningNutrisiMstAnswers['penurunan_berat'] ?? '';
    if (penurunanBerat.contains('(1)')) score += 1;
    if (penurunanBerat.contains('(2)')) score += 2;
    if (penurunanBerat.contains('(3)')) score += 3;
    if (penurunanBerat.contains('(4)')) score += 4;

    final makanMenurun = _skriningNutrisiMstAnswers['makan_menurun'] ?? '';
    if (makanMenurun.contains('(1)')) score += 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWarningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kWarningColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Skor: $score',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: kWarningColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score >= 2
                ? 'Skor ≥ 2: Berisiko Malnutrisi dan Gizi'
                : 'Skor 0-1: Risiko Rendah',
            style: TextStyle(fontSize: 12, color: kTextDark),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 4),
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
    int score = 0;
    for (var answer in _skriningNutrisiStrongkidsAnswers.values) {
      if (answer.contains('(1)')) score += 1;
      if (answer.contains('(2)')) score += 2;
    }

    String riskLevelText;
    Color riskColor;
    if (score >= 4) {
      riskLevelText = 'Skor ≥ 4: Risiko Tinggi';
      riskColor = kDangerColor;
    } else if (score >= 1) {
      riskLevelText = 'Skor 1-3: Risiko Sedang';
      riskColor = kWarningColor;
    } else {
      riskLevelText = 'Skor 0: Risiko Rendah';
      riskColor = kSuccessColor;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Skor: $score',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: riskColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(riskLevelText, style: TextStyle(fontSize: 12, color: kTextDark)),
        ],
      ),
    );
  }

  Widget _buildSubsection(
    String title,
    IconData icon, {
    Color color = kPrimaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
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
            color: kTextGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: kWhite, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.5, color: Color(0xFFE5E7EB)),
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
    bool enabled = true,
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
          enabled: enabled,
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
          style: TextStyle(color: enabled ? kTextDark : kTextGrey),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: kTextGrey.withOpacity(0.5),
              fontSize: 13,
            ),
            filled: true,
            fillColor: enabled ? kCardBg : kTextGrey.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: kTextGrey.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kDangerColor),
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
        Wrap(
          spacing: 10,
          children: options.map((option) {
            return SizedBox(
              width: 140, // Atur lebar tetap untuk konsistensi
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

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: kTextDark),
      ),
      value: value,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: VisualDensity.compact,
      activeColor: kPrimaryColor,
      onChanged: onChanged,
    );
  }

  Widget _buildBottomButton(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(
        16.0,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: kTextGrey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _previousPage,
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Kembali'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: primaryColor, width: 1.5),
                  foregroundColor: primaryColor,
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : (_currentPage < 2 ? _nextPage : _saveAnamnesa),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kWhite,
                      ),
                    )
                  : Icon(_currentPage < 2 ? Icons.arrow_forward : Icons.save),
              label: Text(
                _currentPage < 2
                    ? 'Lanjut (${_currentPage + 1}/3)'
                    : (_isSaving ? 'Menyimpan...' : 'Simpan'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
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
