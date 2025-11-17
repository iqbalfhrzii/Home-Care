import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Import halaman detail. Pastikan file ini ada dan class 'Schedule' didefinisikan di sana.
import 'package:homecare_mobile/features/schedules/presentation/pages/schedule_page.dart';

// --- Palet Warna Baru (Futuristic) ---
const Color kPrimaryColor = Color(0xFF004B8C); // Deep Blue
const Color kPrimaryLight = Color(0xFF0063B2); // Lighter Blue for Gradient
const Color kSecondaryColor = Color(0xFF8BC43E); // Lime Green (Action Color)
const Color kScaffoldBg = Color(0xFFF5F7FA); // Cool White Background
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);

// --- 1. Model Data ---
// Diasumsikan class Schedule diimpor dari 'schedule_page.dart'
// Jika tidak, Anda bisa letakkan class Schedule di file model terpisah.

class ScheduleListPage extends StatefulWidget {
  const ScheduleListPage({super.key});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
  // --- Data Dummy (Hanya yang 'disetujui') ---
  final List<Schedule> _allSchedules = [
    Schedule(
      patientName: 'Ahmad Santoso',
      rmNumber: 'RM-2024-001',
      date: DateTime(2024, 11, 8),
      status: 'disetujui',
    ),
    Schedule(
      patientName: 'Budi Hartono',
      rmNumber: 'RM-2024-003',
      date: DateTime(2024, 11, 9),
      status: 'disetujui',
    ),
    Schedule(
      patientName: 'Rudi Setiawan',
      rmNumber: 'RM-2024-005',
      date: DateTime(2024, 11, 10),
      status: 'disetujui',
    ),
    Schedule(
      patientName: 'Linda Wijaya',
      rmNumber: 'RM-2024-006',
      date: DateTime(2024, 11, 10),
      status: 'disetujui',
    ),
    Schedule(
      patientName: 'Maya Sari',
      rmNumber: 'RM-2024-008',
      date: DateTime(2024, 11, 11),
      status: 'disetujui',
    ),
  ];

  // --- State ---
  List<Schedule> _filteredSchedules = [];
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredSchedules = _allSchedules;
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // --- Logika Filter (Disederhanakan) ---
  void _filterSchedules() {
    setState(() {
      if (_selectedDate == null) {
        _filteredSchedules =
            _allSchedules; // Tampilkan semua jika tanggal kosong
        return;
      }

      _filteredSchedules = _allSchedules.where((schedule) {
        // Filter berdasarkan Tanggal
        return (schedule.date.year == _selectedDate!.year &&
            schedule.date.month == _selectedDate!.month &&
            schedule.date.day == _selectedDate!.day);
      }).toList();
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: kWhite,
              onSurface: kTextDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat(
          'd MMMM yyyy',
          'id_ID',
        ).format(pickedDate);
      });
      _filterSchedules();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _dateController.clear();
    });
    _filterSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Header Futuristik
              _buildHeader(),

              // Spacer untuk memberi ruang bagi Filter yang floating
              const SizedBox(height: 60),

              // 3. List Jadwal
              Expanded(
                child: _filteredSchedules.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 60,
                              color: kTextGrey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tidak ada jadwal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTextDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDate == null
                                  ? 'Belum ada data kunjungan.'
                                  : 'Tidak ada jadwal di tanggal ini.',
                              style: const TextStyle(color: kTextGrey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          24,
                          24,
                          100,
                        ), // Tambah padding atas
                        itemCount: _filteredSchedules.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final schedule = _filteredSchedules[index];
                          return _ScheduleCard(schedule: schedule);
                        },
                      ),
              ),
            ],
          ),

          // 2. Filter Section (Floating)
          Positioned(
            top: 130, // Posisi overlap dengan header
            left: 24,
            right: 24,
            child: _FilterSection(
              dateController: _dateController,
              onDateTap: () => _pickDate(context),
              onClearDate: _clearDateFilter,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HEADER ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 180, // Tinggi header
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    'Kelola Jadwal',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.calendar_month_outlined,
                    color: kSecondaryColor,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Kunjungan Pasien',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: kWhite.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_outlined,
                color: kWhite,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET FILTER (Disederhanakan) ---
class _FilterSection extends StatelessWidget {
  final TextEditingController dateController;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;

  const _FilterSection({
    required this.dateController,
    required this.onDateTap,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Berdasarkan Tanggal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 12),
          // Date Picker (Sekarang Full Width)
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: kScaffoldBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: kPrimaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dateController.text.isEmpty
                          ? 'Pilih Tanggal Kunjungan'
                          : dateController.text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dateController.text.isEmpty
                            ? kTextGrey
                            : kTextDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (dateController.text.isNotEmpty)
                    GestureDetector(
                      onTap: onClearDate,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET CARD JADWAL (Badge Dihilangkan) ---
class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SchedulePage(schedule: schedule)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.05), // Bayangan biru
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: kSecondaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTextDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 12,
                            color: kTextGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            schedule.rmNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              color: kTextGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge Status Dihilangkan
              ],
            ),
            const SizedBox(height: 16),
            // Divider
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final boxWidth = constraints.constrainWidth();
                const dashWidth = 6.0;
                final dashCount = (boxWidth / (2 * dashWidth)).floor();
                return Flex(
                  children: List.generate(dashCount, (_) {
                    return SizedBox(
                      width: dashWidth,
                      height: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.grey.shade300),
                      ),
                    );
                  }),
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  direction: Axis.horizontal,
                );
              },
            ),
            const SizedBox(height: 16),
            // Baris Tanggal
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: kPrimaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat(
                    'EEEE, d MMMM yyyy',
                    'id_ID',
                  ).format(schedule.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: kTextGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
