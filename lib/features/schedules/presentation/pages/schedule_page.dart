import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homecare_mobile/features/schedules/presentation/pages/schedule_anamnesis_page.dart';

// --- Ambil dari file/tema Anda ---
const Color kPrimaryColor = Color(0xFF002F67);
const Color kAccentColor = Color(0xFF3F51B5);
const Color kWhiteColor = Colors.white;
const Color kBadgeGreen = Color(0xFFE0F2E9);
const Color kBadgeGreenText = Color(0xFF006437);
const Color kBadgeOrange = Color(0xFFFFF4E6);
const Color kBadgeOrangeText = Color(0xFFB45309);
const Color kScaffoldBg = Color(0xFFF8F9FA);

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

    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Detail Kunjungan',
          style: TextStyle(color: kWhiteColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: kWhiteColor),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- 1. Kartu Header Pasien ---
          _PatientHeaderCard(schedule: sched),

          const SizedBox(height: 24),

          // --- 2. Judul Form ---
          Text(
            'Form Kunjungan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),

          const SizedBox(height: 16),

          // --- 3. Daftar Aksi Form ---
          _FormActionCard(
            icon: Icons.description_outlined,
            title: 'Anamnesa',
            subtitle: 'Riwayat keluhan dan gejala pasien',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ScheduleAssessmentPage(),
                ),
              );
            },
          ),
          _FormActionCard(
            icon: Icons.medical_services_outlined,
            title: 'Tindakan',
            subtitle: 'Tindakan medis yang diberikan',
            onTap: () {
              // TODO: Navigasi ke halaman Tindakan
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigasi ke halaman Tindakan...'),
                ),
              );
            },
          ),
          _FormActionCard(
            icon: Icons.list_alt_outlined,
            title: 'ICD',
            subtitle: 'Kode diagnosis penyakit',
            onTap: () {
              // TODO: Navigasi ke halaman ICD
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigasi ke halaman ICD...')),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- WIDGET UNTUK KARTU HEADER PASIEN ---

class _PatientHeaderCard extends StatelessWidget {
  final Schedule schedule;
  const _PatientHeaderCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: kWhiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: kAccentColor.withAlpha((0.1 * 255).round()),
                  child: const Icon(
                    Icons.person_outline,
                    color: kAccentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.patientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schedule.rmNumber,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                _StatusBadge(status: schedule.status),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('d MMMM yyyy').format(schedule.date),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET UNTUK KARTU AKSI FORM ---

class _FormActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FormActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: kWhiteColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kAccentColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kAccentColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// --- WIDGET BADGE STATUS (dari file sebelumnya) ---

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
