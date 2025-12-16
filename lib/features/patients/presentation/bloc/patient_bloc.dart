import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/pasien.dart';
import '../../data/repositories/pasien_repository.dart';
import '../../../schedules/data/repositories/registrasi_repository.dart';

part 'patient_event.dart';
part 'patient_state.dart';

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final PasienRepository repository;
  final RegistrasiRepository registrasiRepository;

  PatientBloc({required this.repository, required this.registrasiRepository})
      : super(const PatientInitial()) {
    on<LoadPatients>(_onLoadPatients);
    on<SearchPatients>(_onSearchPatients);
    on<FilterPatients>(_onFilterPatients);
    on<LoadPatientDetail>(_onLoadPatientDetail);
    on<CreatePatient>(_onCreatePatient);
    on<UpdatePatient>(_onUpdatePatient);
    on<DeletePatient>(_onDeletePatient);
    on<RefreshPatients>(_onRefreshPatients);
  }

  Future<void> _onLoadPatients(
    LoadPatients event,
    Emitter<PatientState> emit,
  ) async {
    emit(const PatientLoading());
    try {
      // Muat pasien terlebih dahulu
      final patients = await repository.getAllPasien();

      // Tampilkan indikator loading untuk registrasi
      emit(PatientListLoaded(
        patients: patients,
        filteredPatients: patients,
        isLoadingRegistrations: true,
      ));

      // Ambil semua registrasi lalu tandai pasien yang terdaftar
        final regs = await registrasiRepository.getAllRegistrasi();
        final registeredIds = regs
          .map((r) => r.safePasienId)
          .where((id) => id > 0)
          .toSet();

      final merged = patients.map((p) {
        if (registeredIds.contains(p.id)) {
          return p.copyWith(registrasi: const ['registered']);
        }
        return p;
      }).toList();

      emit(PatientListLoaded(
        patients: merged,
        filteredPatients: merged,
        isLoadingRegistrations: false,
      ));
    } catch (e) {
      emit(PatientError('Gagal memuat data pasien: ${e.toString()}'));
    }
  }

  Future<void> _onSearchPatients(
    SearchPatients event,
    Emitter<PatientState> emit,
  ) async {
    final currentState = state;
    print('🔍 Search triggered: "${event.query}"');

    if (currentState is PatientListLoaded) {
      if (event.query.isEmpty) {
        // Reset to show all patients (or apply active filter)
        List<Pasien> filtered = currentState.patients;
        if (currentState.activeFilter != null) {
          filtered = _applyFilter(filtered, currentState.activeFilter!);
        }

        emit(
          currentState.copyWith(filteredPatients: filtered, searchQuery: ''),
        );
      } else {
        // Filter locally
        var filtered = currentState.patients.where((patient) {
          final query = event.query.toLowerCase();
          return patient.nama.toLowerCase().contains(query) ||
              patient.mrn.toLowerCase().contains(query) ||
              patient.telepon.toLowerCase().contains(query);
        }).toList();

        print('🔍 Found ${filtered.length} results for "${event.query}"');

        // Apply active filter if any
        if (currentState.activeFilter != null) {
          filtered = _applyFilter(filtered, currentState.activeFilter!);
        }

        emit(
          currentState.copyWith(
            filteredPatients: filtered,
            searchQuery: event.query,
          ),
        );

        // Search from API removed - using local search only
      }
    }
  }

  Future<void> _onFilterPatients(
    FilterPatients event,
    Emitter<PatientState> emit,
  ) async {
    final currentState = state;

    if (currentState is PatientListLoaded) {
      List<Pasien> filtered = currentState.patients;

      // Apply filter
      if (event.filterType != null) {
        filtered = _applyFilter(filtered, event.filterType!);
      }

      // Apply search if active
      if (currentState.searchQuery.isNotEmpty) {
        filtered = filtered.where((patient) {
          final query = currentState.searchQuery.toLowerCase();
          return patient.nama.toLowerCase().contains(query) ||
              patient.mrn.toLowerCase().contains(query) ||
              patient.telepon.toLowerCase().contains(query);
        }).toList();
      }

      emit(
        currentState.copyWith(
          filteredPatients: filtered,
          activeFilter: event.filterType,
          clearFilter: event.filterType == null,
        ),
      );
    }
  }

  List<Pasien> _applyFilter(List<Pasien> patients, String filterType) {
    switch (filterType) {
      case 'registered':
        return patients.where((p) => p.isRegistered).toList();
      case 'unregistered':
        return patients.where((p) => !p.isRegistered).toList();
      default:
        return patients;
    }
  }

  Future<void> _onLoadPatientDetail(
    LoadPatientDetail event,
    Emitter<PatientState> emit,
  ) async {
    emit(const PatientLoading());
    try {
      final patients = await repository.getAllPasien();
      final patient = patients.where((p) => p.id == event.id).firstOrNull;
      if (patient != null) {
        emit(PatientDetailLoaded(patient));
      } else {
        emit(const PatientError('Pasien tidak ditemukan'));
      }
    } catch (e) {
      emit(PatientError('Gagal memuat detail pasien: ${e.toString()}'));
    }
  }

  Future<void> _onCreatePatient(
    CreatePatient event,
    Emitter<PatientState> emit,
  ) async {
    final currentState = state;
    emit(const PatientLoading());

    try {
      // Generate MRN unik: RM[YYMMDD][RANDOM5]
      final now = DateTime.now();
      final yy = now.year % 100;
      final mm = now.month.toString().padLeft(2, '0');
      final dd = now.day.toString().padLeft(2, '0');
      final rand = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
      final generatedMrn = 'RM$yy$mm$dd$rand';

      final newPasien = Pasien(
        id: 0,
        mrn: generatedMrn,
        nama: event.nama,
        tanggalLahir: event.tanggalLahir,
        jenisKelamin: event.jenisKelamin,
        alamat: event.alamat,
        telepon: event.telepon,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      await repository.createPasien(newPasien);

      // Reload patient list
      final patients = await repository.getAllPasien();
      emit(PatientListLoaded(patients: patients, filteredPatients: patients));

      emit(
        const PatientOperationSuccess(
          message: 'Pasien berhasil ditambahkan',
          type: PatientOperationType.create,
        ),
      );
    } catch (e) {
      emit(
        PatientError('Gagal menambahkan pasien: ${e.toString()}', currentState),
      );
    }
  }

  Future<void> _onUpdatePatient(
    UpdatePatient event,
    Emitter<PatientState> emit,
  ) async {
    final currentState = state;
    emit(const PatientLoading());

    try {
      // Ambil data lama untuk mempertahankan MRN dan timestamp jika perlu
      final existingList = await repository.getAllPasien();
      final existing = existingList.where((p) => p.id == event.id).firstOrNull;
      final updatedPasien = Pasien(
        id: event.id,
        mrn: existing?.mrn ?? '',
        nama: event.nama,
        tanggalLahir: event.tanggalLahir,
        jenisKelamin: event.jenisKelamin,
        alamat: event.alamat,
        telepon: event.telepon,
        createdAt: existing?.createdAt ?? DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      await repository.updatePasien(updatedPasien);

      // Reload patient list or detail
      final patients = await repository.getAllPasien();
      if (currentState is PatientListLoaded) {
        emit(PatientListLoaded(patients: patients, filteredPatients: patients));
      } else if (currentState is PatientDetailLoaded) {
        final patient = patients.where((p) => p.id == event.id).firstOrNull;
        if (patient != null) {
          emit(PatientDetailLoaded(patient));
        }
      }

      emit(
        const PatientOperationSuccess(
          message: 'Pasien berhasil diperbarui',
          type: PatientOperationType.update,
        ),
      );
    } catch (e) {
      emit(
        PatientError('Gagal memperbarui pasien: ${e.toString()}', currentState),
      );
    }
  }

  Future<void> _onDeletePatient(
    DeletePatient event,
    Emitter<PatientState> emit,
  ) async {
    final currentState = state;

    try {
      // Show loading only if not already loading
      if (state is! PatientLoading) {
        emit(const PatientLoading());
      }

      await repository.deletePasien(event.id);
      print('✅ Patient deleted successfully: ${event.id}');

      // Reload patient list
      final patients = await repository.getAllPasien();

      // Emit success with loaded data (single emit to prevent loops)
      emit(
        const PatientOperationSuccess(
          message: 'Pasien berhasil dihapus',
          type: PatientOperationType.delete,
        ),
      );

      // Then emit the new list
      emit(PatientListLoaded(patients: patients, filteredPatients: patients));
    } catch (e) {
      print('❌ Delete patient error: $e');
      emit(
        PatientError('Gagal menghapus pasien: ${e.toString()}', currentState),
      );
    }
  }

  Future<void> _onRefreshPatients(
    RefreshPatients event,
    Emitter<PatientState> emit,
  ) async {
    final currentState = state;
    print('🔄 RefreshPatients called');

    try {
      repository.clearCache();
      repository.clearCache();
      registrasiRepository.clearCache();
      final patients = await repository.getAllPasien();
      final regs = await registrasiRepository.getAllRegistrasi();
      final registeredIds = regs
          .map((r) => r.safePasienId)
          .where((id) => id > 0)
          .toSet();
      final merged = patients.map((p) {
        if (registeredIds.contains(p.id)) {
          return p.copyWith(registrasi: const ['registered']);
        }
        return p;
      }).toList();

      // Preserve search and filter state if exists
      if (currentState is PatientListLoaded) {
        print('🔄 Preserving search: "${currentState.searchQuery}"');
        print('🔄 Preserving filter: ${currentState.activeFilter}');

        List<Pasien> filtered = merged;

        // Re-apply active filter
        if (currentState.activeFilter != null) {
          filtered = _applyFilter(filtered, currentState.activeFilter!);
        }

        // Re-apply search query
        if (currentState.searchQuery.isNotEmpty) {
          filtered = filtered.where((patient) {
            final query = currentState.searchQuery.toLowerCase();
            return patient.nama.toLowerCase().contains(query) ||
                patient.mrn.toLowerCase().contains(query) ||
                patient.telepon.toLowerCase().contains(query);
          }).toList();
          print('🔄 After re-applying search: ${filtered.length} results');
        }

        emit(PatientListLoaded(
          patients: merged,
          filteredPatients: filtered,
          searchQuery: currentState.searchQuery,
          activeFilter: currentState.activeFilter,
        ));
      } else {
        emit(PatientListLoaded(patients: merged, filteredPatients: merged));
        emit(PatientListLoaded(patients: merged, filteredPatients: merged));
      }
    } catch (e) {
      print('❌ RefreshPatients error: $e');
      emit(PatientError('Gagal memperbarui data: ${e.toString()}'));
    }
  }
}
