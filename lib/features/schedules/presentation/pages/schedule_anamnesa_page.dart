import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final db.Kunjungan? kunjungan;
  final VoidCallback? onCompleted;

  const ScheduleAnamnesaPage({super.key, this.kunjungan, this.onCompleted});

  @override
  State<ScheduleAnamnesaPage> createState() => _ScheduleAnamnesaPageState();
}

class _ScheduleAnamnesaPageState extends State<ScheduleAnamnesaPage> {
  late final db.AppDatabase _database;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  // Form controllers
  final _keluhanUtamaController = TextEditingController();
  final _riwayatPenyakitSekarangController = TextEditingController();
  final _riwayatPenyakitDahuluController = TextEditingController();
  final _riwayatPenyakitKeluargaController = TextEditingController();
  final _riwayatAlergiController = TextEditingController();
  final _tekananDarahController = TextEditingController();
  final _nadiController = TextEditingController();
  final _suhuTubuhController = TextEditingController();
  final _pernapasanController = TextEditingController();
  final _catatanController = TextEditingController();

  db.Anamnesa? _existingAnamnesa;

  @override
  void initState() {
    super.initState();
    _database = getIt<db.AppDatabase>();
    _loadExistingAnamnesa();
  }

  @override
  void dispose() {
    _keluhanUtamaController.dispose();
    _riwayatPenyakitSekarangController.dispose();
    _riwayatPenyakitDahuluController.dispose();
    _riwayatPenyakitKeluargaController.dispose();
    _riwayatAlergiController.dispose();
    _tekananDarahController.dispose();
    _nadiController.dispose();
    _suhuTubuhController.dispose();
    _pernapasanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAnamnesa() async {
    if (widget.kunjungan == null) return;

    setState(() => _isLoading = true);
    try {
      final anamnesa = await _database.getAnamnesaByKunjunganId(widget.kunjungan!.id);
      
      if (anamnesa != null && mounted) {
        setState(() {
          _existingAnamnesa = anamnesa;
          _keluhanUtamaController.text = anamnesa.keluhanUtama;
          _riwayatPenyakitSekarangController.text = anamnesa.riwayatPenyakitSekarang;
          _riwayatPenyakitDahuluController.text = anamnesa.riwayatPenyakitDahulu ?? '';
          _riwayatPenyakitKeluargaController.text = anamnesa.riwayatPenyakitKeluarga ?? '';
          _riwayatAlergiController.text = anamnesa.riwayatAlergi ?? '';
          _tekananDarahController.text = anamnesa.tekananDarah ?? '';
          _nadiController.text = anamnesa.nadi?.toString() ?? '';
          _suhuTubuhController.text = anamnesa.suhuTubuh?.toString() ?? '';
          _pernapasanController.text = anamnesa.pernapasan?.toString() ?? '';
          _catatanController.text = anamnesa.catatan ?? '';
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

  Future<void> _saveAnamnesa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.kunjungan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data kunjungan tidak valid'),
          backgroundColor: kDangerColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final companion = db.AnamnesasCompanion(
        kunjunganId: drift.Value(widget.kunjungan!.id),
        keluhanUtama: drift.Value(_keluhanUtamaController.text),
        riwayatPenyakitSekarang: drift.Value(_riwayatPenyakitSekarangController.text),
        riwayatPenyakitDahulu: drift.Value(_riwayatPenyakitDahuluController.text.isEmpty ? null : _riwayatPenyakitDahuluController.text),
        riwayatPenyakitKeluarga: drift.Value(_riwayatPenyakitKeluargaController.text.isEmpty ? null : _riwayatPenyakitKeluargaController.text),
        riwayatAlergi: drift.Value(_riwayatAlergiController.text.isEmpty ? null : _riwayatAlergiController.text),
        tekananDarah: drift.Value(_tekananDarahController.text.isEmpty ? null : _tekananDarahController.text),
        nadi: drift.Value(_nadiController.text.isEmpty ? null : int.tryParse(_nadiController.text)),
        suhuTubuh: drift.Value(_suhuTubuhController.text.isEmpty ? null : double.tryParse(_suhuTubuhController.text)),
        pernapasan: drift.Value(_pernapasanController.text.isEmpty ? null : int.tryParse(_pernapasanController.text)),
        catatan: drift.Value(_catatanController.text.isEmpty ? null : _catatanController.text),
        updatedAt: drift.Value(DateTime.now()),
      );

      if (_existingAnamnesa != null) {
        // Update existing
        await _database.updateAnamnesa(_existingAnamnesa!.id, companion);
      } else {
        // Insert new
        await _database.insertAnamnesa(companion);
      }

      // Update kunjungan progress
      debugPrint('🔄 Updating kunjungan progress for ID: ${widget.kunjungan!.id}');
      await _database.updateKunjunganProgress(
        widget.kunjungan!.id,
        anamnesaDone: true,
      );
      debugPrint('✅ Kunjungan progress updated');

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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kDangerColor,
          ),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: 'Keluhan Utama',
                      icon: Icons.chat_bubble_outline,
                      color: kPrimaryColor,
                      child: _buildTextField(
                        controller: _keluhanUtamaController,
                        label: 'Keluhan Utama',
                        hint: 'Masukkan keluhan utama pasien...',
                        multiline: true,
                        required: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Riwayat Penyakit',
                      icon: Icons.history,
                      color: const Color(0xFF8B5CF6),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _riwayatPenyakitSekarangController,
                            label: 'Riwayat Penyakit Sekarang',
                            hint: 'Perkembangan keluhan...',
                            multiline: true,
                            required: true,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _riwayatPenyakitDahuluController,
                            label: 'Riwayat Penyakit Dahulu',
                            hint: 'Penyakit yang pernah diderita...',
                            multiline: true,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _riwayatPenyakitKeluargaController,
                            label: 'Riwayat Penyakit Keluarga',
                            hint: 'Penyakit keturunan/keluarga...',
                            multiline: true,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _riwayatAlergiController,
                            label: 'Riwayat Alergi',
                            hint: 'Alergi obat, makanan, dll...',
                            multiline: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Tanda Vital',
                      icon: Icons.monitor_heart,
                      color: kSuccessColor,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _tekananDarahController,
                                  label: 'Tekanan Darah',
                                  hint: '120/80',
                                  icon: Icons.favorite,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _nadiController,
                                  label: 'Nadi (x/menit)',
                                  hint: '80',
                                  isNumber: true,
                                  icon: Icons.monitor_heart_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _suhuTubuhController,
                                  label: 'Suhu (°C)',
                                  hint: '36.5',
                                  isNumber: true,
                                  isDecimal: true,
                                  icon: Icons.thermostat,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _pernapasanController,
                                  label: 'Pernapasan (x/menit)',
                                  hint: '20',
                                  isNumber: true,
                                  icon: Icons.air,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Catatan Tambahan',
                      icon: Icons.note_alt_outlined,
                      color: kWarningColor,
                      child: _buildTextField(
                        controller: _catatanController,
                        label: 'Catatan',
                        hint: 'Catatan pemeriksaan lainnya...',
                        multiline: true,
                        maxLines: 4,
                      ),
                    ),
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
      expandedHeight: 150,
      pinned: true,
      backgroundColor: kPrimaryColor,
      foregroundColor: kWhite,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Anamnesa Pasien',
          style: TextStyle(fontSize: 16),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor, kPrimaryLight],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWhite.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description,
                  size: 40,
                  color: kWhite,
                ),
              ),
            ),
          ),
        ),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
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
            if (icon != null) ...[
              Icon(icon, size: 16, color: kTextGrey),
              const SizedBox(width: 8),
            ],
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
                style: TextStyle(color: kDangerColor, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber
              ? (isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number)
              : (multiline ? TextInputType.multiline : TextInputType.text),
          inputFormatters: isNumber
              ? (isDecimal
                  ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
                  : [FilteringTextInputFormatter.digitsOnly])
              : null,
          maxLines: multiline ? maxLines : 1,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: kTextGrey.withOpacity(0.5), fontSize: 13),
            filled: true,
            fillColor: kCardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kTextGrey.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kDangerColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildBottomButton() {
    return Container(
      color: kWhite,
      padding: const EdgeInsets.all(16.0).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveAnamnesa,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kWhite,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Anamnesa'),
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
    );
  }
}
