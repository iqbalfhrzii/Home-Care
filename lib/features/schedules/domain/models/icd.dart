import 'package:json_annotation/json_annotation.dart';

part 'icd.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Diagnosa {
  final int id;
  @JsonKey(name: 'kunjungan_id')
  final int kunjunganId;
  @JsonKey(name: 'kode_icd')
  final String kodeIcd;
  @JsonKey(name: 'nama_icd')
  final String namaIcd;
  @JsonKey(name: 'is_primary')
  final bool isPrimary; // Primary diagnosis
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Diagnosa({
    required this.id,
    required this.kunjunganId,
    required this.kodeIcd,
    required this.namaIcd,
    this.isPrimary = false,
    required this.createdAt,
  });

  factory Diagnosa.fromJson(Map<String, dynamic> json) =>
      _$DiagnosaFromJson(json);

  Map<String, dynamic> toJson() => _$DiagnosaToJson(this);

  Diagnosa copyWith({
    int? id,
    int? kunjunganId,
    String? kodeIcd,
    String? namaIcd,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return Diagnosa(
      id: id ?? this.id,
      kunjunganId: kunjunganId ?? this.kunjunganId,
      kodeIcd: kodeIcd ?? this.kodeIcd,
      namaIcd: namaIcd ?? this.namaIcd,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
