import 'package:homecare_mobile/shared/local_db/app_database.dart';
import 'package:homecare_mobile/features/visits/data/datasources/registrasi_local_data_source.dart';
import 'package:homecare_mobile/features/visits/data/datasources/anamnesa_local_data_source.dart';
import 'package:homecare_mobile/features/visits/data/datasources/diagnosa_local_data_source.dart';
import 'package:homecare_mobile/features/visits/data/datasources/tindakan_local_data_source.dart';
import 'package:homecare_mobile/features/visits/data/datasources/tagihan_local_data_source.dart';

/// Coordinator untuk mengelola seluruh flow kunjungan
/// dari registrasi hingga tagihan
class VisitFlowCoordinator {
  final RegistrasiLocalDataSource registrasiDS;
  final AnamnesaLocalDataSource anamnesaDS;
  final DiagnosaLocalDataSource diagnosaDS;
  final TindakanLocalDataSource tindakanDS;
  final TagihanLocalDataSource tagihanDS;

  VisitFlowCoordinator({
    required this.registrasiDS,
    required this.anamnesaDS,
    required this.diagnosaDS,
    required this.tindakanDS,
    required this.tagihanDS,
  });

  /// Factory constructor dengan AppDatabase
  factory VisitFlowCoordinator.fromDatabase(AppDatabase database) {
    return VisitFlowCoordinator(
      registrasiDS: RegistrasiLocalDataSource(database),
      anamnesaDS: AnamnesaLocalDataSource(database),
      diagnosaDS: DiagnosaLocalDataSource(database),
      tindakanDS: TindakanLocalDataSource(database),
      tagihanDS: TagihanLocalDataSource(database),
    );
  }

  /// Get complete visit data
  Future<Map<String, dynamic>> getCompleteVisitData(int registrasiId) async {
    final registrasi = await registrasiDS.getRegistrasiById(registrasiId);
    final anamnesa = await anamnesaDS.getAnamnesaByRegistrasiId(registrasiId);
    final diagnosas = await diagnosaDS.getDiagnosaByRegistrasiId(registrasiId);
    final tindakans = await tindakanDS.getTindakanByRegistrasiId(registrasiId);
    final tagihan = await tagihanDS.getTagihanByRegistrasiId(registrasiId);

    return {
      'registrasi': registrasi,
      'anamnesa': anamnesa,
      'diagnosas': diagnosas,
      'tindakans': tindakans,
      'tagihan': tagihan,
    };
  }

  /// Check if step is completed
  Future<bool> isStepCompleted(int registrasiId, int step) async {
    switch (step) {
      case 1: // Anamnesa
        final anamnesa = await anamnesaDS.getAnamnesaByRegistrasiId(registrasiId);
        return anamnesa != null;
      case 2: // Diagnosa
        final diagnosas = await diagnosaDS.getDiagnosaByRegistrasiId(registrasiId);
        return diagnosas.isNotEmpty;
      case 3: // Tindakan
        final tindakans = await tindakanDS.getTindakanByRegistrasiId(registrasiId);
        return tindakans.isNotEmpty;
      default:
        return false;
    }
  }

  /// Complete current step and move to next
  Future<bool> completeStep(int registrasiId, int currentStep) async {
    final isCompleted = await isStepCompleted(registrasiId, currentStep);
    if (!isCompleted) return false;

    // Update progress step
    await registrasiDS.updateProgressStep(registrasiId, currentStep);

    // If all steps completed, generate tagihan
    if (currentStep == 3) {
      await completeVisitAndGenerateTagihan(registrasiId);
    }

    return true;
  }

  /// Complete entire visit and auto-generate tagihan
  Future<bool> completeVisitAndGenerateTagihan(int registrasiId) async {
    try {
      // 1. Verify all steps completed
      final hasAnamnesa = await isStepCompleted(registrasiId, 1);
      final hasDiagnosa = await isStepCompleted(registrasiId, 2);
      final hasTindakan = await isStepCompleted(registrasiId, 3);

      if (!hasAnamnesa || !hasDiagnosa || !hasTindakan) {
        return false;
      }

      // 2. Get registrasi data
      final registrasi = await registrasiDS.getRegistrasiById(registrasiId);
      if (registrasi == null) return false;

      // 3. Calculate total cost from tindakan
      final totalCost = await tindakanDS.calculateTotalCost(registrasiId);

      // 4. Check if tagihan already exists
      final existingTagihan = await tagihanDS.getTagihanByRegistrasiId(registrasiId);
      if (existingTagihan != null) {
        // Update existing tagihan
        await tagihanDS.updatePaymentStatus(
          tagihanId: existingTagihan.id,
          newDeposit: existingTagihan.deposit,
        );
      } else {
        // Generate new tagihan
        await tagihanDS.generateTagihan(
          registrasiId: registrasiId,
          pasienId: registrasi.pasienId,
          totalBiaya: totalCost,
          catatan: 'Tagihan kunjungan ${registrasi.noKunjungan}',
        );
      }

      // 5. Mark registrasi as completed
      await registrasiDS.completeRegistrasi(registrasiId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get visit progress summary
  Future<Map<String, dynamic>> getVisitProgress(int registrasiId) async {
    final registrasi = await registrasiDS.getRegistrasiById(registrasiId);
    if (registrasi == null) {
      return {
        'exists': false,
        'progress_step': 0,
        'steps_completed': [],
      };
    }

    final step1 = await isStepCompleted(registrasiId, 1);
    final step2 = await isStepCompleted(registrasiId, 2);
    final step3 = await isStepCompleted(registrasiId, 3);

    final stepsCompleted = <int>[];
    if (step1) stepsCompleted.add(1);
    if (step2) stepsCompleted.add(2);
    if (step3) stepsCompleted.add(3);

    return {
      'exists': true,
      'progress_step': registrasi.progressStep,
      'status': registrasi.status,
      'steps_completed': stepsCompleted,
      'total_steps': 3,
      'is_completed': registrasi.status == 'selesai',
      'step_1_anamnesa': step1,
      'step_2_diagnosa': step2,
      'step_3_tindakan': step3,
    };
  }

  /// Delete entire visit data (cascade)
  Future<bool> deleteVisit(int registrasiId) async {
    try {
      // Delete in reverse order (tagihan -> tindakan -> diagnosa -> anamnesa)
      final tagihan = await tagihanDS.getTagihanByRegistrasiId(registrasiId);
      if (tagihan != null) {
        await tagihanDS.deleteTagihan(tagihan.id);
      }

      await tindakanDS.clearTindakan(registrasiId);
      await diagnosaDS.clearDiagnosa(registrasiId);
      
      final anamnesa = await anamnesaDS.getAnamnesaByRegistrasiId(registrasiId);
      if (anamnesa != null) {
        await anamnesaDS.deleteAnamnesa(anamnesa.id);
      }

      // Finally delete registrasi (this would be handled by foreign key cascade in production)
      // For now, just mark as deleted or implement soft delete
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
