import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';
import 'package:homecare_mobile/features/patients/presentation/bloc/patient_bloc.dart';
import 'package:homecare_mobile/shared/app_injections.dart';

// --- Palet Warna ---
const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kSecondaryColor = Color(0xFF8BC43E);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kDangerColor = Color(0xFFEF4444);

class PatientEditPage extends StatelessWidget {
  final Pasien patient;

  const PatientEditPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PatientBloc>(),
      child: _PatientEditForm(patient: patient),
    );
  }
}

class _PatientEditForm extends StatefulWidget {
  final Pasien patient;

  const _PatientEditForm({required this.patient});

  @override
  State<_PatientEditForm> createState() => _PatientEditFormState();
}

class _PatientEditFormState extends State<_PatientEditForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _namaController;
  late final TextEditingController _nikController;
  late final TextEditingController _noBpjsController;
  late final TextEditingController _tempatLahirController;
  late final TextEditingController _tanggalLahirController;
  late final TextEditingController _alamatController;
  late final TextEditingController _noTelpController;

  late String _jenisKelamin;
  late String? _golonganDarah;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _namaController = TextEditingController(text: widget.patient.nama);
    _nikController = TextEditingController(text: widget.patient.nik ?? '');
    _noBpjsController = TextEditingController(
      text: widget.patient.noBpjs ?? '',
    );
    _tempatLahirController = TextEditingController(
      text: widget.patient.tempatLahir,
    );
    _alamatController = TextEditingController(text: widget.patient.alamat);
    _noTelpController = TextEditingController(text: widget.patient.noTelp);

    _jenisKelamin = widget.patient.jenisKelamin;
    _golonganDarah = widget.patient.golonganDarah;
    _selectedDate = DateTime.parse(widget.patient.tanggalLahir);
    _tanggalLahirController = TextEditingController(
      text: DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _noBpjsController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _alamatController.dispose();
    _noTelpController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: kWhite,
              surface: kWhite,
              onSurface: kTextDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalLahirController.text = DateFormat(
          'd MMMM yyyy',
          'id_ID',
        ).format(picked);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      context.read<PatientBloc>().add(
        UpdatePatient(
          id: widget.patient.id,
          nama: _namaController.text.trim(),
          tempatLahir: _tempatLahirController.text.trim(),
          tanggalLahir: _selectedDate.toIso8601String(),
          jenisKelamin: _jenisKelamin,
          alamat: _alamatController.text.trim(),
          noTelp: _noTelpController.text.trim(),
          nik: _nikController.text.trim().isEmpty
              ? null
              : _nikController.text.trim(),
          noBpjs: _noBpjsController.text.trim().isEmpty
              ? null
              : _noBpjsController.text.trim(),
          golonganDarah: _golonganDarah,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: BlocListener<PatientBloc, PatientState>(
        listener: (context, state) {
          if (state is PatientOperationSuccess &&
              state.type == PatientOperationType.update) {
            context.pop(true);
          } else if (state is PatientError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: kDangerColor,
              ),
            );
          }
        },
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Informasi Dasar'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _namaController,
                        label: 'Nama Lengkap',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nikController,
                        label: 'NIK (opsional)',
                        icon: Icons.credit_card,
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length != 16) {
                            return 'NIK harus 16 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _noBpjsController,
                        label: 'No. BPJS (opsional)',
                        icon: Icons.local_hospital,
                        keyboardType: TextInputType.number,
                        maxLength: 13,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length != 13) {
                            return 'No. BPJS harus 13 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Informasi Kelahiran'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _tempatLahirController,
                        label: 'Tempat Lahir',
                        icon: Icons.location_city,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tempat lahir harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(),
                      const SizedBox(height: 16),
                      _buildGenderField(),
                      const SizedBox(height: 16),
                      _buildGolonganDarahField(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Kontak & Alamat'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _noTelpController,
                        label: 'No. Telepon',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'No. telepon harus diisi';
                          }
                          if (value.length < 10) {
                            return 'No. telepon tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _alamatController,
                        label: 'Alamat Lengkap',
                        icon: Icons.home,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alamat harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
                icon: const Icon(Icons.arrow_back, color: kWhite),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Text(
                  'Edit Data Pasien',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Text(
              'Perbarui informasi pasien',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.badge, color: kPrimaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No. Rekam Medis',
                  style: TextStyle(fontSize: 12, color: kTextGrey),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.patient.noRm,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: kSecondaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kTextDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        filled: true,
        fillColor: kWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kTextGrey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kTextGrey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDangerColor),
        ),
        counterText: '',
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _tanggalLahirController,
      readOnly: true,
      onTap: () => _selectDate(context),
      decoration: InputDecoration(
        labelText: 'Tanggal Lahir',
        prefixIcon: const Icon(Icons.calendar_today, color: kPrimaryColor),
        suffixIcon: IconButton(
          icon: const Icon(Icons.edit_calendar, color: kPrimaryColor),
          onPressed: () => _selectDate(context),
        ),
        filled: true,
        fillColor: kWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kTextGrey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kTextGrey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Kelamin',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildGenderOption('L', 'Laki-laki', Icons.male)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderOption('P', 'Perempuan', Icons.female)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _jenisKelamin == value;
    final color = value == 'L'
        ? const Color(0xFF3B82F6)
        : const Color(0xFFEC4899);

    return InkWell(
      onTap: () => setState(() => _jenisKelamin = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : kTextGrey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : kTextGrey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : kTextGrey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGolonganDarahField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Golongan Darah (opsional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kTextGrey.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _golonganDarah,
              hint: const Text('Pilih golongan darah'),
              icon: const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
              items: ['A', 'B', 'AB', 'O'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() => _golonganDarah = newValue);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitForm,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(kWhite),
                ),
              )
            : const Icon(Icons.save),
        label: Text(
          _isLoading ? 'Menyimpan...' : 'Update Data Pasien',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: kWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
