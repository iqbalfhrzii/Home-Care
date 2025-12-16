import 'package:json_annotation/json_annotation.dart';

part 'dokter.g.dart';

@JsonSerializable()
class Dokter {
  @JsonKey(name: 'id')
  final int id;
  @JsonKey(name: 'dokter_id')
  final String dokterId;
  @JsonKey(name: 'nama_dokter')
  final String namaDokter;
  @JsonKey(name: 'bidang_keahlian')
  final String? bidangKeahlian;
  @JsonKey(name: 'is_active')
  final bool? isActive;

  Dokter({
    required this.id,
    required this.dokterId,
    required this.namaDokter,
    this.bidangKeahlian,
    this.isActive,
  });

  factory Dokter.fromJson(Map<String, dynamic> json) => _$DokterFromJson(json);
  Map<String, dynamic> toJson() => _$DokterToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dokter &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class DokterCollection {
  final List<Dokter> data;
  @JsonKey(name: 'total')
  final int? total;

  DokterCollection({required this.data, this.total});

  factory DokterCollection.fromJson(Map<String, dynamic> json) =>
      _$DokterCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$DokterCollectionToJson(this);
}
