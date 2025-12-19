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
  final List<dynamic>?
  existingIcdData; // Optional: to avoid API call if already have data

  const ScheduleIcdPage({
    super.key,
    required this.registrationId,
    this.onCompleted,
    this.existingIcdData,
  });

  @override
  State<ScheduleIcdPage> createState() => _ScheduleIcdPageState();
}

class _ScheduleIcdPageState extends State<ScheduleIcdPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSaving = false;
  final List<_SelectedIcd> _selectedIcds = [];
  final List<int> _existingIcdIds = []; // Track existing IDs for detachment
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

      // Use data from widget if provided (avoid API call)
      List<dynamic> existing;
      if (widget.existingIcdData != null) {
        debugPrint('✅ Using existing ICD data from widget parameter');
        existing = widget.existingIcdData!;
      } else {
        debugPrint('🌐 Fetching existing ICD from API');
        final repo = getIt<RegistrasiRepository>();
        existing = await repo.getExistingIcd(widget.registrationId);
      }

      debugPrint('🔍 ICD Page - Found ${existing.length} existing ICD');
      debugPrint('🔍 ICD Page - Data: $existing');
      debugPrint('🔍 ICD Page - Catalog size: ${_allIcd.length}');

      if (existing.isEmpty) {
        debugPrint('✅ No existing ICD to load');
        return;
      }

      final List<_SelectedIcd> loadedIcds = [];

      for (final item in existing) {
        // Robust parsing for icd id: support multiple possible shapes
        int icdId = -1;
        try {
          if (item['icd_id'] is int) {
            icdId = item['icd_id'] as int;
          } else if (item['icd_id'] is Map &&
              (item['icd_id'] as Map).containsKey('id')) {
            icdId = (item['icd_id'] as Map)['id'] is int
                ? (item['icd_id'] as Map)['id'] as int
                : int.tryParse(
                        (item['icd_id'] as Map)['id']?.toString() ?? '',
                      ) ??
                      -1;
          } else if (item['id'] is int) {
            icdId = item['id'] as int;
          } else if (item['icd'] is Map &&
              (item['icd'] as Map).containsKey('id')) {
            icdId = (item['icd'] as Map)['id'] is int
                ? (item['icd'] as Map)['id'] as int
                : int.tryParse((item['icd'] as Map)['id']?.toString() ?? '') ??
                      -1;
          } else {
            icdId =
                int.tryParse(
                  item['icd_id']?.toString() ?? item['id']?.toString() ?? '-1',
                ) ??
                -1;
          }
        } catch (e) {
          debugPrint('⚠️ Failed parsing icd id from item: $item -> $e');
          icdId = -1;
        }
        // Prefer pivot.is_primary when present (from registrasi pivot table)
        bool isPrimary = false;
        try {
          final pivot = item['pivot'] as Map<String, dynamic>?;
          if (pivot != null && pivot.containsKey('is_primary')) {
            final p = pivot['is_primary'];
            isPrimary =
                p == true ||
                p == 1 ||
                p?.toString()?.toLowerCase() == '1' ||
                p?.toString()?.toLowerCase() == 'true';
            debugPrint(
              '🔑 Found pivot.is_primary=$p -> isPrimary=$isPrimary for item id=$icdId',
            );
          } else {
            isPrimary =
                item['is_primary'] == true ||
                item['is_primary'] == 1 ||
                item['is_primary']?.toString().toLowerCase() == 'true';
          }
        } catch (e) {
          debugPrint('⚠️ Error reading pivot.is_primary: $e');
          isPrimary =
              item['is_primary'] == true ||
              item['is_primary'] == 1 ||
              item['is_primary']?.toString().toLowerCase() == 'true';
        }
        final kasus =
            item['kasus']?.toString() ?? (isPrimary ? 'Utama' : 'Sekunder');

        debugPrint('🔍 Looking for ICD ID: $icdId in catalog');

        // Find ICD in catalog
        _IcdItem? icdItem = _allIcd.cast<_IcdItem?>().firstWhere(
          (e) => e?.id == icdId,
          orElse: () => null,
        );

        // If not found in catalog, fetch from API
        if (icdItem == null) {
          if (icdId <= 0) {
            debugPrint('⚠️ Invalid ICD id ($icdId) for item: $item');
          }
          debugPrint(
            '⚠️ ICD ID $icdId not found in catalog, fetching from API...',
          );
          try {
            final icdRepo = IcdRepository();
            final icdData = await icdRepo.getById(icdId);
            if (icdData != null) {
              icdItem = _IcdItem(
                id: (icdData['id'] ?? icdId) as int,
                code: (icdData['kode'] ?? 'ICD-$icdId').toString(),
                name: (icdData['deskripsi'] ?? 'Unknown').toString(),
              );
              // Add to catalog for future use
              _allIcd.add(icdItem);
              debugPrint(
                '✅ Fetched ICD from API: ${icdItem.code} - ${icdItem.name}',
              );
            } else {
              // Fallback to data from existing item
              debugPrint('⚠️ API fetch failed, using fallback data');
              icdItem = _IcdItem(
                id: icdId,
                code: item['kode']?.toString() ?? 'ICD-$icdId',
                name: item['deskripsi']?.toString() ?? 'Unknown',
              );
            }
          } catch (e) {
            debugPrint('❌ Error fetching ICD $icdId from API: $e');
            // Fallback to data from existing item
            icdItem = _IcdItem(
              id: icdId,
              code: item['kode']?.toString() ?? 'ICD-$icdId',
              name: item['deskripsi']?.toString() ?? 'Unknown',
            );
          }
        }

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
        // Track existing ICD ID (use master icd id expected by backend)
        _existingIcdIds.add(icdId);
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
      debugPrint('📚 Loading ICD catalog (50 items)...');
      final repo = IcdRepository();

      // Load only first 50 items
      final response = await repo.getAll(page: 1, perPage: 50);
      final items = response['data'] as List? ?? response as List;

      _allIcd = items
          .map((e) => e as Map<String, dynamic>)
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
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading ICD catalog: $e');
      debugPrint('Stack trace: $stackTrace');
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

      // Validate selected ICD ids exist in loaded catalog to avoid server validation errors
      final availableIds = _allIcd.map((e) => e.id).toSet();
      final missing = _selectedIcds
          .where((s) => !availableIds.contains(s.id))
          .toList();
      if (missing.isNotEmpty) {
        debugPrint(
          '❌ Selected ICD ids not present in catalog: ${missing.map((m) => m.id).toList()}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Beberapa ICD tidak ditemukan di katalog: ${missing.map((m) => m.code).join(', ')}',
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      // Build items payload from selected ICDs
      final items = _selectedIcds.map((item) {
        return {
          'icd_id': item.id,
          'is_primary': item.isPrimary,
          'kasus': item.kasus,
        };
      }).toList();

      // Sanitize existing ids and items to avoid sending invalid zeros
      final sanitizedExisting = _existingIcdIds.where((id) => id > 0).toList();
      final sanitizedItems = items.where((it) {
        final iid = int.tryParse(it['icd_id']?.toString() ?? '-1') ?? -1;
        return iid > 0;
      }).toList();

      // Debug: print sync parameters
      debugPrint('🔁 Sync ICD - registrasiId=${widget.registrationId}');
      debugPrint('📤 Existing ICD IDs (sanitized): $sanitizedExisting');
      debugPrint(
        '📤 Items payload (sanitized count): ${sanitizedItems.length}',
      );
      debugPrint(
        '📤 First ICD preview: ${sanitizedItems.isNotEmpty ? sanitizedItems.first : {}}',
      );

      // Sync (replace) all items in one request
      await repo.syncIcd(
        registrasiId: widget.registrationId,
        existingIcdIds: sanitizedExisting,
        items: sanitizedItems,
      );

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
                        final willBePrimary = !isPrimary;
                        if (willBePrimary) {
                          // Make this the only primary
                          for (var i = 0; i < _selectedIcds.length; i++) {
                            _selectedIcds[i].isPrimary = false;
                            _selectedIcds[i].kasus = 'Sekunder';
                          }
                          _selectedIcds[selectedIndex].isPrimary = true;
                          _selectedIcds[selectedIndex].kasus = 'Utama';
                        } else {
                          // Unset this primary
                          _selectedIcds[selectedIndex].isPrimary = false;
                          _selectedIcds[selectedIndex].kasus = 'Sekunder';
                          // Ensure at least one primary remains: set first selected as primary
                          final anyPrimary = _selectedIcds.any(
                            (e) => e.isPrimary,
                          );
                          if (!anyPrimary && _selectedIcds.isNotEmpty) {
                            _selectedIcds[0].isPrimary = true;
                            _selectedIcds[0].kasus = 'Utama';
                          }
                        }
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
                  final removed = _selectedIcds.removeAt(selectedIndex);
                  // If removed item was primary, promote first remaining to primary
                  if (removed.isPrimary && _selectedIcds.isNotEmpty) {
                    _selectedIcds[0].isPrimary = true;
                    _selectedIcds[0].kasus = 'Utama';
                  }
                } else {
                  // First selected ICD is primary by default
                  final isFirstIcd = _selectedIcds.isEmpty;
                  if (isFirstIcd) {
                    // ensure others are not primary (none exist)
                    _selectedIcds.add(
                      _SelectedIcd(
                        id: item.id,
                        code: item.code,
                        name: item.name,
                        isPrimary: true,
                        kasus: 'Utama',
                      ),
                    );
                  } else {
                    _selectedIcds.add(
                      _SelectedIcd(
                        id: item.id,
                        code: item.code,
                        name: item.name,
                        isPrimary: false,
                        kasus: 'Sekunder',
                      ),
                    );
                  }
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
