part of 'patient_bloc.dart';

abstract class PatientEvent extends Equatable {
  const PatientEvent();

  @override
  List<Object?> get props => [];
}

class ReadManyPatientEvent extends PatientEvent {
  final int page;
  const ReadManyPatientEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class ReadPatientEvent extends PatientEvent {
  final int patientId;
  const ReadPatientEvent(this.patientId);
}
