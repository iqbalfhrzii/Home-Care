import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:homecare_mobile/features/reports/data/repositories/tagihan_repository.dart';
import 'package:homecare_mobile/features/reports/domain/models/tagihan.dart';

// --- Palet Warna Baru (Futuristic) ---

const Color kPrimaryColor = Color(0xFF004B8C); // Deep Blue

const Color kPrimaryLight = Color(0xFF0063B2); // Lighter Blue for Gradient

const Color kSecondaryColor = Color(0xFF8BC43E); // Lime Green (Action Color)

const Color kScaffoldBg = Color(0xFFF5F7FA); // Cool White Background

const Color kWhite = Colors.white;

const Color kTextDark = Color(0xFF1E293B);

const Color kTextGrey = Color(0xFF94A3B8);

const Color kSuccessColor = Color(0xFF22C55E);

const Color kWarningColor = Color(0xFFF59E0B);

const Color kInfoColor = Color(0xFF3B82F6);

const Color kDangerColor = Color(0xFFEF4444);

// --- Dummy models for this page only (decoupled from repo) ---
class PasienLite {
  final String nama;
  final String mrn;
  PasienLite({required this.nama, required this.mrn});
}

class RegistrasiLite {
  final int id;
  final String? tglJamReg; // ISO8601 string
  final String? status; // 'terjadwal' | 'dalam_proses' | 'selesai' | etc
  final PasienLite? pasien;
  RegistrasiLite({
    required this.id,
    this.tglJamReg,
    this.status,
    this.pasien,
  });
}

class ScheduleItem {
  final RegistrasiLite registration;
  final PasienLite? patient;
  final int progress;
  final bool hasTagihan;
  ScheduleItem({required this.registration, this.patient, this.progress = 0, this.hasTagihan = false});
}

class ScheduleListPage extends StatefulWidget {
  const ScheduleListPage({super.key});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
  List<ScheduleItem> _allSchedules = [];

  List<ScheduleItem> _filteredSchedules = [];

  DateTime? _selectedDate;

  final TextEditingController _dateController = TextEditingController();

  bool _isLoading = true;

  String? _selectedStatus;
  bool _enrichmentRan = false;

  // Progress tracking removed - will be calculated from related records if needed

  int get _notStartedCount => _allSchedules.where((s) => s.progress == 0).length;

  int get _inProgressCount => _allSchedules.where((s) => s.progress >= 1 && s.progress <= 2).length;

  int get _completedCount => _allSchedules.where((s) => s.progress == 3).length;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  void dispose() {
    _dateController.dispose();

    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final repo = getIt<RegistrasiRepository>();
      final billsRepo = getIt<TagihanRepository>();
      final allTagihan = await billsRepo.getAllTagihan();
      final regs = await repo.getAllRegistrasi();
      final items = <ScheduleItem>[];
      for (final r in regs) {
        final pasien = r.pasien;
        final litePatient = pasien != null ? PasienLite(nama: pasien.nama, mrn: pasien.mrn) : null;

        int progress = 0;
        bool hasTagihan = false;
        // Avoid per-item raw calls to keep UI responsive; infer from Tagihan only
        Tagihan? found;
        for (final t in allTagihan) {
          if (t.registrasiId == r.id) {
            found = t;
            break;
          }
        }
        if (found != null) {
          hasTagihan = true;
          if ((found.items ?? const []).isNotEmpty) progress += 1; // tindakan
          if ((found.primaryIcd ?? '').isNotEmpty) progress += 1; // icd
        }

        items.add(ScheduleItem(
          registration: RegistrasiLite(
            id: r.id,
            tglJamReg: r.tglJamReg,
            status: r.status,
            pasien: litePatient,
          ),
          patient: litePatient,
          progress: progress,
          hasTagihan: hasTagihan,
        ));
      }

      // Sort newest first
      items.sort((a, b) {
        final dateA = a.registration.tglJamReg != null
            ? DateTime.tryParse(a.registration.tglJamReg!)
            : null;
        final dateB = b.registration.tglJamReg != null
            ? DateTime.tryParse(b.registration.tglJamReg!)
            : null;
        final safeA = dateA ?? DateTime(1970);
        final safeB = dateB ?? DateTime(1970);
        return safeB.compareTo(safeA);
      });

      if (!mounted) return;
      setState(() {
        _allSchedules = items;
        _filteredSchedules = items;
        _isLoading = false;
      });

      // Enrich progress with Anamnesa in background to avoid blocking UI
      if (!_enrichmentRan) {
        _enrichmentRan = true;
        _enrichProgressWithAnamnesa(regs);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat jadwal: $e'),
          backgroundColor: kDangerColor,
        ),
      );
    }
  }

  Future<void> _enrichProgressWithAnamnesa(List<dynamic> regs) async {
    final repo = getIt<RegistrasiRepository>();
    final updated = List<ScheduleItem>.from(_allSchedules);
    // Limit batch size to avoid flooding backend
    final int limit = regs.length > 10 ? 10 : regs.length;
    for (int i = 0; i < limit; i++) {
      final r = regs[i];
      try {
        final raw = await repo.getRegistrasiRawById(r.id);
        final hasAnamnesa = raw != null && raw['anamnesa'] != null;
        if (hasAnamnesa) {
          // find and update the corresponding item
          final idx = updated.indexWhere((s) => s.registration.id == r.id);
          if (idx != -1) {
            final s = updated[idx];
            if (s.progress < 3) {
              updated[idx] = ScheduleItem(
                registration: s.registration,
                patient: s.patient,
                progress: s.progress + 1,
                hasTagihan: s.hasTagihan,
              );
            }
          }
        }
      } catch (_) {
        // ignore per-item errors
      }
    }
    if (!mounted) return;
    setState(() {
      _allSchedules = updated;
      _filterSchedules();
    });
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,

      initialDate: _selectedDate ?? DateTime.now(),

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),

      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,

              onPrimary: kWhite,

              onSurface: kTextDark,
            ),
          ),

          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;

        _dateController.text = DateFormat(
          'd MMMM yyyy',

          'id_ID',
        ).format(pickedDate);
      });

      _filterSchedules();
    }
  }

  void _filterSchedules() {
    List<ScheduleItem> filtered = List.of(_allSchedules);

    if (_selectedDate != null) {
      filtered = filtered.where((item) {
        final dateStr = item.registration.tglJamReg;

        if (dateStr == null) return false;

        final dt = DateTime.tryParse(dateStr);

        if (dt == null) return false;

        return dt.year == _selectedDate!.year &&
            dt.month == _selectedDate!.month &&
            dt.day == _selectedDate!.day;
      }).toList();
    }

    // Status filter: 'belum' (0), 'proses' (1-2), 'selesai' (3 or hasTagihan)
    if (_selectedStatus != null) {
      filtered = filtered.where((item) {
        final p = item.progress;
        final selesai = p == 3;
        switch (_selectedStatus) {
          case 'belum':
            return p == 0;
          case 'proses':
            return p >= 1 && p <= 2;
          case 'selesai':
            return selesai;
          default:
            return true;
        }
      }).toList();
    }

    setState(() => _filteredSchedules = filtered);
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;

      _dateController.clear();
    });

    _filterSchedules();
  }

  void _selectStatusFilter(String? status) {
    setState(() {
      _selectedStatus = _selectedStatus == status ? null : status;
    });

    _filterSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,

      body: Column(
        children: [
          _buildHeader(),

          if (!_isLoading) _buildStatusCards(),

          _buildFilterSection(),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  )
                : _filteredSchedules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Icon(
                          Icons.calendar_today_outlined,

                          size: 64,

                          color: kTextGrey.withValues(alpha: 0.5),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Tidak ada jadwal',

                          style: TextStyle(
                            fontSize: 16,

                            fontWeight: FontWeight.bold,

                            color: kTextDark,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _selectedDate == null
                              ? 'Belum ada data kunjungan.'
                              : 'Tidak ada jadwal di tanggal ini.',

                          style: const TextStyle(color: kTextGrey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),

                    itemCount: _filteredSchedules.length,

                    separatorBuilder: (_, __) => const SizedBox(height: 12),

                    itemBuilder: (context, index) {
                      final schedule = _filteredSchedules[index];

                      return _ScheduleCard(
                        schedule: schedule,

                        onTap: () {
                          context
                              .push(
                                '/schedules/detail/${schedule.registration.id}',
                              )
                              .then((_) => _loadSchedules());
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),

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

      child: SafeArea(
        bottom: false,

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: const [
                  Text(
                    'Kelola Jadwal',

                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),

                  SizedBox(height: 4),

                  Text(
                    'Kunjungan Pasien',

                    style: TextStyle(
                      color: kWhite,

                      fontSize: 20,

                      fontWeight: FontWeight.w700,
                    ),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Container(
              decoration: BoxDecoration(
                color: kWhite.withValues(alpha: 0.15),

                borderRadius: BorderRadius.circular(12),
              ),

              child: IconButton(
                onPressed: _loadSchedules,

                icon: const Icon(Icons.refresh, color: kWhite, size: 22),

                padding: const EdgeInsets.all(8),

                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      color: kWhite,

      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'Belum Mulai',

              _notStartedCount.toString(),

              kWarningColor,

              Icons.schedule,

              'belum',
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildStatusCard(
              'Proses',

              _inProgressCount.toString(),

              kInfoColor,

              Icons.pending_actions,

              'proses',
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildStatusCard(
              'Selesai',

              _completedCount.toString(),

              kSuccessColor,

              Icons.check_circle,

              'selesai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,

    String value,

    Color color,

    IconData icon,

    String statusKey,
  ) {
    final isSelected = _selectedStatus == statusKey;

    return GestureDetector(
      onTap: () => _selectStatusFilter(statusKey),

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),

        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),

          borderRadius: BorderRadius.circular(12),

          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),

            width: isSelected ? 2 : 1,
          ),

          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),

                    blurRadius: 8,

                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),

        child: Column(
          children: [
            Icon(icon, color: isSelected ? kWhite : color, size: 18),

            const SizedBox(height: 4),

            Text(
              value,

              style: TextStyle(
                fontSize: 16,

                fontWeight: FontWeight.bold,

                color: isSelected ? kWhite : color,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              label,

              style: TextStyle(
                fontSize: 9,

                color: isSelected ? kWhite : color.withValues(alpha: 0.8),

                fontWeight: FontWeight.w600,
              ),

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),

      color: kWhite,

      child: GestureDetector(
        onTap: _pickDate,

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

          decoration: BoxDecoration(
            color: kScaffoldBg,

            borderRadius: BorderRadius.circular(12),

            border: Border.all(color: kTextGrey.withValues(alpha: 0.2)),
          ),

          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 20, color: kPrimaryColor),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  _dateController.text.isEmpty
                      ? 'Pilih Tanggal Kunjungan'
                      : _dateController.text,

                  style: TextStyle(
                    color: _dateController.text.isEmpty ? kTextGrey : kTextDark,

                    fontSize: 14,

                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              if (_dateController.text.isNotEmpty)
                GestureDetector(
                  onTap: _clearDateFilter,

                  child: Icon(Icons.close, size: 20, color: kDangerColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET CARD JADWAL ---

class _ScheduleCard extends StatelessWidget {
  final ScheduleItem schedule;

  final VoidCallback onTap;

  const _ScheduleCard({required this.schedule, required this.onTap});

  Color _getProgressColor(int progress) {
    switch (progress) {
      case 0:
        return kWarningColor;

      case 1:
        return kInfoColor;

      case 2:
        return const Color(0xFF8B5CF6);

      case 3:
        return kSuccessColor;

      default:
        return kTextGrey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'terjadwal':
        return 'Terjadwal';

      case 'dalam_proses':
        return 'Berlangsung';

      case 'selesai':
        return 'Selesai';

      case 'dibatalkan':
        return 'Dibatalkan';

      default:
        return 'Terjadwal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = schedule.progress;

    final status = schedule.registration.status ?? 'terjadwal';

    return Container(
      margin: const EdgeInsets.only(bottom: 0),

      decoration: BoxDecoration(
        color: kWhite,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: kTextGrey.withValues(alpha: 0.15)),

        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.04),

            blurRadius: 8,

            offset: const Offset(0, 2),
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
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,

                      height: 50,

                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimaryColor, kPrimaryLight],

                          begin: Alignment.topLeft,

                          end: Alignment.bottomRight,
                        ),

                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: Center(
                        child: Text(
                          schedule.patient?.nama.isNotEmpty == true
                              ? schedule.patient!.nama[0].toUpperCase()
                              : 'P',

                          style: const TextStyle(
                            color: kWhite,

                            fontSize: 20,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            schedule.patient?.nama ?? 'Pasien',

                            style: const TextStyle(
                              fontSize: 15,

                              fontWeight: FontWeight.w600,

                              color: kTextDark,
                            ),

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,

                                  vertical: 3,
                                ),

                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withValues(alpha: 0.1),

                                  borderRadius: BorderRadius.circular(6),
                                ),

                                child: Text(
                                  schedule.patient?.mrn ?? '—',

                                  style: const TextStyle(
                                    fontSize: 11,

                                    color: kPrimaryColor,

                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Progress Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,

                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: _getProgressColor(
                          progress,
                        ).withValues(alpha: 0.1),

                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Icon(
                            Icons.checklist,

                            color: _getProgressColor(progress),

                            size: 14,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            '$progress/3',

                            style: TextStyle(
                              color: _getProgressColor(progress),

                              fontSize: 11,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final boxWidth = constraints.constrainWidth();

                    const dashWidth = 6.0;

                    final dashCount = (boxWidth / (2 * dashWidth)).floor();

                    return Flex(
                      children: List.generate(dashCount, (_) {
                        return SizedBox(
                          width: dashWidth,

                          height: 1,

                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),

                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      direction: Axis.horizontal,
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Baris Tanggal & Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),

                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.05),

                        borderRadius: BorderRadius.circular(8),
                      ),

                      child: const Icon(
                        Icons.calendar_month_rounded,

                        color: kPrimaryColor,

                        size: 16,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(
                              DateTime.tryParse(
                                    schedule.registration.tglJamReg ?? '',
                                  ) ??
                                  DateTime.now(),
                            ),

                            style: const TextStyle(
                              fontSize: 13,

                              color: kTextDark,

                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            '${DateFormat('HH:mm').format(DateTime.tryParse(schedule.registration.tglJamReg ?? '') ?? DateTime.now())} • ${_getStatusText(status)}',

                            style: const TextStyle(
                              fontSize: 11,

                              color: kTextGrey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,

                      size: 14,

                      color: kTextGrey,
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
