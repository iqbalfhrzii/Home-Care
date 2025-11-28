import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:homecare_mobile/features/schedules/domain/models/registrasi.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';

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
const Color kDangerColor = Color(0xFFEF4444);

// --- Data class untuk schedule item ---
class ScheduleItem {
  final Registrasi registration;
  final Pasien? patient;

  ScheduleItem({required this.registration, this.patient});
}

class ScheduleListPage extends StatefulWidget {
  const ScheduleListPage({super.key});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
  late final RegistrasiRepository _repository;

  List<ScheduleItem> _allSchedules = [];
  List<ScheduleItem> _filteredSchedules = [];
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = true;
  String? _selectedStatus;

  // Progress tracking removed - will be calculated from related records if needed
  int get _notStartedCount => _allSchedules.length; // Stub: all schedules
  int get _inProgressCount => 0; // Stub: progress tracking removed
  int get _completedCount => 0; // Stub: progress tracking removed

  @override
  void initState() {
    super.initState();
    _repository = getIt<RegistrasiRepository>();
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
      final registrations = await _repository.getAllRegistrasi();

      // Deduplicate by unique pasien (registered patients only),
      // keeping the latest registration per patient
      final Map<int, ScheduleItem> latestByPatient = {};
      for (final reg in registrations) {
        final pasienId = reg.pasienId;
        final regTime = DateTime.tryParse(reg.tglJamReg) ?? DateTime(1970);
        final current = latestByPatient[pasienId];
        if (current == null) {
          latestByPatient[pasienId] = ScheduleItem(
            registration: reg,
            patient: reg.pasien,
          );
        } else {
          final currentTime =
              DateTime.tryParse(current.registration.tglJamReg) ??
              DateTime(1970);
          if (regTime.isAfter(currentTime)) {
            latestByPatient[pasienId] = ScheduleItem(
              registration: reg,
              patient: reg.pasien,
            );
          }
        }
      }

      // Build schedules list from the deduped map
      final List<ScheduleItem> schedules = latestByPatient.values.toList();

      // Sort by latest registration time (newest first)
      schedules.sort((a, b) {
        final dateA =
            DateTime.tryParse(a.registration.tglJamReg) ?? DateTime(1970);
        final dateB =
            DateTime.tryParse(b.registration.tglJamReg) ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schedules: $e'),
            backgroundColor: kDangerColor,
          ),
        );
      }
    }
  }

  // --- Logika Filter (Disederhanakan) ---
  void _filterSchedules() {
    setState(() {
      var filtered = _allSchedules;

      // Filter by date
      if (_selectedDate != null) {
        filtered = filtered.where((schedule) {
          final scheduleDate = DateTime.tryParse(
            schedule.registration.tglJamReg,
          );
          if (scheduleDate == null) return false;
          return (scheduleDate.year == _selectedDate!.year &&
              scheduleDate.month == _selectedDate!.month &&
              scheduleDate.day == _selectedDate!.day);
        }).toList();
      }

      // Filter by status (stub - all are 'not started')
      if (_selectedStatus != null) {
        filtered = filtered.where((schedule) {
          // Stub: treat all as not started for now
          return _selectedStatus == 'belum';
        }).toList();
      }

      _filteredSchedules = filtered;
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

  void _selectStatusFilter(String? status) {
    setState(() {
      _selectedStatus = _selectedStatus == status ? null : status;
    });
    _filterSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          if (!_isLoading) _buildStatusCards(),
          _buildFilterSection(),
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
                          size: 64,
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
                    padding: const EdgeInsets.all(24),
                    itemCount: _filteredSchedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final schedule = _filteredSchedules[index];
                      return _ScheduleCard(
                        schedule: schedule,
                        onTap: () {
                          context
                              .push(
                                '/schedules/detail/${schedule.registration.id}',
                              )
                              .then((_) => _loadSchedules());
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelola Jadwal',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kunjungan Pasien',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: kWhite.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _loadSchedules,
                icon: const Icon(Icons.refresh, color: kWhite, size: 22),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: kWhite,
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'Belum Mulai',
              _notStartedCount.toString(),
              kWarningColor,
              Icons.schedule,
              'belum',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatusCard(
              'Proses',
              _inProgressCount.toString(),
              kInfoColor,
              Icons.pending_actions,
              'proses',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatusCard(
              'Selesai',
              _completedCount.toString(),
              kSuccessColor,
              Icons.check_circle,
              'selesai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    Color color,
    IconData icon,
    String statusKey,
  ) {
    final isSelected = _selectedStatus == statusKey;

    return GestureDetector(
      onTap: () => _selectStatusFilter(statusKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? kWhite : color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? kWhite : color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? kWhite : color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: kWhite,
      child: GestureDetector(
        onTap: () => _pickDate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kScaffoldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kTextGrey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: kPrimaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _dateController.text.isEmpty
                      ? 'Pilih Tanggal Kunjungan'
                      : _dateController.text,
                  style: TextStyle(
                    color: _dateController.text.isEmpty ? kTextGrey : kTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_dateController.text.isNotEmpty)
                GestureDetector(
                  onTap: _clearDateFilter,
                  child: Icon(Icons.close, size: 20, color: kDangerColor),
                ),
            ],
          ),
        ),
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
    // Stub: Progress tracking removed, use 0 for all
    final progress = 0;
    final status = schedule.registration.status ?? 'terjadwal';

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kTextGrey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimaryColor, kPrimaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          schedule.patient?.nama.isNotEmpty == true
                              ? schedule.patient!.nama[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.patient?.nama ?? 'Pasien',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kTextDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  schedule.patient?.mrn ?? '—',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Progress Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                            ),
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
                            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(
                              DateTime.tryParse(
                                    schedule.registration.tglJamReg,
                                  ) ??
                                  DateTime.now(),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: kTextDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('HH:mm').format(DateTime.tryParse(schedule.registration.tglJamReg) ?? DateTime.now())} • ${_getStatusText(status)}',
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
        ),
      ),
    );
  }
}
