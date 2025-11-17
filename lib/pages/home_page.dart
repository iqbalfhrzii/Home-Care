import 'package:flutter/material.dart';
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _selectedDate;
  List<DateTime> _weekDays = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekDays = _generateWeekDays(DateTime.now());
  }

  // --- LOGIKA KALENDER ---

  // Generate 7 hari dalam satu minggu (Senin - Minggu)
  List<DateTime> _generateWeekDays(DateTime today) {
    // 1. Cari hari Senin di minggu ini
    // today.weekday mengembalikan 1 untuk Senin, 7 untuk Minggu
    int daysToSubtract = today.weekday - 1;
    DateTime startOfWeek = today.subtract(Duration(days: daysToSubtract));

    // 2. Buat list 7 hari dari Senin sampai Minggu
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  // Cek apakah dua DateTime merujuk ke hari yang sama
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Fungsi untuk pindah minggu (maju/mundur)
  void _changeWeek(int direction) {
    setState(() {
      // Ambil hari Senin dari minggu yang sedang ditampilkan
      DateTime currentWeekStart = _weekDays.first;
      // Tambah atau kurangi 7 hari
      DateTime newWeekStart = currentWeekStart.add(
        Duration(days: 7 * direction),
      );

      // Buat ulang 7 hari untuk minggu baru
      _weekDays = _generateWeekDays(newWeekStart);

      // Cek apakah minggu baru adalah minggu ini
      DateTime startOfThisWeek = _generateWeekDays(DateTime.now()).first;
      if (_isSameDay(_weekDays.first, startOfThisWeek)) {
        _selectedDate = DateTime.now(); // Pilih hari ini
      } else {
        _selectedDate = _weekDays.first; // Pilih hari Senin
      }
    });
  }

  // Fungsi untuk menampilkan pop-up kalender
  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      // Styling popup kalender agar sesuai tema
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor, // Warna header
              onPrimary: kWhite, // Warna teks di header
              onSurface: kTextDark, // Warna teks di dalam
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
        _weekDays = _generateWeekDays(
          pickedDate,
        ); // Pindah ke minggu yang dipilih
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
            _buildImportantNotifications(),
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
                Row(
                  children: [
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
          Row(
            children: [
              Expanded(
                child: _NotificationCard(
                  title: 'Kunjungan ke rumah Akmal',
                  actionText: 'Menuju Tugas',
                  icon: Icons.home_work_outlined,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _NotificationCard(
                  title: 'Input Anamnesa Akmal',
                  actionText: 'Menuju Tugas',
                  icon: Icons.edit_document,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _NotificationCard(
                  title: 'High Priority Task',
                  actionText: 'Go to task',
                  icon: Icons.star_border_rounded,
                  isAlert: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _NotificationCard(
                  title: 'Personal Things',
                  actionText: 'On-hold',
                  icon: Icons.person_outline,
                  isPrimaryAction: false,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- WIDGET KARTU NOTIFIKASI (FUTURISTIC STYLE) ---
class _NotificationCard extends StatelessWidget {
  final String title;
  final String actionText;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimaryAction;
  final bool isAlert;

  const _NotificationCard({
    required this.title,
    required this.actionText,
    required this.icon,
    required this.onTap,
    this.isPrimaryAction = true,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isAlert ? Colors.redAccent : kPrimaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 140,
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
        border: isAlert
            ? Border.all(color: Colors.redAccent.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              if (isAlert)
                const Icon(Icons.circle, size: 8, color: Colors.redAccent),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kTextDark,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPrimaryAction
                        ? (isAlert ? Colors.redAccent : kSecondaryColor)
                        : kTextGrey,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: isPrimaryAction
                      ? (isAlert ? Colors.redAccent : kSecondaryColor)
                      : kTextGrey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
