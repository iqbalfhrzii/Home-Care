import 'package:json_annotation/json_annotation.dart';

part 'tindakan.dart.g.dart';

@JsonSerializable()
class TindakanPivot {
  final String jumlah;
  @JsonKey(name: 'harga_satuan')
  final String hargaSatuan;
  final String diskon;
  final String subtotal;
  @JsonKey(name: 'petugas_nama')
  final String petugasNama;
  final String keterangan;

  TindakanPivot({
    required this.jumlah,
    required this.hargaSatuan,
    required this.diskon,
    required this.subtotal,
    required this.petugasNama,
    required this.keterangan,
  });

  factory TindakanPivot.fromJson(Map<String, dynamic> json) =>
      _$TindakanPivotFromJson(json);
  Map<String, dynamic> toJson() => _$TindakanPivotToJson(this);
}

@JsonSerializable()
class Tindakan {
  final String id;
  final String kode;
  @JsonKey(name: 'nama_tindakan')
  final String namaTindakan;
  final String kategori;
  final String harga;
  @JsonKey(name: 'is_active')
  final String isActive;
  final TindakanPivot? pivot;

  Tindakan({
    required this.id,
    required this.kode,
    required this.namaTindakan,
    required this.kategori,
    required this.harga,
    required this.isActive,
    this.pivot,
  });

  factory Tindakan.fromJson(Map<String, dynamic> json) =>
      _$TindakanFromJson(json);
  Map<String, dynamic> toJson() => _$TindakanToJson(this);
}

@JsonSerializable()
class TindakanCollection {
  final List<Tindakan> data;

  TindakanCollection({required this.data});

  factory TindakanCollection.fromJson(Map<String, dynamic> json) =>
      _$TindakanCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$TindakanCollectionToJson(this);
}

@JsonSerializable()
class AttachTindakanRequest {
  @JsonKey(name: 'tindakan_id')
  final int tindakanId;
  final int jumlah;
  @JsonKey(name: 'harga_satuan')
  final int hargaSatuan;
  final int diskon;
  @JsonKey(name: 'petugas_nama')
  final String petugasNama;
  final String keterangan;

  AttachTindakanRequest({
    required this.tindakanId,
    this.jumlah = 1,
    required this.hargaSatuan,
    this.diskon = 0,
    required this.petugasNama,
    required this.keterangan,
  });

  factory AttachTindakanRequest.fromJson(Map<String, dynamic> json) =>
      _$AttachTindakanRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AttachTindakanRequestToJson(this);
}
