import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:homecare_mobile/features/patients/presentation/bloc/patient_bloc.dart';
import 'package:homecare_mobile/shared/app_injections.dart';

// --- Palet Warna (consistent dengan list page) ---
const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kSecondaryColor = Color(0xFF8BC43E);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kDangerColor = Color(0xFFEF4444);

class PatientAddPage extends StatelessWidget {
  const PatientAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use singleton BLoC from getIt - same instance as list page
    return BlocProvider.value(
      value: getIt<PatientBloc>(),
      child: const _PatientAddForm(),
    );
  }
}

class _PatientAddForm extends StatefulWidget {
  const _PatientAddForm();

  @override
  State<_PatientAddForm> createState() => _PatientAddFormState();
}

class _PatientAddFormState extends State<_PatientAddForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _namaController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _alamatController = TextEditingController();
  final _noTelpController = TextEditingController();

  String _jenisKelamin = 'L';
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _tanggalLahirController.dispose();
    _alamatController.dispose();
    _noTelpController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
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
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal lahir harus diisi'),
            backgroundColor: kDangerColor,
          ),
        );
        return;
      }
      setState(() => _isLoading = true);
      // Kirim ke BLoC untuk membuat pasien via API
      final bloc = context.read<PatientBloc>();
      final tanggalIso = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      bloc.add(CreatePatient(
        nama: _namaController.text.trim(),
        tanggalLahir: tanggalIso,
        jenisKelamin: _jenisKelamin,
        alamat: _alamatController.text.trim(),
        telepon: _noTelpController.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: BlocListener<PatientBloc, PatientState>(
        listener: (context, state) {
          if (state is PatientError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: kDangerColor,
              ),
            );
          } else if (state is PatientOperationSuccess && state.type == PatientOperationType.create) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pasien berhasil ditambahkan'),
                backgroundColor: kSuccessColor,
              ),
            );
            context.pop(true);
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
                      _buildSectionTitle('Data Pasien'),
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
                      _buildDateField(),
                      const SizedBox(height: 16),
                      _buildGenderField(),
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
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
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
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: kWhite, size: 24),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tambah Pasien Baru',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 36),
              child: Text(
                'Lengkapi data pasien di bawah ini',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
          borderSide: BorderSide(color: kTextGrey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kTextGrey.withValues(alpha: 0.3)),
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
      validator: (value) {
        if (_selectedDate == null) {
          return 'Tanggal lahir harus diisi';
        }
        return null;
      },
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
          borderSide: BorderSide(color: kTextGrey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kTextGrey.withValues(alpha: 0.3)),
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
          color: isSelected ? color.withValues(alpha: 0.1) : kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : kTextGrey.withValues(alpha: 0.3),
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
          _isLoading ? 'Menyimpan...' : 'Simpan Data Pasien',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: kSecondaryColor,
          foregroundColor: kWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // Success dialog for create is disabled in dummy mode.
}
