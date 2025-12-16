import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:homecare_mobile/core/router/app_router.dart';
import 'package:homecare_mobile/features/patients/presentation/bloc/patient_bloc.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:homecare_mobile/features/patients/data/repositories/pasien_repository.dart';

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kSecondaryColor = Color(0xFF8BC43E);
const Color kSecondaryButton = Color(0xFF97CA4A);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);

class PatientMasterListPage extends StatefulWidget {
  const PatientMasterListPage({super.key});

  @override
  State<PatientMasterListPage> createState() => _PatientMasterListPageState();
}

class _PatientMasterListPageState extends State<PatientMasterListPage> {
  late final PatientBloc _patientBloc;

  @override
  void initState() {
    super.initState();
    _patientBloc = getIt<PatientBloc>();
    // Always load patients when page opens (refresh on navigation)
    _patientBloc.add(const LoadPatients());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _patientBloc,
      child: const _PatientListView(),
    );
  }
}

class _PatientListView extends StatefulWidget {
  const _PatientListView();

  @override
  State<_PatientListView> createState() => _PatientListViewState();
}

class _PatientListViewState extends State<_PatientListView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<PatientBloc>().add(SearchPatients(_searchController.text));
    });
  }

  bool _hasRegistration(Pasien patient) {
    // Check if patient has registrations from the merged data
    return patient.isRegistered;
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  int _calculateAge(String isoDate) {
    try {
      final today = DateTime.now();
      final birth = DateTime.parse(isoDate);
      int age = today.year - birth.year;
      final monthDiff = today.month - birth.month;
      if (monthDiff < 0 || (monthDiff == 0 && today.day < birth.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  void _onAddPatient() async {
    final result = await context.push<bool>('${AppRouter.patients}/add');
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pasien baru berhasil ditambahkan'),
          backgroundColor: kSuccessColor,
        ),
      );
      context.read<PatientBloc>().add(const RefreshPatients());
    }
  }

  void _onEditPatient(Pasien patient) async {
    final result = await context.push<bool>(
      '${AppRouter.patients}/${patient.id}/edit',
      extra: patient,
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pasien berhasil diupdate'),
          backgroundColor: kSuccessColor,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 150));
      context.read<PatientBloc>().add(const LoadPatients());
    }
  }

  void _onRegisterPatient(Pasien patient) async {
    // Cek apakah pasien ini sudah punya registrasi terbaru, jika ya buka edit
    try {
      final regRepo = getIt<RegistrasiRepository>();
      final latest = await regRepo.getLatestRegistrasiForPatient(patient.id);
      final isEdit = latest != null;
      final result = await context.push<String>(
        '${AppRouter.patients}/register/${patient.id}',
        extra: {
          'pasienId': patient.id,
          'pasienNama': patient.nama,
          if (isEdit) 'registrasiId': latest.id,
          'isEdit': isEdit,
        },
      );

      debugPrint('🔍 Registration result: $result');

      if (result != null && mounted) {
      debugPrint('✅ Processing registration result: $result');

      // Clear repository caches to force fresh fetch
      try {
        getIt<RegistrasiRepository>().clearCache();
        getIt<PasienRepository>().clearCache();
      } catch (_) {}

      // Trigger reload to fetch latest data from API
      await Future.delayed(const Duration(milliseconds: 150));
      context.read<PatientBloc>().add(const LoadPatients());
      debugPrint('✅ RefreshPatients event triggered');

      String message;
      Color backgroundColor;

      switch (result) {
        case 'created':
          message = 'Registrasi untuk ${patient.nama} berhasil';
          backgroundColor = kSuccessColor;
          break;
        case 'updated':
          message = 'Registrasi untuk ${patient.nama} berhasil diupdate';
          backgroundColor = kSuccessColor;
          break;
        case 'canceled':
          message = 'Registrasi untuk ${patient.nama} berhasil dibatalkan';
          backgroundColor = Colors.orange;
          break;
        default:
          message = 'Operasi berhasil';
          backgroundColor = kSuccessColor;
      }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: backgroundColor),
        );
      } else {
        debugPrint('❌ Result is null or not mounted');
      }
    } catch (e) {
      debugPrint('❌ Failed to prepare registration: $e');
      final result = await context.push<String>(
        '${AppRouter.patients}/register/${patient.id}',
        extra: {'pasienId': patient.id, 'pasienNama': patient.nama},
      );
      if (result != null && mounted) {
        try {
          getIt<RegistrasiRepository>().clearCache();
          getIt<PasienRepository>().clearCache();
        } catch (_) {}
        context.read<PatientBloc>().add(const LoadPatients());
      }
    }
  }

  void _onDeletePatient(Pasien patient) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Data Pasien?'),
        content: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(dialogContext).style,
            children: [
              const TextSpan(text: 'Apakah Anda yakin ingin menghapus data '),
              TextSpan(
                text: patient.nama,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?\nTindakan ini tidak dapat dibatalkan.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () {
              Navigator.of(dialogContext).pop();

              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  context.read<PatientBloc>().add(DeletePatient(patient.id));
                }
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: BlocConsumer<PatientBloc, PatientState>(
        listenWhen: (previous, current) {
          return current is PatientOperationSuccess || current is PatientError;
        },
        buildWhen: (previous, current) {
          if (previous is PatientListLoaded && current is PatientListLoaded) {
            return previous.filteredPatients.length !=
                    current.filteredPatients.length ||
                previous.searchQuery != current.searchQuery ||
                previous.activeFilter != current.activeFilter ||
                previous.isLoadingRegistrations !=
                    current.isLoadingRegistrations;
          }
          return previous.runtimeType != current.runtimeType;
        },
        listener: (context, state) {
          if (state is PatientOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: kSuccessColor,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is PatientError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: kDangerColor,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildHeader(),
              if (state is PatientListLoaded) _buildStatusCards(state),
              _buildSearchBar(),
              Expanded(child: _buildContent(state, isDesktop)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPatient,
        backgroundColor: kSecondaryColor,
        child: const Icon(Icons.add, color: kWhite, size: 28),
      ),
    );
  }

  Widget _buildContent(PatientState state, bool isDesktop) {
    if (state is PatientLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (state is PatientError && state.previousState == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: kDangerColor),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: kTextGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<PatientBloc>().add(const LoadPatients());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: kWhite,
              ),
            ),
          ],
        ),
      );
    }

    if (state is PatientListLoaded) {
      if (state.filteredPatients.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: kTextGrey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                state.searchQuery.isEmpty
                    ? 'Belum ada data pasien'
                    : 'Tidak ada pasien ditemukan',
                style: const TextStyle(color: kTextGrey),
              ),
            ],
          ),
        );
      }

      // Build list/table content
      Widget listWidget = isDesktop
          ? _buildDesktopTable(state.filteredPatients)
          : _buildMobileList(state.filteredPatients);

      // Show loading overlay if registrations are being fetched
      if (state.isLoadingRegistrations) {
        return Stack(children: [listWidget]);
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<PatientBloc>().add(const RefreshPatients());
        },
        child: listWidget,
      );
    }

    return const SizedBox();
  }

  Widget _buildStatusCards(PatientListLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: kWhite,
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'Total Pasien',
              state.totalPatients.toString(),
              kPrimaryColor,
              Icons.people,
              isActive: state.activeFilter == null,
              onTap: () {
                context.read<PatientBloc>().add(const FilterPatients(null));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              'Teregistrasi',
              state.registeredCount.toString(),
              const Color(0xFF22C55E),
              Icons.check_circle,
              isActive: state.activeFilter == 'registered',
              onTap: () {
                context.read<PatientBloc>().add(
                  const FilterPatients('registered'),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              'Belum Registrasi',
              state.unregisteredCount.toString(),
              const Color(0xFFF59E0B),
              Icons.pending,
              isActive: state.activeFilter == 'unregistered',
              onTap: () {
                context.read<PatientBloc>().add(
                  const FilterPatients('unregistered'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String count,
    Color color,
    IconData icon, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? color : kTextGrey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                'Kelola Data Master',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(width: 6),
              Icon(Icons.people_outline, color: kSecondaryColor, size: 16),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Data Pasien',
            style: TextStyle(
              color: kWhite,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: kWhite,
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama, nomor RM, NIK, atau BPJS...',
                    prefixIcon: const Icon(Icons.search, color: kTextGrey),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: kTextGrey),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: kScaffoldBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    context.read<PatientBloc>().add(SearchPatients(value));
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              context.read<PatientBloc>().add(
                SearchPatients(_searchController.text),
              );
            },
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Cari'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<Pasien> patients) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      itemCount: patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Container(
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: kSecondaryColor.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () async {
                debugPrint('🔍 Navigating to patient detail: ${patient.id}');
                final result = await context.push<bool>(
                  '${AppRouter.patients}/${patient.id}',
                  extra: patient,
                );
                debugPrint('🔍 Returned from detail with result: $result');

                if (result == true) {
                  debugPrint('✅ Scheduling patient list reload...');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      debugPrint('✅ Triggering LoadPatients from list');
                      context.read<PatientBloc>().add(const LoadPatients());
                    }
                  });
                } else {
                  debugPrint('❌ Not reloading: result=$result');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kPrimaryColor, kPrimaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimaryColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: kWhite,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.nama,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kTextDark,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: kPrimaryColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  patient.mrn,
                                  style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            _GenderBadge(jenisKelamin: patient.jenisKelamin),
                            const SizedBox(height: 6),
                            // TODO: Implement registration status check
                            // _RegistrationStatusBadge(isRegistered: hasRegistrations),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kScaffoldBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _ModernInfoRow(
                            icon: Icons.calendar_today_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            label: 'Tanggal Lahir',
                            value:
                                '${_formatDate(patient.tanggalLahir)} (${_calculateAge(patient.tanggalLahir)} th)',
                          ),
                          const SizedBox(height: 12),
                          _ModernInfoRow(
                            icon: Icons.phone_rounded,
                            iconColor: const Color(0xFF22C55E),
                            label: 'Telepon',
                            value: patient.telepon,
                          ),
                          const SizedBox(height: 12),
                          _ModernInfoRow(
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            label: 'Alamat',
                            value: patient.alamat,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Builder(
                      builder: (context) {
                        final has = _hasRegistration(patient);
                        final label = has
                            ? 'Edit Registrasi'
                            : 'Registrasikan Kunjungan';
                        final icon = has
                            ? Icons.edit_calendar
                            : Icons.app_registration;

                        // Warna berbeda berdasarkan status registrasi
                        final gradientColors = has
                            ? [
                                kPrimaryColor,
                                kPrimaryLight,
                              ] // Biru untuk Edit Registrasi
                            : [
                                kSecondaryColor,
                                Color(0xFF059669),
                              ]; // Hijau untuk Registrasi Baru
                        final shadowColor = has
                            ? kPrimaryColor
                            : kSecondaryColor;

                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradientColors),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _onRegisterPatient(patient),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(icon, color: kWhite, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        color: kWhite,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: kPrimaryColor.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _onEditPatient(patient),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.edit_outlined,
                                        color: kPrimaryColor,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _onDeletePatient(patient),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Hapus',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<Pasien> patients) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 0,
        color: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('No. RM')),
            DataColumn(label: Text('Nama Pasien')),
            DataColumn(label: Text('Jenis Kelamin')),
            DataColumn(label: Text('Usia')),
            DataColumn(label: Text('Telepon')),
            DataColumn(label: Text('Alamat')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: patients.map((patient) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    patient.mrn,
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        patient.nama,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatDate(patient.tanggalLahir),
                        style: const TextStyle(fontSize: 12, color: kTextGrey),
                      ),
                    ],
                  ),
                ),
                DataCell(_GenderBadge(jenisKelamin: patient.jenisKelamin)),
                DataCell(Text('${_calculateAge(patient.tanggalLahir)} tahun')),
                DataCell(Text(patient.telepon)),
                DataCell(Text(patient.alamat, overflow: TextOverflow.ellipsis)),
                DataCell(
                  Row(
                    children: [
                      Builder(
                        builder: (context) {
                          final has = _hasRegistration(patient);
                          final label = has ? 'Edit Registrasi' : 'Registrasi';
                          final icon = has
                              ? Icons.edit_calendar
                              : Icons.app_registration;
                          return TextButton.icon(
                            icon: Icon(icon, size: 14),
                            label: Text(label),
                            style: TextButton.styleFrom(
                              foregroundColor: kSecondaryColor,
                            ),
                            onPressed: () => _onRegisterPatient(patient),
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                        ),
                        onPressed: () => _onEditPatient(patient),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text('Hapus'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[700],
                        ),
                        onPressed: () => _onDeletePatient(patient),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ModernInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final int maxLines;

  const _ModernInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: kTextGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: kTextDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GenderBadge extends StatelessWidget {
  final String jenisKelamin;
  const _GenderBadge({required this.jenisKelamin});

  @override
  Widget build(BuildContext context) {
    final bool isLaki = jenisKelamin == 'L';
    final gradient = isLaki
        ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])
        : const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]);
    final icon = isLaki ? Icons.male : Icons.female;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isLaki
                ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                : const Color(0xFFEC4899).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kWhite, size: 16),
          const SizedBox(width: 4),
          Text(
            isLaki ? 'L' : 'P',
            style: const TextStyle(
              color: kWhite,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/* Commented out - not used currently
class _RegistrationStatusBadge extends StatelessWidget {
  final bool? isRegistered;
  const _RegistrationStatusBadge({this.isRegistered});

  @override
  Widget build(BuildContext context) {
    final bool registered = isRegistered ?? false;
    final gradient = registered
        ? const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)])
        : const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEA580C)]);
    final icon = registered ? Icons.check_circle : Icons.pending;
    final text = registered ? 'Teregistrasi' : 'Belum';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:
                (registered ? const Color(0xFF22C55E) : const Color(0xFFF59E0B))
                    .withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kWhite, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: kWhite,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
*/
