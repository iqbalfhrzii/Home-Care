import 'package:flutter/material.dart';
import 'package:homecare_mobile/core/services/sync_service.dart';
import 'package:homecare_mobile/shared/app_injections.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  late final SyncService _syncService;
  Map<String, dynamic>? _syncStatus;

  @override
  void initState() {
    super.initState();
    _syncService = getIt<SyncService>();
    _loadSyncStatus();

    // Refresh status every 10 seconds
    Future.delayed(const Duration(seconds: 10), _loadSyncStatus);
  }

  Future<void> _loadSyncStatus() async {
    if (!mounted) return;

    final status = await _syncService.getSyncStatus();
    setState(() {
      _syncStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_syncStatus == null) {
      return const SizedBox.shrink();
    }

    final unsyncedCount = _syncStatus!['unsynced_count'] as int;
    final isOnline = _syncStatus!['is_online'] as bool;
    final isSyncing = _syncStatus!['is_syncing'] as bool;

    // Don't show if everything is synced
    if (unsyncedCount == 0 && !isSyncing) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        if (isOnline && !isSyncing) {
          _syncService.syncAll().then((_) => _loadSyncStatus());
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSyncing
              ? Colors.blue.shade50
              : isOnline
              ? Colors.orange.shade50
              : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSyncing
                ? Colors.blue.shade200
                : isOnline
                ? Colors.orange.shade200
                : Colors.red.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSyncing
                  ? Icons.sync
                  : isOnline
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_off_outlined,
              color: isSyncing
                  ? Colors.blue.shade700
                  : isOnline
                  ? Colors.orange.shade700
                  : Colors.red.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSyncing
                        ? 'Sedang sinkronisasi...'
                        : isOnline
                        ? 'Ada $unsyncedCount data belum tersinkronisasi'
                        : 'Offline - $unsyncedCount data menunggu sinkronisasi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSyncing
                          ? Colors.blue.shade900
                          : isOnline
                          ? Colors.orange.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                  if (!isSyncing && isOnline)
                    Text(
                      'Tap untuk sinkronisasi sekarang',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                ],
              ),
            ),
            if (isSyncing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue.shade700,
                ),
              )
            else if (isOnline)
              Icon(Icons.touch_app, size: 16, color: Colors.orange.shade700),
          ],
        ),
      ),
    );
  }
}
