import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Modern Design System Colors  ---
const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kAccentColor = Color(0xFF3F51B5);
const Color kWhiteColor = Colors.white;
const Color kBadgeGreen = Color(0xFFE0F2E9);
const Color kBadgeGreenText = Color(0xFF006437);
const Color kBadgeOrange = Color(0xFFFFF4E6);
const Color kBadgeOrangeText = Color(0xFFB45309);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);

// --- Model Data (Contoh dari file sebelumnya) ---
// Anda harus mengimpor ini dari lokasi aslinya
class Schedule {
  final String patientName;
  final String rmNumber;
  final DateTime date;
  final String status;

  Schedule({
    required this.patientName,
    required this.rmNumber,
    required this.date,
    required this.status,
  });
}
// ---------------------------------------------

class SchedulePage extends StatelessWidget {
  // Halaman ini may accept either a Schedule object or an id (from router)
  final Schedule? schedule;
  final int? id;
  final Map<String, dynamic>? scheduleData;

  const SchedulePage({super.key, this.schedule, this.id, this.scheduleData});

  @override
  Widget build(BuildContext context) {
    final sched =
        schedule ??
        (scheduleData != null
            ? Schedule(
                patientName:
                    scheduleData!['patientName'] ?? 'Pasien #${id ?? '-'}',
                rmNumber:
                    scheduleData!['rmNumber'] ??
                    'RM-LOCAL-${id ?? DateTime.now().millisecondsSinceEpoch}',
                date: scheduleData!['date'] ?? DateTime.now(),
                status: scheduleData!['status'] ?? 'disetujui',
              )
            : Schedule(
                patientName: 'Pasien #${id ?? '-'}',
                rmNumber:
                    'RM-LOCAL-${id ?? DateTime.now().millisecondsSinceEpoch}',
                date: DateTime.now(),
                status: 'disetujui',
              ));

    final bool isPending = referral['status'] == "Pending";
    final Color statusColor = isPending
        ? colorScheme.primary
        : colorScheme.secondary;
    final Color statusBackgroundColor = isPending
        ? colorScheme.primary.withValues(alpha: 0.1)
        : colorScheme.secondary.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, sched),
          SliverList(
            delegate: SliverChildListDelegate([_buildContent(context, sched)]),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Schedule schedule) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: kPrimaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor, kPrimaryLight],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Kunjungan',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule.patientName,
                    style: const TextStyle(
                      color: kWhiteColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kWhiteColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              color: kWhiteColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              schedule.rmNumber,
                              style: const TextStyle(
                                color: kWhiteColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kWhiteColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: kWhiteColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('d MMM yyyy').format(schedule.date),
                              style: const TextStyle(
                                color: kWhiteColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Schedule schedule) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- Status Card ---
          _buildStatusCard(schedule),

          const SizedBox(height: 24),

          // --- Section Title ---
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryColor, kPrimaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: kWhiteColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Formulir Kunjungan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryColor, kPrimaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: kWhiteColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Formulir Kunjungan Terintegrasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kTextGrey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Gunakan tombol "Mulai Kunjungan" di atas untuk melakukan proses kunjungan lengkap (Anamnesa → ICD → Tindakan)',
            style: TextStyle(
              fontSize: 12,
              color: kTextGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Schedule schedule) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryColor, kPrimaryLight],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.how_to_reg_outlined,
              color: kWhiteColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Kunjungan',
                  style: TextStyle(
                    fontSize: 12,
                    color: kTextGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: schedule.status),
              ],
            ),
          ),
        ],
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
    final Color color = isApproved ? kBadgeGreen : kBadgeOrange;
    final Color textColor = isApproved ? kBadgeGreenText : kBadgeOrangeText;
    final String text = isApproved ? 'Disetujui' : 'Belum Disetujui';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
