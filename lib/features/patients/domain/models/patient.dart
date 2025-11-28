import 'package:json_annotation/json_annotation.dart';

part 'patient.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Patient {
  final int id;
  final String noRekamMedis;
  final String namaPasien;
  final String tanggalLahir;
  final String alamat;
  final String statusRujukan;
  final String createdAt;
  final String updatedAt;

  const Patient({
    required this.id,
    required this.noRekamMedis,
    required this.namaPasien,
    required this.tanggalLahir,
    required this.alamat,
    required this.statusRujukan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);

  Map<String, dynamic> toJson() => _$PatientToJson(this);
}
