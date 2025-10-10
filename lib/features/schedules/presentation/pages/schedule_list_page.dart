import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';

// @RoutePage()
class ScheduleListPage extends StatefulWidget {
  const ScheduleListPage({super.key});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
  int selectedIndex = 0; // 0 = Semua, 1 = Pending, 2 = Completed

  final List<Map<String, dynamic>> schedules = [
    {
      "time": "10:30",
      "name": "Bp. Arya Andhika",
      "address": "Jl. Giri Rejo II alikpapan",
      "status": "Pending",
    },
    {
      "time": "09:00",
      "name": "Ibu Rizky Amelia",
      "address": "Jl. Melati No. 8, alikpapan",
      "status": "Completed",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kunjungan'), centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text("Semua"),
                  selected: selectedIndex == 0,
                  onSelected: (_) => setState(() => selectedIndex = 0),
                  selectedColor: Colors.blue,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selectedIndex == 0 ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("Pending"),
                  selected: selectedIndex == 1,
                  onSelected: (_) => setState(() => selectedIndex = 1),
                  selectedColor: Colors.blue,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selectedIndex == 1 ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("Completed"),
                  selected: selectedIndex == 2,
                  onSelected: (_) => setState(() => selectedIndex = 2),
                  selectedColor: Colors.blue,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selectedIndex == 2 ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // List Jadwal
          Expanded(
            child: ListView.builder(
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];

                // filter sesuai tab
                if (selectedIndex == 1 && schedule['status'] != 'Pending') {
                  return const SizedBox.shrink();
                }
                if (selectedIndex == 2 && schedule['status'] != 'Completed') {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    onTap: () {
                      context.go('${AppRouter.schedules}/$index');
                    },
                    contentPadding: const EdgeInsets.all(16),
                    leading: Text(
                      schedule['time'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    title: Text(
                      schedule['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(schedule['address']),
                        const SizedBox(height: 6),
                        if (schedule['status'] == "Pending")
                          Chip(
                            label: const Text("Pending"),
                            backgroundColor: Colors.blue[50],
                            labelStyle: const TextStyle(color: Colors.blue),
                          )
                        else
                          Chip(
                            label: const Text("Completed"),
                            backgroundColor: Colors.green[50],
                            labelStyle: const TextStyle(color: Colors.green),
                          ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: schedule['status'] == "Pending"
                            ? Colors.blue
                            : Colors.green,
                      ),
                      onPressed: () {
                        context.go('${AppRouter.schedules}/$index');
                      },
                      child: Text(
                        schedule['status'] == "Pending"
                            ? "Start Visit"
                            : "Lihat Laporan",
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
