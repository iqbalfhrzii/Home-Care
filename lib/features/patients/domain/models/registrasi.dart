import 'package:json_annotation/json_annotation.dart';
import 'pasien.dart';

part 'registrasi.g.dart';

@JsonSerializable()
class Penanggung {
  final String nama;
  @JsonKey(name: 'no_pegawai')
  final String noPegawai;
  final String alamat;
  final String telepon;
  final String id;
  final String eselon;

  Penanggung({
    required this.nama,
    required this.noPegawai,
    required this.alamat,
    required this.telepon,
    required this.id,
    required this.eselon,
  });

  factory Penanggung.fromJson(Map<String, dynamic> json) =>
      _$PenanggungFromJson(json);
  Map<String, dynamic> toJson() => _$PenanggungToJson(this);
}

@JsonSerializable()
class Registrasi {
  final String id;
  @JsonKey(name: 'no_reg')
  final String noReg;
  final Pasien pasien;
  @JsonKey(name: 'tgl_jam_reg')
  final String tglJamReg;
  @JsonKey(name: 'jenis_kunjungan')
  final String jenisKunjungan;
  @JsonKey(name: 'tipe_pasien')
  final String tipePasien;
  final Penanggung penanggung;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  Registrasi({
    required this.id,
    required this.noReg,
    required this.pasien,
    required this.tglJamReg,
    required this.jenisKunjungan,
    required this.tipePasien,
    required this.penanggung,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Registrasi.fromJson(Map<String, dynamic> json) =>
      _$RegistrasiFromJson(json);
  Map<String, dynamic> toJson() => _$RegistrasiToJson(this);
}

@JsonSerializable()
class RegistrasiCollection {
  final List<Registrasi> data;

  RegistrasiCollection({required this.data});

  factory RegistrasiCollection.fromJson(Map<String, dynamic> json) =>
      _$RegistrasiCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$RegistrasiCollectionToJson(this);
}

@JsonSerializable()
class StoreRegistrasiRequest {
  @JsonKey(name: 'no_reg')
  final String noReg;
  @JsonKey(name: 'pasien_id')
  final int pasienId;
  @JsonKey(name: 'tgl_jam_reg')
  final DateTime tglJamReg;
  @JsonKey(name: 'jenis_kunjungan')
  final String jenisKunjungan;
  @JsonKey(name: 'tipe_pasien')
  final String tipePasien;
  @JsonKey(name: 'penanggung_nama')
  final String penanggungNama;
  @JsonKey(name: 'penanggung_no_pegawai')
  final String penanggungNoPegawai;
  @JsonKey(name: 'penanggung_alamat')
  final String penanggungAlamat;
  @JsonKey(name: 'penanggung_telepon')
  final String penanggungTelepon;
  @JsonKey(name: 'penanggung_id')
  final String penanggungId;
  final String eselon;

  StoreRegistrasiRequest({
    required this.noReg,
    required this.pasienId,
    required this.tglJamReg,
    required this.jenisKunjungan,
    required this.tipePasien,
    required this.penanggungNama,
    required this.penanggungNoPegawai,
    required this.penanggungAlamat,
    required this.penanggungTelepon,
    required this.penanggungId,
    required this.eselon,
  });

  factory StoreRegistrasiRequest.fromJson(Map<String, dynamic> json) =>
      _$StoreRegistrasiRequestFromJson(json);
  Map<String, dynamic> toJson() => _$StoreRegistrasiRequestToJson(this);
}

@JsonSerializable()
class UpdateStatusRequest {
  final String status;

  UpdateStatusRequest({required this.status});

  factory UpdateStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateStatusRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateStatusRequestToJson(this);
}
