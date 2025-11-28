import 'package:homecare_mobile/features/patients/domain/models/patient.dart';
import 'package:homecare_mobile/shared/domain/models/pagination_meta.dart';

class PatientsResponse {
  final List<Patient> patients;
  final PaginationMeta pagination;

  PatientsResponse({required this.patients, required this.pagination});
}
