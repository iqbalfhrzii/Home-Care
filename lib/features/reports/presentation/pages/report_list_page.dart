import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:homecare_mobile/features/reports/presentation/pages/report_detail_tagihan_pages.dart';
import 'package:homecare_mobile/features/reports/data/repositories/tagihan_repository.dart';
import 'package:homecare_mobile/features/reports/domain/models/tagihan.dart';
import 'package:homecare_mobile/shared/app_injections.dart';

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);

class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  final TextEditingController _searchController = TextEditingController();
  final TagihanRepository _repository = getIt<TagihanRepository>();

  String _selectedFilter = 'semua';
  List<Tagihan> _allTagihan = [];
  List<Tagihan> _filteredTagihan = [];
  bool _isLoading = true;
  bool _isLoaded = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _loadTagihan();
    _searchController.addListener(_filterTagihan);
  }

  void _refreshData() {
    setState(() {
      _isLoaded = false;
      _allTagihan = [];
      _filteredTagihan = [];
    });
    _loadTagihan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _retryTimer?.cancel();
    _retryTimer = null;
    super.dispose();
  }

  Future<void> _loadTagihan() async {
    // Try once immediately, then start a retry loop until we successfully load data.
    await _attemptLoadOnce(startRetryOnFail: true);
  }

  Future<void> _attemptLoadOnce({bool startRetryOnFail = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      // Protect against hanging network calls by applying a timeout.
      final tagihan = await _repository.getAllTagihan().timeout(
        const Duration(seconds: 8),
      );
      if (!mounted) return;
      // If the fetch returned an empty list, consider it a transient failure
      // (server may have returned non-JSON or connection failed but repository
      // returned []) — keep retrying until we get data. This follows the
      // requested behavior to keep showing a loader until data is successfully
      // loaded.
      if ((tagihan.isEmpty) && !_isLoaded) {
        print('⚠️ getAllTagihan returned empty — will retry');
        setState(() {
          _isLoading = true;
          _isLoaded = false;
        });
        if (startRetryOnFail) _startRetryLoop();
        return;
      }

      setState(() {
        _allTagihan = tagihan;
        _filteredTagihan = tagihan;
        _isLoading = false;
        _isLoaded = true;
      });
      // Cancel any pending retry timer
      _retryTimer?.cancel();
      _retryTimer = null;
    } catch (e) {
      // Log the error to help debugging (network, timeout, parse, etc.)
      print('⚠️ loadTagihan attempt failed: $e');
      if (!mounted) return;
      // Keep showing loading indicator and optionally start retrying
      setState(() {
        _isLoading = true;
        _isLoaded = false;
      });
      if (startRetryOnFail) _startRetryLoop();
    }
  }

  void _startRetryLoop() {
    // If already retrying, do nothing
    if (_retryTimer != null) return;
    // Retry every 2 seconds until success or widget disposed
    _retryTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_isLoaded) {
        t.cancel();
        _retryTimer = null;
        return;
      }
      await _attemptLoadOnce(startRetryOnFail: false);
    });
  }

  void _filterTagihan() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTagihan = _allTagihan.where((tagihan) {
        // Get patient name from registrasi
        String patientName = '';
        String mrNumber = '';
        try {
          final reg = tagihan.registrasi;
          if (reg != null && reg['pasien'] is Map) {
            final pasien = reg['pasien'] as Map;
            patientName = (pasien['nama']?.toString() ?? '').toLowerCase();
            mrNumber = (pasien['mrn']?.toString() ?? '').toLowerCase();
          }
        } catch (e) {
          // Ignore
        }

        final matchesSearch =
            patientName.contains(query) ||
            mrNumber.contains(query) ||
            tagihan.noInvoice.toLowerCase().contains(query) ||
            (tagihan.tanggalInvoice?.toLowerCase().contains(query) ?? false);

        final matchesFilter =
            _selectedFilter == 'semua' ||
            tagihan.statusPembayaran == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterTagihan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSummaryCards(),
                _buildSearchBar(),
              ],
            ),
          ),
          _buildBillingList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        height: 140,
        padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryColor, kPrimaryLight],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33004B8C),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Text(
                  'Tagihan & Pembayaran',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(width: 6),
                Icon(Icons.receipt_long, color: Color(0xFF8BC43E), size: 16),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Laporan Billing',
              style: TextStyle(
                color: kWhite,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final total = _allTagihan.length;
    final sudahBayar = _allTagihan
        .where((t) => t.statusPembayaran == 'sudah_bayar')
        .length;
    final belumBayar = _allTagihan
        .where((t) => t.statusPembayaran == 'belum_bayar')
        .length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Total',
              count: total,
              color: kPrimaryColor,
              icon: Icons.receipt_long,
              isSelected: _selectedFilter == 'semua',
              onTap: () => _setFilter('semua'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Sudah Bayar',
              count: sudahBayar,
              color: kSuccessColor,
              icon: Icons.check_circle,
              isSelected: _selectedFilter == 'sudah_bayar',
              onTap: () => _setFilter('sudah_bayar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Belum Bayar',
              count: belumBayar,
              color: kWarningColor,
              icon: Icons.pending,
              isSelected: _selectedFilter == 'belum_bayar',
              onTap: () => _setFilter('belum_bayar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nama pasien, MR, atau invoice...',
          prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
          filled: true,
          fillColor: kWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kTextGrey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Semua',
              isSelected: _selectedFilter == 'semua',
              onTap: () => _setFilter('semua'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Sudah Bayar',
              isSelected: _selectedFilter == 'sudah_bayar',
              onTap: () => _setFilter('sudah_bayar'),
              color: kSuccessColor,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Belum Bayar',
              isSelected: _selectedFilter == 'belum_bayar',
              onTap: () => _setFilter('belum_bayar'),
              color: kWarningColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_filteredTagihan.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: kTextGrey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada tagihan ditemukan',
                style: TextStyle(color: kTextGrey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final tagihan = _filteredTagihan[index];
          return _TagihanCard(
            tagihan: tagihan,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportDetailTagihanPage(
                    tagihanId: tagihan.id,
                    registrasiId: tagihan.registrasiId,
                  ),
                ),
              );
              // Refresh data if status was updated
              if (result == true) {
                _refreshData();
              }
            },
          );
        }, childCount: _filteredTagihan.length),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color : kWhite,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.3 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? kWhite : color, size: 24),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? kWhite : color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? kWhite : kTextGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? kPrimaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : kTextGrey.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? kWhite : kTextGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TagihanCard extends StatelessWidget {
  final Tagihan tagihan;
  final VoidCallback onTap;

  const _TagihanCard({required this.tagihan, required this.onTap});

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

  int _parseStringToInt(String? value) {
    if (value == null || value.isEmpty) return 0;
    // Parse dari string seperti "267958.00" atau "267958"
    final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanValue)?.toInt() ?? 0;
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  String _getPatientName() {
    try {
      final reg = tagihan.registrasi;
      if (reg != null && reg['pasien'] is Map) {
        final pasien = reg['pasien'] as Map;
        return pasien['nama']?.toString() ?? 'Pasien #${tagihan.registrasiId}';
      }
    } catch (e) {
      // Ignore
    }
    return 'Pasien #${tagihan.registrasiId}';
  }

  String _getMRNumber() {
    try {
      final reg = tagihan.registrasi;
      if (reg != null && reg['pasien'] is Map) {
        final pasien = reg['pasien'] as Map;
        return pasien['mrn']?.toString() ?? '-';
      }
    } catch (e) {
      // Ignore
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(tagihan.statusPembayaran);
    final totalBiaya = _parseStringToInt(tagihan.totalBiaya);
    final deposit = _parseStringToInt(tagihan.deposit);
    final sisaBiaya = _parseStringToInt(tagihan.biayaYangHarusDibayar);
    final tanggal = _parseDate(tagihan.tanggalInvoice);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPatientName(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.badge,
                                size: 14,
                                color: kTextGrey,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _getMRNumber(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kTextGrey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.receipt,
                                size: 14,
                                color: kTextGrey,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  tagihan.noInvoice,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: kTextGrey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 120,
                        minWidth: 0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(tagihan.statusPembayaran),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kScaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total Biaya',
                              style: TextStyle(fontSize: 13, color: kTextGrey),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(totalBiaya)}',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: kTextDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (deposit > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Deposit',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kTextGrey,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Rp ${NumberFormat('#,###', 'id_ID').format(deposit)}',
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kSuccessColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Sisa Bayar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: kTextDark,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(sisaBiaya)}',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: sisaBiaya > 0
                                    ? kDangerColor
                                    : kSuccessColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: kTextGrey),
                        const SizedBox(width: 6),
                        Text(
                          tanggal != null
                              ? DateFormat('d MMM yyyy').format(tanggal)
                              : '-',
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextGrey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.badge, size: 14, color: kTextGrey),
                        const SizedBox(width: 6),
                        Text(
                          'Reg #${tagihan.registrasiId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: kTextGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
