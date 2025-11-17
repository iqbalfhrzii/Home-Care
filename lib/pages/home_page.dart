import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';
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

  NotificationInfo({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _selectedDate;
  List<DateTime> _weekDays = [];

  // --- Mock Data (Diambil dari React) ---
  final List<NotificationInfo> notifications = [
    NotificationInfo(
      id: '1',
      icon: Icons.home_work_outlined, // HomeIcon
      title: 'Kunjungan ke rumah Akmal',
      subtitle: 'RM-2024-002',
      type: 'visit',
    ),
    NotificationInfo(
      id: '2',
      icon: Icons.playlist_add_check_rounded, // ClipboardCheck
      title: 'Input Anamnesa Akmal',
      subtitle: 'REG-2024-003 - Belum diisi',
      type: 'anamnesa',
    ),
  ];

  final List<StatInfo> stats = [
    StatInfo(
      id: 1,
      label: 'Total Pasien',
      value: '45',
      change: '+12%',
      trend: 'up',
      icon: Icons.people_outline, // Users
      gradient: const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
      ),
      shadow: const Color(0xFF3B82F6).withOpacity(0.3),
    ),
    StatInfo(
      id: 2,
      label: 'Kunjungan Hari Ini',
      value: '8',
      change: '+5',
      trend: 'up',
      icon: Icons.playlist_add_check_rounded, // ClipboardCheck
      gradient: const LinearGradient(
        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
      ),
      shadow: const Color(0xFF22C55E).withOpacity(0.3),
    ),
    StatInfo(
      id: 3,
      label: 'Tagihan Pending',
      value: '3',
      change: '-2',
      trend: 'down',
      icon: Icons.article_outlined, // FileText
      gradient: const LinearGradient(
        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
      ),
      shadow: const Color(0xFFF97316).withOpacity(0.3),
    ),
    StatInfo(
      id: 4,
      label: 'Data Lengkap',
      value: '75%',
      change: '+8%',
      trend: 'up',
      icon: Icons.monitor_heart_outlined, // Activity
      gradient: const LinearGradient(
        colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
      ),
      shadow: const Color(0xFFA855F7).withOpacity(0.3),
    ),
  ];
  // --- Akhir Mock Data ---

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekDays = _generateWeekDays(DateTime.now());
  }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFuturisticHeader(),
            const SizedBox(height: 24),
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildNextVisitCard(),
            const SizedBox(height: 24),
            // --- PERUBAHAN ---
            _buildInsights(), // Ditambahkan
            const SizedBox(height: 24),
            _buildImportantNotifications(), // Diperbarui
            const SizedBox(height: 24),
            _buildQuickActions(context), // Ditambahkan
            const SizedBox(height: 100), // Padding di bawah
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildFuturisticHeader() {
    return Container(
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                    const SizedBox(height: 6),
                    const Text(
                      'Dr. Iqbal Fahrozi',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // --- Tombol Ikon di Header ---
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: kWhite.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // TODO: Navigasi ke halaman notifikasi
                        },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: kWhite,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: kWhite.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => showLogoutDialog(context),
                        icon: const Icon(Icons.logout, color: kWhite, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kWhite.withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: kPrimaryColor,
                  size: 28,
                ),
                onPressed: () => _changeWeek(-1),
              ),
              GestureDetector(
                onTap: _pickDate,
                child: Row(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_weekDays.first),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_month_outlined,
                      color: kPrimaryColor.withOpacity(0.7),
                      size: 18,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: kPrimaryColor,
                  size: 28,
                ),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: _weekDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final date = _weekDays[index];
              final isSelected = _isSameDay(date, _selectedDate);
              final String dayOfWeek = DateFormat.E()
                  .format(date)
                  .toUpperCase(); // MON, TUE, ...
              final String dayOfMonth = date.day.toString(); // 4, 5, ...

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 70,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [kPrimaryColor, kPrimaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : kWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 6,
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
                              ? kWhite.withOpacity(0.8)
                              : kTextGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayOfMonth,
                        style: TextStyle(
                          color: isSelected ? kWhite : kTextDark,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 6,
                          height: 6,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryColor, Color(0xFF003366)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kWhite.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'KUNJUNGAN BERIKUTNYA',
                        style: TextStyle(
                          color: kSecondaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bp. Arya Andhika',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: kSecondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '10:30 WITA',
                        style: TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        height: 16,
                        width: 1,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      const Icon(
                        Icons.location_on_outlined,
                        color: kSecondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Jl. Giri Rejo II',
                          style: TextStyle(color: kWhite),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSecondaryColor,
                      foregroundColor: kWhite,
                      elevation: 8,
                      shadowColor: kSecondaryColor.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Mulai Kunjungan',
                      style: TextStyle(
                        fontSize: 16,
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
              size: 120,
              color: kWhite.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  // <<< WIDGET BARU >>>
  Widget _buildInsights() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.trending_up, color: kPrimaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Insight & Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: stats.map((stat) {
              return _StatCard(stat: stat);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // <<< WIDGET DIPERBARUI >>>
  Widget _buildImportantNotifications() {
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
            children: notifications.map((notif) {
              return _NotificationCard(
                notification: notif,
                onTap: () {
                  // TODO: Logika navigasi notifikasi
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
              _QuickActionButton(
                label: 'Stats',
                icon: Icons.monitor_heart_outlined,
                onTap: () {
                  // TODO: Tambahkan rute statistik jika ada
                },
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
            color: Colors.grey.withOpacity(0.08),
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
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? kSecondaryColor.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
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
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, kPrimaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
              color: kTextDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            notification.subtitle,
            style: const TextStyle(color: kTextGrey, fontSize: 11),
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
              color: kPrimaryColor.withOpacity(0.1),
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
