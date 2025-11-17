import 'package:json_annotation/json_annotation.dart';

part 'anamnesa.g.dart';

@JsonSerializable()
class VitalSigns {
  @JsonKey(name: 'tekanan_darah')
  final String tekananDarah;
  final String nadi;
  final String suhu;
  final String pernapasan;

  VitalSigns({
    required this.tekananDarah,
    required this.nadi,
    required this.suhu,
    required this.pernapasan,
  });

  factory VitalSigns.fromJson(Map<String, dynamic> json) =>
      _$VitalSignsFromJson(json);
  Map<String, dynamic> toJson() => _$VitalSignsToJson(this);
}

@JsonSerializable()
class BodyMeasurements {
  @JsonKey(name: 'berat_badan')
  final String beratBadan;
  @JsonKey(name: 'tinggi_badan')
  final String tinggiBadan;
  final String imt;
  @JsonKey(name: 'lingkar_kepala')
  final String lingkarKepala;

  BodyMeasurements({
    required this.beratBadan,
    required this.tinggiBadan,
    required this.imt,
    required this.lingkarKepala,
  });

  factory BodyMeasurements.fromJson(Map<String, dynamic> json) =>
      _$BodyMeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$BodyMeasurementsToJson(this);
}

@JsonSerializable()
class Anamnesa {
  final String id;
  @JsonKey(name: 'registrasi_id')
  final String registrasiId;
  @JsonKey(name: 'doctor_id')
  final String doctorId;
  final String keluhan;
  @JsonKey(name: 'vital_signs')
  final VitalSigns vitalSigns;
  @JsonKey(name: 'body_measurements')
  final BodyMeasurements bodyMeasurements;
  final String diagnosis;
  @JsonKey(name: 'rencana_dan_terapi')
  final String rencanaDanTerapi;
  @JsonKey(name: 'jenis_perawatan')
  final String jenisPerawatan;

  Anamnesa({
    required this.id,
    required this.registrasiId,
    required this.doctorId,
    required this.keluhan,
    required this.vitalSigns,
    required this.bodyMeasurements,
    required this.diagnosis,
    required this.rencanaDanTerapi,
    required this.jenisPerawatan,
  });

  factory Anamnesa.fromJson(Map<String, dynamic> json) =>
      _$AnamnesaFromJson(json);
  Map<String, dynamic> toJson() => _$AnamnesaToJson(this);
}

@JsonSerializable()
class Icd {
  final String id;
  final String kode;
  @JsonKey(name: 'nama_penyakit')
  final String namaPenyakit;
  final String deskripsi;
  @JsonKey(name: 'is_active')
  final String isActive;
  @JsonKey(name: 'is_primary')
  final String? isPrimary;

  Icd({
    required this.id,
    required this.kode,
    required this.namaPenyakit,
    required this.deskripsi,
    required this.isActive,
    this.isPrimary,
  });

  factory Icd.fromJson(Map<String, dynamic> json) => _$IcdFromJson(json);
  Map<String, dynamic> toJson() => _$IcdToJson(this);
}

@JsonSerializable()
class IcdCollection {
  final List<Icd> data;

  IcdCollection({required this.data});

  factory IcdCollection.fromJson(Map<String, dynamic> json) =>
      _$IcdCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$IcdCollectionToJson(this);
}

@JsonSerializable()
class AttachIcdRequest {
  @JsonKey(name: 'icd_id')
  final int icdId;
  @JsonKey(name: 'is_primary')
  final bool isPrimary;

  AttachIcdRequest({required this.icdId, required this.isPrimary});

  factory AttachIcdRequest.fromJson(Map<String, dynamic> json) =>
      _$AttachIcdRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AttachIcdRequestToJson(this);
}
