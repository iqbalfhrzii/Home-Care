import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/features/schedules/domain/models/poli.dart';

class PoliDataSource {
  PoliDataSource(Dio _);

  // Get all poli (dummy)
  Future<PoliCollection> getAllPoli() async {
    debugPrint('ℹ️ Returning dummy poli list');
    return PoliCollection(data: _dummyList(), total: 3);
  }

  // Get poli by kode (dummy)
  Future<Poli> getPoliByKode(String kode) async {
    final list = _dummyList();
    return list.first;
  }

  // Get active poli (dummy)
  Future<PoliCollection> getActivePoli() async {
    debugPrint('ℹ️ Returning dummy active poli list');
    return PoliCollection(data: _dummyList(), total: 3);
  }

  List<Poli> _dummyList() => [
    Poli(
      kodePoli: 'HC',
      namaPoli: 'Home Care',
      deskripsi: 'Kunjungan rumah',
      status: 'aktif',
    ),
    Poli(
      kodePoli: 'UM',
      namaPoli: 'Umum',
      deskripsi: 'Poli umum',
      status: 'aktif',
    ),
    Poli(
      kodePoli: 'AN',
      namaPoli: 'Anak',
      deskripsi: 'Poli anak',
      status: 'aktif',
    ),
  ];
}
