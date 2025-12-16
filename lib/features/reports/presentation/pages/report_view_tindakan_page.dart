import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/reports/data/repositories/tagihan_repository.dart';
import 'package:homecare_mobile/features/reports/domain/models/tagihan.dart';

class ReportViewTindakanPage extends StatefulWidget {
  final int registrasiId;
  const ReportViewTindakanPage({super.key, required this.registrasiId});

  @override
  State<ReportViewTindakanPage> createState() => _ReportViewTindakanPageState();
}

class _ReportViewTindakanPageState extends State<ReportViewTindakanPage> {
  List<dynamic> _tindakan = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Prefer Tagihan items for tindakan view
      final tags = await getIt<TagihanRepository>().getAllTagihan();
      Tagihan? tagihan;
      for (final t in tags) {
        if (t.registrasiId == widget.registrasiId) {
          tagihan = t;
          break;
        }
      }
      _tindakan = tagihan != null ? (tagihan.items ?? const []) : const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lihat Tindakan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryHeader(
                    title: 'Ringkasan Tindakan',
                    subtitle: 'Registrasi #${widget.registrasiId}',
                    countLabel: 'Item',
                    count: _tindakan.length,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _tindakan.isEmpty
                        ? const Text('Tidak ada tindakan')
                        : ListView.builder(
                            itemCount: _tindakan.length,
                            itemBuilder: (context, index) {
                              final item = _tindakan[index];
                              final nama = item.deskripsi ?? '-';
                              final kode = item.kodeLayanan ?? '-';
                              final biaya = _safeInt(item.subtotal);
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
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Text(kode, style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Text('Rp ${NumberFormat('#,###', 'id_ID').format(biaya)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
