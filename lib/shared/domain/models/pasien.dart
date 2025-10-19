import 'package:json_annotation/json_annotation.dart';

part 'pasien.g.dart';

@JsonSerializable()
class Pasien {
  final int id;
  @JsonKey(name: 'no_rm')
  final String noRM;
  @JsonKey(name: 'nama_pasien')
  final String namaPasien;
  @JsonKey(name: 'tanggal_lahir')
  final String? tanggalLahir;
  final String? alamat;
  @JsonKey(name: 'status_rujukan')
  final String statusRujukan;

  const Pasien({
    required this.id,
    required this.noRM,
    required this.namaPasien,
    this.tanggalLahir,
    this.alamat,
    required this.statusRujukan,
  });

  factory Pasien.fromJson(Map<String, dynamic> json) => _$PasienFromJson(json);
  Map<String, dynamic> toJson() => _$PasienToJson(this);
}
