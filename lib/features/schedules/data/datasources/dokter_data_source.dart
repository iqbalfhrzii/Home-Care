import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/features/schedules/domain/models/dokter.dart';

class DokterDataSource {
  DokterDataSource(Dio _);

  // Parser removed in dummy mode

  // Mapper removed in dummy mode

  // Get all dokter (dummy)
  Future<DokterCollection> getAllDokter() async {
    debugPrint('ℹ️ Returning dummy dokter list');
    return DokterCollection(data: _dummyList(), total: 3);
  }

  // Get dokter by ID (dummy)
  Future<Dokter> getDokterById(String id) async {
    final list = _dummyList();
    return list.first;
  }

  // Get active dokter (dummy)
  Future<DokterCollection> getActiveDokter() async {
    debugPrint('ℹ️ Returning dummy active dokter list');
    return DokterCollection(data: _dummyList(), total: 3);
  }

  List<Dokter> _dummyList() => [
    Dokter(
      id: 1,
      dokterId: 'APT40',
      namaDokter: 'dr. Andi',
      bidangKeahlian: 'Umum',
      isActive: true,
    ),
    Dokter(
      id: 2,
      dokterId: 'APT41',
      namaDokter: 'dr. Budi',
      bidangKeahlian: 'Gigi',
      isActive: true,
    ),
    Dokter(
      id: 3,
      dokterId: 'APT42',
      namaDokter: 'dr. Chandra',
      bidangKeahlian: 'Anak',
      isActive: true,
    ),
  ];
}
