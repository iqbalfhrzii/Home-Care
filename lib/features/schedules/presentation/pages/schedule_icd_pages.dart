import 'package:flutter/material.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/icd_repository.dart';

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kSuccessColor = Colors.green;
const Color kDangerColor = Colors.red;

class ScheduleIcdPage extends StatefulWidget {
  final int registrationId;
  final VoidCallback? onCompleted;

  const ScheduleIcdPage({
    super.key,
    required this.registrationId,
    this.onCompleted,
  });

  @override
  State<ScheduleIcdPage> createState() => _ScheduleIcdPageState();
}

class _ScheduleIcdPageState extends State<ScheduleIcdPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSaving = false;
  final List<_SelectedIcd> _selectedIcds = [];
  List<_IcdItem> _allIcd = [];
  List<_IcdItem> _filteredIcd = [];

  @override
  void initState() {
    super.initState();
    debugPrint('\n========================================');
    debugPrint(
      '🎯 [ICD PAGE] Opened for Registrasi ID: ${widget.registrationId}',
    );
    debugPrint('========================================\n');
    _loadIcdCatalog();
    _searchController.addListener(_onSearch);
  }

  Future<void> _loadExistingIcd() async {
    try {
      debugPrint(
        '🔄 Loading existing ICD for registrasi ${widget.registrationId}',
      );
      final repo = getIt<RegistrasiRepository>();
      final existing = await repo.getExistingIcd(widget.registrationId);

      debugPrint('🔍 ICD Page - Found ${existing.length} existing ICD');
      debugPrint('🔍 ICD Page - Data: $existing');
      debugPrint('🔍 ICD Page - Catalog size: ${_allIcd.length}');

      if (existing.isEmpty) {
        debugPrint('✅ No existing ICD to load');
        return;
      }

      final List<_SelectedIcd> loadedIcds = [];

      for (final item in existing) {
        final icdId = item['icd_id'] is int
            ? item['icd_id'] as int
            : int.tryParse(item['icd_id']?.toString() ?? '0') ?? 0;
        final isPrimary =
            item['is_primary'] == true ||
            item['is_primary'] == 1 ||
            item['is_primary']?.toString().toLowerCase() == 'true';
        final kasus =
            item['kasus']?.toString() ?? (isPrimary ? 'Utama' : 'Sekunder');

        debugPrint('🔍 Looking for ICD ID: $icdId in catalog');

        // Find ICD in catalog
        final icdItem = _allIcd.firstWhere(
          (e) => e.id == icdId,
          orElse: () {
            debugPrint('⚠️ ICD ID $icdId not found in catalog, using fallback');
            return _IcdItem(
              id: icdId,
              code: item['kode']?.toString() ?? 'ICD-$icdId',
              name: item['deskripsi']?.toString() ?? 'Unknown',
            );
          },
        );

        debugPrint(
          '✅ Found ICD: id=${icdItem.id}, code=${icdItem.code}, name=${icdItem.name}, isPrimary=$isPrimary',
        );

        loadedIcds.add(
          _SelectedIcd(
            id: icdItem.id,
            code: icdItem.code,
            name: icdItem.name,
            isPrimary: isPrimary,
            kasus: kasus,
          ),
        );
      }

      setState(() {
        _selectedIcds.clear();
        _selectedIcds.addAll(loadedIcds);
      });

      debugPrint('✅ Loaded ${_selectedIcds.length} existing ICD into UI');
    } catch (e) {
      debugPrint('❌ Error loading existing ICD: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadIcdCatalog() async {
    try {
      debugPrint('📚 Loading ICD catalog...');
      final repo = IcdRepository();
      final list = await repo.getAll();
      _allIcd = list
          .map(
            (e) => _IcdItem(
              id: (e['id'] ?? 0) as int,
              code: (e['kode'] ?? '').toString(),
              name: (e['deskripsi'] ?? '').toString(),
            ),
          )
          .toList();
      setState(() {
        _filteredIcd = List.of(_allIcd);
      });
      debugPrint('✅ ICD catalog loaded: ${_allIcd.length} items');

      // Load existing ICD after catalog is ready
      await _loadExistingIcd();
    } catch (e) {
      debugPrint('❌ Error loading ICD catalog: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Diagnosa (ICD-10)',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Registrasi #${widget.registrationId}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: kWhite,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari diagnosa...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(child: _buildIcdList()),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveSelection,
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
          label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: kWhite,
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ),
    );
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredIcd = _allIcd
          .where(
            (e) =>
                e.code.toLowerCase().contains(q) ||
                e.name.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  Future<void> _saveSelection() async {
    setState(() => _isSaving = true);
    try {
      final repo = getIt<RegistrasiRepository>();

      // Build items array
      final items = _selectedIcds.map((item) {
        return {
          'icd_id': item.id,
          'is_primary': item.isPrimary,
          'kasus': item.kasus,
        };
      }).toList();

      // Send all items in one request
      await repo.attachIcd(registrasiId: widget.registrationId, items: items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIcds.length} diagnosa berhasil disimpan'),
            backgroundColor: kSuccessColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Error saving ICD: $e');
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

  Widget _buildIcdList() {
    if (_filteredIcd.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Tidak ada data ICD'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _filteredIcd.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _filteredIcd[index];
        final selectedIndex = _selectedIcds.indexWhere(
          (e) => e.code == item.code,
        );
        final selected = selectedIndex >= 0;
        final isPrimary = selected
            ? _selectedIcds[selectedIndex].isPrimary
            : false;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: selected ? kPrimaryColor : Colors.grey[300],
              child: Text(
                item.code,
                style: const TextStyle(fontSize: 10, color: kWhite),
              ),
            ),
            title: Text(item.name),
            subtitle: Text(
              selected
                  ? '${item.code} - ${isPrimary ? "Utama" : "Sekunder"}'
                  : item.code,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  IconButton(
                    icon: Icon(
                      isPrimary ? Icons.star : Icons.star_border,
                      color: isPrimary ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedIcds[selectedIndex].isPrimary = !isPrimary;
                        _selectedIcds[selectedIndex].kasus = !isPrimary
                            ? 'Utama'
                            : 'Sekunder';
                      });
                    },
                    tooltip: isPrimary
                        ? 'Set sebagai Sekunder'
                        : 'Set sebagai Utama',
                  ),
                Icon(
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: selected ? kPrimaryColor : null,
                ),
              ],
            ),
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedIcds.removeAt(selectedIndex);
                } else {
                  // First selected ICD is primary by default
                  final isFirstIcd = _selectedIcds.isEmpty;
                  _selectedIcds.add(
                    _SelectedIcd(
                      id: item.id,
                      code: item.code,
                      name: item.name,
                      isPrimary: isFirstIcd,
                      kasus: isFirstIcd ? 'Utama' : 'Sekunder',
                    ),
                  );
                }
              });
            },
          ),
        );
      },
    );
  }
}

class _IcdItem {
  final int id;
  final String code;
  final String name;
  _IcdItem({required this.id, required this.code, required this.name});
}

class _SelectedIcd {
  final int id;
  final String code;
  final String name;
  bool isPrimary;
  String kasus;

  _SelectedIcd({
    required this.id,
    required this.code,
    required this.name,
    this.isPrimary = false,
    this.kasus = 'Sekunder',
  });
}
