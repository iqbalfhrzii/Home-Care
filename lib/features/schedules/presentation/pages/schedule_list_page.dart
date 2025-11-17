import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Impor SchedulePage, yang SEHARUSNYA juga berisi definisi class Schedule
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
// CLASS SCHEDULE DIHAPUS DARI SINI
// Kita asumsikan class Schedule didapat dari import 'schedule_page.dart'

class ScheduleListPage extends StatefulWidget {
  const ScheduleListPage({super.key});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
  // --- Data Dummy ---
  // Pastikan class Schedule yang diimpor memiliki constructor yang sama
  final List<Schedule> _allSchedules = [
    Schedule(
      patientName: 'Ahmad Santoso',
      rmNumber: 'RM-2024-001',
      date: DateTime(2024, 11, 8),
      status: 'disetujui',
    ),
    Schedule(
      patientName: 'Siti Nurhaliza',
      rmNumber: 'RM-2024-002',
      date: DateTime(2024, 11, 8),
      status: 'belum_disetujui',
    ),
    Schedule(
      patientName: 'Budi Hartono',
      rmNumber: 'RM-2024-003',
      date: DateTime(2024, 11, 9),
      status: 'disetujui',
    ),
    // ... sisa data dummy
  ];

  // --- State ---
  List<Schedule> _filteredSchedules = [];
  String _selectedStatus = 'semua';
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

  void _filterSchedules() {
    setState(() {
      _filteredSchedules = _allSchedules.where((schedule) {
        final statusMatch =
            _selectedStatus == 'semua' || schedule.status == _selectedStatus;
        final dateMatch =
            _selectedDate == null ||
            (schedule.date.year == _selectedDate!.year &&
                schedule.date.month == _selectedDate!.month &&
                schedule.date.day == _selectedDate!.day);
        return statusMatch && dateMatch;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 60),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
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
          Positioned(
            top: 130, // Posisi overlap dengan header
            left: 24,
            right: 24,
            child: _FilterSection(
              statusValue: _selectedStatus,
              dateController: _dateController,
              onStatusChanged: (newValue) {
                if (newValue == null) return;
                setState(() => _selectedStatus = newValue);
                _filterSchedules();
              },
              onDateTap: () => _pickDate(context),
              onClearDate: () {
                setState(() {
                  _selectedDate = null;
                  _dateController.clear();
                });
                _filterSchedules();
              },
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

// --- WIDGET FILTER ---
class _FilterSection extends StatelessWidget {
  final String statusValue;
  final TextEditingController dateController;
  final Function(String?) onStatusChanged;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;

  const _FilterSection({
    required this.statusValue,
    required this.dateController,
    required this.onStatusChanged,
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
            'Filter Pencarian',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Dropdown Status
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kScaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: statusValue,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: kPrimaryColor,
                      ),
                      isExpanded: true,
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: onStatusChanged,
                      items: const [
                        DropdownMenuItem(value: 'semua', child: Text('Semua')),
                        DropdownMenuItem(
                          value: 'disetujui',
                          child: Text('Disetujui'),
                        ),
                        DropdownMenuItem(
                          value: 'belum_disetujui',
                          child: Text('Pending'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Date Picker
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: onDateTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: kScaffoldBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: kPrimaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateController.text.isEmpty
                                ? 'Pilih Tanggal'
                                : dateController.text,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: dateController.text.isEmpty
                                  ? kTextGrey
                                  : kTextDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (dateController.text.isNotEmpty)
                          GestureDetector(
                            onTap: onClearDate,
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- WIDGET CARD JADWAL ---
class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // --- PERBAIKAN DI SINI ---
        // Hapus 'as dynamic' dan pastikan SchedulePage menerima objek Schedule
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SchedulePage(schedule: schedule)),
        );
        // -------------------------
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
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
                _StatusBadge(status: schedule.status),
              ],
            ),
            const SizedBox(height: 16),
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

// --- WIDGET BADGE STATUS ---
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isApproved = status == 'disetujui';

    final Color bgColor = isApproved
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFFF7ED);
    final Color textColor = isApproved
        ? const Color(0xFF059669)
        : const Color(0xFFEA580C);
    final String text = isApproved ? 'Disetujui' : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
