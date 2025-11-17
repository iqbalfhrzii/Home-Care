import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);

// Mock data model
class TagihanDetailItem {
  final String kategori;
  final String tanggalLayanan;
  final String kodeLayanan;
  final String deskripsi;
  final int jumlah;
  final int hargaSatuan;
  final int diskon;
  final int subtotal;

  TagihanDetailItem({
    required this.kategori,
    required this.tanggalLayanan,
    required this.kodeLayanan,
    required this.deskripsi,
    required this.jumlah,
    required this.hargaSatuan,
    required this.diskon,
    required this.subtotal,
  });
}

class TagihanDetail {
  final String id;
  final String noInvoice;
  final String patientName;
  final String mrNumber;
  final String noTelepon;
  final DateTime tanggalTagihan;
  final String primaryIcd;
  final int totalBiaya;
  final int deposit;
  final int sisaBiaya;
  final String terbilang;
  final String statusPembayaran;
  final List<TagihanDetailItem> items;

  TagihanDetail({
    required this.id,
    required this.noInvoice,
    required this.patientName,
    required this.mrNumber,
    required this.noTelepon,
    required this.tanggalTagihan,
    required this.primaryIcd,
    required this.totalBiaya,
    required this.deposit,
    required this.sisaBiaya,
    required this.terbilang,
    required this.statusPembayaran,
    required this.items,
  });
}

class ReportDetailTagihanPage extends StatefulWidget {
  final String billingId;

  const ReportDetailTagihanPage({super.key, required this.billingId});

  @override
  State<ReportDetailTagihanPage> createState() =>
      _ReportDetailTagihanPageState();
}

class _ReportDetailTagihanPageState extends State<ReportDetailTagihanPage> {
  late TagihanDetail _tagihan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTagihanDetail();
  }

  void _loadTagihanDetail() {
    // Mock data - nanti diganti dengan API call
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _tagihan = TagihanDetail(
          id: widget.billingId,
          noInvoice: 'INV-2025-001',
          patientName: 'Budi Santoso',
          mrNumber: 'MR-2025-001',
          noTelepon: '081234567890',
          tanggalTagihan: DateTime(2025, 11, 15),
          primaryIcd: 'E11 - Diabetes Mellitus Tipe 2',
          totalBiaya: 850000,
          deposit: 500000,
          sisaBiaya: 350000,
          terbilang: 'Delapan Ratus Lima Puluh Ribu Rupiah',
          statusPembayaran: 'belum_lunas',
          items: [
            TagihanDetailItem(
              kategori: 'Tindakan Keperawatan',
              tanggalLayanan: '2025-11-15',
              kodeLayanan: 'T001',
              deskripsi: 'Pemasangan Infus',
              jumlah: 1,
              hargaSatuan: 50000,
              diskon: 0,
              subtotal: 50000,
            ),
            TagihanDetailItem(
              kategori: 'Tindakan Keperawatan',
              tanggalLayanan: '2025-11-15',
              kodeLayanan: 'T002',
              deskripsi: 'Pemberian Obat Injeksi',
              jumlah: 3,
              hargaSatuan: 35000,
              diskon: 5000,
              subtotal: 100000,
            ),
            TagihanDetailItem(
              kategori: 'Tindakan Pemeriksaan',
              tanggalLayanan: '2025-11-15',
              kodeLayanan: 'T005',
              deskripsi: 'EKG',
              jumlah: 1,
              hargaSatuan: 100000,
              diskon: 0,
              subtotal: 100000,
            ),
            TagihanDetailItem(
              kategori: 'Obat-obatan',
              tanggalLayanan: '2025-11-15',
              kodeLayanan: 'OBT-001',
              deskripsi: 'Metformin 500mg',
              jumlah: 30,
              hargaSatuan: 2000,
              diskon: 0,
              subtotal: 60000,
            ),
            TagihanDetailItem(
              kategori: 'Konsultasi',
              tanggalLayanan: '2025-11-15',
              kodeLayanan: 'KNS-001',
              deskripsi: 'Konsultasi Dokter Umum',
              jumlah: 1,
              hargaSatuan: 150000,
              diskon: 0,
              subtotal: 150000,
            ),
            TagihanDetailItem(
              kategori: 'Laboratorium',
              tanggalLayanan: '2025-11-15',
              kodeLayanan: 'LAB-001',
              deskripsi: 'Pemeriksaan Gula Darah',
              jumlah: 1,
              hargaSatuan: 50000,
              diskon: 0,
              subtotal: 50000,
            ),
            TagihanDetailItem(
              kategori: 'Administrasi',
              tanggalLayanan: '2025-11-15',
              kodeLayanan: 'ADM-001',
              deskripsi: 'Biaya Administrasi',
              jumlah: 1,
              hargaSatuan: 340000,
              diskon: 0,
              subtotal: 340000,
            ),
          ],
        );
        _isLoading = false;
      });
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'lunas':
        return kSuccessColor;
      case 'belum_lunas':
        return kWarningColor;
      case 'pending':
        return kDangerColor;
      default:
        return kTextGrey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'lunas':
        return 'Lunas';
      case 'belum_lunas':
        return 'Belum Lunas';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  Future<void> _shareViaWhatsApp() async {
    final message = _generateWhatsAppMessage();
    final phoneNumber = _tagihan.noTelepon.replaceAll(RegExp(r'[^0-9]'), '');

    // Format nomor telepon ke format internasional
    String formattedPhone = phoneNumber;
    if (phoneNumber.startsWith('0')) {
      formattedPhone = '62${phoneNumber.substring(1)}';
    } else if (!phoneNumber.startsWith('62')) {
      formattedPhone = '62$phoneNumber';
    }

    final url = Uri.parse(
      'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka WhatsApp'),
              backgroundColor: kDangerColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kDangerColor),
        );
      }
    }
  }

  String _generateWhatsAppMessage() {
    final buffer = StringBuffer();
    buffer.writeln('*TAGIHAN PEMBAYARAN*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('*Invoice:* ${_tagihan.noInvoice}');
    buffer.writeln(
      '*Tanggal:* ${DateFormat('d MMMM yyyy', 'id_ID').format(_tagihan.tanggalTagihan)}',
    );
    buffer.writeln('*Pasien:* ${_tagihan.patientName}');
    buffer.writeln('*No. RM:* ${_tagihan.mrNumber}');
    buffer.writeln('*Diagnosis:* ${_tagihan.primaryIcd}');
    buffer.writeln('');
    buffer.writeln('*RINCIAN BIAYA*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    // Group items by kategori
    final groupedItems = <String, List<TagihanDetailItem>>{};
    for (var item in _tagihan.items) {
      groupedItems.putIfAbsent(item.kategori, () => []).add(item);
    }

    groupedItems.forEach((kategori, items) {
      buffer.writeln('');
      buffer.writeln('*$kategori*');
      for (var item in items) {
        buffer.write('• ${item.deskripsi}');
        if (item.jumlah > 1) {
          buffer.write(' (${item.jumlah}x)');
        }
        buffer.writeln('');
        buffer.writeln(
          '  Rp ${NumberFormat('#,###', 'id_ID').format(item.subtotal)}',
        );
      }
    });

    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
      '*Total Biaya:* Rp ${NumberFormat('#,###', 'id_ID').format(_tagihan.totalBiaya)}',
    );

    if (_tagihan.deposit > 0) {
      buffer.writeln(
        '*Deposit:* Rp ${NumberFormat('#,###', 'id_ID').format(_tagihan.deposit)}',
      );
      buffer.writeln(
        '*Sisa Pembayaran:* Rp ${NumberFormat('#,###', 'id_ID').format(_tagihan.sisaBiaya)}',
      );
    }

    buffer.writeln('*Terbilang:* ${_tagihan.terbilang}');
    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('*Status:* ${_getStatusText(_tagihan.statusPembayaran)}');
    buffer.writeln('');
    buffer.writeln('Terima kasih atas kepercayaan Anda.');
    buffer.writeln('');
    buffer.writeln('_Pesan otomatis dari Home Care System_');

    return buffer.toString();
  }

  Future<void> _copyToClipboard() async {
    final message = _generateWhatsAppMessage();
    await Clipboard.setData(ClipboardData(text: message));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tagihan berhasil disalin ke clipboard'),
          backgroundColor: kSuccessColor,
        ),
      );
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    // TODO: Implement API call to update status
    setState(() {
      _tagihan = TagihanDetail(
        id: _tagihan.id,
        noInvoice: _tagihan.noInvoice,
        patientName: _tagihan.patientName,
        mrNumber: _tagihan.mrNumber,
        noTelepon: _tagihan.noTelepon,
        tanggalTagihan: _tagihan.tanggalTagihan,
        primaryIcd: _tagihan.primaryIcd,
        totalBiaya: _tagihan.totalBiaya,
        deposit: _tagihan.deposit,
        sisaBiaya: _tagihan.sisaBiaya,
        terbilang: _tagihan.terbilang,
        statusPembayaran: newStatus,
        items: _tagihan.items,
      );
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
              leading: const Icon(Icons.schedule, color: kDangerColor),
              title: const Text('Pending'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('pending');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending, color: kWarningColor),
              title: const Text('Belum Lunas'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('belum_lunas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: kSuccessColor),
              title: const Text('Lunas'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus('lunas');
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
    final statusColor = _getStatusColor(_tagihan.statusPembayaran);

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
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tagihan.noInvoice,
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(_tagihan.statusPembayaran),
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
      ],
    );
  }

  Widget _buildPatientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
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
          _buildInfoRow('Nama', _tagihan.patientName),
          const SizedBox(height: 12),
          _buildInfoRow('No. RM', _tagihan.mrNumber),
          const SizedBox(height: 12),
          _buildInfoRow('Telepon', _tagihan.noTelepon),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Tanggal',
            DateFormat('d MMMM yyyy', 'id_ID').format(_tagihan.tanggalTagihan),
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
            color: kSuccessColor.withOpacity(0.08),
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
                Text(
                  _tagihan.primaryIcd,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    // Group items by kategori
    final groupedItems = <String, List<TagihanDetailItem>>{};
    for (var item in _tagihan.items) {
      groupedItems.putIfAbsent(item.kategori, () => []).add(item);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
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
                child: const Icon(Icons.receipt_long, color: kWhite, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rincian Biaya',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...groupedItems.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                ...entry.value.map((item) => _buildItemRow(item)),
                const Divider(height: 20),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemRow(TagihanDetailItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.deskripsi,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                    ),
                    Text(
                      item.kodeLayanan,
                      style: const TextStyle(fontSize: 12, color: kTextGrey),
                    ),
                  ],
                ),
              ),
              Text(
                'Rp ${NumberFormat('#,###', 'id_ID').format(item.subtotal)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${item.jumlah}x @ Rp ${NumberFormat('#,###', 'id_ID').format(item.hargaSatuan)}',
                style: const TextStyle(fontSize: 12, color: kTextGrey),
              ),
              if (item.diskon > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kDangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Diskon Rp ${NumberFormat('#,###', 'id_ID').format(item.diskon)}',
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Total Biaya',
            'Rp ${NumberFormat('#,###', 'id_ID').format(_tagihan.totalBiaya)}',
            isBold: true,
            color: kWhite,
          ),
          if (_tagihan.deposit > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Deposit',
              'Rp ${NumberFormat('#,###', 'id_ID').format(_tagihan.deposit)}',
              color: Colors.white70,
            ),
            const Divider(color: Colors.white38, height: 24),
            _buildSummaryRow(
              'Sisa Pembayaran',
              'Rp ${NumberFormat('#,###', 'id_ID').format(_tagihan.sisaBiaya)}',
              isBold: true,
              fontSize: 18,
              color: kWhite,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _tagihan.terbilang,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
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
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: kTextGrey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextDark,
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
            color: kTextGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Salin'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  side: const BorderSide(color: kPrimaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _shareViaWhatsApp,
                icon: const Icon(Icons.share),
                label: const Text('Kirim via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: kWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
