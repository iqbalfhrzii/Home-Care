import 'package:json_annotation/json_annotation.dart';

part 'tagihan.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Tagihan {
  final int id;
  @JsonKey(name: 'no_invoice')
  final String noInvoice;
  @JsonKey(name: 'kunjungan_id')
  final int kunjunganId;
  @JsonKey(name: 'pasien_id')
  final int pasienId;
  @JsonKey(name: 'tanggal_tagihan')
  final DateTime tanggalTagihan;
  @JsonKey(name: 'total_biaya')
  final int totalBiaya; // Total cost
  final int deposit; // Deposit paid
  @JsonKey(name: 'sisa_biaya')
  final int sisaBiaya; // Remaining balance
  @JsonKey(name: 'status_pembayaran')
  final String statusPembayaran; // pending, belum_lunas, lunas
  final String? catatan;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Tagihan({
    required this.id,
    required this.noInvoice,
    required this.kunjunganId,
    required this.pasienId,
    required this.tanggalTagihan,
    required this.totalBiaya,
    this.deposit = 0,
    required this.sisaBiaya,
    this.statusPembayaran = 'pending',
    this.catatan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tagihan.fromJson(Map<String, dynamic> json) =>
      _$TagihanFromJson(json);

  Map<String, dynamic> toJson() => _$TagihanToJson(this);

  Tagihan copyWith({
    int? id,
    String? noInvoice,
    int? kunjunganId,
    int? pasienId,
    DateTime? tanggalTagihan,
    int? totalBiaya,
    int? deposit,
    int? sisaBiaya,
    String? statusPembayaran,
    String? catatan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tagihan(
      id: id ?? this.id,
      noInvoice: noInvoice ?? this.noInvoice,
      kunjunganId: kunjunganId ?? this.kunjunganId,
      pasienId: pasienId ?? this.pasienId,
      tanggalTagihan: tanggalTagihan ?? this.tanggalTagihan,
      totalBiaya: totalBiaya ?? this.totalBiaya,
      deposit: deposit ?? this.deposit,
      sisaBiaya: sisaBiaya ?? this.sisaBiaya,
      statusPembayaran: statusPembayaran ?? this.statusPembayaran,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
