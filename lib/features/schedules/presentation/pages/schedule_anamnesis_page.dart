import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF002F67);
const Color kScaffoldBg = Color(0xFFF8F9FA);
const Color kWhiteColor = Colors.white;
const Color kCardBorder = Color(0xFFE2E8F0);
const Color kIconBg = Color(0xFFEFF6FF);
const Color kTextTitle = Color(0xFF002F67); // Warna teks judul section
const Color kTextBody = Color(0xFF475569); // Warna teks abu-abu
const Color kTextLabel = Color(0xFF334155); // Warna label form
const Color kLightGreenBg = Color(0xFFF0FDF4); // Latar belakang hijau muda
const Color kLightGreenBorder = Color(0xFFB4F9C5);

// Halaman utama yang berisi Stepper
class ScheduleAssessmentPage extends StatefulWidget {
  final VoidCallback? onCompleted;
  
  const ScheduleAssessmentPage({super.key, this.onCompleted});

  @override
  State<ScheduleAssessmentPage> createState() => _ScheduleAssessmentPageState();
}

class _ScheduleAssessmentPageState extends State<ScheduleAssessmentPage> {
  int _currentStep = 0;

  // Satu FormKey untuk setiap langkah (step)
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // --- State untuk Form Keperawatan (Langkah 1) ---
  String? _riwayatAlergi;
  String? _adl;
  String? _risikoJatuh;
  String? _riwayatPenyakitDahulu;
  final Map<String, bool> _masalahKeperawatan = {
    'Bersihan jalan nafas': false,
    'Pola nafas tidak efektif': false,
    'Hipertermia': false,
    'Nyeri akut': false,
    'Nyeri kronis': false,
    'Gangguan perfusi jaringan serebal': false,
    'Gangguan keseimbangan cairan': false,
    'Lainnya': false,
  };

  // --- State untuk Form Medis (Langkah 2) ---
  String? _jenisPerawatan;
  final List<TextEditingController> _rujukanControllers = [
    TextEditingController(),
  ];

  // --- State untuk Form Khusus (Langkah 3) ---
  String? _morrional1;
  String? _morrional2;
  String? _morrional3;
  String? _mna1;
  String? _mna2;
  String? _morse1;
  String? _morse2;
  String? _morse3;
  String? _morse4;
  String? _kultivasi1;
  String? _perencanaan1;
  String? _perencanaan2;
  String? _perencanaan3;

  @override
  void dispose() {
    for (var controller in _rujukanControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addRujukanField() {
    setState(() {
      _rujukanControllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            color: kWhiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: kWhiteColor),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          // Validasi form sebelum lanjut
          bool isStepValid = false;
          if (_currentStep == 0) {
            isStepValid =
                _formKeyStep1.currentState?.validate() ??
                true; // Ganti true jika tidak ada validasi
          } else if (_currentStep == 1) {
            isStepValid = _formKeyStep2.currentState?.validate() ?? true;
          } else if (_currentStep == 2) {
            isStepValid = _formKeyStep3.currentState?.validate() ?? true;
            if (isStepValid) {
              _saveForm(); // Simpan jika ini langkah terakhir
            }
            return; // Jangan lanjut ke step berikutnya
          }

          if (isStepValid) {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        onStepTapped: (step) {
          // Izinkan navigasi bebas antar step
          setState(() => _currentStep = step);
        },
        steps: [
          // --- LANGKAH 1: PENGKAJIAN KEPERAWATAN ---
          Step(
            title: const Text('Keperawatan'),
            content: _buildFormKeperawatan(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          // --- LANGKAH 2: PENGKAJIAN MEDIS ---
          Step(
            title: const Text('Medis'),
            content: _buildFormMedis(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          // --- LANGKAH 3: FORM KHUSUS PERAWAT ---
          Step(
            title: const Text('Khusus'),
            content: _buildFormKhusus(),
            isActive: _currentStep >= 2,
            state: _currentStep == 2 ? StepState.editing : StepState.indexed,
          ),
        ],
        // Mengganti tombol default Stepper
        controlsBuilder: (context, details) {
          final bool isLastStep = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kWhiteColor,
                        foregroundColor: kPrimaryColor,
                        side: const BorderSide(color: kPrimaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Sebelumnya'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastStep
                          ? Colors.green
                          : kPrimaryColor,
                      foregroundColor: kWhiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(isLastStep ? 'Simpan' : 'Selanjutnya'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 0:
        return 'Formulir Pengkajian Keperawatan';
      case 1:
        return 'Formulir Pengkajian Medis';
      case 2:
        return 'Diisi Khusus Perawat';
      default:
        return 'Formulir Kunjungan';
    }
  }

  void _saveForm() {
    // TODO: Kumpulkan semua data dari state variables
    // ( _riwayatAlergi, _jenisPerawatan, _morrional1, dll.)
    // TODO: Panggil BLoC/Repository untuk simpan data
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Menyimpan seluruh data...')));
    
    // Panggil callback jika ada (dari visit flow)
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else {
      // Jika tidak ada callback, kembali ke halaman sebelumnya
      Navigator.pop(context);
    }
  }

  // --- WIDGET HELPER UTAMA ---

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    bool isGreen = false,
  }) {
    return Card(
      elevation: 0,
      color: isGreen ? kLightGreenBg : kWhiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isGreen ? kLightGreenBorder : kCardBorder),
      ),
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: isGreen ? Colors.green.shade100 : kIconBg,
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
    String? initialValue,
    required String label,
    bool isNumber = false,
    bool multiline = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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
            initialValue: controller == null ? initialValue : null,
            keyboardType: isNumber
                ? TextInputType.number
                : (multiline ? TextInputType.multiline : TextInputType.text),
            maxLines: multiline ? 3 : 1,
            decoration: InputDecoration(
              hintText: hint,
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
          ),
        ],
      ),
    );
  }

  Widget _buildRadioGroup({
    required String label,
    required List<String> options,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
    bool isHorizontal = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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
          if (isHorizontal)
            Row(
              children: options.map((option) {
                return Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: option,
                        groupValue: groupValue,
                        onChanged: onChanged,
                        activeColor: kPrimaryColor,
                      ),
                      Flexible(child: Text(option)),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (!isHorizontal)
            Column(
              children: options.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: kPrimaryColor,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // --- LANGKAH 1: FORMULIR PENGKAJIAN KEPERAWATAN ---
  // ==========================================================
  Widget _buildFormKeperawatan() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Tanda Vital',
            icon: Icons.monitor_heart_outlined,
            child: Column(
              children: [
                _buildTextField(
                  label: 'Tekanan Darah (mmHg)',
                  hint: '120/80',
                  isNumber: true,
                ),
                _buildTextField(
                  label: 'Frekuensi Nadi (/mrt)',
                  hint: '80',
                  isNumber: true,
                ),
                _buildTextField(
                  label: 'Suhu (˚C)',
                  hint: '36.6',
                  isNumber: true,
                ),
                _buildTextField(
                  label: 'Frekuensi Pernapasan (/mrt)',
                  hint: '20',
                  isNumber: true,
                ),
                _buildRadioGroup(
                  label: 'Riwayat Alergi',
                  options: ['Ya', 'Tidak'],
                  groupValue: _riwayatAlergi,
                  onChanged: (v) => setState(() => _riwayatAlergi = v),
                ),
              ],
            ),
          ),
          _buildSectionCard(
            title: 'Nutrisi',
            icon: Icons.scale_outlined,
            isGreen: true,
            child: Column(
              children: [
                _buildTextField(
                  label: 'Berat Badan (kg)',
                  hint: '60',
                  isNumber: true,
                ),
                _buildTextField(
                  label: 'Tinggi Badan (cm)',
                  hint: '170',
                  isNumber: true,
                ),
                _buildTextField(label: 'IMT', hint: '20.8', isNumber: true),
                _buildTextField(
                  label: 'Khusus Pedia: Lingkar Kepala (cm)',
                  hint: '48',
                  isNumber: true,
                ),
              ],
            ),
          ),
          _buildSectionCard(
            title: 'Fungsional',
            icon: Icons.accessibility_new_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: 'Alat Bantu',
                  hint: 'Tongkat, kursi roda, dll',
                ),
                _buildTextField(label: 'Prostesa', hint: 'Jenis prostesa'),
                _buildTextField(
                  label: 'Cacat Tubuh',
                  hint: 'Jelaskan cacat tubuh',
                ),
                _buildRadioGroup(
                  label: 'ADL (Activities of Daily Living)',
                  options: ['Mandiri', 'Bantuan'],
                  groupValue: _adl,
                  onChanged: (v) => setState(() => _adl = v),
                ),
                _buildRadioGroup(
                  label: 'Resiko Jatuh',
                  options: ['Ya', 'Tidak'],
                  groupValue: _risikoJatuh,
                  onChanged: (v) => setState(() => _risikoJatuh = v),
                ),
                _buildRadioGroup(
                  label: 'Riwayat Penyakit Dahulu',
                  options: ['Tidak ada', 'Melaporkan'],
                  groupValue: _riwayatPenyakitDahulu,
                  onChanged: (v) => setState(() => _riwayatPenyakitDahulu = v),
                ),
                if (_riwayatPenyakitDahulu == 'Melaporkan')
                  _buildTextField(
                    label: 'Melaporkan riwayat penyakit dahulu...',
                    hint: 'Jelaskan...',
                  ),
              ],
            ),
          ),
          _buildSectionCard(
            title: 'Keluhan',
            icon: Icons.chat_bubble_outline,
            isGreen: true,
            child: _buildTextField(
              label: 'Keluhan Pasien',
              hint: 'Masukkan keluhan pasien...',
              multiline: true,
            ),
          ),
          _buildSectionCard(
            title: 'Masalah Keperawatan',
            icon: Icons.assignment_late_outlined,
            child: Column(
              children: [
                ..._masalahKeperawatan.keys.map((String key) {
                  return CheckboxListTile(
                    title: Text(key),
                    value: _masalahKeperawatan[key],
                    onChanged: (bool? value) {
                      setState(() {
                        _masalahKeperawatan[key] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: kPrimaryColor,
                  );
                }).toList(),
                if (_masalahKeperawatan['Lainnya'] == true)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      left: 16,
                      right: 16,
                    ),
                    child: _buildTextField(
                      label: 'Sebutkan masalah keperawatan lainnya',
                      hint: 'Masukkan masalah...',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // --- LANGKAH 2: FORMULIR PENGKAJIAN MEDIS ---
  // ==========================================================
  Widget _buildFormMedis() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Anamnesa Pemeriksaan Fisik',
            icon: Icons.medical_information_outlined,
            child: _buildTextField(
              label: 'Pemeriksaan Fisik',
              hint: 'Masukkan hasil pemeriksaan fisik...',
              multiline: true,
            ),
          ),
          _buildSectionCard(
            title: 'Diagnosis',
            icon: Icons.file_present_outlined,
            isGreen: true,
            child: _buildTextField(
              label: 'Diagnosis',
              hint: 'Masukkan diagnosis...',
              multiline: true,
            ),
          ),
          _buildSectionCard(
            title: 'Rencana dan Terapi',
            icon: Icons.link_outlined,
            child: _buildTextField(
              label: 'Rencana dan Terapi',
              hint: 'Masukkan rencana dan terapi...',
              multiline: true,
            ),
          ),
          _buildSectionCard(
            title: 'Pemeriksaan Penunjang',
            icon: Icons.biotech_outlined,
            isGreen: true,
            child: _buildTextField(
              label: 'Pemeriksaan Penunjang',
              hint: 'Masukkan pemeriksaan penunjang...',
              multiline: true,
            ),
          ),
          _buildSectionCard(
            title: 'Kontrol',
            icon: Icons.description_outlined,
            child: _buildTextField(
              label: 'Kontrol',
              hint: 'Masukkan jadwal/rencana kontrol...',
              multiline: true,
            ),
          ),
          _buildSectionCard(
            title: 'Jenis Perawatan',
            icon: Icons.health_and_safety_outlined,
            isGreen: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Jenis Perawatan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextLabel,
                  ),
                ),
                ...['Preventif', 'Paliatif', 'Kuratif', 'Rehabilitatif'].map(
                  (jenis) => RadioListTile<String>(
                    title: Text(jenis),
                    value: jenis,
                    groupValue: _jenisPerawatan,
                    onChanged: (v) => setState(() => _jenisPerawatan = v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          _buildSectionCard(
            title: 'Rujukan',
            icon: Icons.maps_home_work_outlined,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dirujuk Ke',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextLabel,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addRujukanField,
                      icon: const Icon(Icons.add_home_work_outlined, size: 18),
                      label: const Text('Tambah'),
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _rujukanControllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildTextField(
                        controller: _rujukanControllers[index],
                        label: 'Tujuan Rujukan ${index + 1}',
                        hint: 'Masukkan tujuan rujukan...',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // --- LANGKAH 3: FORMULIR KHUSUS PERAWAT ---
  // ==========================================================
  Widget _buildFormKhusus() {
    return Form(
      key: _formKeyStep3,
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Morrional Time "Up & Go"',
            icon: Icons.directions_run,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pasien Rawat Jalan yang Beresiko Jatuh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Perkabelan/Pengkajian:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextLabel,
                  ),
                ),
                const Text(
                  'Pilih salah satu (bila ada lebih dari satu)',
                  style: TextStyle(color: kTextBody, fontSize: 12),
                ),
                const SizedBox(height: 12),
                _buildRadioGroup(
                  label: '1. Tidak seimbang/sempoyongan/berhenti saat duduk?',
                  options: ['Ya', 'Tidak'],
                  groupValue: _morrional1,
                  onChanged: (v) => setState(() => _morrional1 = v),
                  isHorizontal: false,
                ),
                _buildRadioGroup(
                  label:
                      '2. Jalannya tidak mulus, langkah tak sama, tak lancar, lari-lari, dorong tanpa daya dorong?',
                  options: ['Ya', 'Tidak'],
                  groupValue: _morrional2,
                  onChanged: (v) => setState(() => _morrional2 = v),
                  isHorizontal: false,
                ),
                _buildRadioGroup(
                  label:
                      '3. Mendorong/menopang saat akan duduk, tempati penyangga tangan, jatuh ke kursi, meleset/mencari-cari tempat pegangan atau duduk miring?',
                  options: ['Ya', 'Tidak'],
                  groupValue: _morrional3,
                  onChanged: (v) => setState(() => _morrional3 = v),
                  isHorizontal: false,
                ),
                _buildTextField(
                  label: 'Hasil Resiko RM Tindakan',
                  hint: 'Isi hasil resiko dan tindakan...',
                  multiline: true,
                ),
              ],
            ),
          ),
          _buildSectionCard(
            title: 'MNA Short Form (Mini Nutritional Assessment)',
            icon: Icons.fastfood_outlined,
            isGreen: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pasien Dewasa',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildRadioGroup(
                  label:
                      '1. Apakah ada penurunan berat badan yang tidak di inginkan selama 3 bulan terakhir?',
                  options: [
                    'Tidak (skor 0)',
                    'Mungkin (1-3 kg) (skor 2)',
                    'Ya (>3 kg) (skor 3)',
                  ],
                  groupValue: _mna1,
                  onChanged: (v) => setState(() => _mna1 = v),
                  isHorizontal: false,
                ),
                _buildRadioGroup(
                  label:
                      '2. Apakah asupan makan menurun yang dihubungkan dengan penurunan nafsu makan?',
                  options: ['Tidak (skor 0)', 'Ya (skor 1)'],
                  groupValue: _mna2,
                  onChanged: (v) => setState(() => _mna2 = v),
                  isHorizontal: false,
                ),
                _buildTextField(
                  label: 'Total Skor (A + B, Remobilisasi Dll)',
                  hint: 'Isi total skor...',
                ),
              ],
            ),
          ),
          _buildSectionCard(
            title: 'Morse Fall Scale',
            icon: Icons.personal_injury_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meningkat untuk Pasien Anak',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildRadioGroup(
                  label: '1. Apakah didiagnosis lebih dari satu?',
                  options: ['Ya (15)', 'Tidak (0)'],
                  groupValue: _morse1,
                  onChanged: (v) => setState(() => _morse1 = v),
                  isHorizontal: false,
                ),
                _buildRadioGroup(
                  label: '2. Ambulasi/bantuan (jalan)',
                  options: ['Mandiri (0)', 'Lemah (15)', 'Alat Bantu (30)'],
                  groupValue: _morse2,
                  onChanged: (v) => setState(() => _morse2 = v),
                  isHorizontal: false,
                ),
                _buildRadioGroup(
                  label:
                      '3. Apakah terdapat infus/alat medis/alat bantu/box/oksigen, alat hisap, dll?',
                  options: ['Ya (20)', 'Tidak (0)'],
                  groupValue: _morse3,
                  onChanged: (v) => setState(() => _morse3 = v),
                  isHorizontal: false,
                ),
                _buildRadioGroup(
                  label:
                      '4. Apakah terjadi penurunan berat badan atau nafsu makan atau kesulitan makan atau minum?',
                  options: ['Ya (10)', 'Tidak (0)'],
                  groupValue: _morse4,
                  onChanged: (v) => setState(() => _morse4 = v),
                  isHorizontal: false,
                ),
                _buildTextField(
                  label: 'Total Skor (Resiko Rendah/Tinggi)',
                  hint: 'Isi total skor...',
                ),
              ],
            ),
          ),
          _buildSectionCard(
            title: 'Kultivasi Pasien',
            icon: Icons.psychology_outlined,
            isGreen: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRadioGroup(
                  label:
                      'Edukasi awal, dibicarakan rentang diagnosis, tatalaksana dan lainnya',
                  options: ['Ya', 'Tidak'],
                  groupValue: _kultivasi1,
                  onChanged: (v) => setState(() => _kultivasi1 = v),
                  isHorizontal: false,
                ),
                _buildTextField(
                  label: 'Hasil Edukasi/Respon',
                  hint: 'Masukkan hasil...',
                ),
              ],
            ),
          ),
          _buildSectionCard(
            title: 'Perencanaan Pulang Pasien',
            icon: Icons.logout_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRadioGroup(
                  label: 'Bantuan merawat diri dan aktifitas sehari-hari',
                  options: ['Ya', 'Tidak'],
                  groupValue: _perencanaan1,
                  onChanged: (v) => setState(() => _perencanaan1 = v),
                  isHorizontal: false,
                ),
                _buildRadioGroup(
                  label: 'Kebutuhan nutrisi',
                  options: ['Ya', 'Tidak'],
                  groupValue: _perencanaan2,
                  onChanged: (v) => setState(() => _perencanaan2 = v),
                  isHorizontal: false,
                ),
                _buildRadioGroup(
                  label: 'Kebutuhan pelayanan medis dan perawatan',
                  options: ['Ya', 'Tidak'],
                  groupValue: _perencanaan3,
                  onChanged: (v) => setState(() => _perencanaan3 = v),
                  isHorizontal: false,
                ),
                const Text(
                  'Tergantung dengan orang lain untuk aktifitas harian:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kTextLabel,
                  ),
                ),
                const Text('• Makan', style: TextStyle(color: kTextBody)),
                const Text('• Mandi', style: TextStyle(color: kTextBody)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
