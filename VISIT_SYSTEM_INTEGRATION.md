# Visit System Integration

## Overview

Sistem kunjungan yang terintegrasi menggunakan file-file yang sudah Anda buat sebelumnya dari folder `schedules` dan menggabungkannya ke dalam flow kunjungan yang terstruktur.

## File Structure

### Files You Created (DIGUNAKAN ✅)

1. **schedule_anamnesis_page.dart** - Form pengkajian keperawatan, medis, dan khusus perawat (3 stepper)
2. **schedule_icd_pages.dart** - Form pemilihan ICD/diagnosis dengan primary selection
3. **schedule_tindakan_page.dart** - Form pemilihan tindakan medis dengan harga dan diskon

### Integration File

- **visit_flow_page.dart** - Coordinator yang menggabungkan 3 halaman di atas dalam PageView

## How It Works

### User Flow

```
Schedule List Page
    ↓
Schedule Detail Page
    ↓ [Klik "Mulai Kunjungan (3 Langkah)"]
Visit Flow Page (PageView Controller)
    ↓
Step 1: ScheduleAssessmentPage (Anamnesa)
    ↓ [onCompleted callback]
Step 2: ScheduleIcdPage (Diagnosa/ICD)
    ↓ [onCompleted callback]
Step 3: ScheduleTindakanPage (Tindakan)
    ↓ [onCompleted callback]
Auto-generate Tagihan → Report List
```

### Progress Tracking

- **Step 0 → 1**: Selesai mengisi Anamnesa
- **Step 1 → 2**: Selesai memilih ICD
- **Step 2 → 3**: Selesai memilih Tindakan (complete)
- **Step 3**: Trigger auto-generate tagihan

## Modified Files

### 1. schedule_anamnesis_page.dart

**Changes:**

- Added `onCompleted` callback parameter
- Modified `_saveForm()` to call callback instead of Navigator.pop when in flow

### 2. schedule_icd_pages.dart

**Changes:**

- Added `onCompleted` callback parameter
- Modified `_saveIcds()` to call callback instead of Navigator.pop when in flow

### 3. schedule_tindakan_page.dart

**Changes:**

- Added `onCompleted` callback parameter
- Modified `_saveTindakan()` to call callback instead of Navigator.pop when in flow

### 4. schedule_page.dart

**Changes:**

- Added "Mulai Kunjungan (3 Langkah)" button
- Button navigates to VisitFlowPage with patient data
- Removed individual form access cards (now integrated)

### 5. visit_flow_page.dart

**Changes:**

- Imports existing schedule pages instead of creating new ones
- Passes callbacks to each page for flow control
- Maintains progress tracking (\_step1Completed, \_step2Completed, \_step3Completed)

## Benefits

✅ **No Duplicate Code**: Menggunakan file yang sudah Anda buat
✅ **Consistent UI**: Semua halaman menggunakan design system yang sama
✅ **Flexible**: Bisa digunakan standalone atau dalam flow
✅ **Progress Tracking**: Visual indicator menunjukkan step mana yang sudah selesai
✅ **Validation**: User tidak bisa skip step (harus berurutan)

## Next Steps (TODO)

1. **Database Integration**
   - Simpan data anamnesa ke AnamnesaLocalDataSource
   - Simpan ICD ke DiagnosaLocalDataSource
   - Simpan tindakan ke TindakanLocalDataSource
2. **Auto-generate Tagihan**
   - Call VisitFlowCoordinator.completeVisitAndGenerateTagihan()
   - Generate invoice number otomatis
   - Update registrasi status to 'selesai'
3. **Report Integration**
   - Update report_list_page.dart untuk load dari TagihanLocalDataSource
   - Display actual billing data instead of mock

## File Paths

```
lib/
├── features/
│   ├── schedules/
│   │   └── presentation/
│   │       └── pages/
│   │           ├── schedule_anamnesis_page.dart ✅ (DIGUNAKAN)
│   │           ├── schedule_icd_pages.dart ✅ (DIGUNAKAN)
│   │           ├── schedule_tindakan_page.dart ✅ (DIGUNAKAN)
│   │           ├── schedule_page.dart (Modified)
│   │           ├── schedule_list_page.dart
│   │           └── ...
│   └── visits/
│       ├── data/
│       │   └── datasources/ (6 files - ready)
│       ├── domain/
│       │   └── models/ (5 files - ready)
│       └── presentation/
│           └── pages/
│               └── visit_flow_page.dart (Coordinator)
└── shared/
    └── local_db/
        └── app_database.dart (Schema v4)
```

## Summary

Semua file yang Anda buat **TIDAK SIA-SIA** dan **DIGUNAKAN SEPENUHNYA** dalam sistem kunjungan yang terintegrasi! 🎉
