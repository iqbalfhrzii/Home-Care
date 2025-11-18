import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart' as db;

// --- Palet Warna Baru (Futuristic) ---
const Color kPrimaryColor = Color(0xFF004B8C); // Deep Blue
const Color kPrimaryLight = Color(0xFF0063B2); // Lighter Blue for Gradient
const Color kSecondaryColor = Color(0xFF8BC43E); // Lime Green (Action Color)
const Color kScaffoldBg = Color(0xFFF5F7FA); // Cool White Background
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kInfoColor = Color(0xFF3B82F6);

// --- Data class untuk schedule item ---
class ScheduleItem {
  final db.Registrasi registration;
  final db.Pasien patient;
  final db.Kunjungan? visit;

  ScheduleItem({
    required this.registration,
    required this.patient,
    this.visit,
  });
}

class ScheduleListPage extends StatefulWidget {
  const ScheduleListPage({super.key});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
  late final db.AppDatabase _database;
  
  // --- State ---
  List<ScheduleItem> _allSchedules = [];
  List<ScheduleItem> _filteredSchedules = [];
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _database = getIt<db.AppDatabase>();
    _loadSchedules();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final registrations = await _database.getAllRegistrasis();
      final List<ScheduleItem> schedules = [];

      for (final reg in registrations) {
        final patient = await _database.getPasienById(reg.pasienId);
        if (patient == null || !patient.isRegistered) continue;

        final visit = await _database.getKunjunganByRegistrasiId(reg.id);
        schedules.add(ScheduleItem(
          registration: reg,
          patient: patient,
          visit: visit,
        ));
      }

      schedules.sort((a, b) => b.registration.tanggalKunjungan
          .compareTo(a.registration.tanggalKunjungan));

      if (mounted) {
        setState(() {
          _allSchedules = schedules;
          _filteredSchedules = schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading schedules: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Logika Filter (Disederhanakan) ---
  void _filterSchedules() {
    setState(() {
      if (_selectedDate == null) {
        _filteredSchedules = _allSchedules;
        return;
      }

      _filteredSchedules = _allSchedules.where((schedule) {
        final scheduleDate = schedule.registration.tanggalKunjungan;
        return (scheduleDate.year == _selectedDate!.year &&
            scheduleDate.month == _selectedDate!.month &&
            scheduleDate.day == _selectedDate!.day);
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      )
                    : _filteredSchedules.isEmpty
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
                          return _ScheduleCard(
                            schedule: schedule,
                            onTap: () {
                              context.push(
                                '/schedules/detail/${schedule.registration.id}',
                              ).then((_) => _loadSchedules());
                            },
                          );
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
              onPressed: _loadSchedules,
              icon: const Icon(
                Icons.refresh,
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

// --- WIDGET CARD JADWAL ---
class _ScheduleCard extends StatelessWidget {
  final ScheduleItem schedule;
  final VoidCallback onTap;
  const _ScheduleCard({required this.schedule, required this.onTap});

  Color _getProgressColor(int progress) {
    switch (progress) {
      case 0:
        return kWarningColor;
      case 1:
        return kInfoColor;
      case 2:
        return const Color(0xFF8B5CF6);
      case 3:
        return kSuccessColor;
      default:
        return kTextGrey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'terjadwal':
        return 'Terjadwal';
      case 'dalam_proses':
        return 'Berlangsung';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return 'Terjadwal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = schedule.visit?.progressStep ?? 0;
    final status = schedule.visit?.status ?? 'terjadwal';

    return InkWell(
      onTap: onTap,
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
                        schedule.patient.nama,
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
                            schedule.patient.noRm,
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
                // Progress Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getProgressColor(progress).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.checklist,
                        color: _getProgressColor(progress),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$progress/3',
                        style: TextStyle(
                          color: _getProgressColor(progress),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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
            // Baris Tanggal & Status
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(schedule.registration.tanggalKunjungan),
                        style: const TextStyle(
                          fontSize: 13,
                          color: kTextDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${schedule.registration.jamKunjungan} • ${_getStatusText(status)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: kTextGrey,
                        ),
                      ),
                    ],
                  ),
                ),
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
