import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homecare_mobile/features/reports/presentation/pages/report_detail_tagihan_pages.dart';

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
class BillingData {
  final String id;
  final String noInvoice;
  final String patientName;
  final String mrNumber;
  final DateTime tanggalTagihan;
  final int totalBiaya;
  final int deposit;
  final int sisaBiaya;
  final String statusPembayaran;
  final String primaryIcd;

  BillingData({
    required this.id,
    required this.noInvoice,
    required this.patientName,
    required this.mrNumber,
    required this.tanggalTagihan,
    required this.totalBiaya,
    required this.deposit,
    required this.sisaBiaya,
    required this.statusPembayaran,
    required this.primaryIcd,
  });
}

class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'semua';

  // Mock data - nanti diganti dengan API call
  final List<BillingData> _allBillings = [
    BillingData(
      id: '1',
      noInvoice: 'INV-2025-001',
      patientName: 'Budi Santoso',
      mrNumber: 'MR-2025-001',
      tanggalTagihan: DateTime(2025, 11, 15),
      totalBiaya: 850000,
      deposit: 500000,
      sisaBiaya: 350000,
      statusPembayaran: 'lunas',
      primaryIcd: 'E11 - Diabetes Mellitus Tipe 2',
    ),
    BillingData(
      id: '2',
      noInvoice: 'INV-2025-002',
      patientName: 'Siti Aminah',
      mrNumber: 'MR-2025-002',
      tanggalTagihan: DateTime(2025, 11, 16),
      totalBiaya: 1200000,
      deposit: 600000,
      sisaBiaya: 600000,
      statusPembayaran: 'belum_lunas',
      primaryIcd: 'I10 - Hipertensi Esensial',
    ),
    BillingData(
      id: '3',
      noInvoice: 'INV-2025-003',
      patientName: 'Ahmad Hidayat',
      mrNumber: 'MR-2025-003',
      tanggalTagihan: DateTime(2025, 11, 17),
      totalBiaya: 650000,
      deposit: 0,
      sisaBiaya: 650000,
      statusPembayaran: 'pending',
      primaryIcd: 'J06.9 - Common Cold',
    ),
    BillingData(
      id: '4',
      noInvoice: 'INV-2025-004',
      patientName: 'Dewi Lestari',
      mrNumber: 'MR-2025-004',
      tanggalTagihan: DateTime(2025, 11, 14),
      totalBiaya: 950000,
      deposit: 950000,
      sisaBiaya: 0,
      statusPembayaran: 'lunas',
      primaryIcd: 'J45.0 - Asma',
    ),
  ];

  List<BillingData> _filteredBillings = [];

  @override
  void initState() {
    super.initState();
    _filteredBillings = _allBillings;
    _searchController.addListener(_filterBillings);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBillings() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBillings = _allBillings.where((billing) {
        final matchesSearch =
            billing.noInvoice.toLowerCase().contains(query) ||
            billing.patientName.toLowerCase().contains(query) ||
            billing.mrNumber.toLowerCase().contains(query);

        final matchesFilter =
            _selectedFilter == 'semua' ||
            billing.statusPembayaran == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterBillings();
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
    final total = _allBillings.length;
    final lunas = _allBillings
        .where((b) => b.statusPembayaran == 'lunas')
        .length;
    final belumLunas = _allBillings
        .where((b) => b.statusPembayaran == 'belum_lunas')
        .length;
    final pending = _allBillings
        .where((b) => b.statusPembayaran == 'pending')
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
              count: belumLunas,
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
              icon: Icons.schedule,
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
            borderSide: BorderSide(color: kTextGrey.withOpacity(0.2)),
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
              label: 'Belum Lunas',
              isSelected: _selectedFilter == 'belum_lunas',
              onTap: () => _setFilter('belum_lunas'),
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
    if (_filteredBillings.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: kTextGrey.withOpacity(0.5),
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
          final billing = _filteredBillings[index];
          return _BillingCard(
            billing: billing,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReportDetailTagihanPage(billingId: billing.id),
                ),
              );
            },
          );
        }, childCount: _filteredBillings.length),
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
            color: color.withOpacity(0.1),
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
            color: isSelected ? chipColor : kTextGrey.withOpacity(0.3),
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

class _BillingCard extends StatelessWidget {
  final BillingData billing;
  final VoidCallback onTap;

  const _BillingCard({required this.billing, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(billing.statusPembayaran);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
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
                            billing.noInvoice,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            billing.patientName,
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(billing.statusPembayaran),
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
                            'Rp ${NumberFormat('#,###', 'id_ID').format(billing.totalBiaya)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kTextDark,
                            ),
                          ),
                        ],
                      ),
                      if (billing.deposit > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Deposit',
                              style: TextStyle(fontSize: 13, color: kTextGrey),
                            ),
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(billing.deposit)}',
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
                            'Rp ${NumberFormat('#,###', 'id_ID').format(billing.sisaBiaya)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: billing.sisaBiaya > 0
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
                      DateFormat('d MMM yyyy').format(billing.tanggalTagihan),
                      style: const TextStyle(fontSize: 12, color: kTextGrey),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.badge, size: 14, color: kTextGrey),
                    const SizedBox(width: 6),
                    Text(
                      billing.mrNumber,
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
