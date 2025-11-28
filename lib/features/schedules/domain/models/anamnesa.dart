import 'package:json_annotation/json_annotation.dart';

part 'anamnesa.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Anamnesa {
  final int id;
  final int registrasiId;
  final int? dokterId;
  final String? poliId;
  final String? tanggal;

  // JSON fields - stored as Map in domain, String in DB
  final Map<String, dynamic>? pengkajianKeperawatan;
  final Map<String, dynamic>? pengkajianMedis;
  final Map<String, dynamic>? khususPerawat;

  final String? createdAt;
  final String? updatedAt;

  const Anamnesa({
    required this.id,
    required this.registrasiId,
    this.dokterId,
    this.poliId,
    this.tanggal,
    this.pengkajianKeperawatan,
    this.pengkajianMedis,
    this.khususPerawat,
    this.createdAt,
    this.updatedAt,
  });

  factory Anamnesa.fromJson(Map<String, dynamic> json) =>
      _$AnamnesaFromJson(json);

  Map<String, dynamic> toJson() => _$AnamnesaToJson(this);

  Anamnesa copyWith({
    int? id,
    int? registrasiId,
    int? dokterId,
    String? poliId,
    String? tanggal,
    Map<String, dynamic>? pengkajianKeperawatan,
    Map<String, dynamic>? pengkajianMedis,
    Map<String, dynamic>? khususPerawat,
    String? createdAt,
    String? updatedAt,
  }) {
    return Anamnesa(
      id: id ?? this.id,
      registrasiId: registrasiId ?? this.registrasiId,
      dokterId: dokterId ?? this.dokterId,
      poliId: poliId ?? this.poliId,
      tanggal: tanggal ?? this.tanggal,
      pengkajianKeperawatan:
          pengkajianKeperawatan ?? this.pengkajianKeperawatan,
      pengkajianMedis: pengkajianMedis ?? this.pengkajianMedis,
      khususPerawat: khususPerawat ?? this.khususPerawat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class AnamnesaCollection {
  final List<Anamnesa> data;

  const AnamnesaCollection({required this.data});

  factory AnamnesaCollection.fromJson(Map<String, dynamic> json) =>
      _$AnamnesaCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$AnamnesaCollectionToJson(this);
}
