import 'package:flutter/material.dart';

// --- Palet Warna (dari desain Anda) ---
const Color kPrimaryColor = Color(0xFF002F67);
const Color kScaffoldBg = Color(0xFFF8F9FA);
const Color kWhiteColor = Colors.white;
const Color kCardBorder = Color(0xFFE2E8F0);
const Color kIconBg = Color(0xFFEFF6FF); // Latar belakang ikon
const Color kTextTitle = Color(0xFF002F67); // Warna teks judul section
const Color kTextLabel = Color(0xFF334155); // Warna label form
const Color kFabGreen = Color(0xFF16A34A); // Warna tombol simpan

class AddPatientRegistrationPage extends StatefulWidget {
  final Map<String, String>? initialData;
  const AddPatientRegistrationPage({super.key, this.initialData});

  @override
  State<AddPatientRegistrationPage> createState() =>
      _AddPatientRegistrationPageState();
}

class _AddPatientRegistrationPageState
    extends State<AddPatientRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // --- State untuk Form ---
  final _namaPasienCtrl = TextEditingController();
  final _mrnCtrl = TextEditingController();
  final _teleponPasienCtrl = TextEditingController();
  final _alamatPasienCtrl = TextEditingController();

  String? _jenisKunjungan = 'Rawat Jalan';
  final _kodeIcdCtrl = TextEditingController();
  final _noInvoiceCtrl = TextEditingController();
  final _tanggalInvoiceCtrl = TextEditingController();

  final _namaPenanggungCtrl = TextEditingController();
  final _noPegawaiCtrl = TextEditingController();
  final _alamatPenanggungCtrl = TextEditingController();
  final _teleponPenanggungCtrl = TextEditingController();
  String? _eselon;

  @override
  void dispose() {
    // Dispose semua controller
    _namaPasienCtrl.dispose();
    _mrnCtrl.dispose();
    _teleponPasienCtrl.dispose();
    _alamatPasienCtrl.dispose();
    _kodeIcdCtrl.dispose();
    _noInvoiceCtrl.dispose();
    _tanggalInvoiceCtrl.dispose();
    _namaPenanggungCtrl.dispose();
    _noPegawaiCtrl.dispose();
    _alamatPenanggungCtrl.dispose();
    _teleponPenanggungCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    // Contoh fungsi untuk date picker
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        // Format tanggal sesuai kebutuhan, misal: '2025-11-12'
        _tanggalInvoiceCtrl.text = pickedDate
            .toIso8601String()
            .split('T')
            .first;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Kumpulkan semua data dari controller dan state
      // TODO: Panggil BLoC/Repository untuk menyimpan data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menyimpan data pasien baru...')),
      );
      // Return newly created patient minimal info to caller (name + mrn)
      final newPatient = {
        'name': _namaPasienCtrl.text.trim(),
        'mrn': _mrnCtrl.text.trim(),
      };
      Navigator.pop(context, newPatient);
    }
  }

  @override
  void initState() {
    super.initState();
    // Prefill fields if editing
    final init = widget.initialData;
    if (init != null) {
      _namaPasienCtrl.text = init['name'] ?? '';
      _mrnCtrl.text = init['mrn'] ?? '';
      _teleponPasienCtrl.text = init['phone'] ?? '';
      _alamatPasienCtrl.text = init['address'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Tambah Pasien Baru',
          style: TextStyle(color: kWhiteColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: kWhiteColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Container(
            padding: const EdgeInsets.only(bottom: 8.0),
            alignment: Alignment.centerLeft,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Lengkapi form pendaftaran',
                style: TextStyle(color: kWhiteColor, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildPatientDataSection(),
            const SizedBox(height: 16),
            _buildVisitDataSection(),
            const SizedBox(height: 16),
            _buildGuarantorDataSection(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _saveForm,
          icon: const Icon(Icons.save_alt_outlined, color: kWhiteColor),
          label: const Text('Simpan Data Pasien'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kFabGreen,
            foregroundColor: kWhiteColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // --- SECTION WIDGETS ---

  Widget _buildPatientDataSection() {
    return _buildSectionCard(
      title: 'Data Pasien',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _buildTextField(
            controller: _namaPasienCtrl,
            label: 'Nama Pasien *',
            hint: 'Masukkan nama lengkap',
            validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
          ),
          _buildTextField(
            controller: _mrnCtrl,
            label: 'No. Rekam Medis (MRN) *',
            hint: 'Contoh: MRN001234',
            validator: (v) => v!.isEmpty ? 'MRN tidak boleh kosong' : null,
          ),
          _buildTextField(
            controller: _teleponPasienCtrl,
            label: 'No. Telepon *',
            hint: '08xxxxxxxxxx',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v!.isEmpty ? 'No. Telepon tidak boleh kosong' : null,
          ),
          _buildTextField(
            controller: _alamatPasienCtrl,
            label: 'Alamat *',
            hint: 'Masukkan alamat lengkap',
            icon: Icons.location_on_outlined,
            multiline: true,
            validator: (v) => v!.isEmpty ? 'Alamat tidak boleh kosong' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitDataSection() {
    return _buildSectionCard(
      title: 'Data Kunjungan',
      icon: Icons.file_present_outlined,
      child: Column(
        children: [
          _buildDropdownField(
            label: 'Jenis Kunjungan *',
            value: _jenisKunjungan,
            items: ['Rawat Jalan', 'Rawat Inap', 'IGD'],
            onChanged: (newValue) {
              setState(() => _jenisKunjungan = newValue);
            },
          ),
          _buildTextField(
            controller: _kodeIcdCtrl,
            label: 'Kode ICD *',
            hint: 'Contoh: J00, A09',
            icon: Icons.medical_services_outlined, // Placeholder icon
            validator: (v) => v!.isEmpty ? 'Kode ICD tidak boleh kosong' : null,
          ),
          _buildTextField(
            controller: _noInvoiceCtrl,
            label: 'No. Invoice *',
            hint: 'Contoh: INV-2025-001',
            icon: Icons.receipt_long_outlined, // Placeholder icon
            validator: (v) =>
                v!.isEmpty ? 'No. Invoice tidak boleh kosong' : null,
          ),
          _buildTextField(
            controller: _tanggalInvoiceCtrl,
            label: 'Tanggal Invoice *',
            hint: 'Pilih tanggal',
            icon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: _selectDate,
            validator: (v) => v!.isEmpty ? 'Tanggal tidak boleh kosong' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantorDataSection() {
    return _buildSectionCard(
      title: 'Data Penanggung',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          _buildTextField(
            controller: _namaPenanggungCtrl,
            label: 'Nama Penanggung *',
            hint: 'Contoh: BPJS Kesehatan',
            validator: (v) =>
                v!.isEmpty ? 'Nama Penanggung tidak boleh kosong' : null,
          ),
          _buildTextField(
            controller: _noPegawaiCtrl,
            label: 'No. Pegawai Penanggung *',
            hint: 'Contoh: PEG001',
            validator: (v) =>
                v!.isEmpty ? 'No. Pegawai tidak boleh kosong' : null,
          ),
          _buildTextField(
            controller: _alamatPenanggungCtrl,
            label: 'Alamat Penanggung *',
            hint: 'Masukkan alamat penanggung',
            multiline: true,
            validator: (v) => v!.isEmpty ? 'Alamat tidak boleh kosong' : null,
          ),
          _buildTextField(
            controller: _teleponPenanggungCtrl,
            label: 'No. Telepon Penanggung *',
            hint: 'Contoh: 021xxxxxxx',
            keyboardType: TextInputType.phone,
            validator: (v) => v!.isEmpty ? 'Telepon tidak boleh kosong' : null,
          ),
          _buildDropdownField(
            label: 'Eselon *',
            value: _eselon,
            hint: 'Pilih Eselon',
            items: [
              'Eselon I',
              'Eselon II',
              'Eselon III',
              'Eselon IV',
              'Lainnya',
            ],
            onChanged: (newValue) {
              setState(() => _eselon = newValue);
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 1,
      color: kWhiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kCardBorder),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kIconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: kTextTitle, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextTitle,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    String? hint,
    IconData? icon,
    bool isNumber = false,
    bool multiline = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kTextLabel,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType:
                keyboardType ??
                (isNumber
                    ? TextInputType.number
                    : (multiline
                          ? TextInputType.multiline
                          : TextInputType.text)),
            maxLines: multiline ? 3 : 1,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: kScaffoldBg,
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.grey.shade600, size: 20)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kTextLabel,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: kScaffoldBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            validator: (v) => v == null ? 'Pilihan tidak boleh kosong' : null,
          ),
        ],
      ),
    );
  }
}
