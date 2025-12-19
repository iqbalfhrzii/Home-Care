import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/reports/data/repositories/tagihan_repository.dart';
import 'package:homecare_mobile/features/reports/domain/models/tagihan.dart';

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kSecondaryColor = Color(0xFF8BC43E);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kDangerColor = Color(0xFFEF4444);

class TagihanFormPage extends StatefulWidget {
  final int registrasiId;
  final Tagihan? existingTagihan;
  final Map<String, dynamic>? registrasiData;

  const TagihanFormPage({
    super.key,
    required this.registrasiId,
    this.existingTagihan,
    this.registrasiData,
  });

  @override
  State<TagihanFormPage> createState() => _TagihanFormPageState();
}

class _TagihanFormPageState extends State<TagihanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _noInvoiceController = TextEditingController();
  final _totalBiayaController = TextEditingController();
  final _depositController = TextEditingController();
  final _primaryIcdController = TextEditingController();

  String _statusPembayaran = 'belum_bayar';
  bool _isSaving = false;

  // Items list
  final List<Map<String, dynamic>> _items = [];
  int _parseCurrencyStringToInt(String? str) {
    if (str == null || str.isEmpty) return 0;
    final cleaned = str.replaceAll(RegExp(r'[^(0-9)\.\-]'), '');
    final d = double.tryParse(cleaned) ?? 0.0;
    return d.round();
  }

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _noInvoiceController.dispose();
    _totalBiayaController.dispose();
    _depositController.dispose();
    _primaryIcdController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    // Auto generate invoice number
    final now = DateTime.now();
    _noInvoiceController.text =
        'INV-${DateFormat('yyyyMMdd-HHmmss').format(now)}';

    // AUTO-POPULATE: Load items from tindakan data
    if (widget.registrasiData != null) {
      debugPrint(
        '🔍 Registrasi data keys: ${widget.registrasiData!.keys.toList()}',
      );

      // Get primary ICD
      final icdList = widget.registrasiData!['icd'] as List?;
      debugPrint('🔍 ICD count: ${icdList?.length ?? 0}');
      if (icdList != null && icdList.isNotEmpty) {
        final firstIcd = icdList.first as Map<String, dynamic>?;
        if (firstIcd != null) {
          _primaryIcdController.text =
              '${firstIcd['kode'] ?? ''} - ${firstIcd['deskripsi'] ?? ''}';
        }
      }

      // AUTO-POPULATE items from tindakan
      final tindakanList = widget.registrasiData!['tindakan'] as List?;
      debugPrint('🔍 Tindakan count: ${tindakanList?.length ?? 0}');
      if (tindakanList != null && tindakanList.isNotEmpty) {
        for (var tindakan in tindakanList) {
          if (tindakan is! Map<String, dynamic>) continue;

          final jumlah = (tindakan['jumlah'] is int)
              ? tindakan['jumlah'] as int
              : int.tryParse(tindakan['jumlah']?.toString() ?? '1') ?? 1;

          // Try multiple field names: harga_satuan, tarif, harga
          int harga = 0;
          if (tindakan['harga_satuan'] != null) {
            harga = (tindakan['harga_satuan'] is num)
                ? (tindakan['harga_satuan'] as num).round()
                : _parseCurrencyStringToInt(
                    tindakan['harga_satuan']?.toString(),
                  );
          } else if (tindakan['tarif'] != null) {
            harga = (tindakan['tarif'] is num)
                ? (tindakan['tarif'] as num).round()
                : _parseCurrencyStringToInt(tindakan['tarif']?.toString());
          } else if (tindakan['harga'] != null) {
            harga = (tindakan['harga'] is num)
                ? (tindakan['harga'] as num).round()
                : _parseCurrencyStringToInt(tindakan['harga']?.toString());
          }

          // Check if tindakan has nested 'tindakan' object (master data)
          if (harga == 0 && tindakan['tindakan'] is Map) {
            final masterTindakan = tindakan['tindakan'] as Map<String, dynamic>;
            if (masterTindakan['tarif'] != null) {
              harga = (masterTindakan['tarif'] is num)
                  ? (masterTindakan['tarif'] as num).round()
                  : _parseCurrencyStringToInt(
                      masterTindakan['tarif']?.toString(),
                    );
            }
          }

          final diskon = (tindakan['diskon'] is num)
              ? (tindakan['diskon'] as num).round()
              : _parseCurrencyStringToInt(tindakan['diskon']?.toString());

          final subtotal = (jumlah * harga) - diskon;

          // Get deskripsi from various sources
          String deskripsi = tindakan['deskripsi']?.toString() ?? '';
          if (deskripsi.isEmpty && tindakan['tindakan'] is Map) {
            final masterTindakan = tindakan['tindakan'] as Map<String, dynamic>;
            deskripsi = masterTindakan['deskripsi']?.toString() ?? '';
          }
          if (deskripsi.isEmpty) {
            deskripsi = tindakan['kode']?.toString() ?? 'Tindakan';
          }

          // Determine kode_layanan from possible fields
          String kodeLayanan = '';
          if (tindakan['kode'] != null &&
              tindakan['kode'].toString().isNotEmpty) {
            kodeLayanan = tindakan['kode'].toString();
          } else if (tindakan['kode_layanan'] != null &&
              tindakan['kode_layanan'].toString().isNotEmpty) {
            kodeLayanan = tindakan['kode_layanan'].toString();
          } else if (tindakan['tindakan'] is Map) {
            final masterTindakan = tindakan['tindakan'] as Map<String, dynamic>;
            kodeLayanan =
                masterTindakan['kode']?.toString() ??
                masterTindakan['kode_layanan']?.toString() ??
                '';
          }

          _items.add({
            'kategori_layanan_id':
                tindakan['kategori_layanan_id'] ?? tindakan['tindakan_id'] ?? 1,
            'kode_layanan': kodeLayanan,
            'deskripsi': deskripsi,
            'jumlah': jumlah,
            'harga_satuan': harga,
            'diskon': diskon,
            'subtotal': subtotal,
          });

          debugPrint(
            '📋 Item: $deskripsi | Qty: $jumlah | Harga: Rp $harga | Subtotal: Rp $subtotal',
          );
        }

        // Calculate total after loading items
        _calculateTotal();
      }
    }
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _ItemFormDialog(
        onSave: (item) {
          setState(() {
            _items.add(item);
            _calculateTotal();
          });
        },
      ),
    );
  }

  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (context) => _ItemFormDialog(
        initialData: _items[index],
        onSave: (item) {
          setState(() {
            _items[index] = item;
            _calculateTotal();
          });
        },
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    int total = 0;
    for (var item in _items) {
      total += (item['subtotal'] as int?) ?? 0;
    }
    _totalBiayaController.text = total.toString();
  }

  int _getBiayaYangHarusDibayar() {
    final total =
        int.tryParse(
          _totalBiayaController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final deposit =
        int.tryParse(
          _depositController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    return total - deposit;
  }

  String _numberToWords(int number) {
    // Simplified terbilang - bisa diperbaiki dengan library
    if (number == 0) return 'Nol Rupiah';
    return '${NumberFormat('#,###', 'id_ID').format(number)} Rupiah';
  }

  Future<void> _saveTagihan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal satu item biaya'),
          backgroundColor: kDangerColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = getIt<TagihanRepository>();
      final now = DateTime.now();
      final totalBiaya =
          int.tryParse(
            _totalBiayaController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
      final deposit =
          int.tryParse(
            _depositController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
      final biayaYangHarusDibayar = _getBiayaYangHarusDibayar();

      final primaryIcdValue = _primaryIcdController.text
          .split(' - ')
          .first
          .trim();
      String formatCurrency(num v) =>
          v is int ? v.toStringAsFixed(2) : v.toStringAsFixed(2);

      final data = {
        'registrasi_id': widget.registrasiId,
        'no_invoice': _noInvoiceController.text,
        'tanggal_invoice': now.toIso8601String(),
        // Send totals as decimal strings (backend expects e.g. "150000000.00")
        'total_biaya': formatCurrency(totalBiaya),
        'deposit': formatCurrency(deposit),
        'biaya_yang_harus_dibayar': formatCurrency(biayaYangHarusDibayar),
        // Send only ICD code (short) to satisfy backend length validation
        'primary_icd': primaryIcdValue,
        'status_pembayaran': _statusPembayaran,
        // 'dicetak_oleh' omitted so backend can use authenticated user if available
        'tanggal_cetak': now.toIso8601String(),
        'print_location': 'Mobile App',
        'server_time': now.toIso8601String(),
        'computer_time': now.toIso8601String(),
        // Items: include kode_layanan (if available) and format numeric fields as decimal strings.
        'items': _items.map((item) {
          final num hargaSatuan = item['harga_satuan'] is num
              ? item['harga_satuan'] as num
              : (int.tryParse(item['harga_satuan']?.toString() ?? '0') ?? 0);
          final num diskonVal = item['diskon'] is num
              ? item['diskon'] as num
              : (int.tryParse(item['diskon']?.toString() ?? '0') ?? 0);
          final num subtotalVal = item['subtotal'] is num
              ? item['subtotal'] as num
              : (int.tryParse(item['subtotal']?.toString() ?? '0') ?? 0);

          final itemData = <String, dynamic>{
            'kategori_layanan_id': item['kategori_layanan_id'],
            'kode_layanan': item['kode_layanan'] ?? item['kode'] ?? '',
            'tanggal_layanan': now.toIso8601String(),
            'deskripsi': item['deskripsi'],
            'jumlah': item['jumlah'],
            'harga_satuan': formatCurrency(hargaSatuan),
            'diskon': formatCurrency(diskonVal),
            'subtotal': formatCurrency(subtotalVal),
          };
          if (item['id'] != null) itemData['id'] = item['id'];
          return itemData;
        }).toList(),
      };
      debugPrint('📤 Creating tagihan payload: $data');

      Tagihan? result;
      if (widget.existingTagihan != null) {
        result = await repo.updateTagihan(widget.existingTagihan!.id, data);
      } else {
        result = await repo.createTagihan(data);
      }

      if (!mounted) return;

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingTagihan != null
                  ? 'Tagihan berhasil diperbarui'
                  : 'Tagihan berhasil dibuat',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, result);
      } else {
        throw Exception('Gagal menyimpan tagihan');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: kDangerColor),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.existingTagihan != null ? 'Edit Tagihan' : 'Buat Tagihan',
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: kWhite,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, kPrimaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Invoice Number
            Container(
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _noInvoiceController,
                decoration: InputDecoration(
                  labelText: 'No. Invoice',
                  labelStyle: const TextStyle(color: kTextGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: kWhite,
                  prefixIcon: const Icon(Icons.receipt, color: kPrimaryColor),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
                readOnly: true,
              ),
            ),
            const SizedBox(height: 16),

            // Primary ICD
            Container(
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _primaryIcdController,
                decoration: InputDecoration(
                  labelText: 'Diagnosis Utama',
                  labelStyle: const TextStyle(color: kTextGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: kWhite,
                  prefixIcon: const Icon(
                    Icons.medical_services,
                    color: kPrimaryColor,
                  ),
                ),
                readOnly: true,
              ),
            ),
            const SizedBox(height: 16),

            // Status Pembayaran
            Container(
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _statusPembayaran,
                decoration: InputDecoration(
                  labelText: 'Status Pembayaran',
                  labelStyle: const TextStyle(color: kTextGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: kWhite,
                  prefixIcon: const Icon(Icons.payment, color: kPrimaryColor),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'belum_bayar',
                    child: Text('Belum Bayar'),
                  ),
                  DropdownMenuItem(value: 'sudah_bayar', child: Text('Lunas')),
                ],
                onChanged: (v) => setState(() => _statusPembayaran = v!),
              ),
            ),
            const SizedBox(height: 24),

            // Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rincian Biaya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextDark,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimaryColor, kPrimaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: kWhite,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_items.isNotEmpty && widget.existingTagihan == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kSuccessColor.withValues(alpha: 0.1),
                        kSuccessColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kSuccessColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: kSuccessColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Items otomatis diambil dari tindakan yang sudah diisi',
                          style: TextStyle(
                            fontSize: 12,
                            color: kSuccessColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada item. Tap Tambah untuk menambahkan.',
                    style: TextStyle(color: kTextGrey),
                  ),
                ),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimaryColor, kPrimaryLight],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        color: kWhite,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item['deskripsi'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['kode_layanan'] != null &&
                            item['kode_layanan'].toString().isNotEmpty)
                          Text(
                            item['kode_layanan'],
                            style: const TextStyle(
                              color: kTextGrey,
                              fontSize: 11,
                            ),
                          ),
                        Text(
                          '${item['jumlah']}x @ Rp ${NumberFormat('#,###', 'id_ID').format(item['harga_satuan'])}',
                          style: const TextStyle(
                            color: kTextGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(item['subtotal'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: kPrimaryColor,
                          ),
                          onPressed: () => _editItem(index),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: kDangerColor,
                            size: 18,
                          ),
                          onPressed: () => _deleteItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),

            // Total & Deposit
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimaryColor.withValues(alpha: 0.05),
                    kPrimaryLight.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimaryColor.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _totalBiayaController,
                      decoration: InputDecoration(
                        labelText: 'Total Biaya',
                        labelStyle: const TextStyle(color: kTextGrey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: kWhite,
                        prefixText: 'Rp ',
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          color: kPrimaryColor,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _depositController,
                      decoration: InputDecoration(
                        labelText: 'Deposit/Uang Muka',
                        labelStyle: const TextStyle(color: kTextGrey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: kWhite,
                        prefixText: 'Rp ',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet,
                          color: kPrimaryColor,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimaryColor, kPrimaryLight],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Biaya Yang Harus Dibayar:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kWhite,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(_getBiayaYangHarusDibayar())}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: kWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimaryColor, kPrimaryLight],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveTagihan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: kWhite,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(kWhite),
                    ),
                  )
                : Text(
                    widget.existingTagihan != null
                        ? 'Perbarui Tagihan'
                        : 'Simpan Tagihan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ItemFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const _ItemFormDialog({this.initialData, required this.onSave});

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kodeLayananController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _jumlahController = TextEditingController(text: '1');
  final _hargaSatuanController = TextEditingController();
  final _diskonController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _kodeLayananController.text = widget.initialData!['kode_layanan'] ?? '';
      _deskripsiController.text = widget.initialData!['deskripsi'] ?? '';
      _jumlahController.text = (widget.initialData!['jumlah'] ?? 1).toString();
      _hargaSatuanController.text = (widget.initialData!['harga_satuan'] ?? 0)
          .toString();
      _diskonController.text = (widget.initialData!['diskon'] ?? 0).toString();
    }
  }

  @override
  void dispose() {
    _kodeLayananController.dispose();
    _deskripsiController.dispose();
    _jumlahController.dispose();
    _hargaSatuanController.dispose();
    _diskonController.dispose();
    super.dispose();
  }

  int _calculateSubtotal() {
    final jumlah = int.tryParse(_jumlahController.text) ?? 0;
    final harga = int.tryParse(_hargaSatuanController.text) ?? 0;
    final diskon = int.tryParse(_diskonController.text) ?? 0;
    return (jumlah * harga) - diskon;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final item = {
      'kategori_layanan_id': 1, // TODO: add category selection
      'kode_layanan': _kodeLayananController.text,
      'deskripsi': _deskripsiController.text,
      'jumlah': int.tryParse(_jumlahController.text) ?? 1,
      'harga_satuan': int.tryParse(_hargaSatuanController.text) ?? 0,
      'diskon': int.tryParse(_diskonController.text) ?? 0,
      'subtotal': _calculateSubtotal(),
    };

    // Preserve ID if editing
    if (widget.initialData?['id'] != null) {
      item['id'] = widget.initialData!['id'];
    }

    widget.onSave(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialData != null ? 'Edit Item' : 'Tambah Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _kodeLayananController,
                decoration: const InputDecoration(
                  labelText: 'Kode Layanan',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jumlahController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hargaSatuanController,
                decoration: const InputDecoration(
                  labelText: 'Harga Satuan',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diskonController,
                decoration: const InputDecoration(
                  labelText: 'Diskon',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(_calculateSubtotal())}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: kWhite,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
