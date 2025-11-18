import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';
import 'package:homecare_mobile/features/patients/presentation/bloc/patient_bloc.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart' as db;

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kSecondaryColor = Color(0xFF8BC43E);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kButtonRed = Color(0xFFDC2626);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kDangerColor = Color(0xFFEF4444);

class PatientDetailPage extends StatelessWidget {
  final String? patientId;
  final Pasien? pasien;

  const PatientDetailPage({super.key, this.patientId, this.pasien});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<PatientBloc>(),
      child: Builder(
        builder: (context) {
          if (pasien == null && patientId != null) {
            context.read<PatientBloc>().add(LoadPatientDetail(patientId!));
          }
          return _PatientDetailView(initialPatient: pasien);
        },
      ),
    );
  }
}

class _PatientDetailView extends StatefulWidget {
  final Pasien? initialPatient;

  const _PatientDetailView({this.initialPatient});

  @override
  State<_PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<_PatientDetailView> {
  db.Registrasi? _latestRegistration;
  bool _loadingRegistration = false;
  Pasien? _currentPatient;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.initialPatient;
    _loadRegistrationData();
  }

  Future<void> _loadRegistrationData() async {
    final patient = _currentPatient ?? widget.initialPatient;
    if (patient == null) return;

    setState(() => _loadingRegistration = true);
    try {
      final database = getIt<db.AppDatabase>();
      final pasienIdInt = int.tryParse(patient.id);
      if (pasienIdInt != null) {
        final registration = await database.getLatestRegistrasiByPasienId(
          pasienIdInt,
        );
        if (mounted) {
          setState(() {
            _latestRegistration = registration;
            _loadingRegistration = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading registration: $e');
      if (mounted) {
        setState(() => _loadingRegistration = false);
      }
    }
  }

  Future<void> _reloadPatientData(String patientId) async {
    try {
      final database = getIt<db.AppDatabase>();
      final pasienIdInt = int.tryParse(patientId);
      if (pasienIdInt != null) {
        final patient = await database.getPasienById(pasienIdInt);
        if (patient != null && mounted) {
          setState(() {
            _currentPatient = Pasien(
              id: patient.id.toString(),
              noRm: patient.noRm,
              nama: patient.nama,
              nik: patient.nik,
              noBpjs: patient.noBpjs,
              tempatLahir: patient.tempatLahir,
              tanggalLahir: patient.tanggalLahir.toIso8601String(),
              jenisKelamin: patient.jenisKelamin,
              golonganDarah: patient.golonganDarah,
              alamat: patient.alamat,
              noTelp: patient.noTelp,
              isRegistered: patient.isRegistered,
              createdAt: patient.createdAt.toIso8601String(),
              updatedAt: patient.updatedAt.toIso8601String(),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error reloading patient: $e');
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    try {
      return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return dateTime.toString();
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PatientBloc, PatientState>(
      listener: (context, state) {
        if (state is PatientOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: kSuccessColor,
            ),
          );
          if (state.type == PatientOperationType.delete) {
            Navigator.of(context).pop(true);
          }
        } else if (state is PatientError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: kDangerColor,
            ),
          );
        } else if (state is PatientDetailLoaded) {
          setState(() {
            _currentPatient = state.patient;
          });
          _loadRegistrationData();
        }
      },
      builder: (context, state) {
        Pasien? currentPatient = _currentPatient;

        if (state is PatientDetailLoaded) {
          currentPatient = state.patient;
        }

        if (state is PatientLoading && currentPatient == null) {
          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              title: const Text('Detail Pasien'),
              backgroundColor: kPrimaryColor,
              foregroundColor: kWhite,
            ),
            body: const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          );
        }

        if (state is PatientError && currentPatient == null) {
          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              title: const Text('Detail Pasien'),
              backgroundColor: kPrimaryColor,
              foregroundColor: kWhite,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: kDangerColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: kTextGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kWhite,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (currentPatient == null) {
          return Scaffold(
            backgroundColor: kScaffoldBg,
            appBar: AppBar(
              title: const Text('Detail Pasien'),
              backgroundColor: kPrimaryColor,
              foregroundColor: kWhite,
            ),
            body: const Center(child: Text('Data pasien tidak ditemukan')),
          );
        }

        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop(true);
            return false;
          },
          child: Scaffold(
            backgroundColor: kScaffoldBg,
            body: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, currentPatient),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildInfoCard(currentPatient),
                        const SizedBox(height: 16),
                        if (currentPatient.isRegistered ?? false) ...[
                          _buildRegistrationCard(),
                          const SizedBox(height: 16),
                        ],
                        _buildActionButtons(context, currentPatient),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Pasien patient) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: kPrimaryColor,
      foregroundColor: kWhite,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        title: Text(
          patient.nama,
          style: const TextStyle(
            color: kWhite,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor, kPrimaryLight],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: kWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kWhite.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.person, size: 36, color: kWhite),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: kWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kWhite.withOpacity(0.3)),
                  ),
                  child: Text(
                    patient.noRm,
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Pasien patient) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pasien',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            'Nama Lengkap',
            patient.nama,
            Icons.person_outline,
            kPrimaryColor,
          ),
          _buildInfoRow(
            'No. Rekam Medis',
            patient.noRm,
            Icons.badge_outlined,
            const Color(0xFF3B82F6),
          ),
          _buildInfoRow(
            'NIK',
            patient.nik ?? '-',
            Icons.credit_card_outlined,
            const Color(0xFF8B5CF6),
          ),
          _buildInfoRow(
            'No. BPJS',
            patient.noBpjs ?? '-',
            Icons.medical_information_outlined,
            const Color(0xFF10B981),
          ),
          _buildInfoRow(
            'Jenis Kelamin',
            patient.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan',
            patient.jenisKelamin == 'L' ? Icons.male : Icons.female,
            patient.jenisKelamin == 'L'
                ? const Color(0xFF3B82F6)
                : const Color(0xFFEC4899),
          ),
          _buildInfoRow(
            'Tempat Lahir',
            patient.tempatLahir,
            Icons.location_city_outlined,
            const Color(0xFFF59E0B),
          ),
          _buildInfoRow(
            'Tanggal Lahir',
            '${_formatDate(patient.tanggalLahir)} (${_calculateAge(patient.tanggalLahir)} tahun)',
            Icons.cake_outlined,
            const Color(0xFFEF4444),
          ),
          _buildInfoRow(
            'Golongan Darah',
            patient.golonganDarah ?? '-',
            Icons.bloodtype_outlined,
            const Color(0xFFDC2626),
          ),
          _buildInfoRow(
            'No. Telepon',
            patient.noTelp,
            Icons.phone_outlined,
            const Color(0xFF22C55E),
          ),
          _buildInfoRow(
            'Alamat',
            patient.alamat,
            Icons.home_outlined,
            const Color(0xFF6366F1),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kTextGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard() {
    if (_loadingRegistration) {
      return Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    if (_latestRegistration == null) {
      return const SizedBox.shrink();
    }

    final reg = _latestRegistration!;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: kWhite, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Informasi Registrasi',
                  style: TextStyle(
                    color: kWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRegInfoRow('No. Registrasi', reg.noReg),
          _buildRegInfoRow(
            'Tanggal Registrasi',
            _formatDateTime(reg.tglJamReg),
          ),
          _buildRegInfoRow(
            'Jadwal Kunjungan',
            '${_formatDate(reg.tanggalKunjungan.toIso8601String())} - ${reg.jamKunjungan}',
          ),
          _buildRegInfoRow('Jenis Kunjungan', reg.jenisKunjungan),
          _buildRegInfoRow('Tipe Pasien', reg.tipePasien),
          const Divider(color: Colors.white54, height: 24),
          const Text(
            'Penanggung Jawab',
            style: TextStyle(
              color: kWhite,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildRegInfoRow('Nama', reg.penanggungNama),
          _buildRegInfoRow('Telepon', reg.penanggungTelepon),
          _buildRegInfoRow('Alamat', reg.penanggungAlamat),
          if (reg.penanggungNoPegawai != null &&
              reg.penanggungNoPegawai!.isNotEmpty)
            _buildRegInfoRow('No. Pegawai', reg.penanggungNoPegawai!),
          if (reg.eselon != null && reg.eselon!.isNotEmpty)
            _buildRegInfoRow('Eselon', reg.eselon!),
        ],
      ),
    );
  }

  Widget _buildRegInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: kWhite.withOpacity(0.9), fontSize: 13),
            ),
          ),
          const Text(': ', style: TextStyle(color: kWhite, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: kWhite,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Pasien patient) {
    final bool isRegistered = patient.isRegistered ?? false;
    final bool hasRegistrationData = _latestRegistration != null;

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isRegistered
                  ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
                  : [kSecondaryColor, kSecondaryColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    (isRegistered ? const Color(0xFF3B82F6) : kSecondaryColor)
                        .withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final extra = {
                  'pasienId': patient.id,
                  'pasienNama': patient.nama,
                  if (hasRegistrationData)
                    'registrasiId': _latestRegistration!.id,
                  if (hasRegistrationData) 'isEdit': true,
                };

                final result = await context.push<String>(
                  '${AppRouter.patients}/register/${patient.id}',
                  extra: extra,
                );

                debugPrint('🔍 Registration result from detail: $result');

                if (result != null && mounted) {
                  debugPrint('✅ Processing result: $result');

                  await _reloadPatientData(patient.id);
                  debugPrint('✅ Patient data reloaded');

                  await _loadRegistrationData();
                  debugPrint('✅ Registration data reloaded');

                  String message;
                  Color backgroundColor;

                  switch (result) {
                    case 'created':
                      message = 'Registrasi untuk ${patient.nama} berhasil';
                      backgroundColor = kSuccessColor;
                      break;
                    case 'updated':
                      message =
                          'Registrasi untuk ${patient.nama} berhasil diupdate';
                      backgroundColor = kSuccessColor;
                      break;
                    case 'canceled':
                      message =
                          'Registrasi untuk ${patient.nama} berhasil dibatalkan';
                      backgroundColor = Colors.orange;
                      break;
                    default:
                      message = 'Operasi berhasil';
                      backgroundColor = kSuccessColor;
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: backgroundColor,
                      ),
                    );
                  }
                } else {
                  debugPrint('❌ Result is null or widget not mounted');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isRegistered
                          ? Icons.edit_calendar
                          : Icons.app_registration,
                      color: kWhite,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isRegistered
                          ? 'Edit Registrasi Kunjungan'
                          : 'Registrasikan Kunjungan',
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      final result = await context.push<bool>(
                        '${AppRouter.patients}/${patient.id}/edit',
                        extra: patient,
                      );
                      if (result == true && context.mounted) {
                        // Reload patient detail to update UI
                        context.read<PatientBloc>().add(
                          LoadPatientDetail(patient.id),
                        );
                        // Small delay then refresh list
                        await Future.delayed(const Duration(milliseconds: 150));
                        context.read<PatientBloc>().add(const LoadPatients());
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.edit_outlined,
                            color: kPrimaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Edit Data',
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 15,
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

            // Delete Button
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kButtonRed.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Hapus Data Pasien?'),
                          content: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(dialogContext).style,
                              children: [
                                const TextSpan(
                                  text:
                                      'Apakah Anda yakin ingin menghapus data ',
                                ),
                                TextSpan(
                                  text: patient.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      '?\nTindakan ini tidak dapat dibatalkan.',
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Batal'),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Hapus'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                context.read<PatientBloc>().add(
                                  DeletePatient(patient.id),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.delete_outline,
                            color: kButtonRed,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hapus',
                            style: TextStyle(
                              color: kButtonRed,
                              fontSize: 15,
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
    );
  }
}
