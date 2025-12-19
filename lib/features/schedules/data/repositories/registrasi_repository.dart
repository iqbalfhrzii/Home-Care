import 'package:dio/dio.dart' as dio_pkg;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/core/network/dio.dart';
import 'package:homecare_mobile/features/schedules/domain/models/registrasi.dart';

/// Repository untuk Registrasi
///
/// CACHING STRATEGY:
/// - getAllRegistrasi() : Uses cache (_cached) for list view performance
/// - getRegistrasiById() : ALWAYS bypasses cache, fetches from API with full relations (icds, tindakans)
///   This is CRITICAL for edit forms that need to load existing selections
///
/// Cache is cleared on: create, update, delete, attach, detach operations
class RegistrasiRepository {
  // Cache ONLY for list operations - NOT used for detail fetching
  List<Registrasi>? _cached;

  /// Ambil semua registrasi dari API Laravel (paginated)
  Future<List<Registrasi>> getAllRegistrasi({
    int perPage = 1000,
    String? status,
  }) async {
    // If cache exists, serve it to keep UI responsive
    if (_cached != null) return _cached!;

    // Try progressively smaller page sizes to avoid large-payload issues
    final candidates = <int>{
      perPage,
      200,
      100,
      50,
      25,
      15,
    }.where((p) => p > 0).toList();
    dio_pkg.Response? lastResp;
    dio_pkg.DioException? lastErr;
    for (final size in candidates) {
      try {
        final params = <String, dynamic>{'per_page': size};
        if (status != null && status.isNotEmpty) params['status'] = status;

        const int maxAttempts = 3;
        dio_pkg.Response? resp;
        dynamic data;
        dio_pkg.DioException? lastDioErr;
        bool success = false;

        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
          try {
            resp = await dio.get(
              '/registrasi',
              queryParameters: params,
              options: dio_pkg.Options(
                receiveTimeout: const Duration(seconds: 25),
                sendTimeout: const Duration(seconds: 20),
                followRedirects: false,
                // Keep body on errors for diagnostics
                receiveDataWhenStatusError: true,
                responseType: dio_pkg.ResponseType.plain,
                // Treat non-2xx as responses so we can inspect
                validateStatus: (_) => true,
              ),
            );

            lastResp = resp;
            if (resp.statusCode != null && resp.statusCode! >= 400) {
              debugPrint(
                '❌ Registrasi API error (perPage=$size, attempt=$attempt): status=${resp.statusCode}, data=${resp?.data}',
              );
              // If server returns 4xx/5xx, no point retrying this size
              break;
            }

            // Try parse normally, then fallback to extraction
            try {
              final body = resp!.data is String
                  ? resp!.data as String
                  : jsonEncode(resp!.data);
              data = jsonDecode(body);
              success = true;
              break;
            } catch (e) {
              try {
                final raw = resp!.data is String
                    ? resp!.data as String
                    : resp!.data.toString();
                data = _tryExtractAndDecodeJson(raw);
                debugPrint(
                  '⚠️ Parsed registrasi response by extraction (perPage=$size, attempt=$attempt)',
                );
                success = true;
                break;
              } catch (e2) {
                debugPrint(
                  '⚠️ Attempt $attempt failed to decode registrasi (perPage=$size): $e2',
                );
                if (attempt < maxAttempts)
                  await Future.delayed(const Duration(milliseconds: 250));
                continue;
              }
            }
          } on dio_pkg.DioException catch (e) {
            lastDioErr = e;
            debugPrint(
              '❌ DioException fetching registrasi (perPage=$size, attempt=$attempt): type=${e.type}, message=${e.message}',
            );
            if (attempt < maxAttempts)
              await Future.delayed(const Duration(milliseconds: 250));
            continue;
          }
        }

        if (!success) {
          if (lastResp != null &&
              lastResp.statusCode != null &&
              lastResp.statusCode! >= 400) {
            // server returned error for this page size; try next smaller size
            continue;
          }
          // Parsing failed after retries — try next smaller page size
          debugPrint(
            '❌ Failed to decode registrasi response after $maxAttempts attempts (perPage=$size)',
          );
          continue;
        }
        // `data` has already been decoded in the retry loop above.
        // Use the parsed `data` variable populated earlier.

        final List<dynamic> items = (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : (data is List ? data : const <dynamic>[]);
        final regs = items
            .map((e) => Registrasi.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // If response contains pagination meta, fetch remaining pages
        Map meta = {};
        if (data is Map && data.containsKey('meta')) {
          try {
            meta = Map<String, dynamic>.from(data['meta'] ?? {});
          } catch (_) {
            meta = {};
          }
        }

        final lastPage = (meta['last_page'] is int)
            ? meta['last_page'] as int
            : int.tryParse('${meta['last_page'] ?? 1}') ?? 1;

        if (lastPage > 1) {
          for (int page = 2; page <= lastPage; page++) {
            bool pageSuccess = false;
            const int pageMaxAttempts = 3;
            for (int attempt = 1; attempt <= pageMaxAttempts; attempt++) {
              try {
                final respPage = await dio.get(
                  '/registrasi',
                  queryParameters: {'per_page': size, 'page': page},
                  options: dio_pkg.Options(
                    receiveTimeout: const Duration(seconds: 25),
                    sendTimeout: const Duration(seconds: 20),
                    followRedirects: false,
                    receiveDataWhenStatusError: true,
                    responseType: dio_pkg.ResponseType.plain,
                    validateStatus: (_) => true,
                  ),
                );
                if (respPage.statusCode != null &&
                    respPage.statusCode! >= 400) {
                  debugPrint(
                    '❌ Registrasi API error (page=$page): status=${respPage.statusCode}, data=${respPage.data}',
                  );
                  break;
                }

                // parse page response robustly
                dynamic pageData;
                try {
                  final body = respPage.data is String
                      ? respPage.data as String
                      : jsonEncode(respPage.data);
                  pageData = jsonDecode(body);
                  pageSuccess = true;
                } catch (e) {
                  try {
                    final raw = respPage.data is String
                        ? respPage.data as String
                        : respPage.data.toString();
                    pageData = _tryExtractAndDecodeJson(raw);
                    debugPrint(
                      '⚠️ Parsed registrasi page response by extraction (page=$page, attempt=$attempt)',
                    );
                    pageSuccess = true;
                  } catch (e2) {
                    debugPrint(
                      '⚠️ Attempt $attempt failed to decode registrasi page $page: $e2',
                    );
                    if (attempt < pageMaxAttempts)
                      await Future.delayed(const Duration(milliseconds: 250));
                    continue;
                  }
                }

                if (pageSuccess) {
                  final List<dynamic> pageItems =
                      (pageData is Map && pageData['data'] is List)
                      ? (pageData['data'] as List)
                      : (pageData is List ? pageData : const <dynamic>[]);
                  regs.addAll(
                    pageItems.map(
                      (e) => Registrasi.fromJson(Map<String, dynamic>.from(e)),
                    ),
                  );
                  break;
                }
              } on dio_pkg.DioException catch (e) {
                debugPrint(
                  '❌ DioException fetching registrasi (page=$page, attempt=$attempt): type=${e.type}, message=${e.message}',
                );
                if (attempt < pageMaxAttempts)
                  await Future.delayed(const Duration(milliseconds: 250));
                continue;
              } catch (e) {
                debugPrint(
                  '❌ Unexpected error fetching registrasi (page=$page, attempt=$attempt): $e',
                );
                break;
              }
            }
            if (!pageSuccess) {
              debugPrint('⚠️ Skipping page $page after repeated failures');
              continue;
            }
          }
        }

        // Deduplicate by ID in case paginated responses overlap or API returned duplicates
        try {
          final Map<int, Registrasi> byId = {};
          for (final r in regs) {
            byId[r.id] = r;
          }
          final deduped = byId.values.toList();
          if (deduped.length != regs.length) {
            debugPrint(
              '⚠️ Duplicates removed from registrasi list: original=${regs.length}, deduped=${deduped.length}',
            );
          }
          _cached = deduped;
          return deduped;
        } catch (_) {
          _cached = regs;
          return regs;
        }
      } on dio_pkg.DioException catch (e) {
        lastErr = e;
        debugPrint(
          '❌ DioException fetching registrasi (perPage=$size): type=${e.type}, message=${e.message}, error=${e.error}, response=${e.response?.data}',
        );
        // Try next smaller page size
        continue;
      } catch (e) {
        debugPrint('❌ Error fetching registrasi (perPage=$size): $e');
        // Try next smaller page size
        continue;
      }
    }
    // If we reached here, all attempts failed
    if (lastResp != null) {
      debugPrint(
        '⚠️ Returning cached/empty registrasi after last response: status=${lastResp.statusCode}',
      );
    }
    if (lastErr != null) {
      debugPrint(
        '⚠️ Returning cached/empty registrasi after last DioException: type=${lastErr.type}, message=${lastErr.message}',
      );
    }
    return _cached ?? [];
  }

  // Try to extract a JSON substring from a noisy or truncated response and decode it.
  // This scans for an object that contains a "data" key or falls back to extracting
  // the first well-formed JSON array/object using a simple brace matcher.
  dynamic _tryExtractAndDecodeJson(String raw) {
    // Fast path: look for object that contains "\"data\""
    final dataIndex = raw.indexOf('"data"');
    if (dataIndex != -1) {
      // find nearest '{' before dataIndex
      final start = raw.lastIndexOf('{', dataIndex);
      if (start != -1) {
        // find matching closing brace from start
        int depth = 0;
        for (int i = start; i < raw.length; i++) {
          final ch = raw.codeUnitAt(i);
          if (ch == 0x7B) depth++; // '{'
          if (ch == 0x7D) depth--; // '}'
          if (depth == 0) {
            final sub = raw.substring(start, i + 1);
            return jsonDecode(sub);
          }
        }
      }
    }

    // Fallback: try to extract first JSON array or object by searching for '[' or '{'
    final startIdx = raw.indexOf(RegExp(r'[\[{]'));
    if (startIdx == -1) throw FormatException('No JSON start char found');

    final startChar = raw[startIdx];
    final endChar = startChar == '[' ? ']' : '}';
    int depth = 0;
    for (int i = startIdx; i < raw.length; i++) {
      final ch = raw[i];
      if (ch == startChar) depth++;
      if (ch == endChar) depth--;
      if (depth == 0) {
        final sub = raw.substring(startIdx, i + 1);
        return jsonDecode(sub);
      }
    }

    throw FormatException('Failed to extract balanced JSON substring');
  }

  /// Ambil registrasi pasien tertentu dari API (atau cache) lalu urutkan terbaru.
  Future<List<Registrasi>> getRegistrasiByPasienId(int pasienId) async {
    // Prefer ambil semua lalu filter untuk mengurangi ketergantungan query server
    final all = await getAllRegistrasi();
    final filtered = all.where((r) => r.safePasienId == pasienId).toList();
    filtered.sort((a, b) {
      final ad =
          a.parsedTglReg ??
          a.parsedTglKunjungan ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bd =
          b.parsedTglReg ??
          b.parsedTglKunjungan ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return filtered;
  }

  /// Ambil registrasi terbaru untuk pasien tertentu, jika ada.
  Future<Registrasi?> getLatestRegistrasiForPatient(int pasienId) async {
    final list = await getRegistrasiByPasienId(pasienId);
    if (list.isEmpty) return null;
    return list.first;
  }

  /// Fetch registrasi by ID from API - ALWAYS bypasses cache to get full details with relations
  /// This is critical for edit forms that need icds and tindakans relations
  Future<Registrasi?> getRegistrasiById(int id) async {
    debugPrint('\n🎯 [DETAIL] Requesting registrasi $id');

    // Prefer using cached list if available to avoid multiple per-ID API calls.
    if (_cached != null) {
      try {
        Registrasi? cached;
        try {
          cached = _cached!.firstWhere((r) => r.id == id);
        } catch (_) {
          cached = null;
        }
        if (cached != null) {
          // If cached object already contains relations (icds/tindakans), return it
          final hasIcd = cached.icds != null && cached.icds!.isNotEmpty;
          final hasTindakan =
              cached.tindakans != null && cached.tindakans!.isNotEmpty;
          if (hasIcd || hasTindakan) {
            debugPrint(
              'ℹ️ Returning registrasi $id from cache (hasIcd=$hasIcd, hasTindakan=$hasTindakan)',
            );
            return cached;
          }
          // Otherwise fall through to fetch fresh detail
          debugPrint(
            'ℹ️ Cached registrasi $id has no relations; fetching fresh detail',
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error checking cache for registrasi $id: $e');
      }
    } else {
      debugPrint('ℹ️ No registrasi cache available; will fetch from API');
    }

    debugPrint('🌐 [API] GET /registrasi/$id');

    try {
      final resp = await dio.get(
        '/registrasi/$id',
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );

      debugPrint('✅ [API] Response status: ${resp.statusCode}');

      if (resp.statusCode == null || resp.statusCode! >= 400) {
        debugPrint('❌ Get registrasi by id failed: status=${resp.statusCode}');
        debugPrint('📦 Response data: ${resp.data}');
        return null;
      }

      final data = resp.data is Map && (resp.data as Map).containsKey('data')
          ? resp.data['data']
          : resp.data;

      final registrasi = Registrasi.fromJson(Map<String, dynamic>.from(data));

      debugPrint('✅ [DETAIL] Registrasi loaded successfully');
      debugPrint('   - ID: ${registrasi.id}');
      debugPrint('   - No. Reg: ${registrasi.noReg}');
      debugPrint(
        '   - Has ICDs: ${registrasi.icds != null} (${registrasi.icds?.length ?? 0} items)',
      );
      debugPrint(
        '   - Has Tindakans: ${registrasi.tindakans != null} (${registrasi.tindakans?.length ?? 0} items)',
      );

      return registrasi;
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException get registrasi by id: type=${e.type}, message=${e.message}',
      );
      debugPrint('📦 Response: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error getting registrasi by id: $e');
      return null;
    }
  }

  /// Return total registrasi count from pagination meta without fetching all pages.
  /// Uses `per_page=1` and reads `meta.total` safely.
  Future<int?> getRegistrasiCount() async {
    try {
      final resp = await dio.get(
        '/registrasi',
        queryParameters: {'per_page': 1},
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
          responseType: dio_pkg.ResponseType.plain,
          validateStatus: (_) => true,
        ),
      );

      if (resp.statusCode == null || resp.statusCode! >= 400) {
        debugPrint(
          '❌ Registrasi count endpoint failed: status=${resp.statusCode}',
        );
        return null;
      }

      dynamic data;
      try {
        final body = resp.data is String
            ? resp.data as String
            : jsonEncode(resp.data);
        data = jsonDecode(body);
      } catch (e) {
        try {
          final raw = resp.data is String
              ? resp.data as String
              : resp.data.toString();
          final start = raw.indexOf(RegExp(r'[\[{]'));
          final end = raw.lastIndexOf(RegExp(r'[\]}]'));
          if (start != -1 && end != -1 && end > start) {
            final sub = raw.substring(start, end + 1);
            data = jsonDecode(sub);
            debugPrint(
              '⚠️ Parsed registrasi count response by trimming non-JSON prefix/suffix',
            );
          } else {
            throw e;
          }
        } catch (e2) {
          debugPrint('❌ Failed to parse registrasi count response: $e2');
          return null;
        }
      }

      if (data is Map && data.containsKey('meta')) {
        final meta = data['meta'];
        if (meta is Map && meta.containsKey('total')) {
          final t = meta['total'];
          if (t is int) return t;
          return int.tryParse(t?.toString() ?? '');
        }
      }

      // sometimes API returns total at top-level
      if (data is Map && data.containsKey('total')) {
        final t = data['total'];
        if (t is int) return t;
        return int.tryParse(t?.toString() ?? '');
      }

      return null;
    } on dio_pkg.DioException catch (e) {
      debugPrint('❌ DioException getRegistrasiCount: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error getRegistrasiCount: $e');
      return null;
    }
  }

  Future<Registrasi> createRegistrasi(Registrasi registrasi) async {
    try {
      final resp = await dio.post(
        '/registrasi',
        data: registrasi.toJson(),
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Create registrasi error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal membuat registrasi');
      }
      final created = Registrasi.fromJson(
        Map<String, dynamic>.from(
          resp.data is Map && (resp.data as Map).containsKey('data')
              ? resp.data['data']
              : resp.data,
        ),
      );
      clearCache();
      return created;
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException create registrasi: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<Registrasi> createRegistrasiFromMap(Map<String, dynamic> data) async {
    try {
      final resp = await dio.post(
        '/registrasi',
        data: data,
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Create registrasi (map) error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal membuat registrasi');
      }
      final created = Registrasi.fromJson(
        Map<String, dynamic>.from(
          resp.data is Map && (resp.data as Map).containsKey('data')
              ? resp.data['data']
              : resp.data,
        ),
      );
      clearCache();
      return created;
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException create registrasi (map): type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<void> updateRegistrasi(Registrasi registrasi) async {
    try {
      final id = registrasi.id;
      final resp = await dio.put(
        '/registrasi/$id',
        data: registrasi.toJson(),
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Update registrasi error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal mengupdate registrasi');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException update registrasi: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<Registrasi> updateRegistrasiFromMap(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final resp = await dio.put(
        '/registrasi/$id',
        data: data,
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Update registrasi (map) error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal mengupdate registrasi');
      }
      final updated = Registrasi.fromJson(
        Map<String, dynamic>.from(
          resp.data is Map && (resp.data as Map).containsKey('data')
              ? resp.data['data']
              : resp.data,
        ),
      );
      clearCache();
      return updated;
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException update registrasi (map): type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  /// Attach multiple ICD to a registrasi
  Future<void> attachIcd({
    required int registrasiId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final fullUrl =
          '${dio.options.baseUrl}/registrasi/$registrasiId/attach-icd';
      debugPrint('🔗 [API] POST $fullUrl');
      debugPrint('📤 Body: ${{'items': items}}');
      final resp = await dio.post(
        '/registrasi/$registrasiId/attach-icd',
        data: {'items': items},
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Attach ICD error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal menambahkan ICD');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException attach ICD: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  /// Detach ICD items from registrasi
  Future<void> detachIcd({
    required int registrasiId,
    required List<int> icdIds,
  }) async {
    try {
      final fullUrl =
          '${dio.options.baseUrl}/registrasi/$registrasiId/detach-icd';
      debugPrint('🔗 [API] POST $fullUrl');
      debugPrint('📤 Body: ${{'icd_ids': icdIds}}');
      final resp = await dio.post(
        '/registrasi/$registrasiId/detach-icd',
        data: {'icd_ids': icdIds},
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Detach ICD error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal menghapus ICD');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException detach ICD: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  /// Sync (replace) all ICD for a registrasi by detaching old and attaching new
  Future<void> syncIcd({
    required int registrasiId,
    required List<int> existingIcdIds,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // First detach all existing ICD
      if (existingIcdIds.isNotEmpty) {
        debugPrint(
          '🗑️ Detaching ${existingIcdIds.length} existing ICD (attempt by master id)...',
        );
        try {
          await detachIcd(registrasiId: registrasiId, icdIds: existingIcdIds);
        } catch (e) {
          debugPrint('⚠️ Detach by master id failed: $e');
          // Try to resolve pivot ids and retry
          debugPrint(
            '🔎 Attempting detach by pivot (registrasi_icd_id) mapping...',
          );
          try {
            final registrasi = await getRegistrasiById(registrasiId);
            final pivotIds = <int>[];
            if (registrasi != null && registrasi.icds != null) {
              for (final e in registrasi.icds!) {
                if (e is Map<String, dynamic>) {
                  final masterId = e['id'] is int
                      ? e['id'] as int
                      : int.tryParse(e['id']?.toString() ?? '') ?? 0;
                  if (existingIcdIds.contains(masterId)) {
                    final pivot = e['pivot'] as Map<String, dynamic>?;
                    if (pivot != null && pivot['id'] != null) {
                      pivotIds.add(
                        pivot['id'] is int
                            ? pivot['id'] as int
                            : int.tryParse(pivot['id']?.toString() ?? '') ?? 0,
                      );
                    }
                  }
                }
              }
            }
            if (pivotIds.isNotEmpty) {
              debugPrint('🗑️ Retrying detach with pivot ids: $pivotIds');
              await dio.post(
                '/registrasi/$registrasiId/detach-icd',
                data: {'icd_ids': pivotIds},
                options: dio_pkg.Options(validateStatus: (_) => true),
              );
            } else {
              debugPrint('⚠️ No pivot ids found to retry detach');
            }
          } catch (e2) {
            debugPrint('❌ Retry detach by pivot failed: $e2');
            rethrow;
          }
        }
      }

      // Then attach new ICD items
      if (items.isNotEmpty) {
        debugPrint('➕ Attaching ${items.length} new ICD...');
        await attachIcd(registrasiId: registrasiId, items: items);
      }

      clearCache();
      debugPrint('✅ ICD sync completed');
    } catch (e) {
      debugPrint('❌ Sync ICD failed: $e');
      rethrow;
    }
  }

  /// Attach multiple tindakan to a registrasi
  Future<void> attachTindakan({
    required int registrasiId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final fullUrl =
          '${dio.options.baseUrl}/registrasi/$registrasiId/attach-tindakan';
      debugPrint('🔗 [API] POST $fullUrl');
      debugPrint('📤 Body: ${{'items': items}}');
      final resp = await dio.post(
        '/registrasi/$registrasiId/attach-tindakan',
        data: {'items': items},
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Attach tindakan error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal menambahkan tindakan');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException attach tindakan: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  /// Detach tindakan items from registrasi
  Future<void> detachTindakan({
    required int registrasiId,
    required List<int> tindakanIds,
  }) async {
    try {
      final fullUrl =
          '${dio.options.baseUrl}/registrasi/$registrasiId/detach-tindakan';
      debugPrint('🔗 [API] POST $fullUrl');
      debugPrint('📤 Body: ${{'tindakan_ids': tindakanIds}}');
      final resp = await dio.post(
        '/registrasi/$registrasiId/detach-tindakan',
        data: {'tindakan_ids': tindakanIds},
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Detach tindakan error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal menghapus tindakan');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException detach tindakan: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  /// Sync (replace) all tindakan for a registrasi by detaching old and attaching new
  Future<void> syncTindakan({
    required int registrasiId,
    required List<int> existingTindakanIds,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // First detach all existing tindakan
      if (existingTindakanIds.isNotEmpty) {
        debugPrint(
          '🗑️ Detaching ${existingTindakanIds.length} existing tindakan...',
        );
        await detachTindakan(
          registrasiId: registrasiId,
          tindakanIds: existingTindakanIds,
        );
      }

      // Then attach new tindakan items
      if (items.isNotEmpty) {
        debugPrint('➕ Attaching ${items.length} new tindakan...');
        await attachTindakan(registrasiId: registrasiId, items: items);
      }

      clearCache();
      debugPrint('✅ Tindakan sync completed');
    } catch (e) {
      debugPrint('❌ Sync tindakan failed: $e');
      rethrow;
    }
  }

  /// Get existing tindakan for a registrasi
  Future<List<Map<String, dynamic>>> getExistingTindakan(
    int registrasiId,
  ) async {
    try {
      debugPrint(
        '📥 [REPO] Calling getRegistrasiById($registrasiId) for Tindakan...',
      );
      final registrasi = await getRegistrasiById(registrasiId);
      debugPrint(
        '📦 [REPO] Registrasi loaded: id=${registrasi?.id}, noReg=${registrasi?.noReg}',
      );
      debugPrint('📦 [REPO] Has tindakans? ${registrasi?.tindakans != null}');

      if (registrasi == null || registrasi.tindakans == null) {
        debugPrint('⚠️ No Tindakan data found');
        return [];
      }

      debugPrint('📋 Raw Tindakan data: ${registrasi.tindakans}');

      final result = registrasi.tindakans!.map((e) {
        if (e is Map<String, dynamic>) {
          // Check if it has pivot data (for many-to-many relations)
          final pivot = e['pivot'] as Map<String, dynamic>?;
          if (pivot != null) {
            // Has pivot: Merge tindakan data with pivot data
            return {
              'tindakan_id': e['id'],
              'kode': e['kode'],
              'nama_tindakan': e['deskripsi'],
              'kategori': e['kategori'] ?? 'Unknown',
              'jumlah': pivot['jumlah'] ?? 1,
              'harga_satuan': pivot['harga_satuan'] ?? e['tarif'],
              'diskon': pivot['diskon'] ?? 0,
              'petugas_nama': pivot['petugas_nama'],
              'keterangan': pivot['keterangan'],
              'kunjungan_ke': pivot['kunjungan_ke'],
              'is_free': pivot['is_free'] ?? false,
              'dokter_id': pivot['dokter_id'],
              'poli_id': pivot['poli_id'],
              'tanggal_layanan': pivot['tanggal_layanan'],
              ...e,
            };
          } else {
            // No pivot: Use tindakan data directly
            return {
              'tindakan_id': e['id'],
              'kode': e['kode'],
              'nama_tindakan': e['deskripsi'],
              'kategori': e['kategori'] ?? 'Unknown',
              'jumlah': e['jumlah'] ?? 1,
              'harga_satuan': e['harga_satuan'] ?? e['tarif'],
              'diskon': e['diskon'] ?? 0,
              'petugas_nama': e['petugas_nama'],
              'keterangan': e['keterangan'],
              ...e,
            };
          }
        }
        return <String, dynamic>{};
      }).toList();

      debugPrint('✅ Processed Tindakan data: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error getting existing tindakan: $e');
      return [];
    }
  }

  /// Get existing ICD for a registrasi
  Future<List<Map<String, dynamic>>> getExistingIcd(int registrasiId) async {
    try {
      debugPrint(
        '📥 [REPO] Calling getRegistrasiById($registrasiId) for ICD...',
      );
      final registrasi = await getRegistrasiById(registrasiId);
      debugPrint(
        '📦 [REPO] Registrasi loaded: id=${registrasi?.id}, noReg=${registrasi?.noReg}',
      );
      debugPrint('📦 [REPO] Has icds? ${registrasi?.icds != null}');

      if (registrasi == null || registrasi.icds == null) {
        debugPrint('⚠️ No ICD data found');
        return [];
      }

      debugPrint('📋 Raw ICD data: ${registrasi.icds}');

      final result = registrasi.icds!.map((e) {
        if (e is Map<String, dynamic>) {
          // Check if it has pivot data (for many-to-many relations)
          final pivot = e['pivot'] as Map<String, dynamic>?;
          if (pivot != null) {
            // Has pivot: Merge ICD data with pivot data
            return {
              'icd_id': e['id'],
              'kode': e['kode'],
              'deskripsi': e['deskripsi'],
              'is_primary': pivot['is_primary'] ?? false,
              'kasus': pivot['kasus'] ?? 'Sekunder',
              // include pivot id so client can reference the specific registrasi_icd record
              'registrasi_icd_id': pivot['id'],
              ...e,
            };
          } else {
            // No pivot: Use ICD data directly (assume it's already attached)
            return {
              'icd_id': e['id'],
              'kode': e['kode'],
              'deskripsi': e['deskripsi'],
              'is_primary': e['is_primary'] ?? false,
              'kasus': e['kasus'] ?? 'Sekunder',
              'registrasi_icd_id': e['registrasi_icd_id'] ?? null,
              ...e,
            };
          }
        }
        return <String, dynamic>{};
      }).toList();

      debugPrint('✅ Processed ICD data: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error getting existing ICD: $e');
      return [];
    }
  }

  /// Reset helpers
  Future<void> deleteAnamnesaByRegistrasiId(int registrasiId) async {
    try {
      final resp = await dio.delete(
        '/anamnesa',
        queryParameters: {'registrasi_id': registrasiId},
        options: dio_pkg.Options(validateStatus: (_) => true),
      );
      if ((resp.statusCode ?? 500) >= 400) {
        debugPrint(
          '❌ Reset anamnesa error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal reset anamnesa');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException reset anamnesa: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<void> detachAllTindakan(int registrasiId) async {
    try {
      final resp = await dio.post(
        '/registrasi/$registrasiId/detach-tindakan',
        options: dio_pkg.Options(validateStatus: (_) => true),
      );
      if ((resp.statusCode ?? 500) >= 400) {
        debugPrint(
          '❌ Detach tindakan error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal reset tindakan');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException detach tindakan: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  Future<void> detachAllIcd(int registrasiId) async {
    try {
      final resp = await dio.post(
        '/registrasi/$registrasiId/detach-icd',
        options: dio_pkg.Options(validateStatus: (_) => true),
      );
      if ((resp.statusCode ?? 500) >= 400) {
        debugPrint(
          '❌ Detach ICD error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal reset ICD');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException detach ICD: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  /// Get raw registrasi map by id to inspect related entities
  Future<Map<String, dynamic>?> getRegistrasiRawById(int id) async {
    try {
      final resp = await dio.get(
        '/registrasi/$id',
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Get raw registrasi error: status=${resp.statusCode}, data=${resp.data}',
        );
        return null;
      }
      final data = resp.data is Map && (resp.data as Map).containsKey('data')
          ? resp.data['data']
          : resp.data;
      return Map<String, dynamic>.from(data as Map);
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException get raw registrasi: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      return null;
    }
  }

  Future<void> deleteRegistrasi(int id) async {
    try {
      final resp = await dio.delete(
        '/registrasi/$id',
        options: dio_pkg.Options(
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      if (resp.statusCode != null && resp.statusCode! >= 400) {
        debugPrint(
          '❌ Delete registrasi error: status=${resp.statusCode}, data=${resp.data}',
        );
        throw Exception('Gagal menghapus registrasi');
      }
      clearCache();
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '❌ DioException delete registrasi: type=${e.type}, message=${e.message}, response=${e.response?.data}',
      );
      rethrow;
    }
  }

  void clearCache() {
    _cached = null;
  }
}
