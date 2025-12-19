import 'package:json_annotation/json_annotation.dart';

part 'tagihan.g.dart';

// Tagihan (Billing)
@JsonSerializable(fieldRename: FieldRename.snake)
class Tagihan {
  final int id;
  final int registrasiId;
  final String noInvoice;
  final String? tanggalInvoice;
  final String? totalBiaya;
  final String? deposit;
  final String? biayaYangHarusDibayar;
  final String? terbilang;
  final String? primaryIcd;
  final String statusPembayaran; // belum_bayar, lunas
  final String? dicetakOleh;
  final String? tanggalCetak;
  final String? printLocation;
  final String? serverTime;
  final String? computerTime;
  final int? userId;

  // Items will be loaded separately
  final List<TagihanItem>? items;

  // Registrasi data (includes pasien info)
  final Map<String, dynamic>? registrasi;

  final String? createdAt;
  final String? updatedAt;

  const Tagihan({
    required this.id,
    required this.registrasiId,
    required this.noInvoice,
    this.tanggalInvoice,
    this.totalBiaya,
    this.deposit,
    this.biayaYangHarusDibayar,
    this.terbilang,
    this.primaryIcd,
    this.statusPembayaran = 'belum_bayar',
    this.dicetakOleh,
    this.tanggalCetak,
    this.printLocation,
    this.serverTime,
    this.computerTime,
    this.userId,
    this.items,
    this.registrasi,
    this.createdAt,
    this.updatedAt,
  });

  factory Tagihan.fromJson(Map<String, dynamic> json) =>
      _$TagihanFromJson(json);

  Map<String, dynamic> toJson() => _$TagihanToJson(this);

  Tagihan copyWith({
    int? id,
    int? registrasiId,
    String? noInvoice,
    String? tanggalInvoice,
    String? totalBiaya,
    String? deposit,
    String? biayaYangHarusDibayar,
    String? terbilang,
    String? primaryIcd,
    String? statusPembayaran,
    String? dicetakOleh,
    String? tanggalCetak,
    String? printLocation,
    String? serverTime,
    String? computerTime,
    int? userId,
    List<TagihanItem>? items,
    Map<String, dynamic>? registrasi,
    String? createdAt,
    String? updatedAt,
  }) {
    return Tagihan(
      id: id ?? this.id,
      registrasiId: registrasiId ?? this.registrasiId,
      noInvoice: noInvoice ?? this.noInvoice,
      tanggalInvoice: tanggalInvoice ?? this.tanggalInvoice,
      totalBiaya: totalBiaya ?? this.totalBiaya,
      deposit: deposit ?? this.deposit,
      biayaYangHarusDibayar:
          biayaYangHarusDibayar ?? this.biayaYangHarusDibayar,
      terbilang: terbilang ?? this.terbilang,
      primaryIcd: primaryIcd ?? this.primaryIcd,
      statusPembayaran: statusPembayaran ?? this.statusPembayaran,
      dicetakOleh: dicetakOleh ?? this.dicetakOleh,
      tanggalCetak: tanggalCetak ?? this.tanggalCetak,
      printLocation: printLocation ?? this.printLocation,
      serverTime: serverTime ?? this.serverTime,
      computerTime: computerTime ?? this.computerTime,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      registrasi: registrasi ?? this.registrasi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class TagihanCollection {
  final List<Tagihan> data;

  const TagihanCollection({required this.data});

  factory TagihanCollection.fromJson(Map<String, dynamic> json) =>
      _$TagihanCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$TagihanCollectionToJson(this);
}

// Tagihan Item (Line item)
@JsonSerializable(fieldRename: FieldRename.snake)
class TagihanItem {
  final int id;
  final int tagihanId;
  final int? kategoriLayananId;
  final String? kodeLayanan;
  final String? deskripsi;
  final int jumlah;
  final String? hargaSatuan;
  final String? diskon;
  final String? subtotal;
  final String? tanggalLayanan;
  final int urutan;
  final String? createdAt;
  final String? updatedAt;

  const TagihanItem({
    required this.id,
    required this.tagihanId,
    this.kategoriLayananId,
    this.kodeLayanan,
    this.deskripsi,
    this.jumlah = 0,
    this.hargaSatuan,
    this.diskon,
    this.subtotal,
    this.tanggalLayanan,
    this.urutan = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory TagihanItem.fromJson(Map<String, dynamic> json) =>
      _$TagihanItemFromJson(json);

  Map<String, dynamic> toJson() => _$TagihanItemToJson(this);

  TagihanItem copyWith({
    int? id,
    int? tagihanId,
    int? kategoriLayananId,
    String? kodeLayanan,
    String? deskripsi,
    int? jumlah,
    String? hargaSatuan,
    String? diskon,
    String? subtotal,
    String? tanggalLayanan,
    int? urutan,
    String? createdAt,
    String? updatedAt,
  }) {
    return TagihanItem(
      id: id ?? this.id,
      tagihanId: tagihanId ?? this.tagihanId,
      kategoriLayananId: kategoriLayananId ?? this.kategoriLayananId,
      kodeLayanan: kodeLayanan ?? this.kodeLayanan,
      deskripsi: deskripsi ?? this.deskripsi,
      jumlah: jumlah ?? this.jumlah,
      hargaSatuan: hargaSatuan ?? this.hargaSatuan,
      diskon: diskon ?? this.diskon,
      subtotal: subtotal ?? this.subtotal,
      tanggalLayanan: tanggalLayanan ?? this.tanggalLayanan,
      urutan: urutan ?? this.urutan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class TagihanItemCollection {
  final List<TagihanItem> data;

  const TagihanItemCollection({required this.data});

  factory TagihanItemCollection.fromJson(Map<String, dynamic> json) =>
      _$TagihanItemCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$TagihanItemCollectionToJson(this);
}
