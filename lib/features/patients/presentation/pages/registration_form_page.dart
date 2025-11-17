import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/patients/data/repositories/pasien_repository.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart' as db;
import 'package:drift/drift.dart' as drift;

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
  db.Registrasi? _existingRegistration;

  DateTime _selectedDateTime = DateTime.now();
  DateTime _tanggalKunjungan = DateTime.now().add(const Duration(days: 1)); // Default besok
  TimeOfDay _jamKunjungan = const TimeOfDay(hour: 9, minute: 0); // Default jam 9 pagi
  String _jenisKunjungan = 'Kunjungan Baru';
  String _tipePasien = 'Umum';
  String _eselon = 'I';

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.registrasiId != null) {
      _loadExistingRegistration();
    } else {
      // Generate nomor registrasi otomatis
      _noRegController.text =
          'REG-${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  Future<void> _loadExistingRegistration() async {
    setState(() => _isLoading = true);
    try {
      final database = getIt<db.AppDatabase>();
      final registration = await database.getRegistrasiById(widget.registrasiId!);
      
      if (registration != null && mounted) {
        setState(() {
          _existingRegistration = registration;
          _noRegController.text = registration.noReg;
          _selectedDateTime = registration.tglJamReg;
          _tanggalKunjungan = registration.tanggalKunjungan;
          
          // Parse jam kunjungan (HH:mm format)
          final timeParts = registration.jamKunjungan.split(':');
          if (timeParts.length == 2) {
            _jamKunjungan = TimeOfDay(
              hour: int.tryParse(timeParts[0]) ?? 9,
              minute: int.tryParse(timeParts[1]) ?? 0,
            );
          }
          
          _jenisKunjungan = registration.jenisKunjungan;
          _tipePasien = registration.tipePasien;
          _penanggungNamaController.text = registration.penanggungNama;
          _penanggungNoPegawaiController.text = registration.penanggungNoPegawai ?? '';
          _penanggungAlamatController.text = registration.penanggungAlamat;
          _penanggungTeleponController.text = registration.penanggungTelepon;
          _penanggungIdController.text = registration.penanggungId ?? '';
          _eselon = registration.eselon ?? 'I';
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

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      try {
        final jamKunjunganFormatted = '${_jamKunjungan.hour.toString().padLeft(2, '0')}:${_jamKunjungan.minute.toString().padLeft(2, '0')}';
        
        // Get database and patient ID
        final database = getIt<db.AppDatabase>();
        final pasienIdInt = int.tryParse(widget.pasienId ?? '0');
        
        if (pasienIdInt == null || pasienIdInt == 0) {
          throw Exception('Invalid patient ID');
        }

        if (widget.isEdit && widget.registrasiId != null) {
          // UPDATE existing registration
          final registrasiCompanion = db.RegistrasisCompanion(
            noReg: drift.Value(_noRegController.text),
            pasienId: drift.Value(pasienIdInt),
            tglJamReg: drift.Value(_selectedDateTime),
            tanggalKunjungan: drift.Value(_tanggalKunjungan),
            jamKunjungan: drift.Value(jamKunjunganFormatted),
            jenisKunjungan: drift.Value(_jenisKunjungan),
            tipePasien: drift.Value(_tipePasien),
            penanggungNama: drift.Value(_penanggungNamaController.text),
            penanggungNoPegawai: drift.Value(_penanggungNoPegawaiController.text),
            penanggungAlamat: drift.Value(_penanggungAlamatController.text),
            penanggungTelepon: drift.Value(_penanggungTeleponController.text),
            penanggungId: drift.Value(_penanggungIdController.text),
            eselon: drift.Value(_eselon),
          );

          await database.updateRegistrasi(widget.registrasiId!, registrasiCompanion);
          debugPrint('✅ Registration updated with ID: ${widget.registrasiId}');
        } else {
          // INSERT new registration
          final registrasiCompanion = db.RegistrasisCompanion(
            noReg: drift.Value(_noRegController.text),
            pasienId: drift.Value(pasienIdInt),
            tglJamReg: drift.Value(_selectedDateTime),
            tanggalKunjungan: drift.Value(_tanggalKunjungan),
            jamKunjungan: drift.Value(jamKunjunganFormatted),
            jenisKunjungan: drift.Value(_jenisKunjungan),
            tipePasien: drift.Value(_tipePasien),
            penanggungNama: drift.Value(_penanggungNamaController.text),
            penanggungNoPegawai: drift.Value(_penanggungNoPegawaiController.text),
            penanggungAlamat: drift.Value(_penanggungAlamatController.text),
            penanggungTelepon: drift.Value(_penanggungTeleponController.text),
            penanggungId: drift.Value(_penanggungIdController.text),
            eselon: drift.Value(_eselon),
          );

          final registrasiId = await database.insertRegistrasi(registrasiCompanion);
          debugPrint('✅ Registration saved with ID: $registrasiId');

          // Update patient isRegistered flag (only for new registration)
          final repository = getIt<PasienRepository>();
          await repository.markAsRegistered(widget.pasienId!);
          debugPrint('✅ Patient marked as registered');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEdit
                  ? 'Registrasi berhasil diupdate'
                  : 'Registrasi berhasil disimpan'),
              backgroundColor: Colors.green,
            ),
          );

          context.pop(true); // Return true to signal success
        }
      } catch (e) {
        debugPrint('❌ Error saving registration: $e');
        if (mounted) {
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
                          _buildDateTimeField(),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Jenis Kunjungan',
                            icon: Icons.local_hospital,
                            value: _jenisKunjungan,
                            items: [
                              'Kunjungan Baru',
                              'Kunjungan Lanjutan',
                              'Kunjungan Darurat'
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
                            items: ['Umum', 'BPJS', 'Asuransi'],
                            onChanged: (value) {
                              setState(() {
                                _tipePasien = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Jadwal Kunjungan',
                        icon: Icons.calendar_today,
                        children: [
                          _buildScheduleDateField(),
                          const SizedBox(height: 16),
                          _buildScheduleTimeField(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionCard(
                        title: 'Data Penanggung Jawab',
                        icon: Icons.family_restroom,
                        children: [
                          _buildTextField(
                            controller: _penanggungNamaController,
                            label: 'Nama Penanggung',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama penanggung harus diisi';
                              }
                              return null;
                            },
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
                          _buildDropdownField(
                            label: 'Eselon',
                            icon: Icons.military_tech,
                            value: _eselon,
                            items: ['I', 'II', 'III', 'IV', 'V'],
                            onChanged: (value) {
                              setState(() {
                                _eselon = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _penanggungTeleponController,
                            label: 'No. Telepon',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'No. telepon harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _penanggungAlamatController,
                            label: 'Alamat Penanggung',
                            icon: Icons.location_on,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Alamat harus diisi';
                              }
                              return null;
                            },
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

  Widget _buildDateTimeField() {
    return InkWell(
      onTap: _selectDateTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Tanggal & Jam Registrasi',
          prefixIcon: const Icon(Icons.calendar_today, color: kPrimaryColor),
          filled: true,
          fillColor: kScaffoldBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        child: Text(
          DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(_selectedDateTime),
          style: const TextStyle(fontSize: 16),
        ),
      ),
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
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildScheduleDateField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _tanggalKunjungan,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('id', 'ID'),
        );
        if (date != null) {
          setState(() {
            _tanggalKunjungan = date;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Tanggal Kunjungan',
          prefixIcon: const Icon(Icons.event, color: kPrimaryColor),
          filled: true,
          fillColor: kScaffoldBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_tanggalKunjungan),
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down, color: kTextGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTimeField() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _jamKunjungan,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );
        if (time != null) {
          setState(() {
            _jamKunjungan = time;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Jam Kunjungan',
          prefixIcon: const Icon(Icons.access_time, color: kPrimaryColor),
          filled: true,
          fillColor: kScaffoldBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_jamKunjungan.hour.toString().padLeft(2, '0')}:${_jamKunjungan.minute.toString().padLeft(2, '0')} WIB',
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down, color: kTextGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      color: kWhite,
      padding: const EdgeInsets.all(16.0).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
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
              label: Text(widget.isEdit ? 'Update Registrasi' : 'Simpan Registrasi'),
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
