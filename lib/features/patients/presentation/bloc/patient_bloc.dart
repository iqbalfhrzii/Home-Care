import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/pasien.dart';
import '../../data/repositories/pasien_repository.dart';

part 'patient_event.dart';
part 'patient_state.dart';

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  final PasienRepository repository;

  PatientBloc({required this.repository}) : super(const PatientInitial()) {
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
      final patients = await repository.getAllPasien();
      emit(PatientListLoaded(
        patients: patients,
        filteredPatients: patients,
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
        print('🔍 Empty query - showing all patients');
        // Reset to show all patients (or apply active filter)
        List<Pasien> filtered = currentState.patients;
        if (currentState.activeFilter != null) {
          filtered = _applyFilter(filtered, currentState.activeFilter!);
        }
        
        emit(currentState.copyWith(
          filteredPatients: filtered,
          searchQuery: '',
        ));
      } else {
        // Filter locally
        var filtered = currentState.patients.where((patient) {
          final query = event.query.toLowerCase();
          return patient.nama.toLowerCase().contains(query) ||
              patient.noRm.toLowerCase().contains(query) ||
              (patient.nik?.toLowerCase().contains(query) ?? false) ||
              (patient.noBpjs?.toLowerCase().contains(query) ?? false);
        }).toList();

        print('🔍 Found ${filtered.length} results for "${event.query}"');

        // Apply active filter if any
        if (currentState.activeFilter != null) {
          filtered = _applyFilter(filtered, currentState.activeFilter!);
        }

        emit(currentState.copyWith(
          filteredPatients: filtered,
          searchQuery: event.query,
        ));

        // Optionally search from API for more results
        if (event.searchFromApi) {
          try {
            final patients = await repository.searchPasien(event.query);
            emit(currentState.copyWith(
              patients: patients,
              filteredPatients: patients,
              searchQuery: event.query,
            ));
          } catch (e) {
            // Keep local filtered results on API error
            // Optionally emit error if needed
          }
        }
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
              patient.noRm.toLowerCase().contains(query) ||
              (patient.nik?.toLowerCase().contains(query) ?? false) ||
              (patient.noBpjs?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      
      emit(currentState.copyWith(
        filteredPatients: filtered,
        activeFilter: event.filterType,
        clearFilter: event.filterType == null,
      ));
    }
  }

  List<Pasien> _applyFilter(List<Pasien> patients, String filterType) {
    switch (filterType) {
      case 'registered':
        return patients.where((p) => p.isRegistered ?? false).toList();
      case 'unregistered':
        return patients.where((p) => !(p.isRegistered ?? false)).toList();
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
      final patient = await repository.getPasienById(event.id);
      emit(PatientDetailLoaded(patient));
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
      await repository.createPasien(
        nama: event.nama,
        tempatLahir: event.tempatLahir,
        tanggalLahir: event.tanggalLahir,
        jenisKelamin: event.jenisKelamin,
        alamat: event.alamat,
        noTelp: event.noTelp,
        nik: event.nik,
        noBpjs: event.noBpjs,
        golonganDarah: event.golonganDarah,
      );

      // Reload patient list
      final patients = await repository.getAllPasien();
      emit(PatientListLoaded(
        patients: patients,
        filteredPatients: patients,
      ));

      emit(const PatientOperationSuccess(
        message: 'Pasien berhasil ditambahkan',
        type: PatientOperationType.create,
      ));
    } catch (e) {
      emit(PatientError(
        'Gagal menambahkan pasien: ${e.toString()}',
        currentState,
      ));
    }
  }

  Future<void> _onUpdatePatient(
    UpdatePatient event,
    Emitter<PatientState> emit,
  ) async {
    final currentState = state;
    emit(const PatientLoading());
    
    try {
      await repository.updatePasien(
        id: event.id,
        nama: event.nama,
        tempatLahir: event.tempatLahir,
        tanggalLahir: event.tanggalLahir,
        jenisKelamin: event.jenisKelamin,
        alamat: event.alamat,
        noTelp: event.noTelp,
        nik: event.nik,
        noBpjs: event.noBpjs,
        golonganDarah: event.golonganDarah,
      );

      // Reload patient list or detail
      if (currentState is PatientListLoaded) {
        final patients = await repository.getAllPasien();
        emit(PatientListLoaded(
          patients: patients,
          filteredPatients: patients,
        ));
      } else if (currentState is PatientDetailLoaded) {
        final patient = await repository.getPasienById(event.id);
        emit(PatientDetailLoaded(patient));
      }

      emit(const PatientOperationSuccess(
        message: 'Pasien berhasil diperbarui',
        type: PatientOperationType.update,
      ));
    } catch (e) {
      emit(PatientError(
        'Gagal memperbarui pasien: ${e.toString()}',
        currentState,
      ));
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
      emit(const PatientOperationSuccess(
        message: 'Pasien berhasil dihapus',
        type: PatientOperationType.delete,
      ));
      
      // Then emit the new list
      emit(PatientListLoaded(
        patients: patients,
        filteredPatients: patients,
      ));
    } catch (e) {
      print('❌ Delete patient error: $e');
      emit(PatientError(
        'Gagal menghapus pasien: ${e.toString()}',
        currentState,
      ));
    }
  }

  Future<void> _onRefreshPatients(
    RefreshPatients event,
    Emitter<PatientState> emit,
  ) async {
    final currentState = state;
    print('🔄 RefreshPatients called');
    
    try {
      final patients = await repository.getAllPasien();
      
      // Preserve search and filter state if exists
      if (currentState is PatientListLoaded) {
        print('🔄 Preserving search: "${currentState.searchQuery}"');
        print('🔄 Preserving filter: ${currentState.activeFilter}');
        
        List<Pasien> filtered = patients;
        
        // Re-apply active filter
        if (currentState.activeFilter != null) {
          filtered = _applyFilter(filtered, currentState.activeFilter!);
        }
        
        // Re-apply search query
        if (currentState.searchQuery.isNotEmpty) {
          filtered = filtered.where((patient) {
            final query = currentState.searchQuery.toLowerCase();
            return patient.nama.toLowerCase().contains(query) ||
                patient.noRm.toLowerCase().contains(query) ||
                (patient.nik?.toLowerCase().contains(query) ?? false) ||
                (patient.noBpjs?.toLowerCase().contains(query) ?? false);
          }).toList();
          print('🔄 After re-applying search: ${filtered.length} results');
        }
        
        emit(PatientListLoaded(
          patients: patients,
          filteredPatients: filtered,
          searchQuery: currentState.searchQuery,
          activeFilter: currentState.activeFilter,
        ));
      } else {
        print('🔄 First load, no filters to preserve');
        // First load, no filters to preserve
        emit(PatientListLoaded(
          patients: patients,
          filteredPatients: patients,
        ));
      }
    } catch (e) {
      print('❌ RefreshPatients error: $e');
      emit(PatientError('Gagal memperbarui data: ${e.toString()}'));
    }
  }
}
