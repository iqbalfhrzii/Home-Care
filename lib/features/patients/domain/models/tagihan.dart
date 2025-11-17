import 'package:json_annotation/json_annotation.dart';
import 'registrasi.dart';

part 'tagihan.g.dart';

@JsonSerializable()
class TagihanItem {
  final String id;
  final String kategori;
  @JsonKey(name: 'tanggal_layanan')
  final String tanggalLayanan;
  @JsonKey(name: 'kode_layanan')
  final String kodeLayanan;
  final String deskripsi;
  final String jumlah;
  @JsonKey(name: 'harga_satuan')
  final String hargaSatuan;
  final String diskon;
  final String subtotal;

  TagihanItem({
    required this.id,
    required this.kategori,
    required this.tanggalLayanan,
    required this.kodeLayanan,
    required this.deskripsi,
    required this.jumlah,
    required this.hargaSatuan,
    required this.diskon,
    required this.subtotal,
  });

  factory TagihanItem.fromJson(Map<String, dynamic> json) =>
      _$TagihanItemFromJson(json);
  Map<String, dynamic> toJson() => _$TagihanItemToJson(this);
}

@JsonSerializable()
class Tagihan {
  final String id;
  @JsonKey(name: 'no_invoice')
  final String noInvoice;
  @JsonKey(name: 'registrasi_id')
  final String registrasiId;
  @JsonKey(name: 'primary_icd')
  final String primaryIcd;
  @JsonKey(name: 'total_biaya')
  final String totalBiaya;
  final String deposit;
  @JsonKey(name: 'biaya_yang_harus_dibayar')
  final String biayaYangHarusDibayar;
  final String terbilang;
  @JsonKey(name: 'status_pembayaran')
  final String statusPembayaran;
  final Registrasi registrasi;
  final List<TagihanItem> items;

  Tagihan({
    required this.id,
    required this.noInvoice,
    required this.registrasiId,
    required this.primaryIcd,
    required this.totalBiaya,
    required this.deposit,
    required this.biayaYangHarusDibayar,
    required this.terbilang,
    required this.statusPembayaran,
    required this.registrasi,
    required this.items,
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
