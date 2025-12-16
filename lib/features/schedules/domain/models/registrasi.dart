import 'package:json_annotation/json_annotation.dart';
import 'package:homecare_mobile/features/patients/domain/models/pasien.dart';

part 'registrasi.g.dart';

// Helper functions for flexible type parsing (must be top-level or static)
int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.parse(value);
  if (value is num) return value.toInt();
  throw FormatException('Cannot parse int from $value');
}

// More lenient parser for IDs returned as null during create
int _parseIntId(dynamic value) {
  if (value == null) return 0;
  return _parseInt(value);
}

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    if (value.isEmpty) return null;
    final parsed = int.tryParse(value);
    return parsed; // null jika string bukan angka (contoh: 'PT0384')
  }
  if (value is num) return value.toInt();
  return null;
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Registrasi {
  @JsonKey(fromJson: _parseIntId)
  final int id;
  final String noReg;
  final String? noUrut;
  @JsonKey(fromJson: _parseIntNullable)
  final int? pasienId;
  final String? tglJamReg; // Tanggal jam registrasi (kapan pasien mendaftar)
  final String?
  tglJamKunjungan; // Tanggal jam kunjungan (kapan akan/sudah dikunjungi)
  final String? kodePoli;
  @JsonKey(fromJson: _parseIntNullable)
  final int? dokterId;
  final String? jenisKunjungan;
  final String? asalPasien;
  final String? tipePasien;
  @JsonKey(fromJson: _parseIntNullable)
  final int? pasienBaru;
  final String? pagiSore;
  @JsonKey(fromJson: _parseIntNullable)
  final int? isCash;
  @JsonKey(fromJson: _parseIntNullable)
  final int? isPribadi;
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

  // Relations - Map from "tindakan" and "icd" in JSON to plural field names
  @JsonKey(name: 'tindakan')
  final List<dynamic>? tindakans;
  @JsonKey(name: 'icd')
  final List<dynamic>? icds;

  final String? createdAt;
  final String? updatedAt;

  Registrasi({
    required this.id,
    required this.noReg,
    this.noUrut,
    this.pasienId,
    this.tglJamReg,
    this.tglJamKunjungan,
    this.kodePoli,
    this.dokterId,
    this.jenisKunjungan,
    this.asalPasien,
    this.tipePasien,
    this.pasienBaru,
    this.pagiSore,
    this.isCash,
    this.isPribadi,
    this.eselon,
    this.status,
    this.penanggungId,
    this.penanggungNama,
    this.penanggungNoPegawai,
    this.penanggungAlamat,
    this.penanggungTelepon,
    this.pasien,
    this.tindakans,
    this.icds,
    this.createdAt,
    this.updatedAt,
  });

  factory Registrasi.fromJson(Map<String, dynamic> json) =>
      _$RegistrasiFromJson(json);

  Map<String, dynamic> toJson() => _$RegistrasiToJson(this);

  // --- Safe getters / normalization ---
  String get safeNoReg => noReg.isNotEmpty ? noReg : '-';
  String get safeJenisKunjungan =>
      (jenisKunjungan == null || jenisKunjungan!.isEmpty)
      ? 'HOME CARE'
      : jenisKunjungan!;
  String get safeAsalPasien =>
      (asalPasien == null || asalPasien!.isEmpty) ? 'POLIKLINIK' : asalPasien!;
  String get safeTipePasien =>
      (tipePasien == null || tipePasien!.isEmpty) ? 'UMUM' : tipePasien!;
  int get safePasienId => pasienId ?? 0;
  DateTime? get parsedTglReg => DateTime.tryParse(tglJamReg ?? '');
  DateTime? get parsedTglKunjungan => DateTime.tryParse(tglJamKunjungan ?? '');
}

@JsonSerializable()
class RegistrasiCollection {
  final List<Registrasi> data;

  RegistrasiCollection({required this.data});

  factory RegistrasiCollection.fromJson(Map<String, dynamic> json) =>
      _$RegistrasiCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$RegistrasiCollectionToJson(this);
}
