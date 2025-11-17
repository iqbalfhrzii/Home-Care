import 'package:flutter/material.dart';
// Menggunakan halaman yang sudah dibuat user di folder schedules
import 'package:homecare_mobile/features/schedules/presentation/pages/schedule_anamnesis_page.dart';
import 'package:homecare_mobile/features/schedules/presentation/pages/schedule_icd_pages.dart';
import 'package:homecare_mobile/features/schedules/presentation/pages/schedule_tindakan_page.dart';

const Color kPrimaryColor = Color(0xFF004B8C);
const Color kPrimaryLight = Color(0xFF0063B2);
const Color kSecondaryColor = Color(0xFF8BC43E);
const Color kScaffoldBg = Color(0xFFF5F7FA);
const Color kWhite = Colors.white;
const Color kTextDark = Color(0xFF1E293B);
const Color kTextGrey = Color(0xFF94A3B8);
const Color kSuccessColor = Color(0xFF22C55E);

class VisitFlowPage extends StatefulWidget {
  final int registrasiId;
  final String patientName;
  final String noRm;

  const VisitFlowPage({
    super.key,
    required this.registrasiId,
    required this.patientName,
    required this.noRm,
  });

  @override
  State<VisitFlowPage> createState() => _VisitFlowPageState();
}

class _VisitFlowPageState extends State<VisitFlowPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Progress tracking
  bool _step1Completed = false;
  bool _step2Completed = false;
  bool _step3Completed = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepCompleted(int step) {
    setState(() {
      switch (step) {
        case 0:
          _step1Completed = true;
          break;
        case 1:
          _step2Completed = true;
          break;
        case 2:
          _step3Completed = true;
          break;
      }
    });
  }

  void _goToStep(int step) {
    // Validate navigation
    if (step > 0 && !_step1Completed) {
      _showError('Selesaikan Step 1 (Anamnesa) terlebih dahulu');
      return;
    }
    if (step > 1 && !_step2Completed) {
      _showError('Selesaikan Step 2 (Diagnosa) terlebih dahulu');
      return;
    }

    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                // Step 1: Menggunakan ScheduleAssessmentPage yang sudah dibuat user
                ScheduleAssessmentPage(
                  onCompleted: () {
                    _onStepCompleted(0);
                    _goToStep(1);
                  },
                ),
                // Step 2: Menggunakan ScheduleIcdPage yang sudah dibuat user
                ScheduleIcdPage(
                  registrasiId: widget.registrasiId.toString(),
                  onCompleted: () {
                    _onStepCompleted(1);
                    _goToStep(2);
                  },
                ),
                // Step 3: Menggunakan ScheduleTindakanPage yang sudah dibuat user
                ScheduleTindakanPage(
                  registrasiId: widget.registrasiId.toString(),
                  onCompleted: () {
                    _onStepCompleted(2);
                    _completeVisit();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
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
                      'Kunjungan Pasien',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.patientName,
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No. RM: ${widget.noRm}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
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

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Progress: ${_currentStep + 1}/3',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStepIndicator(
                stepNumber: 1,
                title: 'Anamnesa',
                isActive: _currentStep == 0,
                isCompleted: _step1Completed,
                onTap: () => _goToStep(0),
              ),
              _buildStepConnector(_step1Completed),
              _buildStepIndicator(
                stepNumber: 2,
                title: 'Diagnosa',
                isActive: _currentStep == 1,
                isCompleted: _step2Completed,
                onTap: () => _goToStep(1),
              ),
              _buildStepConnector(_step2Completed),
              _buildStepIndicator(
                stepNumber: 3,
                title: 'Tindakan',
                isActive: _currentStep == 2,
                isCompleted: _step3Completed,
                onTap: () => _goToStep(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    Color bgColor;
    Color textColor;
    Widget icon;

    if (isCompleted) {
      bgColor = kSuccessColor;
      textColor = kWhite;
      icon = const Icon(Icons.check, color: kWhite, size: 16);
    } else if (isActive) {
      bgColor = kPrimaryColor;
      textColor = kWhite;
      icon = Text(
        '$stepNumber',
        style: const TextStyle(
          color: kWhite,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    } else {
      bgColor = kScaffoldBg;
      textColor = kTextGrey;
      icon = Text(
        '$stepNumber',
        style: const TextStyle(
          color: kTextGrey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? kPrimaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? kPrimaryColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28),
        decoration: BoxDecoration(
          color: isCompleted ? kSuccessColor : kScaffoldBg,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  void _completeVisit() {
    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: kSuccessColor, size: 32),
            SizedBox(width: 12),
            Text('Kunjungan Selesai'),
          ],
        ),
        content: const Text(
          'Kunjungan telah selesai. Tagihan akan segera dibuat.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to schedule list
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
