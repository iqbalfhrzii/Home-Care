import 'dart:convert';
import 'package:homecare_mobile/shared/local_db/app_database.dart';
import 'package:homecare_mobile/features/schedules/domain/models/anamnesa.dart'
    as domain;
import 'package:drift/drift.dart' as drift;

class AnamnesaLocalDataSource {
  final AppDatabase _database;

  AnamnesaLocalDataSource(this._database);

  // Convert Drift Anamnesa to Domain Anamnesa
  domain.Anamnesa _toDomainModel(Anamnesa driftAnamnesa) {
    return domain.Anamnesa(
      id: driftAnamnesa.id,
      registrasiId: driftAnamnesa.registrasiId,
      dokterId: driftAnamnesa.dokterId,
      poliId: driftAnamnesa.poliId,
      tanggal: driftAnamnesa.tanggal,
      // Convert JSON strings to Map
      pengkajianKeperawatan: driftAnamnesa.pengkajianKeperawatan != null
          ? json.decode(driftAnamnesa.pengkajianKeperawatan!)
                as Map<String, dynamic>
          : null,
      pengkajianMedis: driftAnamnesa.pengkajianMedis != null
          ? json.decode(driftAnamnesa.pengkajianMedis!) as Map<String, dynamic>
          : null,
      khususPerawat: driftAnamnesa.khususPerawat != null
          ? json.decode(driftAnamnesa.khususPerawat!) as Map<String, dynamic>
          : null,
      createdAt: driftAnamnesa.createdAt.toIso8601String(),
      updatedAt: driftAnamnesa.updatedAt.toIso8601String(),
    );
  }

  // Get all anamnesa
  Future<List<domain.Anamnesa>> getAllAnamnesa() async {
    final anamnesas = await _database.getAllAnamnesas();
    return anamnesas.map(_toDomainModel).toList();
  }

  // Get anamnesa by ID
  Future<domain.Anamnesa> getAnamnesaById(int id) async {
    final anamnesa = await _database.getAnamnesaById(id);
    if (anamnesa == null) {
      throw Exception('Anamnesa with id $id not found');
    }
    return _toDomainModel(anamnesa);
  }

  // Get anamnesa by registrasi ID
  Future<List<domain.Anamnesa>> getAnamnesaByRegistrasiId(
    int registrasiId,
  ) async {
    final anamnesas = await _database.getAnamnesasByRegistrasiId(registrasiId);
    return anamnesas.map(_toDomainModel).toList();
  }

  // Create new anamnesa
  Future<domain.Anamnesa> createAnamnesa(Map<String, dynamic> data) async {
    final companion = AnamnesasCompanion(
      registrasiId: drift.Value(data['registrasi_id'] as int),
      dokterId: data['dokter_id'] != null
          ? drift.Value(data['dokter_id'] as int)
          : const drift.Value.absent(),
      poliId: data['poli_id'] != null
          ? drift.Value(data['poli_id'] as String)
          : const drift.Value.absent(),
      tanggal: data['tanggal'] != null
          ? drift.Value(data['tanggal'] as String)
          : const drift.Value.absent(),
      // Convert Map to JSON string
      pengkajianKeperawatan: data['pengkajian_keperawatan'] != null
          ? drift.Value(json.encode(data['pengkajian_keperawatan']))
          : const drift.Value.absent(),
      pengkajianMedis: data['pengkajian_medis'] != null
          ? drift.Value(json.encode(data['pengkajian_medis']))
          : const drift.Value.absent(),
      khususPerawat: data['khusus_perawat'] != null
          ? drift.Value(json.encode(data['khusus_perawat']))
          : const drift.Value.absent(),
      isSynced: const drift.Value(false), // Will sync later
    );

    final id = await _database.insertAnamnesa(companion);
    return getAnamnesaById(id);
  }

  // Update anamnesa
  Future<domain.Anamnesa> updateAnamnesa(
    int id,
    Map<String, dynamic> data,
  ) async {
    final companion = AnamnesasCompanion(
      registrasiId: data['registrasi_id'] != null
          ? drift.Value(data['registrasi_id'] as int)
          : const drift.Value.absent(),
      dokterId: data['dokter_id'] != null
          ? drift.Value(data['dokter_id'] as int)
          : const drift.Value.absent(),
      poliId: data['poli_id'] != null
          ? drift.Value(data['poli_id'] as String)
          : const drift.Value.absent(),
      tanggal: data['tanggal'] != null
          ? drift.Value(data['tanggal'] as String)
          : const drift.Value.absent(),
      // Convert Map to JSON string
      pengkajianKeperawatan: data['pengkajian_keperawatan'] != null
          ? drift.Value(json.encode(data['pengkajian_keperawatan']))
          : const drift.Value.absent(),
      pengkajianMedis: data['pengkajian_medis'] != null
          ? drift.Value(json.encode(data['pengkajian_medis']))
          : const drift.Value.absent(),
      khususPerawat: data['khusus_perawat'] != null
          ? drift.Value(json.encode(data['khusus_perawat']))
          : const drift.Value.absent(),
      updatedAt: drift.Value(DateTime.now()),
    );

    await _database.updateAnamnesa(id, companion);
    return getAnamnesaById(id);
  }

  // Delete anamnesa
  Future<void> deleteAnamnesa(int id) async {
    await _database.deleteAnamnesa(id);
  }

  // Upsert anamnesa from API (for sync)
  Future<void> upsertAnamnesa(domain.Anamnesa anamnesa) async {
    final existing = await _database.getAnamnesaById(anamnesa.id);

    final companion = AnamnesasCompanion(
      id: drift.Value(anamnesa.id),
      registrasiId: drift.Value(anamnesa.registrasiId),
      dokterId: anamnesa.dokterId != null
          ? drift.Value(anamnesa.dokterId!)
          : const drift.Value.absent(),
      poliId: anamnesa.poliId != null
          ? drift.Value(anamnesa.poliId!)
          : const drift.Value.absent(),
      tanggal: anamnesa.tanggal != null
          ? drift.Value(anamnesa.tanggal!)
          : const drift.Value.absent(),
      // Convert Map to JSON string
      pengkajianKeperawatan: anamnesa.pengkajianKeperawatan != null
          ? drift.Value(json.encode(anamnesa.pengkajianKeperawatan))
          : const drift.Value.absent(),
      pengkajianMedis: anamnesa.pengkajianMedis != null
          ? drift.Value(json.encode(anamnesa.pengkajianMedis))
          : const drift.Value.absent(),
      khususPerawat: anamnesa.khususPerawat != null
          ? drift.Value(json.encode(anamnesa.khususPerawat))
          : const drift.Value.absent(),
      isSynced: const drift.Value(true), // From API
      serverId: drift.Value(anamnesa.id), // Server ID
      createdAt: anamnesa.createdAt != null
          ? drift.Value(DateTime.parse(anamnesa.createdAt!))
          : const drift.Value.absent(),
      updatedAt: anamnesa.updatedAt != null
          ? drift.Value(DateTime.parse(anamnesa.updatedAt!))
          : drift.Value(DateTime.now()),
    );

    if (existing != null) {
      // Update existing
      await _database.updateAnamnesa(existing.id, companion);
    } else {
      // Insert new
      await _database.insertAnamnesa(companion);
    }
  }

  // Search anamnesa locally (simple search in tanggal field)
  Future<List<domain.Anamnesa>> searchAnamnesa(String query) async {
    final allAnamnesas = await _database.getAllAnamnesas();
    final filtered = allAnamnesas.where((anamnesa) {
      return anamnesa.tanggal?.toLowerCase().contains(query.toLowerCase()) ??
          false;
    }).toList();
    return filtered.map(_toDomainModel).toList();
  }

  // Get anamnesa by date
  Future<List<domain.Anamnesa>> getAnamnesaByDate(String date) async {
    final allAnamnesas = await _database.getAllAnamnesas();
    final filtered = allAnamnesas.where((anamnesa) {
      return anamnesa.tanggal?.startsWith(date) ?? false;
    }).toList();
    return filtered.map(_toDomainModel).toList();
  }
}
