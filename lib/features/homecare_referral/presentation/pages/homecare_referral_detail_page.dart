// lib/pages/homecare_referral_detail_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomecareReferralDetailPage extends StatelessWidget {
  final int id;
  const HomecareReferralDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    // Dummy data (sementara hardcoded)
    final Map<String, dynamic> referral = {
      "time": "10:30",
      "name": "Bp. Arya Andhika",
      "address": "Jl. Giri Rejo II, Balikpapan",
      "status": "Pending",
      "complaint": "Pasien mengeluhkan sakit kepala sejak 2 hari lalu.",
      "assignedStaff": "dr. Budi Santoso"
    };

    return Scaffold(
      appBar: AppBar(
        title:  Text("Detail Rujukan $id"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Jam kunjungan
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  referral['time'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                const Icon(Icons.location_on, color: Colors.red),
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
                const Text("Status: ",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Chip(
                  label: Text(referral['status']),
                  backgroundColor: referral['status'] == "Pending"
                      ? Colors.blue[50]
                      : Colors.green[50],
                  labelStyle: TextStyle(
                    color: referral['status'] == "Pending"
                        ? Colors.blue
                        : Colors.green,
                  ),
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
                backgroundColor: referral['status'] == "Pending"
                    ? Colors.blue
                    : Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                // nanti bisa navigasi ke halaman visit / laporan
              },
              child: Text(
                referral['status'] == "Pending"
                    ? "Start Visit"
                    : "Lihat Laporan",
                style: const TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }
}
