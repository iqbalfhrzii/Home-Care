import 'package:json_annotation/json_annotation.dart';

part 'poli.g.dart';

@JsonSerializable()
class Poli {
  @JsonKey(name: 'kode_poli')
  final String kodePoli;
  @JsonKey(name: 'nama_poli')
  final String namaPoli;
  @JsonKey(name: 'deskripsi')
  final String? deskripsi;
  @JsonKey(name: 'status')
  final String? status;

  Poli({
    required this.kodePoli,
    required this.namaPoli,
    this.deskripsi,
    this.status,
  });

  factory Poli.fromJson(Map<String, dynamic> json) => _$PoliFromJson(json);
  Map<String, dynamic> toJson() => _$PoliToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Poli &&
          runtimeType == other.runtimeType &&
          kodePoli == other.kodePoli;

  @override
  int get hashCode => kodePoli.hashCode;
}

@JsonSerializable()
class PoliCollection {
  final List<Poli> data;
  @JsonKey(name: 'total')
  final int? total;

  PoliCollection({required this.data, this.total});

  factory PoliCollection.fromJson(Map<String, dynamic> json) =>
      _$PoliCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$PoliCollectionToJson(this);
}
