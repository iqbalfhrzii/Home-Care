import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';
import 'package:homecare_mobile/features/patients/domain/usecases/read_patient_by_id_usecase.dart';
import 'package:homecare_mobile/features/patients/domain/usecases/read_patients_usecase.dart';
import 'package:homecare_mobile/shared/domain/models/pagination_meta.dart';

part 'patient_event.dart';
part 'patient_state.dart';

class PatientListBloc extends Bloc<PatientEvent, PatientState> {
  final ReadPatientsUseCase _readPatientsUseCase;

  PatientListBloc({required ReadPatientsUseCase readPatientsUseCase})
    : _readPatientsUseCase = readPatientsUseCase,
      super(const PatientInitial()) {
    on<ReadManyPatientEvent>(_onFetchPatients);
  }

  Future<void> _onFetchPatients(
    ReadManyPatientEvent event,
    Emitter<PatientState> emit,
  ) async {
    if (state is! PatientReadManySuccess) {
      emit(const PatientLoading());
    }
    final result = await _readPatientsUseCase(event.page).run();
    result.fold(
      (e) => emit(PatientError(e.toString())),
      (result) => emit(
        PatientReadManySuccess(
          patients: result.patients,
          pagination: result.pagination,
        ),
      ),
    );
  }
}

class PatientDetailsBloc extends Bloc<PatientEvent, PatientState> {
  final ReadPatientByIdUseCase _readPatientByIdUseCase;

  PatientDetailsBloc({required ReadPatientByIdUseCase readPatientByIdUseCase})
    : _readPatientByIdUseCase = readPatientByIdUseCase,
      super(const PatientInitial()) {
    on<ReadPatientEvent>(_onReadPatient);
  }

  Future<void> _onReadPatient(
    ReadPatientEvent event,
    Emitter<PatientState> emit,
  ) async {
    emit(const PatientLoading());

    final result = await _readPatientByIdUseCase(event.patientId).run();

    result.fold(
      (error) => emit(PatientError(error.toString())),
      (patient) => emit(PatientReadSuccess(patient)),
    );
  }
}
