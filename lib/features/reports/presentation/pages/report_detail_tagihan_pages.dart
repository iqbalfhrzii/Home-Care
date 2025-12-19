import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/reports/data/repositories/tagihan_repository.dart';
import 'package:homecare_mobile/features/reports/domain/models/tagihan.dart'
    as model;
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
// Removed report view pages (Anamnesa/Tindakan/ICD) per request

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);

// Mock data models no longer used - using real Tagihan model from API

class ReportDetailTagihanPage extends StatefulWidget {
  final int tagihanId;
  final int? registrasiId;

  const ReportDetailTagihanPage({
    super.key,
    required this.tagihanId,
    this.registrasiId,
  });

  @override
  State<ReportDetailTagihanPage> createState() =>
      _ReportDetailTagihanPageState();
}

class _ReportDetailTagihanPageState extends State<ReportDetailTagihanPage> {
  model.Tagihan? _tagihan;
  bool _isLoading = true;
  String? _errorMessage;

  int _parseCurrencyStringToInt(String? str) {
    if (str == null || str.isEmpty) return 0;
    final cleaned = str.replaceAll(RegExp(r'[^(0-9)\.\-]'), '');
    final d = double.tryParse(cleaned) ?? 0.0;
    return d.round();
  }

  @override
  void initState() {
    super.initState();
    _loadTagihanDetail();
  }

  // Helper methods to extract data from embedded registrasi
  String _getPatientName() {
    final reg = _tagihan?.registrasi;
    if (reg == null) return 'Tidak diketahui';
    final pasien = reg['pasien'];
    if (pasien is Map) return pasien['nama'] as String? ?? 'Tidak diketahui';
    return 'Tidak diketahui';
  }

  String _getMRNumber() {
    final reg = _tagihan?.registrasi;
    if (reg == null) return '-';
    final pasien = reg['pasien'];
    if (pasien is Map) return pasien['mrn'] as String? ?? '-';
    return '-';
  }

  String _getPhoneNumber() {
    final reg = _tagihan?.registrasi;
    if (reg == null) return '-';
    final pasien = reg['pasien'];
    if (pasien is Map) return pasien['telepon'] as String? ?? '-';
    return '-';
  }

  DateTime _getTagihanDate() {
    final dateStr = _tagihan?.tanggalInvoice;
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }

  int _getTotalBiaya() {
    final str = _tagihan?.totalBiaya;
    if (str == null || str.isEmpty) return 0;
    // Parse decimal string like "150000000.00" correctly to int (rupiah)
    final cleaned = str.replaceAll(RegExp(r'[^(0-9)\.\-]'), '');
    final d = double.tryParse(cleaned) ?? 0.0;
    return d.round();
  }

  int _getDeposit() {
    final str = _tagihan?.deposit;
    if (str == null || str.isEmpty) return 0;
    final cleaned = str.replaceAll(RegExp(r'[^(0-9)\.\-]'), '');
    final d = double.tryParse(cleaned) ?? 0.0;
    return d.round();
  }

  int _getSisaBiaya() {
    final str = _tagihan?.biayaYangHarusDibayar;
    if (str == null || str.isEmpty) return 0;
    final cleaned = str.replaceAll(RegExp(r'[^(0-9)\.\-]'), '');
    final d = double.tryParse(cleaned) ?? 0.0;
    return d.round();
  }

  Future<void> _loadTagihanDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = getIt<TagihanRepository>();
      final tagihan = await repo.getTagihanById(widget.tagihanId);

      if (!mounted) return;

      if (tagihan == null) {
        setState(() {
          _errorMessage = 'Tagihan tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _tagihan = tagihan;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading tagihan detail: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat data tagihan: $e';
        _isLoading = false;
      });
    }
  }

  // Raw registrasi fetching handled by dedicated view pages

  Color _getStatusColor(String status) {
    switch (status) {
      case 'sudah_bayar':
        return kSuccessColor;
      case 'belum_bayar':
        return kWarningColor;
      default:
        return kTextGrey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'sudah_bayar':
        return 'Sudah Bayar';
      case 'belum_bayar':
        return 'Belum Bayar';
      default:
        return status;
    }
  }

  // WhatsApp sharing removed per user request.

  String _generateWhatsAppMessage() {
    final buffer = StringBuffer();
    buffer.writeln('*TAGIHAN PEMBAYARAN*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('*Invoice:* ${_tagihan!.noInvoice}');
    buffer.writeln(
      '*Tanggal:* ${DateFormat('d MMMM yyyy', 'id_ID').format(_getTagihanDate())}',
    );
    buffer.writeln('*Pasien:* ${_getPatientName()}');
    buffer.writeln('*No. RM:* ${_getMRNumber()}');
    buffer.writeln('*Diagnosis:* ${_tagihan!.primaryIcd ?? '-'}');
    buffer.writeln('');
    buffer.writeln('*RINCIAN BIAYA*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    final items = _tagihan!.items ?? [];
    for (var item in items) {
      buffer.write('• ${item.deskripsi ?? '-'}');
      if (item.jumlah > 1) {
        buffer.write(' (${item.jumlah}x)');
      }
      buffer.writeln('');
      final subtotal = _parseCurrencyStringToInt(item.subtotal);
      buffer.writeln('  Rp ${NumberFormat('#,###', 'id_ID').format(subtotal)}');
    }

    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
      '*Total Biaya:* Rp ${NumberFormat('#,###', 'id_ID').format(_getTotalBiaya())}',
    );

    final deposit = _getDeposit();
    if (deposit > 0) {
      buffer.writeln(
        '*Deposit:* Rp ${NumberFormat('#,###', 'id_ID').format(deposit)}',
      );
      buffer.writeln(
        '*Sisa Pembayaran:* Rp ${NumberFormat('#,###', 'id_ID').format(_getSisaBiaya())}',
      );
    }

    buffer.writeln('*Terbilang:* ${_tagihan!.terbilang ?? '-'}');
    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('*Status:* ${_getStatusText(_tagihan!.statusPembayaran)}');
    buffer.writeln('');
    buffer.writeln('Terima kasih atas kepercayaan Anda.');
    buffer.writeln('');
    buffer.writeln('_Pesan otomatis dari Home Care System_');

    return buffer.toString();
  }

  Future<void> _printPdf() async {
    // Download PDF bytes via authenticated request and render locally
    try {
      final repo = getIt<TagihanRepository>();
      final bytes = await repo.downloadPrintPdf(_tagihan!.id);
      if (bytes == null) {
        throw Exception('Gagal mengunduh PDF dari server');
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'Invoice-${_tagihan!.noInvoice}.pdf',
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kDangerColor),
      );
      // fallback: try open URL externally (may fail if authentication required)
      try {
        final repo = getIt<TagihanRepository>();
        final printUrl = await repo.getPrintUrl(_tagihan!.id);
        if (printUrl != null) {
          final url = Uri.parse(printUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      } catch (_) {}
      return;
    }

    final doc = pw.Document();
    final items = _tagihan!.items ?? [];
    final currency = (num v) =>
        'Rp ${NumberFormat('#,###', 'id_ID').format(v)}';

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Invoice',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _tagihan!.noInvoice,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      DateFormat(
                        'd MMMM yyyy',
                        'id_ID',
                      ).format(_getTagihanDate()),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    _getStatusText(_tagihan!.statusPembayaran),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Patient + diagnosis
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Data Pasien',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                _pdfInfoRow('Nama', _getPatientName()),
                _pdfInfoRow('No. RM', _getMRNumber()),
                _pdfInfoRow('Telepon', _getPhoneNumber()),
                _pdfInfoRow('Diagnosis', _tagihan!.primaryIcd ?? '-'),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Items list
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Rincian Biaya',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 8),
                ...items.map((item) {
                  final subtotal = _parseCurrencyStringToInt(item.subtotal);
                  final hargaSatuan = _parseCurrencyStringToInt(
                    item.hargaSatuan,
                  );
                  final diskon = _parseCurrencyStringToInt(item.diskon);

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  item.deskripsi ?? '-',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  item.kodeLayanan ?? '-',
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Flexible(
                            flex: 2,
                            child: pw.Text(
                              currency(subtotal),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          pw.Text(
                            '${item.jumlah}x @ ${currency(hargaSatuan)}',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                          if (diskon > 0) ...[
                            pw.SizedBox(width: 6),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(
                                'Diskon ${currency(diskon)}',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.red,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Divider(height: 6),
                    ],
                  );
                }),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(kPrimaryColor.value),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _pdfSummaryRow(
                  'Total Biaya',
                  currency(_getTotalBiaya()),
                  isBold: true,
                  color: PdfColors.white,
                ),
                if (_getDeposit() > 0) ...[
                  pw.SizedBox(height: 6),
                  _pdfSummaryRow(
                    'Deposit',
                    currency(_getDeposit()),
                    color: PdfColors.white,
                  ),
                  pw.Divider(
                    color: PdfColors.white,
                    height: 16,
                    thickness: 0.3,
                  ),
                  _pdfSummaryRow(
                    'Sisa Pembayaran',
                    currency(_getSisaBiaya()),
                    isBold: true,
                    color: PdfColors.white,
                  ),
                ],
                pw.SizedBox(height: 6),
                pw.Text(
                  _tagihan!.terbilang ?? '-',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Invoice-${_tagihan!.noInvoice}.pdf',
    );
  }

  pw.Widget _pdfInfoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          flex: 3,
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  pw.Widget _pdfSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          color: color ?? PdfColors.grey100,
          fontSize: 12,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
      pw.Text(
        value,
        style: pw.TextStyle(
          color: color ?? PdfColors.black,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ],
  );

  Future<void> _updateStatus(String newStatus) async {
    // TODO: Implement API call to update status
    setState(() {
      _tagihan = _tagihan?.copyWith(statusPembayaran: newStatus);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status diubah menjadi ${_getStatusText(newStatus)}'),
          backgroundColor: kSuccessColor,
        ),
      );
    }
  }

  void _showUpdateStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pending, color: kWarningColor),
              title: const Text('Belum Bayar'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('belum_bayar');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: kSuccessColor),
              title: const Text('Sudah Bayar'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('sudah_bayar');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          title: const Text('Detail Tagihan'),
          backgroundColor: kPrimaryColor,
          foregroundColor: kWhite,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _tagihan == null) {
      return Scaffold(
        backgroundColor: kScaffoldBg,
        appBar: AppBar(
          title: const Text('Detail Tagihan'),
          backgroundColor: kPrimaryColor,
          foregroundColor: kWhite,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: kDangerColor),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Tagihan tidak ditemukan',
                style: const TextStyle(fontSize: 16, color: kTextGrey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientCard(),
                  const SizedBox(height: 16),
                  _buildDiagnosisCard(),
                  const SizedBox(height: 16),
                  _buildItemsSection(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    final statusColor = _getStatusColor(_tagihan!.statusPembayaran);

    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: kPrimaryColor,
      foregroundColor: kWhite,
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
                    'Invoice',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tagihan!.noInvoice,
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 160,
                      minWidth: 0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getStatusText(_tagihan!.statusPembayaran),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _showUpdateStatusDialog,
          tooltip: 'Update Status',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _confirmDeleteTagihan,
          tooltip: 'Hapus Tagihan',
        ),
      ],
    );
  }

  Future<void> _confirmDeleteTagihan() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tagihan'),
        content: const Text(
          'Yakin ingin menghapus tagihan ini? Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      final repo = getIt<TagihanRepository>();
      final success = await repo.deleteTagihan(_tagihan!.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tagihan berhasil dihapus'),
            backgroundColor: kSuccessColor,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus tagihan'),
            backgroundColor: kDangerColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kDangerColor),
      );
    }
  }

  Widget _buildPatientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.person_outline,
                  color: kWhite,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Data Pasien',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nama', _getPatientName()),
          const SizedBox(height: 12),
          _buildInfoRow('No. RM', _getMRNumber()),
          const SizedBox(height: 12),
          _buildInfoRow('Telepon', _getPhoneNumber()),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Tanggal',
            DateFormat('d MMMM yyyy', 'id_ID').format(_getTagihanDate()),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kSuccessColor.withValues(alpha: 0.08),
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
                colors: [kSuccessColor, Color(0xFF16A34A)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_information_outlined,
              color: kWhite,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diagnosis Utama',
                  style: TextStyle(fontSize: 12, color: kTextGrey),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    // Try to extract ICD/deskripsi from registrasi if present
                    final reg = _tagihan?.registrasi;
                    final List<String> icdNames = [];

                    if (reg is Map) {
                      final Map<String, dynamic> regMap =
                          Map<String, dynamic>.from(reg as Map);
                      final dynamic rawIcd =
                          regMap['icd'] ??
                          regMap['icd_list'] ??
                          regMap['diagnosa'];
                      if (rawIcd is List) {
                        for (final item in rawIcd) {
                          if (item is Map) {
                            final name =
                                (item['deskripsi'] ??
                                        item['deskripsi_icd'] ??
                                        item['name'] ??
                                        item['nama'] ??
                                        item['kode'])
                                    ?.toString();
                            if (name != null && name.isNotEmpty) {
                              icdNames.add(name);
                            }
                          } else if (item != null) {
                            final s = item.toString();
                            if (s.isNotEmpty) icdNames.add(s);
                          }
                        }
                      }
                    }

                    // Fallback to primaryIcd (may contain code or description)
                    if (icdNames.isEmpty) {
                      final primary = _tagihan!.primaryIcd;
                      if (primary != null && primary.isNotEmpty)
                        icdNames.add(primary);
                    }

                    if (icdNames.isEmpty) {
                      return const Text('-');
                    }

                    // If multiple diagnoses, show as vertical list; otherwise single bold line
                    if (icdNames.length == 1) {
                      return Text(
                        icdNames.first,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kTextDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: icdNames
                          .map(
                            (n) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $n',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: kTextDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    // Prefer showing tindakan from registrasi (billing-first: registrasi.tindakan)
    final reg = _tagihan?.registrasi;

    List<dynamic> tindakan = [];
    if (reg is Map) {
      final Map<String, dynamic> regMap = Map<String, dynamic>.from(reg as Map);
      final dynamic t =
          regMap['tindakan'] ?? regMap['tindakan_from_tagihan'] ?? [];
      if (t is List) tindakan = List<dynamic>.from(t);
    }

    if (tindakan.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Tidak ada rincian tindakan',
            style: TextStyle(color: kTextGrey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  Icons.medical_services,
                  color: kWhite,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tindakan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tindakan.map((t) => _buildTindakanRow(t)),
        ],
      ),
    );
  }

  Widget _buildTindakanRow(dynamic tindakan) {
    // tindakan can be a Map with pivot or a model-like object. Normalize access.
    final Map t = tindakan is Map ? tindakan : {};
    final pivot = t['pivot'] is Map ? t['pivot'] as Map : <String, dynamic>{};

    final deskripsi =
        t['deskripsi'] as String? ?? t['description'] as String? ?? '-';
    final kode = t['kode'] as String? ?? t['kode_layanan'] as String? ?? '-';

    final jumlah = (pivot['jumlah'] ?? t['jumlah'] ?? 0);
    final hargaStr =
        (pivot['harga_satuan'] ?? t['harga_satuan'] ?? t['tarif'] ?? '0')
            .toString();
    final diskonStr = (pivot['diskon'] ?? t['diskon'] ?? '0').toString();
    final subtotalStr =
        (pivot['subtotal'] ??
                t['subtotal'] ??
                (int.parse(jumlah.toString()) *
                        (double.tryParse(hargaStr) ?? 0.0))
                    .toString())
            .toString();

    final tanggalRaw = pivot['tanggal_layanan'] ?? t['tanggal_layanan'];
    String tanggalText = '';
    if (tanggalRaw != null) {
      try {
        final dt = DateTime.tryParse(tanggalRaw.toString());
        if (dt != null) {
          tanggalText = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
        } else {
          tanggalText = tanggalRaw.toString();
        }
      } catch (_) {
        tanggalText = tanggalRaw.toString();
      }
    }

    final subtotalInt = _parseCurrencyStringToInt(subtotalStr);
    final hargaInt = _parseCurrencyStringToInt(hargaStr);
    final diskonInt = _parseCurrencyStringToInt(diskonStr);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deskripsi,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kode,
                      style: const TextStyle(fontSize: 11, color: kTextGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(subtotalInt)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${jumlah}x @ Rp ${NumberFormat('#,###', 'id_ID').format(hargaInt)}',
                style: const TextStyle(fontSize: 12, color: kTextGrey),
              ),
              if ((diskonInt) > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kDangerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Diskon Rp ${NumberFormat('#,###', 'id_ID').format(diskonInt)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: kDangerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (tanggalText.isNotEmpty)
                Text(
                  tanggalText,
                  style: const TextStyle(fontSize: 11, color: kTextGrey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(model.TagihanItem item) {
    final subtotalInt = _parseCurrencyStringToInt(item.subtotal);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.deskripsi ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.kodeLayanan ?? '-',
                      style: const TextStyle(fontSize: 11, color: kTextGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  'Rp ${NumberFormat('#,###', 'id_ID').format(subtotalInt)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${item.jumlah}x @ Rp ${NumberFormat('#,###', 'id_ID').format(_parseCurrencyStringToInt(item.hargaSatuan))}',
                style: const TextStyle(fontSize: 12, color: kTextGrey),
              ),
              if ((_parseCurrencyStringToInt(item.diskon)) > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kDangerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Diskon Rp ${NumberFormat('#,###', 'id_ID').format(_parseCurrencyStringToInt(item.diskon))}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: kDangerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalBiaya = _getTotalBiaya();
    final deposit = _getDeposit();
    final sisaBiaya = _getSisaBiaya();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Total Biaya',
            'Rp ${NumberFormat('#,###', 'id_ID').format(totalBiaya)}',
            isBold: true,
            fontSize: 14,
            color: kWhite,
          ),
          if (deposit > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Deposit',
              'Rp ${NumberFormat('#,###', 'id_ID').format(deposit)}',
              color: Colors.white70,
            ),
            const Divider(color: Colors.white38, height: 24),
            _buildSummaryRow(
              'Sisa Pembayaran',
              'Rp ${NumberFormat('#,###', 'id_ID').format(sisaBiaya)}',
              isBold: true,
              fontSize: 16,
              color: kWhite,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            _tagihan!.terbilang ?? '-',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double? fontSize,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize ?? 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? kTextGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize ?? 14,
            fontWeight: FontWeight.bold,
            color: color ?? kTextDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: kTextGrey),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextDark,
            ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: kTextGrey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _printPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text(
                      'Cetak PDF',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: const BorderSide(color: kPrimaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Bottom sheet helper removed; navigation to pages is used

  // Anamnesa/Tindakan/ICD pages removed per request
}
