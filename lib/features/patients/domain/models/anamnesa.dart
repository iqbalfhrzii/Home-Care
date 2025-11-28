import 'package:json_annotation/json_annotation.dart';

part 'anamnesa.g.dart';

// ========== Pengkajian Keperawatan Models ==========

@JsonSerializable()
class TandaVital {
  @JsonKey(name: 'tekanan_darah')
  final String? tekananDarah;
  final int? nadi;
  final int? suhu;
  final int? pernapasan;
  @JsonKey(name: 'riwayat_alergi')
  final bool? riwayatAlergi;

  TandaVital({
    this.tekananDarah,
    this.nadi,
    this.suhu,
    this.pernapasan,
    this.riwayatAlergi,
  });

  factory TandaVital.fromJson(Map<String, dynamic> json) =>
      _$TandaVitalFromJson(json);
  Map<String, dynamic> toJson() => _$TandaVitalToJson(this);
}

@JsonSerializable()
class Nutrisi {
  @JsonKey(name: 'berat_badan')
  final String? beratBadan;
  @JsonKey(name: 'tinggi_badan')
  final String? tinggiBadan;
  final int? imt;
  @JsonKey(name: 'lingkar_kepala')
  final String? lingkarKepala;

  Nutrisi({this.beratBadan, this.tinggiBadan, this.imt, this.lingkarKepala});

  factory Nutrisi.fromJson(Map<String, dynamic> json) =>
      _$NutrisiFromJson(json);
  Map<String, dynamic> toJson() => _$NutrisiToJson(this);
}

@JsonSerializable()
class Fungsional {
  @JsonKey(name: 'alat_bantu')
  final String? alatBantu;
  final String? prothesa;
  @JsonKey(name: 'cacat_tubuh')
  final String? cacatTubuh;
  final bool? adl;
  @JsonKey(name: 'resiko_jatuh')
  final bool? resikoJatuh;
  final String? riwayat;

  Fungsional({
    this.alatBantu,
    this.prothesa,
    this.cacatTubuh,
    this.adl,
    this.resikoJatuh,
    this.riwayat,
  });

  factory Fungsional.fromJson(Map<String, dynamic> json) =>
      _$FungsionalFromJson(json);
  Map<String, dynamic> toJson() => _$FungsionalToJson(this);
}

@JsonSerializable()
class Keluhan {
  final String? keluhan;

  Keluhan({this.keluhan});

  factory Keluhan.fromJson(Map<String, dynamic> json) =>
      _$KeluhanFromJson(json);
  Map<String, dynamic> toJson() => _$KeluhanToJson(this);
}

@JsonSerializable()
class MasalahKeperawatan {
  @JsonKey(name: 'jalan_nafas')
  final bool? jalanNafas;
  @JsonKey(name: 'pola_nafas')
  final bool? polaNafas;
  final bool? hipertermia;
  @JsonKey(name: 'nyeri_akut')
  final bool? nyeriAkut;
  @JsonKey(name: 'nyeri_kronik')
  final bool? nyeriKronik;
  final bool? mual;
  @JsonKey(name: 'gangguan_perfusi')
  final bool? gangguanPerfusi;
  @JsonKey(name: 'gangguan_cairan')
  final bool? gangguanCairan;
  final String? lainnya;

  MasalahKeperawatan({
    this.jalanNafas,
    this.polaNafas,
    this.hipertermia,
    this.nyeriAkut,
    this.nyeriKronik,
    this.mual,
    this.gangguanPerfusi,
    this.gangguanCairan,
    this.lainnya,
  });

  factory MasalahKeperawatan.fromJson(Map<String, dynamic> json) =>
      _$MasalahKeperawatanFromJson(json);
  Map<String, dynamic> toJson() => _$MasalahKeperawatanToJson(this);
}

@JsonSerializable()
class PengkajianKeperawatan {
  @JsonKey(name: 'tanda_vital')
  final TandaVital? tandaVital;
  final Nutrisi? nutrisi;
  final Fungsional? fungsional;
  final Keluhan? keluhan;
  @JsonKey(name: 'masalah_keperawatan')
  final MasalahKeperawatan? masalahKeperawatan;

  PengkajianKeperawatan({
    this.tandaVital,
    this.nutrisi,
    this.fungsional,
    this.keluhan,
    this.masalahKeperawatan,
  });

  factory PengkajianKeperawatan.fromJson(Map<String, dynamic> json) =>
      _$PengkajianKeperawatanFromJson(json);
  Map<String, dynamic> toJson() => _$PengkajianKeperawatanToJson(this);
}

// ========== Pengkajian Medis Models ==========

@JsonSerializable()
class Rujukan {
  final String? tujuan;

  Rujukan({this.tujuan});

  factory Rujukan.fromJson(Map<String, dynamic> json) =>
      _$RujukanFromJson(json);
  Map<String, dynamic> toJson() => _$RujukanToJson(this);
}

@JsonSerializable()
class PengkajianMedis {
  @JsonKey(name: 'pemeriksaan_fisik')
  final String? pemeriksaanFisik;
  final String? diagnosis;
  @JsonKey(name: 'rencana_dan_terapi')
  final String? rencanaDanTerapi;
  @JsonKey(name: 'pemeriksaan_penunjang')
  final String? pemeriksaanPenunjang;
  final String? kontrol;
  @JsonKey(name: 'jenis_perawatan')
  final String? jenisPerawatan;
  final Rujukan? rujukan;

  PengkajianMedis({
    this.pemeriksaanFisik,
    this.diagnosis,
    this.rencanaDanTerapi,
    this.pemeriksaanPenunjang,
    this.kontrol,
    this.jenisPerawatan,
    this.rujukan,
  });

  factory PengkajianMedis.fromJson(Map<String, dynamic> json) =>
      _$PengkajianMedisFromJson(json);
  Map<String, dynamic> toJson() => _$PengkajianMedisToJson(this);
}

// ========== Khusus Perawat Models ==========

@JsonSerializable()
class IntervensiTimeUpGo {
  @JsonKey(name: 'cara_berjalan')
  final bool? caraBerjalan;
  @JsonKey(name: 'cara_berjalan2')
  final bool? caraBerjalan2;
  final bool? menopang;
  final String? risiko;

  IntervensiTimeUpGo({
    this.caraBerjalan,
    this.caraBerjalan2,
    this.menopang,
    this.risiko,
  });

  factory IntervensiTimeUpGo.fromJson(Map<String, dynamic> json) =>
      _$IntervensiTimeUpGoFromJson(json);
  Map<String, dynamic> toJson() => _$IntervensiTimeUpGoToJson(this);
}

@JsonSerializable()
class SkriningMstDewasa {
  @JsonKey(name: 'nutrisi_bb')
  final String? nutrisiBb;
  @JsonKey(name: 'asup_makan')
  final String? asupMakan;

  SkriningMstDewasa({this.nutrisiBb, this.asupMakan});

  factory SkriningMstDewasa.fromJson(Map<String, dynamic> json) =>
      _$SkriningMstDewasaFromJson(json);
  Map<String, dynamic> toJson() => _$SkriningMstDewasaToJson(this);
}

@JsonSerializable()
class SkriningStrongkids {
  @JsonKey(name: 'strong_kids1')
  final bool? strongKids1;
  @JsonKey(name: 'strong_kids2')
  final bool? strongKids2;
  @JsonKey(name: 'strong_kids3')
  final bool? strongKids3;
  @JsonKey(name: 'strong_kids4')
  final bool? strongKids4;

  SkriningStrongkids({
    this.strongKids1,
    this.strongKids2,
    this.strongKids3,
    this.strongKids4,
  });

  factory SkriningStrongkids.fromJson(Map<String, dynamic> json) =>
      _$SkriningStrongkidsFromJson(json);
  Map<String, dynamic> toJson() => _$SkriningStrongkidsToJson(this);
}

@JsonSerializable()
class Edukasi {
  final bool? edukasi;
  @JsonKey(name: 'edukasi_ket')
  final String? edukasiKet;

  Edukasi({this.edukasi, this.edukasiKet});

  factory Edukasi.fromJson(Map<String, dynamic> json) =>
      _$EdukasiFromJson(json);
  Map<String, dynamic> toJson() => _$EdukasiToJson(this);
}

@JsonSerializable()
class RencanaPulang {
  @JsonKey(name: 'renc_usia_lanjut')
  final bool? rencUsiaLanjut;
  @JsonKey(name: 'renc_hmbtn_mobil')
  final bool? rencHmbtnMobil;
  @JsonKey(name: 'renc_layanan_medis')
  final bool? rencLayananMedis;
  @JsonKey(name: 'renc_tergnt_org')
  final bool? rencTergntOrg;

  RencanaPulang({
    this.rencUsiaLanjut,
    this.rencHmbtnMobil,
    this.rencLayananMedis,
    this.rencTergntOrg,
  });

  factory RencanaPulang.fromJson(Map<String, dynamic> json) =>
      _$RencanaPulangFromJson(json);
  Map<String, dynamic> toJson() => _$RencanaPulangToJson(this);
}

@JsonSerializable()
class KhususPerawat {
  @JsonKey(name: 'intervensi_time_up_go')
  final IntervensiTimeUpGo? intervensiTimeUpGo;
  @JsonKey(name: 'skrining_mst_dewasa')
  final SkriningMstDewasa? skriningMstDewasa;
  @JsonKey(name: 'skrining_strongkids')
  final SkriningStrongkids? skriningStrongkids;
  final Edukasi? edukasi;
  @JsonKey(name: 'rencana_pulang')
  final RencanaPulang? rencanaPulang;

  KhususPerawat({
    this.intervensiTimeUpGo,
    this.skriningMstDewasa,
    this.skriningStrongkids,
    this.edukasi,
    this.rencanaPulang,
  });

  factory KhususPerawat.fromJson(Map<String, dynamic> json) =>
      _$KhususPerawatFromJson(json);
  Map<String, dynamic> toJson() => _$KhususPerawatToJson(this);
}

// ========== Main Anamnesa Model ==========

@JsonSerializable(explicitToJson: true)
class Anamnesa {
  final int id;
  @JsonKey(name: 'registrasi_id')
  final int registrasiId;
  @JsonKey(name: 'dokter_id')
  final int? dokterId;
  @JsonKey(name: 'poli_id')
  final String? poliId;
  final String? tanggal;

  @JsonKey(name: 'pengkajian_keperawatan')
  final PengkajianKeperawatan? pengkajianKeperawatan;
  @JsonKey(name: 'pengkajian_medis')
  final PengkajianMedis? pengkajianMedis;
  @JsonKey(name: 'khusus_perawat')
  final KhususPerawat? khususPerawat;

  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  // Ignore nested objects to prevent circular reference
  @JsonKey(includeFromJson: false, includeToJson: false)
  final dynamic registrasi;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final dynamic dokter;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<dynamic>? poli;

  Anamnesa({
    required this.id,
    required this.registrasiId,
    this.dokterId,
    this.poliId,
    this.tanggal,
    this.pengkajianKeperawatan,
    this.pengkajianMedis,
    this.khususPerawat,
    this.createdAt,
    this.updatedAt,
    this.registrasi,
    this.dokter,
    this.poli,
  });

  factory Anamnesa.fromJson(Map<String, dynamic> json) =>
      _$AnamnesaFromJson(json);
  Map<String, dynamic> toJson() => _$AnamnesaToJson(this);
}

@JsonSerializable()
class AnamnesaCollection {
  final List<Anamnesa> data;

  AnamnesaCollection({required this.data});

  factory AnamnesaCollection.fromJson(Map<String, dynamic> json) =>
      _$AnamnesaCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$AnamnesaCollectionToJson(this);
}
