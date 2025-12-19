part of 'patient_bloc.dart';

abstract class PatientState {
  const PatientState();
}

class PatientInitial extends PatientState {
  const PatientInitial();
}

class PatientLoading extends PatientState {
  const PatientLoading();
}

class PatientListLoaded extends PatientState {
  final List<Pasien> patients;
  final List<Pasien> filteredPatients;
  final String searchQuery;
  final String? activeFilter; // null, 'registered', 'unregistered'
  final bool isLoadingRegistrations; // true ketika sedang fetch registrations
  final int? registrasiCount;

  const PatientListLoaded({
    required this.patients,
    required this.filteredPatients,
    this.searchQuery = '',
    this.activeFilter,
    this.isLoadingRegistrations = false,
    this.registrasiCount,
  });

  PatientListLoaded copyWith({
    List<Pasien>? patients,
    List<Pasien>? filteredPatients,
    String? searchQuery,
    String? activeFilter,
    bool clearFilter = false,
    bool? isLoadingRegistrations,
    int? registrasiCount,
  }) {
    return PatientListLoaded(
      patients: patients ?? this.patients,
      filteredPatients: filteredPatients ?? this.filteredPatients,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      isLoadingRegistrations:
          isLoadingRegistrations ?? this.isLoadingRegistrations,
      registrasiCount: registrasiCount ?? this.registrasiCount,
    );
  }

  int get totalPatients => patients.length;
  int get maleCount => patients.where((p) => p.jenisKelamin == 'L').length;
  int get femaleCount => patients.where((p) => p.jenisKelamin == 'P').length;

  // Hitung berdasarkan array registrasi dari API
  int get registeredCount =>
      registrasiCount ?? patients.where((p) => p.isRegistered).length;
  int get unregisteredCount =>
      (patients.length - registeredCount).clamp(0, patients.length);
}

class PatientDetailLoaded extends PatientState {
  final Pasien patient;

  const PatientDetailLoaded(this.patient);
}

class PatientOperationSuccess extends PatientState {
  final String message;
  final PatientOperationType type;

  const PatientOperationSuccess({required this.message, required this.type});
}

class PatientError extends PatientState {
  final String message;
  final PatientState? previousState;

  const PatientError(this.message, [this.previousState]);
}

enum PatientOperationType { create, update, delete }
