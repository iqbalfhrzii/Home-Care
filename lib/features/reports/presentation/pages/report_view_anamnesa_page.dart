import 'package:flutter/material.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';

class ReportViewAnamnesaPage extends StatefulWidget {
  final int registrasiId;
  const ReportViewAnamnesaPage({super.key, required this.registrasiId});

  @override
  State<ReportViewAnamnesaPage> createState() => _ReportViewAnamnesaPageState();
}

class _ReportViewAnamnesaPageState extends State<ReportViewAnamnesaPage> {
  Map<String, dynamic>? _anamnesa;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await getIt<RegistrasiRepository>().getRegistrasiRawById(widget.registrasiId);
      _anamnesa = raw?['anamnesa'] as Map<String, dynamic>?;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lihat Anamnesa')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryHeader(
                    title: 'Ringkasan Anamnesa',
                    subtitle: 'Registrasi #${widget.registrasiId}',
                    countLabel: 'Field',
                    count: _anamnesa?.length ?? 0,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _anamnesa == null
                        ? const Text('Belum ada data Anamnesa')
                        : ListView(
                            children: _anamnesa!.entries
                                .map((e) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                              child: Text(e.key,
                                                  style: const TextStyle(
                                                      color: Colors.grey))),
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  e.value.toString(),
                                                  textAlign: TextAlign.end)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String countLabel;
  final int count;
  const _SummaryHeader({
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('$countLabel: $count',
                style: const TextStyle(color: Color(0xFF1E40AF))),
          ),
        ],
      ),
    );
  }
}
