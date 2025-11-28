import 'package:json_annotation/json_annotation.dart';

part 'patient.g.dart';

@JsonSerializable()
class Patient {
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

  Patient({
    required this.id,
    required this.noRM,
    required this.namaPasien,
    this.tanggalLahir,
    this.alamat,
    required this.statusRujukan,
  });

  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);

  Map<String, dynamic> toJson() => _$PatientToJson(this);
}
