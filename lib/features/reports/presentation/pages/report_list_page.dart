import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTagihan();
    _searchController.addListener(_filterTagihan);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTagihan() async {
    setState(() => _isLoading = true);
    try {
      final tagihan = await _repository.getAllTagihan();
      setState(() {
        _allTagihan = tagihan;
        _filteredTagihan = tagihan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading tagihan: $e')));
      }
    }
  }

  void _filterTagihan() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTagihan = _allTagihan.where((tagihan) {
        final matchesSearch =
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
                _buildFilterChips(),
              ],
            ),
          ),
          _buildBillingList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: kPrimaryColor,
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
                    'Tagihan & Pembayaran',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Laporan Billing',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final total = _allTagihan.length;
    final lunas = _allTagihan
        .where((t) => t.statusPembayaran == 'lunas')
        .length;
    final belumBayar = _allTagihan
        .where((t) => t.statusPembayaran == 'belum_bayar')
        .length;
    final pending = _allTagihan
        .where((t) => t.statusPembayaran == 'pending')
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
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Lunas',
              count: lunas,
              color: kSuccessColor,
              icon: Icons.check_circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Belum',
              count: belumBayar,
              color: kWarningColor,
              icon: Icons.pending,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Pending',
              count: pending,
              color: kDangerColor,
              icon: Icons.hourglass_empty,
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
          hintText: 'Cari invoice, pasien, atau MR...',
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
              label: 'Lunas',
              isSelected: _selectedFilter == 'lunas',
              onTap: () => _setFilter('lunas'),
              color: kSuccessColor,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Belum Bayar',
              isSelected: _selectedFilter == 'belum_bayar',
              onTap: () => _setFilter('belum_bayar'),
              color: kWarningColor,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Pending',
              isSelected: _selectedFilter == 'pending',
              onTap: () => _setFilter('pending'),
              color: kDangerColor,
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportDetailTagihanPage(
                    tagihanId: tagihan.id,
                    registrasiId: tagihan.registrasiId,
                  ),
                ),
              );
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

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: kTextGrey)),
        ],
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : kTextGrey.withValues(alpha: 0.3),
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
      case 'lunas':
        return kSuccessColor;
      case 'belum_bayar':
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
      case 'belum_bayar':
        return 'Belum Bayar';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  int _parseStringToInt(String? value) {
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
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
                            tagihan.noInvoice,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pasien #${tagihan.registrasiId}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: kTextGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Biaya',
                            style: TextStyle(fontSize: 13, color: kTextGrey),
                          ),
                          Text(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(totalBiaya)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kTextDark,
                            ),
                          ),
                        ],
                      ),
                      if (deposit > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Deposit',
                              style: TextStyle(fontSize: 13, color: kTextGrey),
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(deposit)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: kSuccessColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sisa Bayar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kTextDark,
                            ),
                          ),
                          Text(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(sisaBiaya)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: sisaBiaya > 0
                                  ? kDangerColor
                                  : kSuccessColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: kTextGrey),
                    const SizedBox(width: 6),
                    Text(
                      tanggal != null
                          ? DateFormat('d MMM yyyy').format(tanggal)
                          : '-',
                      style: const TextStyle(fontSize: 12, color: kTextGrey),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.badge, size: 14, color: kTextGrey),
                    const SizedBox(width: 6),
                    Text(
                      'Reg #${tagihan.registrasiId}',
                      style: const TextStyle(fontSize: 12, color: kTextGrey),
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
