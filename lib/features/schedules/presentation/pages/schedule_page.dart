// lib/pages/homecare_referral_detail_page.dart
// import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

// @RoutePage()
class SchedulePage extends StatelessWidget {
  final int id;
  const SchedulePage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Dummy data (sementara hardcoded)
    final Map<String, dynamic> referral = {
      "time": "10:30",
      "name": "Bp. Arya Andhika",
      "address": "Jl. Giri Rejo II, Balikpapan",
      "status": "Pending",
      "complaint": "Pasien mengeluhkan sakit kepala sejak 2 hari lalu.",
      "assignedStaff": "dr. Budi Santoso",
    };

    final bool isPending = referral['status'] == "Pending";
    final Color statusColor = isPending
        ? colorScheme.primary
        : colorScheme.secondary;
    final Color statusBackgroundColor = isPending
        ? colorScheme.primary.withValues(alpha: 0.1)
        : colorScheme.secondary.withValues(alpha: 0.1);

    return Scaffold(
      appBar: AppBar(title: Text("Detail Rujukan $id"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Jam kunjungan
            Row(
              children: [
                Icon(Icons.access_time, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  referral['time'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nama pasien
            Text(
              referral['name'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Alamat
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    referral['address'],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            Row(
              children: [
                const Text(
                  "Status: ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Chip(
                  label: Text(referral['status']),
                  backgroundColor: statusBackgroundColor,
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Keluhan
            const Text(
              "Keluhan:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(referral['complaint']),
            const SizedBox(height: 16),

            // Petugas medis
            const Text(
              "Petugas Medis:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(referral['assignedStaff']),
            const SizedBox(height: 32),

            // Tombol Aksi
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                // nanti bisa navigasi ke halaman visit / laporan
              },
              child: Text(
                isPending ? "Start Visit" : "Lihat Laporan",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
