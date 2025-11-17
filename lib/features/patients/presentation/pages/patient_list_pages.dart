import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homecare_mobile/features/patients/presentation/pages/add_patient_page.dart';
import 'package:homecare_mobile/features/patients/presentation/pages/patient_detail_pages.dart';
import 'package:homecare_mobile/shared/widgets/summary_card.dart';

// --- Palet Warna (dari desain Anda) ---
const Color kPrimaryColor = Color(0xFF002F67);
const Color kAccentColor = Color(0xFF3F51B5);
const Color kWhiteColor = Colors.white;
const Color kScaffoldBg = Color(0xFFF8F9FA);
const Color kFabGreen = Color(0xFF16A34A);

const Color kBadgeGreenBg = Color(0xFFE0F2E9);
const Color kBadgeGreenText = Color(0xFF006437);
const Color kBadgeOrangeBg = Color(0xFFFFF4E6);
const Color kBadgeOrangeText = Color(0xFFB45309);

class RegistrationEntry {
  final String patientName;
  final String mrn;
  final String registrationId;
  final DateTime dateTime;
  final String phone;
  final String visitType;
  final String status; // 'disetujui' atau 'pending'

  RegistrationEntry({
    required this.patientName,
    required this.mrn,
    required this.registrationId,
    required this.dateTime,
    required this.phone,
    required this.visitType,
    required this.status,
  });
}

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage>
    with SingleTickerProviderStateMixin {
  final List<RegistrationEntry> _allRegistrations = [
    RegistrationEntry(
      patientName: 'Rudi Santoso',
      mrn: 'MRN001234',
      registrationId: 'R09254411',
      dateTime: DateTime(2025, 11, 11, 8, 30),
      phone: '081234567890',
      visitType: 'Rawat Jalan',
      status: 'disetujui',
    ),
    RegistrationEntry(
      patientName: 'Siti Nurhaliza',
      mrn: 'MRN001235',
      registrationId: 'R09254412',
      dateTime: DateTime(2025, 11, 11, 9, 15),
      phone: '081298765432',
      visitType: 'Rawat Inap',
      status: 'pending',
    ),
    RegistrationEntry(
      patientName: 'Ahmad Hidayat',
      mrn: 'MRN001236',
      registrationId: 'R09254413',
      dateTime: DateTime(2025, 11, 11, 10, 0),
      phone: '081345678567',
      visitType: 'Rawat Jalan',
      status: 'disetujui',
    ),
    RegistrationEntry(
      patientName: 'Dewi Lestari',
      mrn: 'MRN001237',
      registrationId: 'R09254414',
      dateTime: DateTime(2025, 11, 11, 11, 30),
      phone: '081445566778',
      visitType: 'IGD',
      status: 'pending',
    ),
  ];

  late List<RegistrationEntry> _filteredRegistrations;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredRegistrations = List.from(_allRegistrations);
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_filterList);
    _tabController.addListener(_filterList);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterList);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _filterList() {
    final searchQuery = _searchController.text.toLowerCase();
    final tabIndex = _tabController.index;

    setState(() {
      _filteredRegistrations = _allRegistrations.where((entry) {
        bool statusMatch;
        if (tabIndex == 1) {
          statusMatch = entry.status == 'disetujui';
        } else if (tabIndex == 2) {
          statusMatch = entry.status == 'pending';
        } else {
          statusMatch = true;
        }

        final bool searchMatch =
            searchQuery.isEmpty ||
            entry.patientName.toLowerCase().contains(searchQuery) ||
            entry.mrn.toLowerCase().contains(searchQuery) ||
            entry.registrationId.toLowerCase().contains(searchQuery);

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        title: const Text('Daftar Pasien'),
        backgroundColor: kPrimaryColor,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Disetujui'),
              Tab(text: 'Pending'),
            ],
            labelColor: kPrimaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kPrimaryColor,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PatientListView(
                  patients: _filteredRegistrations,
                  onTap: _onEntryTap,
                ),
                _PatientListView(
                  patients: _filteredRegistrations
                      .where((e) => e.status == 'disetujui')
                      .toList(),
                  onTap: _onEntryTap,
                ),
                _PatientListView(
                  patients: _filteredRegistrations
                      .where((e) => e.status == 'pending')
                      .toList(),
                  onTap: _onEntryTap,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPressed,
        backgroundColor: kFabGreen,
        child: const Icon(Icons.add, color: kWhiteColor),
      ),
    );
  }

  Future<void> _onEntryTap(RegistrationEntry entry) async {
    final res = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => PatientDetailPage(
          patientData: {'name': entry.patientName, 'mrn': entry.mrn},
        ),
      ),
    );
    if (res != null) {
      if (res['action'] == 'delete') {
        setState(
          () => _allRegistrations.removeWhere(
            (e) => e.registrationId == entry.registrationId,
          ),
        );
        _filterList();
      } else if (res['action'] == 'edit' &&
          res['data'] is Map<String, String>) {
        final updated = res['data'] as Map<String, String>;
        setState(() {
          final idx = _allRegistrations.indexWhere(
            (e) => e.registrationId == entry.registrationId,
          );
          if (idx != -1) {
            _allRegistrations[idx] = RegistrationEntry(
              patientName: updated['name'] ?? entry.patientName,
              mrn: updated['mrn'] ?? entry.mrn,
              registrationId: entry.registrationId,
              dateTime: entry.dateTime,
              phone: updated['phone'] ?? entry.phone,
              visitType: entry.visitType,
              status: entry.status,
            );
          }
        });
        _filterList();
      }
    }
  }

  Future<void> _onAddPressed() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const AddPatientRegistrationPage()),
    );
    if (result != null) {
      final name = result['name'] ?? 'Pasien Baru';
      final mrn = result['mrn'] ?? '';
      final newEntry = RegistrationEntry(
        patientName: name,
        mrn: mrn,
        registrationId: 'LOCAL-${DateTime.now().millisecondsSinceEpoch}',
        dateTime: DateTime.now(),
        phone: '-',
        visitType: '',
        status: 'pending',
      );
      setState(() => _allRegistrations.insert(0, newEntry));
      _filterList();
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: 8),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Pasien',
              style: TextStyle(
                color: kWhiteColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kelola dan pantau status pendaftaran',
              style: TextStyle(color: kWhiteColor, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: SummaryCard(
                    count: '${_allRegistrations.length}',
                    label: 'Total',
                    icon: Icons.people,
                    color: kAccentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: SummaryCard(
                    count:
                        '${_allRegistrations.where((e) => e.status == "disetujui").length}',
                    label: 'Disetujui',
                    icon: Icons.check_circle,
                    color: kFabGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: SummaryCard(
                    count:
                        '${_allRegistrations.where((e) => e.status == "pending").length}',
                    label: 'Pending',
                    icon: Icons.pending,
                    color: kBadgeOrangeText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: kWhiteColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nama atau No. RM...',
          prefixIcon: const Icon(Icons.search),
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
}

class _PatientListView extends StatelessWidget {
  final List<RegistrationEntry> patients;
  final Future<void> Function(RegistrationEntry)? onTap;
  const _PatientListView({required this.patients, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data pasien ditemukan.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: kAccentColor.withAlpha(
                        (0.1 * 255).round(),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: kAccentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.patientName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            patient.mrn,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: patient.status),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('d MMMM yyyy').format(patient.dateTime),
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        if (onTap != null) await onTap!(patient);
                      },
                      child: const Text('Detail'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isApproved = status == 'disetujui';
    final Color color = isApproved ? kBadgeGreenBg : kBadgeOrangeBg;
    final Color textColor = isApproved ? kBadgeGreenText : kBadgeOrangeText;
    final String text = isApproved ? 'Disetujui' : 'Pending';
    final IconData icon = isApproved
        ? Icons.check_circle_outline
        : Icons.pending_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
