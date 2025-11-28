import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/core/services/notification_service.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:homecare_mobile/features/schedules/domain/models/dokter.dart';
import 'package:homecare_mobile/features/schedules/domain/models/poli.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/dokter_data_source.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/poli_data_source.dart';
import 'package:dio/dio.dart';

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);

class RegistrationFormPage extends StatefulWidget {
  final String? pasienId;
  final String? pasienNama;
  final int? registrasiId;
  final bool isEdit;

  const RegistrationFormPage({
    super.key,
    this.pasienId,
    this.pasienNama,
    this.registrasiId,
    this.isEdit = false,
  });

  @override
  State<RegistrationFormPage> createState() => _RegistrationFormPageState();
}

class _RegistrationFormPageState extends State<RegistrationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _noRegController = TextEditingController();
  final _penanggungNamaController = TextEditingController();
  final _penanggungNoPegawaiController = TextEditingController();
  final _penanggungAlamatController = TextEditingController();
  final _penanggungTeleponController = TextEditingController();
  final _penanggungIdController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingDokter = false;
  bool _isLoadingPoli = false;

  String _jenisKunjungan = 'HOME CARE';
  String _tipePasien = 'UMUM';
  String? _selectedDokterId;
  String? _selectedPoliKode;
  String _pagiSore = 'PAGI';
  String _asalPasien = 'POLIKLINIK';
  String _status = 'butuh_diisi';
  bool _isCash = true;
  bool _isPribadi = true;
  bool _pasienBaru = false;

  List<Dokter> _dokterList = [];
  List<Poli> _poliList = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Load dokter and poli data first
    await _loadDokterAndPoli();

    // Then load existing registration if in edit mode
    if (widget.isEdit && widget.registrasiId != null) {
      await _loadExistingRegistration();
    } else {
      // Generate nomor registrasi otomatis dengan format: R[YYMMDD][BS][RANDOM5]
      final now = DateTime.now();
      final dateStr = DateFormat('yyMMdd').format(now);
      final random = now.millisecondsSinceEpoch.toString().substring(8, 13);
      _noRegController.text = 'R${dateStr}BS$random';
    }
  }

  Future<void> _loadDokterAndPoli() async {
    setState(() {
      _isLoadingDokter = true;
      _isLoadingPoli = true;
    });

    try {
      final dio = getIt<Dio>();
      final dokterDataSource = DokterDataSource(dio);
      final poliDataSource = PoliDataSource(dio);

      // Load dokter list
      try {
        debugPrint('🔍 Fetching dokter data from API...');
        final dokterCollection = await dokterDataSource.getActiveDokter();
        debugPrint(
          '✅ Dokter data received: ${dokterCollection.data.length} items',
        );
        if (mounted) {
          setState(() {
            _dokterList = dokterCollection.data;
            _isLoadingDokter = false;
          });
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error loading dokter: $e');
        debugPrint('📍 Stack trace: $stackTrace');
        if (mounted) setState(() => _isLoadingDokter = false);
      }

      // Load poli list
      try {
        debugPrint('🔍 Fetching poli data from API...');
        final poliCollection = await poliDataSource.getActivePoli();
        debugPrint('✅ Poli data received: ${poliCollection.data.length} items');
        if (mounted) {
          setState(() {
            _poliList = poliCollection.data;
            _isLoadingPoli = false;
          });
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error loading poli: $e');
        debugPrint('📍 Stack trace: $stackTrace');
        if (mounted) setState(() => _isLoadingPoli = false);
      }
    } catch (e) {
      debugPrint('❌ Error in _loadDokterAndPoli: $e');
      if (mounted) {
        setState(() {
          _isLoadingDokter = false;
          _isLoadingPoli = false;
        });
      }
    }
  }

  Future<void> _loadExistingRegistration() async {
    setState(() => _isLoading = true);
    try {
      final repository = getIt<RegistrasiRepository>();
      final registration = await repository.getRegistrasiById(
        widget.registrasiId!,
      );

      if (registration != null && mounted) {
        // Normalize incoming values to match allowed dropdown items to avoid assertion failures
        const jenisKunjunganItems = [
          'HOME CARE',
          'KUNJUNGAN BARU',
          'KUNJUNGAN LANJUTAN',
        ];
        const tipePasienItems = ['UMUM', 'BPJS', 'ASURANSI'];
        const asalPasienItems = ['POLIKLINIK', 'LANGSUNG', 'RUJUKAN', 'IGD'];
        const waktuKunjunganItems = ['PAGI', 'SORE'];

        String _norm(String? v) => (v ?? '').trim().toUpperCase();

        final normJenis = _norm(registration.jenisKunjungan);
        final normTipe = _norm(registration.tipePasien);
        final normAsal = _norm(registration.asalPasien);
        final normWaktu = _norm(registration.pagiSore);

        if (!jenisKunjunganItems.contains(normJenis)) {
          debugPrint(
            "ℹ️ jenis_kunjungan '${registration.jenisKunjungan}' tidak ditemukan di opsi. Fallback ke 'HOME CARE'.",
          );
        }
        if (registration.asalPasien != null &&
            !asalPasienItems.contains(normAsal)) {
          debugPrint(
            "ℹ️ asal_pasien '${registration.asalPasien}' tidak ditemukan di opsi. Fallback ke 'POLIKLINIK'.",
          );
        }
        if (registration.pagiSore != null &&
            !waktuKunjunganItems.contains(normWaktu)) {
          debugPrint(
            "ℹ️ waktu_kunjungan '${registration.pagiSore}' tidak ditemukan di opsi. Fallback ke 'PAGI'.",
          );
        }
        if (!tipePasienItems.contains(normTipe)) {
          debugPrint(
            "ℹ️ tipe_pasien '${registration.tipePasien}' tidak ditemukan di opsi. Fallback ke 'UMUM'.",
          );
        }

        setState(() {
          _noRegController.text = registration.noReg;

          _jenisKunjungan = jenisKunjunganItems.contains(normJenis)
              ? normJenis
              : 'HOME CARE';
          _tipePasien = tipePasienItems.contains(normTipe) ? normTipe : 'UMUM';

          // Only set selected values if they exist in the dropdown lists
          if (registration.dokterId != null &&
              _dokterList.any((d) => d.dokterId == registration.dokterId)) {
            _selectedDokterId = registration.dokterId;
          }

          if (registration.kodePoli != null &&
              _poliList.any((p) => p.kodePoli == registration.kodePoli)) {
            _selectedPoliKode = registration.kodePoli;
          }

          _pagiSore = waktuKunjunganItems.contains(normWaktu)
              ? normWaktu
              : 'PAGI';
          _asalPasien = asalPasienItems.contains(normAsal)
              ? normAsal
              : 'POLIKLINIK';

          _penanggungNamaController.text = registration.penanggungNama ?? '';
          _penanggungNoPegawaiController.text =
              registration.penanggungNoPegawai ?? '';
          _penanggungAlamatController.text =
              registration.penanggungAlamat ?? '';
          _penanggungTeleponController.text =
              registration.penanggungTelepon ?? '';
          _penanggungIdController.text = registration.penanggungId ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading registration: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data registrasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _noRegController.dispose();
    _penanggungNamaController.dispose();
    _penanggungNoPegawaiController.dispose();
    _penanggungAlamatController.dispose();
    _penanggungTeleponController.dispose();
    _penanggungIdController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final pasienIdInt = int.tryParse(widget.pasienId ?? '0');

        if (pasienIdInt == null || pasienIdInt == 0) {
          throw Exception('Invalid patient ID');
        }

        // Validate required fields
        if (_selectedDokterId == null || _selectedDokterId!.isEmpty) {
          throw Exception('Dokter harus dipilih');
        }
        if (_selectedPoliKode == null || _selectedPoliKode!.isEmpty) {
          throw Exception('Poli harus dipilih');
        }

        // Calculate no_urut (increment based on today's registrations)
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final repository = getIt<RegistrasiRepository>();
        final todayRegs = await repository.getRegistrasiByDate(today);
        final noUrut = (todayRegs.length + 1);

        // Use current datetime for registration
        final currentDateTime = DateTime.now();

        final registrationData = {
          'no_reg': _noRegController.text,
          'no_urut': noUrut,
          'pasien_id': pasienIdInt,
          'tgl_jam_reg': currentDateTime.toIso8601String(),
          'tgl_jam_kunjungan': currentDateTime.toIso8601String(),
          'kode_poli': _selectedPoliKode!,
          'dokter_id': _selectedDokterId!,
          'jenis_kunjungan': _jenisKunjungan,
          'asal_pasien': _asalPasien,
          'tipe_pasien': _tipePasien,
          'pasien_baru': _pasienBaru,
          'pagi_sore': _pagiSore,
          'is_cash': _isCash,
          'is_pribadi': _isPribadi,
          'eselon': null,
          'status': _status,
          'penanggung_id': _penanggungIdController.text.isNotEmpty
              ? _penanggungIdController.text
              : null,
          'penanggung_nama': _penanggungNamaController.text.isNotEmpty
              ? _penanggungNamaController.text
              : null,
          'penanggung_no_pegawai':
              _penanggungNoPegawaiController.text.isNotEmpty
              ? _penanggungNoPegawaiController.text
              : null,
          'penanggung_alamat': _penanggungAlamatController.text.isNotEmpty
              ? _penanggungAlamatController.text
              : null,
          'penanggung_telepon': _penanggungTeleponController.text.isNotEmpty
              ? _penanggungTeleponController.text
              : null,
        };

        debugPrint('📤 Registration data to save:');
        debugPrint(
          '   no_reg: ${registrationData['no_reg']} (${registrationData['no_reg'].runtimeType})',
        );
        debugPrint(
          '   no_urut: ${registrationData['no_urut']} (${registrationData['no_urut'].runtimeType})',
        );
        debugPrint(
          '   pasien_id: ${registrationData['pasien_id']} (${registrationData['pasien_id'].runtimeType})',
        );
        debugPrint(
          '   kode_poli: ${registrationData['kode_poli']} (${registrationData['kode_poli'].runtimeType})',
        );
        debugPrint(
          '   dokter_id: ${registrationData['dokter_id']} (${registrationData['dokter_id'].runtimeType})',
        );
        debugPrint(
          '   pasien_baru: ${registrationData['pasien_baru']} (${registrationData['pasien_baru'].runtimeType})',
        );
        debugPrint(
          '   is_cash: ${registrationData['is_cash']} (${registrationData['is_cash'].runtimeType})',
        );
        debugPrint(
          '   is_pribadi: ${registrationData['is_pribadi']} (${registrationData['is_pribadi'].runtimeType})',
        );

        if (widget.isEdit && widget.registrasiId != null) {
          // UPDATE existing registration
          final updateRepo = getIt<RegistrasiRepository>();
          await updateRepo.updateRegistrasi(
            widget.registrasiId!,
            registrationData,
          );
          debugPrint('✅ Registration updated with ID: ${widget.registrasiId}');
        } else {
          // CREATE new registration
          final newRegistration = await repository.createRegistrasi(
            registrationData,
          );
          debugPrint('✅ Registration saved with ID: ${newRegistration.id}');

          // Send notification for successful registration
          final notificationService = getIt<NotificationService>();
          await notificationService.showPatientRegisteredNotification(
            patientName: widget.pasienNama ?? 'Pasien',
            noRm: 'REG-${newRegistration.id}',
            visitDate: DateFormat(
              'd MMMM yyyy',
              'id_ID',
            ).format(currentDateTime),
          );

          debugPrint('✅ Notification sent');
        }

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEdit
                    ? 'Registrasi berhasil diupdate'
                    : 'Registrasi berhasil disimpan',
              ),
              backgroundColor: Colors.green,
            ),
          );

          context.pop(widget.isEdit ? 'updated' : 'created');
        }
      } catch (e) {
        debugPrint('❌ Error saving registration: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan registrasi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelRegistration() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Registrasi?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan registrasi kunjungan ini? Data registrasi akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (widget.registrasiId != null) {
        final repository = getIt<RegistrasiRepository>();
        await repository.deleteRegistrasi(widget.registrasiId!);
        debugPrint('✅ Registration deleted with ID: ${widget.registrasiId}');
      } else {
        debugPrint('✅ Registration cancelled (not saved yet)');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil dibatalkan'),
            backgroundColor: Colors.orange,
          ),
        );

        context.pop('canceled');
      }
    } catch (e) {
      debugPrint('❌ Error canceling registration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan registrasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kScaffoldBg,
        body: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionCard(
                        title: 'Informasi Registrasi',
                        icon: Icons.assignment,
                        children: [
                          _buildTextField(
                            controller: _noRegController,
                            label: 'No. Registrasi',
                            icon: Icons.confirmation_number,
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Jenis Kunjungan',
                            icon: Icons.local_hospital,
                            value: _jenisKunjungan,
                            items: [
                              'HOME CARE',
                              'KUNJUNGAN BARU',
                              'KUNJUNGAN LANJUTAN',
                            ],
                            onChanged: (value) {
                              setState(() {
                                _jenisKunjungan = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Tipe Pasien',
                            icon: Icons.person,
                            value: _tipePasien,
                            items: ['UMUM', 'BPJS', 'ASURANSI'],
                            onChanged: (value) {
                              setState(() {
                                _tipePasien = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Asal Pasien',
                            icon: Icons.directions_walk,
                            value: _asalPasien,
                            items: ['POLIKLINIK', 'LANGSUNG', 'RUJUKAN', 'IGD'],
                            onChanged: (value) {
                              setState(() {
                                _asalPasien = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Waktu Kunjungan',
                            icon: Icons.wb_sunny,
                            value: _pagiSore,
                            items: ['PAGI', 'SORE'],
                            onChanged: (value) {
                              setState(() {
                                _pagiSore = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Layanan Medis',
                        icon: Icons.medical_services,
                        children: [
                          _buildDokterDropdown(),
                          const SizedBox(height: 16),
                          _buildPoliDropdown(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Data Penanggung Jawab (Opsional)',
                        icon: Icons.family_restroom,
                        children: [
                          _buildTextField(
                            controller: _penanggungNamaController,
                            label: 'Nama Penanggung',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _penanggungNoPegawaiController,
                            label: 'No. Pegawai',
                            icon: Icons.badge,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _penanggungIdController,
                            label: 'ID Penanggung',
                            icon: Icons.credit_card,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _penanggungTeleponController,
                            label: 'No. Telepon',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _penanggungAlamatController,
                            label: 'Alamat Penanggung',
                            icon: Icons.location_on,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33004B8C),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: kWhite),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEdit ? 'Edit Registrasi' : 'Registrasi Pasien',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.pasienNama ?? 'Pasien Baru',
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimaryColor, kPrimaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: kWhite, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        filled: true,
        fillColor: kScaffoldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        filled: true,
        fillColor: kScaffoldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDokterDropdown() {
    if (_isLoadingDokter) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kScaffoldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Memuat data dokter...'),
          ],
        ),
      );
    }

    if (_dokterList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Data dokter tidak tersedia. Pastikan koneksi internet aktif.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedDokterId,
      decoration: InputDecoration(
        labelText: 'Pilih Dokter *',
        prefixIcon: const Icon(Icons.medical_information, color: kPrimaryColor),
        filled: true,
        fillColor: kScaffoldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
      hint: const Text('Pilih dokter'),
      isExpanded: true,
      items: _dokterList.toSet().toList().map((dokter) {
        return DropdownMenuItem(
          value: dokter.dokterId,
          child: Text(
            '${dokter.namaDokter}${dokter.bidangKeahlian != null ? ' - ${dokter.bidangKeahlian}' : ''}',
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDokterId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Dokter harus dipilih';
        }
        return null;
      },
    );
  }

  Widget _buildPoliDropdown() {
    if (_isLoadingPoli) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kScaffoldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Memuat data poli...'),
          ],
        ),
      );
    }

    if (_poliList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Data poli tidak tersedia. Pastikan koneksi internet aktif.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedPoliKode,
      decoration: InputDecoration(
        labelText: 'Pilih Poli *',
        prefixIcon: const Icon(Icons.local_hospital, color: kPrimaryColor),
        filled: true,
        fillColor: kScaffoldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
      hint: const Text('Pilih poliklinik'),
      items: _poliList.toSet().toList().map((poli) {
        return DropdownMenuItem(
          value: poli.kodePoli,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                poli.namaPoli,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                poli.kodePoli,
                style: const TextStyle(fontSize: 12, color: kTextGrey),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPoliKode = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Poli harus dipilih';
        }
        return null;
      },
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      color: kWhite,
      padding: const EdgeInsets.all(
        16.0,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      child: widget.isEdit
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Batalkan Registrasi button (only in edit mode)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _cancelRegistration,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Batalkan Registrasi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Batal & Update buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Batal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kTextGrey,
                          side: BorderSide(color: kTextGrey.withOpacity(0.3)),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _submitRegistration,
                        icon: const Icon(Icons.check),
                        label: const Text('Update Registrasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: kWhite,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Batal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextGrey,
                      side: BorderSide(color: kTextGrey.withOpacity(0.3)),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _submitRegistration,
                    icon: const Icon(Icons.check),
                    label: const Text('Simpan Registrasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kWhite,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
