import 'package:dio/dio.dart';
import 'package:homecare_mobile/core/error/exceptions.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';
import 'package:homecare_mobile/shared/domain/models/pagination_meta.dart';

abstract class PatientRemoteDataSource {
  Future<({List<Patient> patients, PaginationMeta pagination})> getPatients(
    int page,
  );
  Future<Patient> getPatientById(int id);
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final Dio _dio;

  const PatientRemoteDataSourceImpl(this._dio);

  @override
  Future<({List<Patient> patients, PaginationMeta pagination})> getPatients(
    int page,
  ) async {
    try {
      final response = await _dio.get(
        '/patients',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final paginationJson =
            response.data['pagination'] as Map<String, dynamic>;

        final patients = data
            .map((p) => Patient.fromJson(p as Map<String, dynamic>))
            .toList();

        final pagination = PaginationMeta.fromJson(paginationJson);

        return (patients: patients, pagination: pagination);
      } else {
        throw const ServerException('Failed to load patients');
      }
    } on DioException catch (e) {
      throw ServerException('Network error: ${e.message}');
    }
  }

  @override
  Future<Patient> getPatientById(int id) async {
    try {
      final response = await _dio.get('/patients/$id');

      if (response.statusCode == 200) {
        return Patient.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw const ServerException('Failed to load patient');
      }
    } on DioException catch (e) {
      throw ServerException('Network error: ${e.message}');
    }
  }
}
