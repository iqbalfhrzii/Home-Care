import 'package:json_annotation/json_annotation.dart';

part 'tindakan.g.dart';

// Master data Tindakan
@JsonSerializable(fieldRename: FieldRename.snake)
class Tindakan {
  final int id;
  final String kode;
  final String deskripsi;
  final String tarif;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const Tindakan({
    required this.id,
    required this.kode,
    required this.deskripsi,
    required this.tarif,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Tindakan.fromJson(Map<String, dynamic> json) =>
      _$TindakanFromJson(json);

  Map<String, dynamic> toJson() => _$TindakanToJson(this);

  Tindakan copyWith({
    int? id,
    String? kode,
    String? deskripsi,
    String? tarif,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Tindakan(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      deskripsi: deskripsi ?? this.deskripsi,
      tarif: tarif ?? this.tarif,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class TindakanCollection {
  final List<Tindakan> data;

  const TindakanCollection({required this.data});

  factory TindakanCollection.fromJson(Map<String, dynamic> json) =>
      _$TindakanCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$TindakanCollectionToJson(this);
}

// Junction table: Registrasi-Tindakan relationship
@JsonSerializable(fieldRename: FieldRename.snake)
class RegistrasiTindakan {
  final int id;
  final int registrasiId;
  final int tindakanId;

  // Pivot data
  final String? jumlah;
  final String? hargaSatuan;
  final String? diskon;
  final String? subtotal;
  final String? petugasNama;
  final String? keterangan;
  final String? kunjunganKe;
  final String? isFree;
  final String? dokterId;
  final String? poliId;
  final String? tanggalLayanan;

  final String? createdAt;

  const RegistrasiTindakan({
    required this.id,
    required this.registrasiId,
    required this.tindakanId,
    this.jumlah,
    this.hargaSatuan,
    this.diskon,
    this.subtotal,
    this.petugasNama,
    this.keterangan,
    this.kunjunganKe,
    this.isFree,
    this.dokterId,
    this.poliId,
    this.tanggalLayanan,
    this.createdAt,
  });

  factory RegistrasiTindakan.fromJson(Map<String, dynamic> json) =>
      _$RegistrasiTindakanFromJson(json);

  Map<String, dynamic> toJson() => _$RegistrasiTindakanToJson(this);

  RegistrasiTindakan copyWith({
    int? id,
    int? registrasiId,
    int? tindakanId,
    String? jumlah,
    String? hargaSatuan,
    String? diskon,
    String? subtotal,
    String? petugasNama,
    String? keterangan,
    String? kunjunganKe,
    String? isFree,
    String? dokterId,
    String? poliId,
    String? tanggalLayanan,
    String? createdAt,
  }) {
    return RegistrasiTindakan(
      id: id ?? this.id,
      registrasiId: registrasiId ?? this.registrasiId,
      tindakanId: tindakanId ?? this.tindakanId,
      jumlah: jumlah ?? this.jumlah,
      hargaSatuan: hargaSatuan ?? this.hargaSatuan,
      diskon: diskon ?? this.diskon,
      subtotal: subtotal ?? this.subtotal,
      petugasNama: petugasNama ?? this.petugasNama,
      keterangan: keterangan ?? this.keterangan,
      kunjunganKe: kunjunganKe ?? this.kunjunganKe,
      isFree: isFree ?? this.isFree,
      dokterId: dokterId ?? this.dokterId,
      poliId: poliId ?? this.poliId,
      tanggalLayanan: tanggalLayanan ?? this.tanggalLayanan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@JsonSerializable()
class RegistrasiTindakanCollection {
  final List<RegistrasiTindakan> data;

  const RegistrasiTindakanCollection({required this.data});

  factory RegistrasiTindakanCollection.fromJson(Map<String, dynamic> json) =>
      _$RegistrasiTindakanCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$RegistrasiTindakanCollectionToJson(this);
}
