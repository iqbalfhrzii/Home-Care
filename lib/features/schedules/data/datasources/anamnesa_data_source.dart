import 'package:dio/dio.dart';
import 'package:homecare_mobile/features/schedules/domain/models/anamnesa.dart';

class AnamnesaDataSource {
  AnamnesaDataSource(Dio _);

  // GET /anamnesa - Get all anamnesa
  Future<AnamnesaCollection> getAllAnamnesa() async {
    return AnamnesaCollection(data: const []);
  }

  // GET /anamnesa/{id} - Get anamnesa by ID
  Future<Anamnesa> getAnamnesaById(int id) async {
    throw UnimplementedError('Dummy only');
  }

  // POST /anamnesa - Create new anamnesa
  Future<Anamnesa> createAnamnesa(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 200));
    throw UnimplementedError('Dummy only');
  }

  // PUT /anamnesa/{id} - Update anamnesa
  Future<Anamnesa> updateAnamnesa(int id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 200));
    throw UnimplementedError('Dummy only');
  }

  // DELETE /anamnesa/{id} - Delete anamnesa
  Future<void> deleteAnamnesa(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // GET /anamnesa?search=query - Search anamnesa
  Future<AnamnesaCollection> searchAnamnesa(String query) async {
    return AnamnesaCollection(data: const []);
  }

  // GET /anamnesa?registrasi_id={id} - Get anamnesa by registrasi ID
  Future<AnamnesaCollection> getAnamnesaByRegistrasiId(int registrasiId) async {
    return AnamnesaCollection(data: const []);
  }

  // GET /anamnesa?tanggal={date} - Get anamnesa by date
  Future<AnamnesaCollection> getAnamnesaByDate(String date) async {
    return AnamnesaCollection(data: const []);
  }
}
