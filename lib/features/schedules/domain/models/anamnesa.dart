import 'package:json_annotation/json_annotation.dart';

part 'anamnesa.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Anamnesa {
  final int id;
  @JsonKey(name: 'kunjungan_id')
  final int kunjunganId;
  @JsonKey(name: 'keluhan_utama')
  final String keluhanUtama;
  @JsonKey(name: 'riwayat_penyakit_sekarang')
  final String riwayatPenyakitSekarang;
  @JsonKey(name: 'riwayat_penyakit_dahulu')
  final String? riwayatPenyakitDahulu;
  @JsonKey(name: 'riwayat_penyakit_keluarga')
  final String? riwayatPenyakitKeluarga;
  @JsonKey(name: 'riwayat_alergi')
  final String? riwayatAlergi;
  @JsonKey(name: 'tekanan_darah')
  final String? tekananDarah; // e.g., "120/80"
  final int? nadi; // beats per minute
  @JsonKey(name: 'suhu_tubuh')
  final double? suhuTubuh; // Celsius
  final int? pernapasan; // breaths per minute
  final String? catatan;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Anamnesa({
    required this.id,
    required this.kunjunganId,
    required this.keluhanUtama,
    required this.riwayatPenyakitSekarang,
    this.riwayatPenyakitDahulu,
    this.riwayatPenyakitKeluarga,
    this.riwayatAlergi,
    this.tekananDarah,
    this.nadi,
    this.suhuTubuh,
    this.pernapasan,
    this.catatan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Anamnesa.fromJson(Map<String, dynamic> json) =>
      _$AnamnesaFromJson(json);

  Map<String, dynamic> toJson() => _$AnamnesaToJson(this);

  Anamnesa copyWith({
    int? id,
    int? kunjunganId,
    String? keluhanUtama,
    String? riwayatPenyakitSekarang,
    String? riwayatPenyakitDahulu,
    String? riwayatPenyakitKeluarga,
    String? riwayatAlergi,
    String? tekananDarah,
    int? nadi,
    double? suhuTubuh,
    int? pernapasan,
    String? catatan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Anamnesa(
      id: id ?? this.id,
      kunjunganId: kunjunganId ?? this.kunjunganId,
      keluhanUtama: keluhanUtama ?? this.keluhanUtama,
      riwayatPenyakitSekarang:
          riwayatPenyakitSekarang ?? this.riwayatPenyakitSekarang,
      riwayatPenyakitDahulu:
          riwayatPenyakitDahulu ?? this.riwayatPenyakitDahulu,
      riwayatPenyakitKeluarga:
          riwayatPenyakitKeluarga ?? this.riwayatPenyakitKeluarga,
      riwayatAlergi: riwayatAlergi ?? this.riwayatAlergi,
      tekananDarah: tekananDarah ?? this.tekananDarah,
      nadi: nadi ?? this.nadi,
      suhuTubuh: suhuTubuh ?? this.suhuTubuh,
      pernapasan: pernapasan ?? this.pernapasan,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
