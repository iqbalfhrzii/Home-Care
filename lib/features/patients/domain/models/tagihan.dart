import 'package:json_annotation/json_annotation.dart';

part 'tagihan.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;
  @JsonKey(name: 'email_verified_at')
  final String? emailVerifiedAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'two_factor_secret')
  final String? twoFactorSecret;
  @JsonKey(name: 'two_factor_recovery_codes')
  final String? twoFactorRecoveryCodes;
  @JsonKey(name: 'two_factor_confirmed_at')
  final String? twoFactorConfirmedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.twoFactorSecret,
    this.twoFactorRecoveryCodes,
    this.twoFactorConfirmedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class KategoriLayanan {
  final int id;
  final String kode;
  final String nama;
  final int urutan;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  // Ignore nested tagihan_items to prevent circular reference
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<dynamic>? tagihanItems;

  KategoriLayanan({
    required this.id,
    required this.kode,
    required this.nama,
    required this.urutan,
    this.createdAt,
    this.updatedAt,
    this.tagihanItems,
  });

  factory KategoriLayanan.fromJson(Map<String, dynamic> json) =>
      _$KategoriLayananFromJson(json);
  Map<String, dynamic> toJson() => _$KategoriLayananToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TagihanItem {
  final int id;
  @JsonKey(name: 'tagihan_id')
  final int tagihanId;
  @JsonKey(name: 'kategori_layanan_id')
  final int? kategoriLayananId;
  @JsonKey(name: 'kode_layanan')
  final String? kodeLayanan;
  final String? deskripsi;
  final int jumlah;
  @JsonKey(name: 'harga_satuan')
  final String? hargaSatuan;
  final String? diskon;
  final String? subtotal;
  @JsonKey(name: 'tanggal_layanan')
  final String? tanggalLayanan;
  final int urutan;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  // Ignore nested tagihan to prevent circular reference
  @JsonKey(includeFromJson: false, includeToJson: false)
  final dynamic tagihan;

  @JsonKey(name: 'kategori_layanan')
  final KategoriLayanan? kategoriLayanan;

  TagihanItem({
    required this.id,
    required this.tagihanId,
    this.kategoriLayananId,
    this.kodeLayanan,
    this.deskripsi,
    required this.jumlah,
    this.hargaSatuan,
    this.diskon,
    this.subtotal,
    this.tanggalLayanan,
    required this.urutan,
    this.createdAt,
    this.updatedAt,
    this.tagihan,
    this.kategoriLayanan,
  });

  factory TagihanItem.fromJson(Map<String, dynamic> json) =>
      _$TagihanItemFromJson(json);
  Map<String, dynamic> toJson() => _$TagihanItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Tagihan {
  final int id;
  @JsonKey(name: 'registrasi_id')
  final int registrasiId;
  @JsonKey(name: 'no_invoice')
  final String noInvoice;
  @JsonKey(name: 'tanggal_invoice')
  final String? tanggalInvoice;
  @JsonKey(name: 'total_biaya')
  final String? totalBiaya;
  final String? deposit;
  @JsonKey(name: 'biaya_yang_harus_dibayar')
  final String? biayaYangHarusDibayar;
  final String? terbilang;
  @JsonKey(name: 'primary_icd')
  final String? primaryIcd;
  @JsonKey(name: 'status_pembayaran')
  final String statusPembayaran;
  @JsonKey(name: 'dicetak_oleh')
  final String? dicetakOleh;
  @JsonKey(name: 'tanggal_cetak')
  final String? tanggalCetak;
  @JsonKey(name: 'print_location')
  final String? printLocation;
  @JsonKey(name: 'server_time')
  final String? serverTime;
  @JsonKey(name: 'computer_time')
  final String? computerTime;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  final User? user;
  final List<TagihanItem>? items;

  // Ignore nested registrasi to prevent circular reference
  @JsonKey(includeFromJson: false, includeToJson: false)
  final dynamic registrasi;

  Tagihan({
    required this.id,
    required this.registrasiId,
    required this.noInvoice,
    this.tanggalInvoice,
    this.totalBiaya,
    this.deposit,
    this.biayaYangHarusDibayar,
    this.terbilang,
    this.primaryIcd,
    required this.statusPembayaran,
    this.dicetakOleh,
    this.tanggalCetak,
    this.printLocation,
    this.serverTime,
    this.computerTime,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.items,
    this.registrasi,
  });

  factory Tagihan.fromJson(Map<String, dynamic> json) =>
      _$TagihanFromJson(json);
  Map<String, dynamic> toJson() => _$TagihanToJson(this);
}

@JsonSerializable()
class TagihanCollection {
  final List<Tagihan> data;

  TagihanCollection({required this.data});

  factory TagihanCollection.fromJson(Map<String, dynamic> json) =>
      _$TagihanCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$TagihanCollectionToJson(this);
}
