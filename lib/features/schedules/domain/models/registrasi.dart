import 'package:json_annotation/json_annotation.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';

part 'registrasi.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Registrasi {
  final int id;
  final String noReg;
  final String? noUrut;
  final int pasienId;
  final String tglJamReg; // Tanggal jam registrasi (kapan pasien mendaftar)
  final String?
  tglJamKunjungan; // Tanggal jam kunjungan (kapan akan/sudah dikunjungi)
  final String? kodePoli;
  final String? dokterId;
  final String jenisKunjungan;
  final String? asalPasien;
  final String tipePasien;
  final int pasienBaru;
  final String? pagiSore;
  final int isCash;
  final int isPribadi;
  final String? eselon;
  final String? status;

  // Penanggung jawab data
  final String? penanggungId;
  final String? penanggungNama;
  final String? penanggungNoPegawai;
  final String? penanggungAlamat;
  final String? penanggungTelepon;

  // Nested pasien data from API
  final Pasien? pasien;

  final String? createdAt;
  final String? updatedAt;

  Registrasi({
    required this.id,
    required this.noReg,
    this.noUrut,
    required this.pasienId,
    required this.tglJamReg,
    this.tglJamKunjungan,
    this.kodePoli,
    this.dokterId,
    required this.jenisKunjungan,
    this.asalPasien,
    required this.tipePasien,
    required this.pasienBaru,
    this.pagiSore,
    required this.isCash,
    required this.isPribadi,
    this.eselon,
    this.status,
    this.penanggungId,
    this.penanggungNama,
    this.penanggungNoPegawai,
    this.penanggungAlamat,
    this.penanggungTelepon,
    this.pasien,
    this.createdAt,
    this.updatedAt,
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
