import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';

class ScheduleListPage extends StatefulWidget {
  const ScheduleListPage({super.key});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
  int selectedIndex = 0;

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kunjungan'), centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text("Semua"),
                  selected: selectedIndex == 0,
                  onSelected: (_) => setState(() => selectedIndex = 0),
                  selectedColor: colorScheme.primary,
                  checkmarkColor: colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    color: selectedIndex == 0
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("Pending"),
                  selected: selectedIndex == 1,
                  onSelected: (_) => setState(() => selectedIndex = 1),
                  selectedColor: colorScheme.primary,
                  checkmarkColor: colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    color: selectedIndex == 1
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text("Completed"),
                  selected: selectedIndex == 2,
                  onSelected: (_) => setState(() => selectedIndex = 2),
                  selectedColor: colorScheme.secondary,
                  checkmarkColor: colorScheme.onSecondary,
                  labelStyle: TextStyle(
                    color: selectedIndex == 2
                        ? colorScheme.onSecondary
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                final isPending = schedule['status'] == 'Pending';

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
                        Chip(
                          label: Text(schedule['status']),
                          backgroundColor: isPending
                              ? colorScheme.primaryContainer
                              : colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: isPending
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                    trailing: isPending
                        ? ElevatedButton(
                            onPressed: () {
                              context.go('${AppRouter.schedules}/$index');
                            },
                            child: const Text("Start Visit"),
                          )
                        : OutlinedButton(
                            onPressed: () {
                              context.go('${AppRouter.schedules}/$index');
                            },
                            child: const Text("Lihat Laporan"),
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
