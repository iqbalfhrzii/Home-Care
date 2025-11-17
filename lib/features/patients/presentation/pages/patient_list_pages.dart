import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';

// --- Palet Warna Baru ---
const Color kPrimaryColor = Color(0xFF004B8C); // Deep Blue
const Color kPrimaryLight = Color(0xFF0063B2); // Lighter Blue for Gradient
const Color kSecondaryColor = Color(0xFF8BC43E); // Lime Green
const Color kSecondaryButton = Color(0xFF97CA4A); // Warna Tombol Tambah
const Color kScaffoldBg = Color(0xFFF5F7FA); // Cool White Background
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);

// --- 1. Model Data (Berdasarkan PasienResource) ---
class Pasien {
  final String id;
  final String mrn;
  final String nama;
  final String alamat;
  final String telepon;
  final String tanggalLahir; // Simpan sebagai String ISO
  final String jenisKelamin; // 'L' or 'P'
  final String createdAt;
  final String updatedAt;

  Pasien({
    required this.id,
    required this.mrn,
    required this.nama,
    required this.alamat,
    required this.telepon,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.createdAt,
    required this.updatedAt,
  });
}

// --- 2. Halaman Utama (Stateful) ---
class PatientMasterListPage extends StatefulWidget {
  const PatientMasterListPage({super.key});

  @override
  State<PatientMasterListPage> createState() => _PatientMasterListPageState();
}

class _PatientMasterListPageState extends State<PatientMasterListPage> {
  // --- State & Mock Data ---
  final List<Pasien> _allPatients = [
    Pasien(
      id: '1',
      mrn: 'RM-2024-001',
      nama: 'Ahmad Santoso',
      alamat: 'Jl. Merdeka No. 123, Jakarta',
      telepon: '081234567890',
      tanggalLahir: '1985-05-15',
      jenisKelamin: 'L',
      createdAt: '2024-01-15T08:00:00Z',
      updatedAt: '2024-01-15T08:00:00Z',
    ),
    Pasien(
      id: '2',
      mrn: 'RM-2024-002',
      nama: 'Siti Nurhaliza',
      alamat: 'Jl. Sudirman No. 45, Bandung',
      telepon: '082345678901',
      tanggalLahir: '1990-08-22',
      jenisKelamin: 'P',
      createdAt: '2024-02-10T09:30:00Z',
      updatedAt: '2024-02-10T09:30:00Z',
    ),
    Pasien(
      id: '3',
      mrn: 'RM-2024-003',
      nama: 'Budi Hartono',
      alamat: 'Jl. Gatot Subroto No. 78, Surabaya',
      telepon: '083456789012',
      tanggalLahir: '1978-03-10',
      jenisKelamin: 'L',
      createdAt: '2024-03-05T10:15:00Z',
      updatedAt: '2024-03-05T10:15:00Z',
    ),
    Pasien(
      id: '4',
      mrn: 'RM-2024-004',
      nama: 'Dewi Lestari',
      alamat: 'Jl. Ahmad Yani No. 234, Yogyakarta',
      telepon: '084567890123',
      tanggalLahir: '1995-12-05',
      jenisKelamin: 'P',
      createdAt: '2024-04-12T11:20:00Z',
      updatedAt: '2024-04-12T11:20:00Z',
    ),
    Pasien(
      id: '5',
      mrn: 'RM-2024-005',
      nama: 'Rudi Setiawan',
      alamat: 'Jl. Diponegoro No. 567, Semarang',
      telepon: '085678901234',
      tanggalLahir: '1982-07-18',
      jenisKelamin: 'L',
      createdAt: '2024-05-08T13:45:00Z',
      updatedAt: '2024-05-08T13:45:00Z',
    ),
  ];

  late List<Pasien> _filteredPatients;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredPatients = _allPatients;
    _searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterList);
    _searchController.dispose();
    super.dispose();
  }

  // --- Logika Helper ---
  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((p) {
        return p.nama.toLowerCase().contains(query) ||
            p.mrn.toLowerCase().contains(query) ||
            p.telepon.contains(query);
      }).toList();
    });
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  int _calculateAge(String isoDate) {
    try {
      final today = DateTime.now();
      final birth = DateTime.parse(isoDate);
      int age = today.year - birth.year;
      final monthDiff = today.month - birth.month;
      if (monthDiff < 0 || (monthDiff == 0 && today.day < birth.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  // --- Logika Aksi CRUD ---
  void _onAddPatient() async {
    final result = await context.push<Map<String, String>>(
      '${AppRouter.patients}/add',
    );
    if (result != null && mounted) {
      // Refresh list atau tambahkan pasien baru ke list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pasien baru ditambahkan: ${result['name']}')),
      );
      // TODO: Refresh data dari server/state management
    }
  }

  void _onEditPatient(Pasien patient) async {
    final result = await context.push<Map<String, String>>(
      '${AppRouter.patients}/${patient.id}/edit',
      extra: {
        'name': patient.nama,
        'mrn': patient.mrn,
        'phone': patient.telepon,
        'address': patient.alamat,
      },
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data pasien ${result['name']} diupdate')),
      );
      // TODO: Refresh data dari server/state management
    }
  }

  // <<< FUNGSI BARU UNTUK REGISTRASI >>>
  void _onRegisterPatient(Pasien patient) {
    // TODO: Navigasi ke Halaman Form Registrasi Kunjungan
    // Kirim 'patient.id' dan 'patient.nama' ke halaman form registrasi
    // Sesuai dengan StoreRegistrasiRequest
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registrasikan kunjungan untuk: ${patient.nama}')),
    );
  }

  void _onDeletePatient(Pasien patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Pasien?'),
        content: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              const TextSpan(text: 'Apakah Anda yakin ingin menghapus data '),
              TextSpan(
                text: patient.nama,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?\nTindakan ini tidak dapat dibatalkan.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () {
              // TODO: Implementasi logika delete di sini
              setState(() {
                _allPatients.removeWhere((p) => p.id == patient.id);
                _filterList();
              });
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: _filteredPatients.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada data pasien ditemukan.',
                      style: TextStyle(color: kTextGrey),
                    ),
                  )
                : isDesktop
                ? _buildDesktopTable()
                : _buildMobileList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPatient,
        backgroundColor: kSecondaryColor,
        child: const Icon(Icons.add, color: kWhite, size: 28),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
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
            children: const [
              Text(
                'Kelola Data Master',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(width: 6),
              Icon(Icons.people_outline, color: kSecondaryColor, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Data Pasien',
            style: TextStyle(
              color: kWhite,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      color: kWhite,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nama, nomor RM, atau telepon...',
          prefixIcon: const Icon(Icons.search, color: kTextGrey),
          filled: true,
          fillColor: kScaffoldBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  // Tampilan Daftar untuk Mobile (Futuristic Design)
  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      itemCount: _filteredPatients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
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
              BoxShadow(
                color: kSecondaryColor.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                context.push(
                  '${AppRouter.patients}/${patient.id}',
                  extra: {
                    'name': patient.nama,
                    'mrn': patient.mrn,
                    'phone': patient.telepon,
                    'address': patient.alamat,
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Header dengan Avatar dan Info Utama
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kPrimaryColor, kPrimaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: kWhite,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.nama,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kTextDark,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      kPrimaryColor.withOpacity(0.1),
                                      kPrimaryLight.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: kPrimaryColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  patient.mrn,
                                  style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _GenderBadge(jenisKelamin: patient.jenisKelamin),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Info Details dengan Icon Modern
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kScaffoldBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _ModernInfoRow(
                            icon: Icons.calendar_today_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            label: 'Tanggal Lahir',
                            value:
                                '${_formatDate(patient.tanggalLahir)} (${_calculateAge(patient.tanggalLahir)} th)',
                          ),
                          const SizedBox(height: 12),
                          _ModernInfoRow(
                            icon: Icons.phone_rounded,
                            iconColor: const Color(0xFF22C55E),
                            label: 'Telepon',
                            value: patient.telepon,
                          ),
                          const SizedBox(height: 12),
                          _ModernInfoRow(
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            label: 'Alamat',
                            value: patient.alamat,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons dengan Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kSecondaryColor,
                            kSecondaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: kSecondaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _onRegisterPatient(patient),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.app_registration,
                                  color: kWhite,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Registrasikan Kunjungan',
                                  style: TextStyle(
                                    color: kWhite,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Edit & Delete Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: kPrimaryColor.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _onEditPatient(patient),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.edit_outlined,
                                        color: kPrimaryColor,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _onDeletePatient(patient),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Hapus',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Tampilan Tabel untuk Desktop (dari React)
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 0,
        color: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('No. RM')),
            DataColumn(label: Text('Nama Pasien')),
            DataColumn(label: Text('Jenis Kelamin')),
            DataColumn(label: Text('Usia')),
            DataColumn(label: Text('Telepon')),
            DataColumn(label: Text('Alamat')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _filteredPatients.map((patient) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    patient.mrn,
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        patient.nama,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatDate(patient.tanggalLahir),
                        style: const TextStyle(fontSize: 12, color: kTextGrey),
                      ),
                    ],
                  ),
                ),
                DataCell(_GenderBadge(jenisKelamin: patient.jenisKelamin)),
                DataCell(Text('${_calculateAge(patient.tanggalLahir)} tahun')),
                DataCell(Text(patient.telepon)),
                DataCell(Text(patient.alamat, overflow: TextOverflow.ellipsis)),
                DataCell(
                  Row(
                    children: [
                      // <<< Tombol Registrasikan (DITAMBAHKAN) >>>
                      TextButton.icon(
                        icon: const Icon(Icons.app_registration, size: 14),
                        label: const Text('Registrasi'),
                        style: TextButton.styleFrom(
                          foregroundColor: kSecondaryColor,
                        ),
                        onPressed: () => _onRegisterPatient(patient),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                        ),
                        onPressed: () => _onEditPatient(patient),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text('Hapus'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[700],
                        ),
                        onPressed: () => _onDeletePatient(patient),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// --- WIDGET HELPER ---

// Modern Info Row Widget untuk display informasi dengan style futuristik
class _ModernInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final int maxLines;

  const _ModernInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: kTextGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: kTextDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GenderBadge extends StatelessWidget {
  final String jenisKelamin;
  const _GenderBadge({required this.jenisKelamin});

  @override
  Widget build(BuildContext context) {
    final bool isLaki = jenisKelamin == 'L';
    final gradient = isLaki
        ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])
        : const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]);
    final icon = isLaki ? Icons.male : Icons.female;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isLaki
                ? const Color(0xFF3B82F6).withOpacity(0.3)
                : const Color(0xFFEC4899).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kWhite, size: 16),
          const SizedBox(width: 4),
          Text(
            isLaki ? 'L' : 'P',
            style: const TextStyle(
              color: kWhite,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
