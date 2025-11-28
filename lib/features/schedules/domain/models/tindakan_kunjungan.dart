import 'package:json_annotation/json_annotation.dart';

part 'tindakan_kunjungan.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TindakanKunjungan {
  final int id;
  @JsonKey(name: 'kunjungan_id')
  final int kunjunganId;
  @JsonKey(name: 'kode_tindakan')
  final String kodeTindakan;
  @JsonKey(name: 'nama_tindakan')
  final String namaTindakan;
  final int jumlah; // Quantity
  @JsonKey(name: 'harga_satuan')
  final int hargaSatuan; // Price per unit
  @JsonKey(name: 'total_harga')
  final int totalHarga; // Quantity * Unit price
  final String? keterangan;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  TindakanKunjungan({
    required this.id,
    required this.kunjunganId,
    required this.kodeTindakan,
    required this.namaTindakan,
    this.jumlah = 1,
    required this.hargaSatuan,
    required this.totalHarga,
    this.keterangan,
    required this.createdAt,
  });

  factory TindakanKunjungan.fromJson(Map<String, dynamic> json) =>
      _$TindakanKunjunganFromJson(json);

  Map<String, dynamic> toJson() => _$TindakanKunjunganToJson(this);

  TindakanKunjungan copyWith({
    int? id,
    int? kunjunganId,
    String? kodeTindakan,
    String? namaTindakan,
    int? jumlah,
    int? hargaSatuan,
    int? totalHarga,
    String? keterangan,
    DateTime? createdAt,
  }) {
    return TindakanKunjungan(
      id: id ?? this.id,
      kunjunganId: kunjunganId ?? this.kunjunganId,
      kodeTindakan: kodeTindakan ?? this.kodeTindakan,
      namaTindakan: namaTindakan ?? this.namaTindakan,
      jumlah: jumlah ?? this.jumlah,
      hargaSatuan: hargaSatuan ?? this.hargaSatuan,
      totalHarga: totalHarga ?? this.totalHarga,
      keterangan: keterangan ?? this.keterangan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
