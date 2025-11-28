part of 'patient_bloc.dart';

abstract class PatientState extends Equatable {
  const PatientState();

  @override
  List<Object?> get props => [];
}

class PatientInitial extends PatientState {
  const PatientInitial();
}

class PatientLoading extends PatientState {
  const PatientLoading();
}

class PatientReadManySuccess extends PatientState {
  final List<Patient> patients;
  final PaginationMeta pagination;

  const PatientReadManySuccess({
    required this.patients,
    required this.pagination,
  });

  @override
  List<Object?> get props => [patients, pagination];
}

class PatientReadSuccess extends PatientState {
  final Patient patient;

  const PatientReadSuccess(this.patient);

  @override
  List<Object?> get props => [patient];
}

class PatientError extends PatientState {
  final String message;
  const PatientError(this.message);
  @override
  List<Object?> get props => [message];
}
