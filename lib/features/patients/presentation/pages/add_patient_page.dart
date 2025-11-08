import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homecare_mobile/shared/local_db/db_provider.dart';
import 'package:homecare_mobile/features/patients/data/datasources/patient_local_datasource.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';

const Color _kPrimaryColor = Color(0xFF002F67);
const Color _kAccentColor = Color(0xFF3F51B5);
const Color _kWhiteColor = Colors.white;
const double _kSpacing = 16.0;

class AddPatientPage extends StatefulWidget {
  final Patient? patientToEdit;
  const AddPatientPage({super.key, this.patientToEdit});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _noRmCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _tanggalLahirCtrl = TextEditingController();
  DateTime? _tanggalLahir;
  String _statusRujukan = 'disetujui';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFormFields();
  }

  void _initializeFormFields() {
    if (widget.patientToEdit != null) {
      final p = widget.patientToEdit!;
      _noRmCtrl.text = p.noRM;
      _namaCtrl.text = p.namaPasien;
      _alamatCtrl.text = p.alamat ?? '';
      _statusRujukan = p.statusRujukan;

      if (p.tanggalLahir != null) {
        try {
          _tanggalLahir = DateTime.parse(p.tanggalLahir!);
          _tanggalLahirCtrl.text = DateFormat(
            'd MMMM yyyy',
            'id_ID',
          ).format(_tanggalLahir!);
        } catch (_) {
          _tanggalLahir = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _noRmCtrl.dispose();
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _tanggalLahirCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final db = provideDb();
    final local = PatientLocalDataSource(db);

    try {
      final String noRm = _noRmCtrl.text.trim();
      final String namaPasien = _namaCtrl.text.trim();
      final String? alamat = _alamatCtrl.text.trim().isEmpty
          ? null
          : _alamatCtrl.text.trim();

      if (widget.patientToEdit != null) {
        final orig = widget.patientToEdit!;
        final localId = orig.id % 100000;

        await local.updatePatient(
          localId: localId,
          noRm: noRm,
          namaPasien: namaPasien,
          tanggalLahir: _tanggalLahir,
          alamat: alamat,
          statusRujukan: _statusRujukan,
        );
      } else {
        await local.insertPatient(
          noRm: noRm,
          namaPasien: namaPasien,
          tanggalLahir: _tanggalLahir,
          alamat: alamat,
          statusRujukan: _statusRujukan,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPrimaryColor,
              onPrimary: _kWhiteColor,
              onSurface: _kPrimaryColor,
            ),
            dialogBackgroundColor: _kWhiteColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tanggalLahir = picked;
        _tanggalLahirCtrl.text = DateFormat(
          'd MMMM yyyy',
          'id_ID',
        ).format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.patientToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? 'Edit Pasien' : 'Tambah Pasien Baru',
          style: const TextStyle(
            color: _kWhiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _kPrimaryColor,
        iconTheme: const IconThemeData(color: _kWhiteColor),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(_kSpacing),
          children: [
            _buildTextField(
              controller: _noRmCtrl,
              label: 'No. Rekam Medis (RM)',
              icon: Icons.medical_services_outlined,
              validator: (v) => v!.trim().isEmpty ? 'No RM wajib diisi' : null,
              keyboardType: TextInputType.number, // Tambahkan jenis keyboard
            ),
            const SizedBox(height: _kSpacing),

            _buildTextField(
              controller: _namaCtrl,
              label: 'Nama Lengkap Pasien',
              icon: Icons.person_outline,
              validator: (v) => v!.trim().isEmpty ? 'Nama wajib diisi' : null,
              textCapitalization:
                  TextCapitalization.words, // Kapitalisasi setiap kata
            ),
            const SizedBox(height: _kSpacing),

            _buildDatePicker(),
            const SizedBox(height: _kSpacing),

            _buildTextField(
              controller: _alamatCtrl,
              label: 'Alamat',
              icon: Icons.home_outlined,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: _kSpacing * 1.5),

            _buildRadioGroup(),
            const SizedBox(height: _kSpacing * 2),
            _buildSubmitButton(editing),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    // Konsistensi style Input
    const OutlineInputBorder borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(10),
      ), // Sudut sedikit melengkung
      borderSide: BorderSide(color: Colors.grey),
    );

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kAccentColor),
        border: borderStyle.copyWith(
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: borderStyle.copyWith(
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: borderStyle.copyWith(
          borderSide: const BorderSide(color: _kAccentColor, width: 2),
        ),
        errorBorder: borderStyle.copyWith(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: borderStyle.copyWith(
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        floatingLabelStyle: const TextStyle(
          color: _kAccentColor,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ), // Padding yang lebih nyaman
      ),
      validator: validator,
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      controller: _tanggalLahirCtrl,
      readOnly: true,
      onTap: _pickDate,
      decoration: InputDecoration(
        labelText: 'Tanggal Lahir',
        prefixIcon: const Icon(
          Icons.calendar_today_outlined,
          color: _kAccentColor,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kAccentColor, width: 2),
        ),
        floatingLabelStyle: const TextStyle(
          color: _kAccentColor,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
      ),
    );
  }

  Widget _buildRadioGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
          child: Text(
            'Status Rujukan',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                value: 'disetujui',
                groupValue: _statusRujukan,
                onChanged: (v) =>
                    setState(() => _statusRujukan = v ?? 'disetujui'),
                title: const Text('Disetujui'),
                activeColor: _kAccentColor,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const Divider(height: 0),
              RadioListTile<String>(
                value: 'belum_disetujui',
                groupValue: _statusRujukan,
                onChanged: (v) =>
                    setState(() => _statusRujukan = v ?? 'belum_disetujui'),
                title: const Text('Belum Disetujui'),
                activeColor: _kAccentColor,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool editing) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPrimaryColor,
        foregroundColor: _kWhiteColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 4, // Tambahkan sedikit bayangan
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: _kWhiteColor,
                strokeWidth: 3,
              ),
            )
          : Text(editing ? 'Perbarui Data' : 'Simpan Data'),
    );
  }
}
