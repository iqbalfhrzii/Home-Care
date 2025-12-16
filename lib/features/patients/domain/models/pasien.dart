import 'package:json_annotation/json_annotation.dart';

part 'pasien.g.dart';

@JsonSerializable()
class Pasien {
  final int id;
  final String mrn;
  final String nama;
  @JsonKey(name: 'tanggal_lahir')
  final String tanggalLahir;
  @JsonKey(name: 'jenis_kelamin')
  final String jenisKelamin;
  final String alamat;
  final String telepon;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  // Array registrasi dari API - empty array = belum registrasi
  final List<dynamic>? registrasi;

  Pasien({
    required this.id,
    required this.mrn,
    required this.nama,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.alamat,
    required this.telepon,
    required this.createdAt,
    required this.updatedAt,
    this.registrasi,
  });

  // Helper untuk cek apakah pasien sudah registrasi
  bool get isRegistered => registrasi != null && registrasi!.isNotEmpty;

  // CopyWith method untuk update data
  Pasien copyWith({
    int? id,
    String? mrn,
    String? nama,
    String? tanggalLahir,
    String? jenisKelamin,
    String? alamat,
    String? telepon,
    String? createdAt,
    String? updatedAt,
    List<dynamic>? registrasi,
  }) {
    return Pasien(
      id: id ?? this.id,
      mrn: mrn ?? this.mrn,
      nama: nama ?? this.nama,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      alamat: alamat ?? this.alamat,
      telepon: telepon ?? this.telepon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      registrasi: registrasi ?? this.registrasi,
    );
  }

  factory Pasien.fromJson(Map<String, dynamic> json) => _$PasienFromJson(json);
  Map<String, dynamic> toJson() => _$PasienToJson(this);

  // --- Safe getters / normalization ---
  String get safeNama => nama.isNotEmpty ? nama : '-';
  String get safeMrn => mrn.isNotEmpty ? mrn : '-';
  String get safeTelepon => telepon.isNotEmpty ? telepon : '-';
  String get safeAlamat => alamat.isNotEmpty ? alamat : '-';
  DateTime? get parsedTanggalLahir => DateTime.tryParse(tanggalLahir);
}

@JsonSerializable()
class PasienCollection {
  final List<Pasien> data;

  PasienCollection({required this.data});

  factory PasienCollection.fromJson(Map<String, dynamic> json) =>
      _$PasienCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$PasienCollectionToJson(this);
}
