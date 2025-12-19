import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/patients/data/repositories/pasien_repository.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart'
    as db;
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:homecare_mobile/features/reports/data/repositories/tagihan_repository.dart';
import 'package:homecare_mobile/features/schedules/domain/models/registrasi.dart'
    as db;
import 'package:intl/intl.dart';
import 'package:homecare_mobile/features/auth/presentation/widgets/logout_confirmation_dialog.dart';

// --- Palet Warna Baru ---
const Color kPrimaryColor = Color(0xFF004B8C); // Deep Blue
const Color kPrimaryLight = Color(0xFF0063B2); // Lighter Blue for Gradient
const Color kSecondaryColor = Color(0xFF8BC43E); // Lime Green (Action Color)
const Color kScaffoldBg = Color(0xFFF5F7FA); // Cool White Background
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);

// --- Tipe Data untuk Mock (Diambil dari React) ---
class StatInfo {
  final int id;
  final String label;
  final String value;
  final String change;
  final String trend;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadow;

  StatInfo({
    required this.id,
    required this.label,
    required this.value,
    required this.change,
    required this.trend,
    required this.icon,
    required this.gradient,
    required this.shadow,
  });
}

class NotificationInfo {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String type;
  final bool persistent; // stays in bottom notifications
  bool read; // mutable: whether header popup item has been read

  NotificationInfo({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.type,
    this.persistent = false,
    this.read = false,
  });
}

// DISABLED - Kunjungan table removed in schema v7
// class UpcomingVisit {
//   final db.Registrasi registration;
//   final db.Pasien patient;
//   final db.Kunjungan? visit;
//
//   UpcomingVisit({
//     required this.registration,
//     required this.patient,
//     this.visit,
//   });
// }

// Simple local join object (top-level)
class _UpcomingVisit {
  final db.Registrasi registration;
  final db.Pasien patient;
  const _UpcomingVisit({required this.registration, required this.patient});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _selectedDate;
  List<DateTime> _weekDays = [];
  // Built from Registrasi + Pasien (dummy repositories)
  final List<_UpcomingVisit> _upcomingVisits = [];
  bool _isLoadingVisits = true;

  // Stats data
  int _totalPatients = 0;
  int _totalVisits = 0;
  int _pendingVisits = 0; // jumlah kunjungan pending (belum memiliki tagihan)
  int _completeRegistrations =
      0; // registrasi dengan data lengkap (anamnesa, tindakan, icd)
  bool _isLoadingStats = true;

  // Notifications data
  List<NotificationInfo> _importantNotifications = [];
  bool _isLoadingNotifications = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekDays = _generateWeekDays(DateTime.now());
    _loadUpcomingVisits();
    _loadStats();
    _loadNotifications();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);

    try {
      final pasienRepo = getIt<PasienRepository>();
      final regRepo = getIt<RegistrasiRepository>();
      final patients = await pasienRepo.getAllPasien();
      final regs = await regRepo.getAllRegistrasi();

      // De-duplicate patients using IDs from both `/pasien` and `/registrasi`
      final uniquePatientIds = <int>{};
      for (final p in patients) {
        uniquePatientIds.add(p.id);
      }
      for (final r in regs) {
        final pid = r.pasienId;
        if (pid != null) uniquePatientIds.add(pid);
      }

      // Calculate progress and pending visits using same logic as schedule page
      int pendingCount = 0;
      int completeCount = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final r in regs) {
        // Calculate progress from complete data (same as schedule page)
        int progress = 0;
        final rawData = r.toJson();

        // Check tindakan
        final tindakanList = rawData['tindakan'] as List?;
        final hasTindakan = tindakanList != null && tindakanList.isNotEmpty;
        if (hasTindakan) progress += 1;

        // Check ICD
        final icdList = rawData['icd'] as List?;
        final hasIcd = icdList != null && icdList.isNotEmpty;
        if (hasIcd) progress += 1;

        // Check anamnesa (vital signs)
        final anamnesaData = rawData['anamnesa'];
        bool hasAnamnesa = false;
        if (anamnesaData != null && anamnesaData is Map) {
          final pengkajianKeperawatan = anamnesaData['pengkajian_keperawatan'];
          if (pengkajianKeperawatan != null && pengkajianKeperawatan is Map) {
            final tandaVital = pengkajianKeperawatan['tanda_vital'];
            if (tandaVital != null && tandaVital is Map && tandaVital.isNotEmpty) {
              final hasTekananDarah = tandaVital['tekanan_darah']?.toString().isNotEmpty == true;
              final hasNadi = tandaVital['nadi'] != null;
              final hasSuhu = tandaVital['suhu'] != null;
              final hasPernapasan = tandaVital['pernapasan'] != null;
              hasAnamnesa = hasTekananDarah || hasNadi || hasSuhu || hasPernapasan;
            }
          }
        }
        if (hasAnamnesa) progress += 1;

        // Check if overdue (same logic as schedule page)
        final dateStr = r.tglJamReg;
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null) {
            final scheduleDate = DateTime(dt.year, dt.month, dt.day);
            final isOverdue = scheduleDate.isBefore(today) && progress < 3;
            if (isOverdue) pendingCount++;
          }
        }

        // Count complete registrations
        if (progress == 3) completeCount++;
      }

      if (mounted) {
        setState(() {
          _totalPatients = uniquePatientIds.length;
          _totalVisits = regs.length;
          _pendingVisits = pendingCount; // Now matches schedule page logic
          _completeRegistrations = completeCount;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoadingNotifications = true);

    try {
      final regRepo = getIt<RegistrasiRepository>();
      final regs = await regRepo.getAllRegistrasi();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final notifications = <NotificationInfo>[]; // persistent bottom list

      // Count today's visits
      final todayVisits = regs.where((r) {
        final ts = r.tglJamReg;
        if (ts == null) return false;
        final dt = DateTime.tryParse(ts);
        if (dt == null) return false;
        return dt.year == today.year &&
            dt.month == today.month &&
            dt.day == today.day;
      }).length;

      if (todayVisits > 0) {
        final n = NotificationInfo(
          id: 'today_visits',
          icon: Icons.medical_services,
          title: 'Kunjungan Hari Ini',
          subtitle: '$todayVisits pasien menunggu',
          type: 'visit',
          persistent: true,
        );
        notifications.add(n);
      }

      // Check for visits within 1 hour
      final upcomingSoon = regs.where((r) {
        final ts = r.tglJamReg;
        if (ts == null) return false;
        final dt = DateTime.tryParse(ts);
        if (dt == null) return false;
        final diff = dt.difference(now);
        return diff.inMinutes > 0 && diff.inMinutes <= 60;
      }).length;

      if (upcomingSoon > 0) {
        final n = NotificationInfo(
          id: 'upcoming_soon',
          icon: Icons.alarm,
          title: 'Kunjungan Segera',
          subtitle: '$upcomingSoon dalam 1 jam',
          type: 'urgent',
          persistent: true,
        );
        notifications.add(n);
      }

      if (mounted) {
        setState(() {
          _importantNotifications = notifications;
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoadingNotifications = false);
      }
    }
  }

  Future<void> _loadUpcomingVisits() async {
    setState(() => _isLoadingVisits = true);

    try {
      final pasienRepo = getIt<PasienRepository>();
      final regRepo = getIt<RegistrasiRepository>();
      final patients = await pasienRepo.getAllPasien();
      final regs = await regRepo.getAllRegistrasi();

      final filtered = regs.where((r) {
        final ts = r.tglJamReg;
        if (ts == null) return false;
        final dt = DateTime.tryParse(ts);
        if (dt == null) return false;
        return dt.year == _selectedDate.year &&
            dt.month == _selectedDate.month &&
            dt.day == _selectedDate.day;
      }).toList();

      final visits = <_UpcomingVisit>[];
      for (final reg in filtered) {
        // Prefer embedded patient from registrasi response if present
        db.Pasien? patient;
        try {
          // Many APIs embed `pasien` under registrasi; if your domain model maps it,
          // prefer that to avoid lookup mismatches.
          final embedded = (reg as dynamic).pasien;
          if (embedded != null && embedded is db.Pasien) {
            patient = embedded;
          }
        } catch (_) {
          // ignore cast errors; fall back to lookup below
        }

        if (patient == null) {
          final pid = reg.pasienId;
          patient = patients.firstWhere(
            (p) => p.id == pid,
            orElse: () => patients.isNotEmpty
                ? patients.first
                : db.Pasien(
                    id: 0,
                    mrn: 'MRN-NA',
                    nama: 'Tidak diketahui',
                    alamat: '-',
                    tanggalLahir: '',
                    jenisKelamin: '',
                    telepon: '',
                    createdAt: '',
                    updatedAt: '',
                    registrasi: const [],
                  ),
          );
        }
        visits.add(_UpcomingVisit(registration: reg, patient: patient));
      }

      visits.sort((a, b) {
        final da = DateTime.tryParse(a.registration.tglJamReg ?? '');
        final dbt = DateTime.tryParse(b.registration.tglJamReg ?? '');
        return (da ?? DateTime(1970)).compareTo(dbt ?? DateTime(1970));
      });
      if (mounted) {
        setState(() {
          _upcomingVisits
            ..clear()
            ..addAll(visits);
          _isLoadingVisits = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading upcoming visits: $e');
      if (mounted) {
        setState(() => _isLoadingVisits = false);
      }
    }
  }

  // Removed unused helper to satisfy analyzer

  // --- LOGIKA KALENDER ---
  List<DateTime> _generateWeekDays(DateTime today) {
    int daysToSubtract = today.weekday - 1;
    DateTime startOfWeek = today.subtract(Duration(days: daysToSubtract));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _changeWeek(int direction) {
    setState(() {
      DateTime currentWeekStart = _weekDays.first;
      DateTime newWeekStart = currentWeekStart.add(
        Duration(days: 7 * direction),
      );
      _weekDays = _generateWeekDays(newWeekStart);
      DateTime startOfThisWeek = _generateWeekDays(DateTime.now()).first;
      if (_isSameDay(_weekDays.first, startOfThisWeek)) {
        _selectedDate = DateTime.now();
      } else {
        _selectedDate = _weekDays.first;
      }
    });
    _loadUpcomingVisits();
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: kWhite,
              onSurface: kTextDark,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && !_isSameDay(pickedDate, _selectedDate)) {
      setState(() {
        _selectedDate = pickedDate;
        _weekDays = _generateWeekDays(pickedDate);
      });
      _loadUpcomingVisits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: kPrimaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: kScaffoldBg,
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _loadUpcomingVisits(),
                _loadStats(),
                _loadNotifications(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Add bottom padding so content won't be clipped by system UI or
              // bottom navigation bars. Keeps visit cards from overflowing.
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFuturisticHeader(),
                  const SizedBox(height: 16),
                  _buildDateSelector(),
                  const SizedBox(height: 16),
                  _buildNextVisitCard(),
                  const SizedBox(height: 16),
                  _buildInsights(),
                  const SizedBox(height: 16),
                  _buildImportantNotifications(),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  // PERBAIKAN LENGKAP UNTUK HOMEPAGE
  // Ganti method-method berikut di HomePage Anda:

  // 1. PERBAIKAN HEADER - Tambahkan SafeArea
  Widget _buildFuturisticHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        24,
      ),
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'Selamat Pagi',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.wb_sunny_outlined,
                      color: kSecondaryColor,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dr. Iqbal Fahrozi',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: kWhite.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // header notification icon removed
                    child: const SizedBox.shrink(),
                  ),
                  // no header badge
                ],
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: kWhite.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: kWhite, size: 20),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. PERBAIKAN DATE SELECTOR - Constraint pada month text
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: kPrimaryColor,
                  size: 26,
                ),
                onPressed: () => _changeWeek(-1),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          DateFormat('MMMM yyyy').format(_weekDays.first),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kTextDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.calendar_month_outlined,
                        color: kPrimaryColor.withValues(alpha: 0.7),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: kPrimaryColor,
                  size: 26,
                ),
                onPressed: () => _changeWeek(1),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: _weekDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final date = _weekDays[index];
              final isSelected = _isSameDay(date, _selectedDate);
              final dayOfWeek = DateFormat.E().format(date).toUpperCase();
              final dayOfMonth = date.day.toString();

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                  _loadUpcomingVisits();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [kPrimaryColor, kPrimaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : kWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: kPrimaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayOfWeek,
                        style: TextStyle(
                          color: isSelected
                              ? kWhite.withValues(alpha: 0.8)
                              : kTextGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayOfMonth,
                        style: TextStyle(
                          color: isSelected ? kWhite : kTextDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: kSecondaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNextVisitCard() {
    if (_isLoadingVisits) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 200,
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    if (_upcomingVisits.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kPrimaryColor, Color(0xFF003366)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: kWhite.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada kunjungan',
              style: TextStyle(
                color: kWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada jadwal kunjungan pada tanggal ini',
              style: TextStyle(
                color: kWhite.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Jika hanya 1 kunjungan, tampilkan normal tanpa scroll
    if (_upcomingVisits.length == 1) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildVisitCard(_upcomingVisits.first, 0),
      );
    }

    // Jika lebih dari 1, tampilkan horizontal scroll
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text(
                'KUNJUNGAN BERIKUTNYA',
                style: TextStyle(
                  color: kTextGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_upcomingVisits.length}',
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _upcomingVisits.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < _upcomingVisits.length - 1 ? 16 : 0,
                ),
                child: _buildVisitCard(_upcomingVisits[index], index),
              );
            },
          ),
        ),
      ],
    );
  }

  // Perbaikan untuk _buildVisitCard - area yang overflow
  Widget _buildVisitCard(dynamic visit, int index) {
    final isFirst = index == 0;

    return Container(
      width: _upcomingVisits.length > 1 ? 300 : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFirst
              ? [kPrimaryColor, const Color(0xFF003366)]
              : [const Color(0xFF0063B2), kPrimaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFirst && _upcomingVisits.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: kSecondaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TERDEKAT',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              Text(
                visit.patient.nama,
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                visit.patient.mrn,
                style: TextStyle(
                  color: kWhite.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: kSecondaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('HH:mm', 'id_ID').format(
                            DateTime.parse(visit.registration.tglJamReg),
                          ),
                          style: const TextStyle(
                            color: kWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: kSecondaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            visit.patient.alamat,
                            style: const TextStyle(color: kWhite, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/schedules/detail/${visit.registration.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSecondaryColor,
                    foregroundColor: kWhite,
                    elevation: 6,
                    shadowColor: kSecondaryColor.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Mulai Kunjungan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PERBAIKAN ALTERNATIF: Jika masih overflow, gunakan layout ini
  Widget _buildVisitCardAlternative(dynamic visit, int index) {
    final isFirst = index == 0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: _upcomingVisits.length > 1 ? 320 : double.infinity,
        minHeight: 200,
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isFirst
                    ? [kPrimaryColor, Color(0xFF003366)]
                    : [Color(0xFF0063B2), kPrimaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: isFirst ? 0.4 : 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFirst && _upcomingVisits.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kSecondaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'TERDEKAT',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Nama dengan max 2 lines
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 50),
                  child: Text(
                    visit.patient.nama,
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 18, // Sedikit dikecilkan
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  visit.patient.mrn,
                  style: TextStyle(
                    color: kWhite.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),

                // Info waktu dan lokasi dalam Column (bukan Row)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: kSecondaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('HH:mm', 'id_ID').format(
                              DateTime.parse(visit.registration.tglJamReg),
                            ),
                            style: const TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: kSecondaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              visit.patient.alamat,
                              style: const TextStyle(
                                color: kWhite,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(
                        '/schedules/detail/${visit.registration.id}',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSecondaryColor,
                      foregroundColor: kWhite,
                      elevation: 8,
                      shadowColor: kSecondaryColor.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Mulai Kunjungan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.medical_services_outlined,
              size: 100,
              color: kWhite.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  // <<< WIDGET BARU >>>
  Widget _buildInsights() {
    if (_isLoadingStats) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 150,
          child: const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          ),
        ),
      );
    }

    final stats = [
      StatInfo(
        id: 1,
        label: 'Total Pasien',
        value: '$_totalPatients',
        change: '',
        trend: 'up',
        icon: Icons.people_outline,
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        shadow: const Color(0xFF3B82F6).withValues(alpha: 0.3),
      ),
      StatInfo(
        id: 2,
        label: 'Total Kunjungan',
        value: '$_totalVisits',
        change: '',
        trend: 'up',
        icon: Icons.medical_services_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
        ),
        shadow: const Color(0xFF22C55E).withValues(alpha: 0.3),
      ),
      StatInfo(
        id: 3,
        label: 'Kunjungan Pending',
        value: '$_pendingVisits',
        change: '',
        trend: 'up',
        icon: Icons.article_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        ),
        shadow: const Color(0xFFF97316).withValues(alpha: 0.3),
      ),
      StatInfo(
        id: 4,
        label: 'Data Lengkap',
        value: '$_completeRegistrations',
        change: '',
        trend: 'up',
        icon: Icons.monitor_heart_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
        ),
        shadow: const Color(0xFFA855F7).withValues(alpha: 0.3),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.trending_up, color: kPrimaryColor, size: 18),
              SizedBox(width: 8),
              Text(
                'Insight & Analytics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 12) / 2;
              final cardHeight = cardWidth * 0.85;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats.map((stat) {
                  return SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _StatCard(stat: stat),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // <<< WIDGET DIPERBARUI >>>
  Widget _buildImportantNotifications() {
    if (_isLoadingNotifications) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 150,
          child: const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          ),
        ),
      );
    }

    if (_importantNotifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NOTIFIKASI PENTING',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: kTextGrey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 48,
                      color: kTextGrey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tidak ada notifikasi',
                      style: TextStyle(color: kTextGrey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTIFIKASI PENTING',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: kTextGrey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          // Menggunakan GridView agar lebih dinamis
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: _importantNotifications.map((notif) {
              return _NotificationCard(
                notification: notif,
                onTap: () {
                  // TODO: Navigate based on notification type
                  if (notif.type == 'visit') {
                    // Navigate to schedules
                    context.go('/schedules');
                  } else if (notif.type == 'anamnesa') {
                    // Navigate to specific schedule detail
                    context.go('/schedules');
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // <<< WIDGET BARU >>>
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: kTextGrey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: [
              _QuickActionButton(
                label: 'Pasien',
                icon: Icons.people_outline,
                onTap: () => context.go(AppRouter.patients),
              ),
              _QuickActionButton(
                label: 'Jadwal',
                icon: Icons.playlist_add_check_rounded,
                onTap: () => context.go(AppRouter.schedules),
              ),
              _QuickActionButton(
                label: 'Laporan',
                icon: Icons.article_outlined,
                onTap: () => context.go(AppRouter.reports),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- WIDGET KARTU STATISTIK (INSIGHT) ---
class _StatCard extends StatelessWidget {
  final StatInfo stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final bool isPositive = stat.trend == 'up';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: stat.gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: stat.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(stat.icon, color: kWhite, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            stat.label,
            style: const TextStyle(color: kTextGrey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  stat.value,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (stat.change.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? kSecondaryColor.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stat.change,
                    style: TextStyle(
                      color: isPositive ? kSecondaryColor : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// --- WIDGET KARTU NOTIFIKASI (STYLE BARU DARI REACT) ---
class _NotificationCard extends StatelessWidget {
  final NotificationInfo notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryColor, kPrimaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kWhite.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon, color: kWhite, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            notification.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kWhite,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            notification.subtitle,
            style: TextStyle(
              color: kWhite.withValues(alpha: 0.7),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Menuju Tugas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: kSecondaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET TOMBOL QUICK ACTION ---
class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kWhite,
        foregroundColor: kPrimaryColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: kPrimaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
