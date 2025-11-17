import 'package:json_annotation/json_annotation.dart';

part 'pasien.g.dart';

@JsonSerializable()
class Pasien {
  final String id;
  @JsonKey(name: 'no_rm')
  final String noRm;
  final String nama;
  final String? nik;
  @JsonKey(name: 'no_bpjs')
  final String? noBpjs;
  @JsonKey(name: 'tempat_lahir')
  final String tempatLahir;
  @JsonKey(name: 'tanggal_lahir')
  final String tanggalLahir;
  @JsonKey(name: 'jenis_kelamin')
  final String jenisKelamin;
  @JsonKey(name: 'golongan_darah')
  final String? golonganDarah;
  final String alamat;
  @JsonKey(name: 'no_telp')
  final String noTelp;
  @JsonKey(name: 'is_registered')
  final bool? isRegistered;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  Pasien({
    required this.id,
    required this.noRm,
    required this.nama,
    this.nik,
    this.noBpjs,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.jenisKelamin,
    this.golonganDarah,
    required this.alamat,
    required this.noTelp,
    this.isRegistered,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pasien.fromJson(Map<String, dynamic> json) => _$PasienFromJson(json);
  Map<String, dynamic> toJson() => _$PasienToJson(this);
}

@JsonSerializable()
class PasienCollection {
  final List<Pasien> data;

  PasienCollection({required this.data});

  factory PasienCollection.fromJson(Map<String, dynamic> json) =>
      _$PasienCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$PasienCollectionToJson(this);
}
