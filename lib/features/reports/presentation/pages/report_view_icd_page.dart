import 'package:flutter/material.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';

class ReportViewIcdPage extends StatefulWidget {
  final int registrasiId;
  const ReportViewIcdPage({super.key, required this.registrasiId});

  @override
  State<ReportViewIcdPage> createState() => _ReportViewIcdPageState();
}

class _ReportViewIcdPageState extends State<ReportViewIcdPage> {
  List<dynamic> _icd = const [];
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
      _icd = (raw?['icd'] as List?) ?? const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lihat ICD')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryHeader(
                    title: 'Ringkasan Diagnosa',
                    subtitle: 'Registrasi #${widget.registrasiId}',
                    countLabel: 'ICD',
                    count: _icd.length,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _icd.isEmpty
                        ? const Text('Tidak ada diagnosa ICD')
                        : ListView.builder(
                            itemCount: _icd.length,
                            itemBuilder: (context, index) {
                              final item = _icd[index] as Map<String, dynamic>;
                              final kode = item['kode']?.toString() ?? '-';
                              final nama = item['nama']?.toString() ?? item['deskripsi']?.toString() ?? '-';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(kode, style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              );
                            },
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
