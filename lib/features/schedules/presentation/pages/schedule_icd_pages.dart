// ICD Selection Page - Uses API data stored in local database

import 'package:flutter/material.dart';
import 'package:homecare_mobile/shared/app_injections.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart' as db;
import 'package:drift/drift.dart' as drift;
import 'package:dio/dio.dart';

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);
const Color kWarningColor = Color(0xFFF59E0B);
const Color kDangerColor = Color(0xFFEF4444);

class IcdItem {
  final String id;
  final String kode;
  final String namaPenyakit;
  final String deskripsi;
  bool isPrimary;

  IcdItem({
    required this.id,
    required this.kode,
    required this.namaPenyakit,
    required this.deskripsi,
    this.isPrimary = false,
  });
}

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
  late final db.AppDatabase _database;
  late final Dio _dio;
  final TextEditingController _searchController = TextEditingController();
  final List<IcdItem> _selectedIcds = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingIcds = false;

  List<db.Icd> _allIcds = [];
  List<db.Icd> _filteredIcds = [];

  @override
  void initState() {
    super.initState();
    _database = getIt<db.AppDatabase>();
    _dio = getIt<Dio>();
    _searchController.addListener(_filterIcds);
    _loadExistingIcds();
    _loadAllIcds();
  }

  Future<void> _loadAllIcds() async {
    setState(() => _isLoadingIcds = true);
    try {
      // Try to load from local database first
      final localIcds = await _database.getAllIcds();

      if (localIcds.isNotEmpty) {
        setState(() {
          _allIcds = localIcds;
          _filteredIcds = localIcds;
          _isLoadingIcds = false;
        });

        // Fetch from API in background to update data
        _fetchIcdsFromApi();
      } else {
        // No local data, fetch from API
        await _fetchIcdsFromApi();
      }
    } catch (e) {
      debugPrint('❌ Error loading ICDs: $e');
      setState(() => _isLoadingIcds = false);
    }
  }

  Future<void> _fetchIcdsFromApi() async {
    try {
      debugPrint('🔍 Fetching ICDs from /icd API...');
      final response = await _dio.get('/icd');

      debugPrint('✅ GET /icd - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Handle both direct array and wrapped response
        final data = response.data is List
            ? response.data as List
            : (response.data['data'] as List? ?? []);

        // Clear existing data
        await _database.deleteAllIcds();

        // Insert new data from API
        for (var item in data) {
          await _database.insertIcd(
            db.IcdsCompanion(
              id: drift.Value(item['id']),
              kode: drift.Value(item['kode']),
              deskripsi: drift.Value(item['deskripsi']),
              katIcd: drift.Value(item['kat_icd']),
              isActive: drift.Value(item['is_active'] ?? true),
            ),
          );
        }

        // Reload from database
        final icds = await _database.getAllIcds();
        if (mounted) {
          setState(() {
            _allIcds = icds;
            _filteredIcds = icds;
            _isLoadingIcds = false;
          });
        }

        debugPrint('✅ Synced ${icds.length} ICDs from /icd API');
      }
    } catch (e) {
      debugPrint('❌ Error fetching ICDs from API: $e');
      // Keep using local data if API fails
      if (mounted) {
        setState(() => _isLoadingIcds = false);
      }
    }
  }

  Future<void> _loadExistingIcds() async {
    setState(() => _isLoading = true);
    try {
      final icds = await _database.getRegistrasiIcdsByRegistrasiId(
        widget.registrationId,
      );

      setState(() {
        _selectedIcds.clear();
        for (var registrasiIcd in icds) {
          // Join with Icds table to get actual data
          _database.getIcdById(registrasiIcd.icdId).then((icd) {
            if (icd != null && mounted) {
              setState(() {
                _selectedIcds.add(
                  IcdItem(
                    id: icd.id.toString(),
                    kode: icd.kode,
                    namaPenyakit: icd.deskripsi,
                    deskripsi: icd.deskripsi,
                    isPrimary: false,
                  ),
                );
              });
            }
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading existing ICDs: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterIcds() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredIcds = _allIcds.where((icd) {
        return icd.kode.toLowerCase().contains(query) ||
            icd.deskripsi.toLowerCase().contains(query) ||
            (icd.katIcd?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  void _addIcd(db.Icd icd) {
    // Check if already added
    if (_selectedIcds.any((item) => item.id == icd.id.toString())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ICD sudah ditambahkan'),
          backgroundColor: kWarningColor,
        ),
      );
      return;
    }

    setState(() {
      _selectedIcds.add(
        IcdItem(
          id: icd.id.toString(),
          kode: icd.kode,
          namaPenyakit: icd.deskripsi,
          deskripsi: icd.deskripsi,
          isPrimary: _selectedIcds.isEmpty, // First one is primary by default
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${icd.kode} ditambahkan'),
        backgroundColor: kSuccessColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeIcd(int index) {
    setState(() {
      final wasPrimary = _selectedIcds[index].isPrimary;
      _selectedIcds.removeAt(index);

      // If removed item was primary, make first item primary
      if (wasPrimary && _selectedIcds.isNotEmpty) {
        _selectedIcds[0].isPrimary = true;
      }
    });
  }

  void _setPrimary(int index) {
    setState(() {
      // Remove primary from all
      for (var icd in _selectedIcds) {
        icd.isPrimary = false;
      }
      // Set selected as primary
      _selectedIcds[index].isPrimary = true;
    });
  }

  Future<void> _saveIcds() async {
    if (_selectedIcds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 ICD'),
          backgroundColor: kWarningColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Delete existing ICDs
      final existingIcds = await _database.getRegistrasiIcdsByRegistrasiId(
        widget.registrationId,
      );
      for (var icd in existingIcds) {
        await _database.deleteRegistrasiIcd(icd.id);
      }

      // Insert new ICDs
      for (var icd in _selectedIcds) {
        await _database.insertRegistrasiIcd(
          db.RegistrasiIcdsCompanion(
            registrasiId: drift.Value(widget.registrationId),
            icdId: drift.Value(int.tryParse(icd.id) ?? 0),
            isSynced: const drift.Value(false), // Will be synced automatically
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIcds.length} ICD berhasil disimpan'),
            backgroundColor: kSuccessColor,
          ),
        );

        // Panggil callback jika ada (dari visit flow)
        if (widget.onCompleted != null) {
          widget.onCompleted!();
        }

        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Error saving diagnosas: $e');
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
                  if (_selectedIcds.isNotEmpty) _buildSelectedSection(),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnosis ICD',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pilih Kode Diagnosis',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_information, color: kWhite, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_selectedIcds.length} ICD dipilih',
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
            color: kPrimaryColor.withOpacity(0.08),
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
                'ICD Terpilih',
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
            itemCount: _selectedIcds.length,
            itemBuilder: (context, index) {
              final icd = _selectedIcds[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: icd.isPrimary
                    ? kSuccessColor.withOpacity(0.1)
                    : kScaffoldBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: icd.isPrimary
                        ? kSuccessColor
                        : kTextGrey.withOpacity(0.2),
                    width: icd.isPrimary ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: icd.isPrimary
                        ? kSuccessColor
                        : kPrimaryColor,
                    radius: 20,
                    child: Text(
                      icd.kode.split('.')[0],
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        icd.kode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (icd.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kSuccessColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRIMARY',
                            style: TextStyle(
                              color: kWhite,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    icd.namaPenyakit,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'primary') {
                        _setPrimary(index);
                      } else if (value == 'remove') {
                        _removeIcd(index);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!icd.isPrimary)
                        const PopupMenuItem(
                          value: 'primary',
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 20, color: kSuccessColor),
                              SizedBox(width: 8),
                              Text('Jadikan Primary'),
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
              hintText: 'Cari kode atau deskripsi ICD...',
              prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
              filled: true,
              fillColor: kWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kTextGrey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimaryColor, width: 2),
              ),
            ),
          ),
        ),
        if (_isLoadingIcds)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: kPrimaryColor),
          )
        else
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: _filteredIcds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: kTextGrey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada ICD ditemukan',
                          style: TextStyle(color: kTextGrey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredIcds.length,
                    itemBuilder: (context, index) {
                      final icd = _filteredIcds[index];
                      final isSelected = _selectedIcds.any(
                        (item) => item.id == icd.id.toString(),
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: kWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? kSuccessColor
                                : kTextGrey.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _addIcd(icd),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isSelected
                                          ? [kSuccessColor, kSuccessColor]
                                          : [kPrimaryColor, kPrimaryLight],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      icd.kode.split('.').first,
                                      style: const TextStyle(
                                        color: kWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            icd.kode,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: kPrimaryColor,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.check_circle,
                                              color: kSuccessColor,
                                              size: 18,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        icd.deskripsi,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: kTextDark,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (icd.katIcd != null) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: kPrimaryColor.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Kategori: ${icd.katIcd}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: kPrimaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
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
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveIcds,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: kWhite),
              )
            : const Icon(Icons.save),
        label: Text(
          _isSaving ? 'Menyimpan...' : 'Simpan ${_selectedIcds.length} ICD',
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
    );
  }
}
