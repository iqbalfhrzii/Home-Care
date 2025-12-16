// TEMPORARILY DISABLED - Needs refactoring for schema v7
// Kunjungan table removed, use Registrasi directly

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/tindakan_catalog_repository.dart';
// intl import removed - not needed

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);

class TindakanItem {
  final String id;
  final String kode;
  final String namaTindakan;
  final String kategori;
  final int harga;
  int jumlah;
  int hargaSatuan;
  int diskon;
  String petugasNama;
  String keterangan;
  int? dokterId;
  int? poliId;
  String? tanggalLayanan;

  TindakanItem({
    required this.id,
    required this.kode,
    required this.namaTindakan,
    required this.kategori,
    required this.harga,
    this.jumlah = 1,
    int? hargaSatuan,
    this.diskon = 0,
    this.petugasNama = '',
    this.keterangan = '',
    this.dokterId,
    this.poliId,
    this.tanggalLayanan,
  }) : hargaSatuan = hargaSatuan ?? harga;

  int get subtotal => (hargaSatuan * jumlah) - diskon;
}

class ScheduleTindakanPage extends StatefulWidget {
  final int registrationId;
  final VoidCallback? onCompleted;

  const ScheduleTindakanPage({
    super.key,
    required this.registrationId,
    this.onCompleted,
  });

  @override
  State<ScheduleTindakanPage> createState() => _ScheduleTindakanPageState();
}

class _ScheduleTindakanPageState extends State<ScheduleTindakanPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<TindakanItem> _selectedTindakan = [];
  bool _isSaving = false;
  bool _isLoadingTindakan = false;

  List<TindakanItem> _allTindakan = [];
  List<TindakanItem> _filteredTindakan = [];

  @override
  void initState() {
    super.initState();
    debugPrint('\n========================================');
    debugPrint(
      '🎯 [TINDAKAN PAGE] Opened for Registrasi ID: ${widget.registrationId}',
    );
    debugPrint('========================================\n');
    _searchController.addListener(_filterTindakan);
    _loadAllTindakan();
  }

  Future<void> _loadAllTindakan() async {
    setState(() => _isLoadingTindakan = true);
    try {
      debugPrint('📚 Loading Tindakan catalog...');
      final repo = TindakanCatalogRepository();
      final list = await repo.getAll();
      final items = list.map((e) {
        final id = (e['id'] ?? '').toString();
        final kode = (e['kode'] ?? '').toString();
        final nama = (e['deskripsi'] ?? '').toString();
        final hargaStr = (e['tarif'] ?? '0').toString();
        final harga =
            int.tryParse(hargaStr.split('.').first) ??
            int.tryParse(hargaStr) ??
            0;
        return TindakanItem(
          id: id,
          kode: kode,
          namaTindakan: nama,
          kategori: 'Tindakan',
          harga: harga,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _allTindakan = items;
          _filteredTindakan = _allTindakan;
          _isLoadingTindakan = false;
        });
        debugPrint('✅ Tindakan catalog loaded: ${_allTindakan.length} items');

        // Load existing tindakan after catalog is ready
        await _loadExistingTindakan();
      }
    } catch (e) {
      debugPrint('❌ Error loading tindakan catalog: $e');
      if (mounted) {
        setState(() {
          _allTindakan = [];
          _filteredTindakan = [];
          _isLoadingTindakan = false;
        });
      }
    }
  }

  Future<void> _loadExistingTindakan() async {
    setState(() => _isLoadingTindakan = true);
    try {
      debugPrint(
        '🔄 Loading existing tindakan for registrasi ${widget.registrationId}',
      );
      final repo = getIt<RegistrasiRepository>();
      final existing = await repo.getExistingTindakan(widget.registrationId);

      debugPrint(
        '🔍 Tindakan Page - Found ${existing.length} existing tindakan',
      );
      debugPrint('🔍 Tindakan Page - Data: $existing');
      debugPrint('🔍 Tindakan Page - Catalog size: ${_allTindakan.length}');

      if (existing.isEmpty) {
        debugPrint('✅ No existing tindakan to load');
        setState(() => _isLoadingTindakan = false);
        return;
      }

      final List<TindakanItem> loadedTindakan = [];

      for (final item in existing) {
        // Parse tindakan data
        final tindakanId = item['tindakan_id'] is int
            ? item['tindakan_id'] as int
            : int.tryParse(item['tindakan_id']?.toString() ?? '0') ?? 0;

        final jumlah = item['jumlah'] is int
            ? item['jumlah'] as int
            : int.tryParse(item['jumlah']?.toString() ?? '1') ?? 1;

        final hargaSatuan = item['harga_satuan'] is int
            ? item['harga_satuan'] as int
            : int.tryParse(item['harga_satuan']?.toString() ?? '0') ?? 0;

        final diskon = item['diskon'] is int
            ? item['diskon'] as int
            : int.tryParse(item['diskon']?.toString() ?? '0') ?? 0;

        final petugasNama = item['petugas_nama']?.toString() ?? 'Perawat A';
        final keterangan = item['keterangan']?.toString() ?? '';

        final dokterId = item['dokter_id'] is int
            ? item['dokter_id'] as int
            : int.tryParse(item['dokter_id']?.toString() ?? '0');

        final poliId = item['poli_id'] is int
            ? item['poli_id'] as int
            : int.tryParse(item['poli_id']?.toString() ?? '0');

        final tanggalLayanan = item['tanggal_layanan']?.toString();

        debugPrint('🔍 Looking for Tindakan ID: $tindakanId in catalog');

        // Find tindakan in catalog or use fallback data
        TindakanItem? tindakanItem;
        try {
          final catalogItem = _allTindakan.firstWhere(
            (e) => int.tryParse(e.id) == tindakanId,
          );
          tindakanItem = TindakanItem(
            id: catalogItem.id,
            kode: catalogItem.kode,
            namaTindakan: catalogItem.namaTindakan,
            kategori: catalogItem.kategori,
            harga: catalogItem.harga,
            jumlah: jumlah,
            hargaSatuan: hargaSatuan,
            diskon: diskon,
            petugasNama: petugasNama,
            keterangan: keterangan,
            dokterId: dokterId,
            poliId: poliId,
            tanggalLayanan: tanggalLayanan,
          );
          debugPrint(
            '✅ Found tindakan in catalog: ${catalogItem.namaTindakan}',
          );
        } catch (e) {
          // If not found in catalog, create from API response data
          debugPrint(
            '⚠️ Tindakan ID $tindakanId not found in catalog, using API data',
          );
          tindakanItem = TindakanItem(
            id: tindakanId.toString(),
            kode: item['kode']?.toString() ?? 'TND-$tindakanId',
            namaTindakan:
                item['nama_tindakan']?.toString() ?? 'Tindakan $tindakanId',
            kategori: item['kategori']?.toString() ?? 'Unknown',
            harga: hargaSatuan,
            jumlah: jumlah,
            hargaSatuan: hargaSatuan,
            diskon: diskon,
            petugasNama: petugasNama,
            keterangan: keterangan,
            dokterId: dokterId,
            poliId: poliId,
            tanggalLayanan: tanggalLayanan,
          );
        }

        loadedTindakan.add(tindakanItem);
      }

      setState(() {
        _selectedTindakan.clear();
        _selectedTindakan.addAll(loadedTindakan);
        _isLoadingTindakan = false;
      });

      debugPrint(
        '✅ Loaded ${_selectedTindakan.length} existing tindakan into UI',
      );
    } catch (e) {
      debugPrint('❌ Error loading existing tindakan: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      setState(() => _isLoadingTindakan = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTindakan() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTindakan = _allTindakan.where((tindakan) {
        return tindakan.kode.toLowerCase().contains(query) ||
            tindakan.namaTindakan.toLowerCase().contains(query) ||
            tindakan.kategori.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _addTindakan(TindakanItem tindakan) {
    setState(() {
      _selectedTindakan.add(
        TindakanItem(
          id: tindakan.id,
          kode: tindakan.kode,
          namaTindakan: tindakan.namaTindakan,
          kategori: tindakan.kategori,
          harga: tindakan.harga,
          jumlah: 1,
          hargaSatuan: tindakan.harga,
          diskon: 0,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tindakan.namaTindakan} ditambahkan'),
        backgroundColor: kSuccessColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // duplicate removed; see implementation near bottom

  void _removeTindakan(int index) {
    setState(() {
      _selectedTindakan.removeAt(index);
    });
  }

  void _showEditDialog(int index) {
    final tindakan = _selectedTindakan[index];
    final jumlahController = TextEditingController(
      text: tindakan.jumlah.toString(),
    );
    final hargaController = TextEditingController(
      text: tindakan.hargaSatuan.toString(),
    );
    final diskonController = TextEditingController(
      text: tindakan.diskon.toString(),
    );
    final petugasController = TextEditingController(text: tindakan.petugasNama);
    final keteranganController = TextEditingController(
      text: tindakan.keterangan,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${tindakan.namaTindakan}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jumlahController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hargaController,
                decoration: const InputDecoration(
                  labelText: 'Harga Satuan',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diskonController,
                decoration: const InputDecoration(
                  labelText: 'Diskon',
                  prefixIcon: Icon(Icons.discount),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: petugasController,
                decoration: const InputDecoration(
                  labelText: 'Nama Petugas',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                tindakan.jumlah = int.tryParse(jumlahController.text) ?? 1;
                tindakan.hargaSatuan =
                    int.tryParse(hargaController.text) ?? tindakan.harga;
                tindakan.diskon = int.tryParse(diskonController.text) ?? 0;
                tindakan.petugasNama = petugasController.text;
                tindakan.keterangan = keteranganController.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kWhite,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  int get _totalBiaya {
    return _selectedTindakan.fold(0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _saveTindakan() async {
    if (_selectedTindakan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 tindakan'),
          backgroundColor: kWarningColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = getIt<RegistrasiRepository>();

      // Build items array
      final items = _selectedTindakan.map((item) {
        final tindakanId = int.tryParse(item.id) ?? 0;
        return {
          'tindakan_id': tindakanId,
          'jumlah': item.jumlah,
          'harga_satuan': item.hargaSatuan,
          'diskon': item.diskon,
          'subtotal': item.subtotal,
          'petugas_nama': item.petugasNama.isNotEmpty
              ? item.petugasNama
              : 'Perawat A',
          'kunjungan_ke': 1,
          'is_free': false,
          'dokter_id': item.dokterId?.toString() ?? '5',
          'poli_id': item.poliId?.toString() ?? '2',
          'tanggal_layanan':
              item.tanggalLayanan ??
              DateTime.now().toIso8601String().split('T')[0],
        };
      }).toList();

      // Send all items in one request
      await repo.attachTindakan(
        registrasiId: widget.registrationId,
        items: items,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedTindakan.length} tindakan berhasil disimpan',
            ),
            backgroundColor: kSuccessColor,
          ),
        );

        if (widget.onCompleted != null) {
          widget.onCompleted!();
        }

        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Error saving tindakan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kDangerColor),
        );
      }
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
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_selectedTindakan.isNotEmpty) _buildSelectedSection(),
                  _buildSearchSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33004B8C),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: kWhite),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tindakan Medis',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pilih Tindakan',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registrasi #${widget.registrationId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.medical_services,
                        color: kWhite,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedTindakan.length} Tindakan',
                        style: const TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: kWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments, color: kWhite, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Rp ${_totalBiaya.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: const TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimaryColor, kPrimaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle, color: kWhite, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tindakan Terpilih',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedTindakan.length,
            itemBuilder: (context, index) {
              final tindakan = _selectedTindakan[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: kScaffoldBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: kPrimaryColor,
                    child: Text(
                      tindakan.jumlah.toString(),
                      style: const TextStyle(
                        color: kWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    tindakan.namaTindakan,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tindakan.kode, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${tindakan.hargaSatuan.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} x ${tindakan.jumlah}',
                        style: TextStyle(fontSize: 12, color: kTextGrey),
                      ),
                      if (tindakan.diskon > 0)
                        Text(
                          'Diskon: Rp ${tindakan.diskon.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      Text(
                        'Subtotal: Rp ${tindakan.subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kSuccessColor,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(index);
                      } else if (value == 'remove') {
                        _removeTindakan(index);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: kPrimaryColor),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari kode atau nama tindakan...',
              prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
              filled: true,
              fillColor: kWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kTextGrey.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimaryColor, width: 2),
              ),
            ),
          ),
        ),
        if (_isLoadingTindakan)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: kPrimaryColor),
          )
        else
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: _filteredTindakan.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: kTextGrey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada tindakan ditemukan',
                          style: TextStyle(color: kTextGrey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTindakan.length,
                    itemBuilder: (context, index) {
                      final tindakan = _filteredTindakan[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: kWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _addTindakan(tindakan),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [kPrimaryColor, kPrimaryLight],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.medical_services,
                                    color: kWhite,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tindakan.kode,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tindakan.namaTindakan,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: kTextDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tindakan.kategori,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: kPrimaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Rp ${tindakan.harga.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: kSuccessColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      color: kWhite,
      padding: const EdgeInsets.all(
        16.0,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedTindakan.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSuccessColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kSuccessColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Biaya:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextDark,
                    ),
                  ),
                  Text(
                    'Rp ${_totalBiaya.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kSuccessColor,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveTindakan,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kWhite,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isSaving
                  ? 'Menyimpan...'
                  : 'Simpan ${_selectedTindakan.length} Tindakan',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kWhite,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
