import 'package:json_annotation/json_annotation.dart';

part 'kunjungan.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Kunjungan {
  final int id;
  @JsonKey(name: 'no_kunjungan')
  final String noKunjungan;
  @JsonKey(name: 'pasien_id')
  final int pasienId;
  @JsonKey(name: 'tanggal_kunjungan')
  final DateTime tanggalKunjungan;
  final String status; // dalam_proses, selesai
  @JsonKey(name: 'progress_step')
  final int progressStep; // 0-3 (0=baru, 1=anamnesa, 2=diagnosa, 3=tindakan)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Kunjungan({
    required this.id,
    required this.noKunjungan,
    required this.pasienId,
    required this.tanggalKunjungan,
    this.status = 'dalam_proses',
    this.progressStep = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Kunjungan.fromJson(Map<String, dynamic> json) =>
      _$KunjunganFromJson(json);

  Map<String, dynamic> toJson() => _$KunjunganToJson(this);

  Kunjungan copyWith({
    int? id,
    String? noKunjungan,
    int? pasienId,
    DateTime? tanggalKunjungan,
    String? status,
    int? progressStep,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Kunjungan(
      id: id ?? this.id,
      noKunjungan: noKunjungan ?? this.noKunjungan,
      pasienId: pasienId ?? this.pasienId,
      tanggalKunjungan: tanggalKunjungan ?? this.tanggalKunjungan,
      status: status ?? this.status,
      progressStep: progressStep ?? this.progressStep,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
