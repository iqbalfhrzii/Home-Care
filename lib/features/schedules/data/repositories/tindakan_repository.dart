import 'package:homecare_mobile/features/schedules/domain/models/tindakan.dart';
import 'package:flutter/foundation.dart';

class TindakanRepository {
  TindakanRepository();

  Future<List<Tindakan>> getAllTindakan() async {
    debugPrint('📥 Loading dummy tindakan');
    return [];
  }

  Future<Tindakan> getTindakanById(int id) async {
    throw UnimplementedError('Dummy only');
  }

  Future<Tindakan> createTindakan(Tindakan tindakan) async {
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('ℹ️ Create tindakan disabled (dummy)');
    return tindakan;
  }

  Future<void> updateTindakan(Tindakan tindakan) async {
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('ℹ️ Update tindakan disabled (dummy)');
  }

  Future<void> deleteTindakan(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('ℹ️ Delete tindakan disabled (dummy)');
  }
}
