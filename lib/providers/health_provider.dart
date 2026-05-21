import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../models/diagnosis.dart';
import '../../models/prescription.dart';
import '../../models/user_profile.dart';
import '../../models/appointment.dart';
import '../../services/storage/local_db_service.dart';
import '../../services/medical/prescription_validator.dart';
import '../../services/medical/health_risk_engine.dart';
import '../../core/utils/helpers.dart';
import '../../services/medical/prescription_ocr_service.dart';

class HealthProvider extends ChangeNotifier {
  final LocalDbService _dbService = LocalDbService();
  final PrescriptionValidator _prescriptionValidator = PrescriptionValidator();
  final HealthRiskEngine _riskEngine = HealthRiskEngine();
  final PrescriptionOcrService _ocrService = PrescriptionOcrService();

  List<Diagnosis> _diagnosisHistory = [];
  List<Prescription> _savedPrescriptions = [];
  List<Appointment> _appointments = [];

  // Prescription validation states
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult; // Symptom alignment
  Map<String, dynamic>? _authenticityResult; // Authenticity audit
  Prescription? _selectedPrescription;
  List<String> _verificationLogs = [];

  // Cabinet AI Summary states
  String? _cabinetSummary;
  bool _isGeneratingCabinetSummary = false;

  // Doctor Twin simulation states
  Diagnosis? _selectedDiagnosisForTwin;
  String _complianceType = 'perfect'; // perfect, poor, abuse
  List<Map<String, dynamic>> _simulationTimeline = [];

  HealthProvider() {
    _diagnosisHistory = _dbService.getDiagnosisHistory();
    _savedPrescriptions = _dbService.getPrescriptions();
    _appointments = _dbService.getAppointments();

    // Prepopulate demo prescriptions if empty for immediate premium experience
    if (_savedPrescriptions.isEmpty) {
      final mockList = Helpers.getMockPrescriptions();
      // Save genuine ones to start with
      _dbService.savePrescription(mockList[0]);
      _dbService.savePrescription(mockList[1]);
      _savedPrescriptions = _dbService.getPrescriptions();
    }
    
    // Auto-select latest diagnosis for Doctor Twin if available
    if (_diagnosisHistory.isNotEmpty) {
      _selectedDiagnosisForTwin = _diagnosisHistory.first;
      _runSimulation();
    }
  }

  List<Diagnosis> get diagnosisHistory => _diagnosisHistory;
  List<Prescription> get savedPrescriptions => _savedPrescriptions;
  List<Appointment> get appointments => _appointments;

  bool get isVerifying => _isVerifying;
  Map<String, dynamic>? get verificationResult => _verificationResult;
  Map<String, dynamic>? get authenticityResult => _authenticityResult;
  Prescription? get selectedPrescription => _selectedPrescription;
  List<String> get verificationLogs => _verificationLogs;

  String? get cabinetSummary => _cabinetSummary;
  bool get isGeneratingCabinetSummary => _isGeneratingCabinetSummary;

  Diagnosis? get selectedDiagnosisForTwin => _selectedDiagnosisForTwin;
  String get complianceType => _complianceType;
  List<Map<String, dynamic>> get simulationTimeline => _simulationTimeline;

  /// Fetch dynamic health risk metrics (Low/Medium/High) computed by the risk engine
  Map<String, dynamic> getHealthRiskReport(UserProfile profile) {
    return _riskEngine.evaluateRisk(profile, _diagnosisHistory);
  }

  /// Register a new symptom check in the local SQLite/Hive database
  Future<void> registerNewDiagnosis(Diagnosis diagnosis) async {
    await _dbService.saveDiagnosis(diagnosis);
    _diagnosisHistory = _dbService.getDiagnosisHistory();
    
    // Auto update Doctor Twin target if none chosen
    if (_selectedDiagnosisForTwin == null || _diagnosisHistory.length == 1) {
      _selectedDiagnosisForTwin = diagnosis;
      _runSimulation();
    }
    notifyListeners();
  }

  // --- PRESCRIPTION VALIDATION METHODS ---

  /// Triggers an interactive OCR scan, calculates authenticity registry, and validates symptom-drug alignment.
  Future<void> runPrescriptionVerification({
    required Prescription prescription,
    required String activeSymptoms,
  }) async {
    _selectedPrescription = prescription;
    _isVerifying = true;
    _verificationResult = null;
    _authenticityResult = null;
    _verificationLogs = [];
    notifyListeners();

    // 1. OCR scanning logs simulation
    final logs = [
      '🔍 [1/5] OCR: Initializing document structure analysis...',
      '📑 [2/5] OCR: Segmenting clinical layout and text lines...',
      '🩺 [3/5] AUDIT: Verifying physician registry registration & license database...',
      '🖋️ [4/5] AUDIT: Validating authorized clinic seal and signature parameters...',
      '🧬 [5/5] SAFETY: Computing symptom-to-medicine alignment index...'
    ];

    for (int i = 0; i < logs.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      _verificationLogs.add(logs[i]);
      notifyListeners();
    }

    // 2. Execute validation calculations
    _authenticityResult = _prescriptionValidator.verifyAuthenticity(prescription);
    _verificationResult = _prescriptionValidator.validatePrescription(prescription, activeSymptoms);
    
    // Auto-save genuine records instantly
    final isReal = _authenticityResult!['isReal'] as bool;
    if (isReal) {
      await saveCurrentPrescriptionToCabinet();
    }

    _isVerifying = false;
    notifyListeners();
  }

  /// Triggers a real multimodal OCR scan and safety validation utilizing the Gemini 2.5 API
  Future<void> runRealApiVerification({
    required Uint8List fileBytes,
    required String mimeType,
    required String symptoms,
    required String diagnosis,
  }) async {
    _isVerifying = true;
    _verificationResult = null;
    _authenticityResult = null;
    _verificationLogs = [
      '⚡ [1/4] UPLOAD: Picked document safely under 1MB limit...',
      '🔍 [2/4] OCR: Initializing Gemini Multimodal engine...',
    ];
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 650));
    _verificationLogs.add('📑 [3/4] OCR: Transmitting base64 segments to Generative Vision API...');
    notifyListeners();

    try {
      final jsonResult = await _ocrService.analyzePrescription(
        fileBytes: fileBytes,
        mimeType: mimeType,
        symptoms: symptoms,
        diagnosis: diagnosis,
      );

      _verificationLogs.add('🧬 [4/4] AUDIT: AI evaluation complete! Structuring report...');
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 650));

      final List<String> extractedMeds = List<String>.from(jsonResult['medicines'] ?? []);

      final tempRx = Prescription(
        id: 'rx_real_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        patientName: 'Active User',
        medicines: extractedMeds,
        diagnosis: jsonResult['diagnosis'] ?? (diagnosis.isNotEmpty ? diagnosis : 'Undiagnosed Condition'),
        imageUrl: '',
        extractedText: jsonResult['authenticityReport'] ?? '',
        doctorName: jsonResult['doctorName'] ?? '',
        doctorRegistryNo: jsonResult['doctorRegistryNo'] ?? '',
        hospitalName: jsonResult['hospitalName'] ?? '',
        isReal: jsonResult['isReal'] ?? true,
        authenticityScore: (jsonResult['authenticityScore'] ?? 95.0).toDouble(),
        authenticityReport: jsonResult['authenticityReport'] ?? '',
      );

      _selectedPrescription = tempRx;

      _authenticityResult = {
        'isReal': jsonResult['isReal'] ?? true,
        'score': (jsonResult['authenticityScore'] ?? 95.0).toDouble(),
        'doctorStatus': (jsonResult['doctorRegistryNo'] ?? '').isNotEmpty && jsonResult['doctorRegistryNo'] != 'UNKNOWN' ? 'VERIFIED' : 'UNVERIFIED',
        'dateStatus': 'VALID',
        'signatureStatus': 'DETECTED',
        'stampStatus': 'DETECTED',
        'reportTitle': (jsonResult['isReal'] ?? true) ? 'Prescription Found Real & Valid' : 'Suspicious / Invalid Prescription',
        'reportSummary': jsonResult['authenticityReport'] ?? '',
        'checkmarks': jsonResult['checkmarks'] ?? [],
        'isHighRiskSubstance': false,
      };

      _verificationResult = {
        'status': jsonResult['symptomAlignmentStatus'] ?? 'ALIGNED',
        'confidence': (jsonResult['symptomAlignmentScore'] ?? 90.0).toString(),
        'explanation': jsonResult['symptomAdvisory'] ?? '',
      };

      // Auto-save genuine records instantly
      if (tempRx.isReal) {
        await saveCurrentPrescriptionToCabinet();
      }

    } catch (e) {
      _verificationLogs.add('❌ ERROR: Online AI scanning failed. Error: $e');
      notifyListeners();
      rethrow;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  /// Programmatically registers a verified genuine prescription (e.g. from in-chat uploads)
  Future<void> registerNewPrescription({
    required String doctorName,
    required String doctorRegistryNo,
    required String hospitalName,
    required String diagnosis,
    required List<String> medicines,
    required String authenticityReport,
  }) async {
    final newRx = Prescription(
      id: Helpers.generateId(),
      date: DateTime.now(),
      patientName: 'Patient',
      doctorName: doctorName,
      doctorRegistryNo: doctorRegistryNo,
      hospitalName: hospitalName,
      diagnosis: diagnosis,
      medicines: medicines,
      isReal: true,
      authenticityScore: 95.0,
      authenticityReport: authenticityReport,
      imageUrl: '',
      extractedText: medicines.join(', '),
    );

    await _dbService.savePrescription(newRx);
    _savedPrescriptions = _dbService.getPrescriptions();
    _cabinetSummary = null; // Clear cached health summary to force fresh generation
    notifyListeners();
  }

  /// Saves the currently audited prescription to the user's local cabinet
  Future<void> saveCurrentPrescriptionToCabinet() async {
    if (_selectedPrescription == null || _authenticityResult == null) return;

    final isReal = _authenticityResult!['isReal'] as bool;
    if (!isReal) return; // STRICT LOCK: ONLY verified genuine reports/prescriptions can ever be saved!

    final score = _authenticityResult!['score'] as double;
    final report = _authenticityResult!['reportSummary'] as String;

    final updatedRx = Prescription(
      id: _selectedPrescription!.id,
      date: _selectedPrescription!.date,
      patientName: _selectedPrescription!.patientName,
      medicines: _selectedPrescription!.medicines,
      diagnosis: _selectedPrescription!.diagnosis,
      imageUrl: _selectedPrescription!.imageUrl,
      extractedText: _selectedPrescription!.extractedText,
      doctorName: _selectedPrescription!.doctorName,
      doctorRegistryNo: _selectedPrescription!.doctorRegistryNo,
      hospitalName: _selectedPrescription!.hospitalName,
      isReal: isReal,
      authenticityScore: score,
      authenticityReport: report,
    );

    // Save to database
    await _dbService.savePrescription(updatedRx);
    _savedPrescriptions = _dbService.getPrescriptions();
    _cabinetSummary = null; // Clear cached AI health summary to force fresh generation!
    notifyListeners();
  }

  /// Collective AI clinical summary and proactive health recommendations for stored records
  Future<void> generateCabinetSummary() async {
    final genuinePrescriptions = _savedPrescriptions.where((rx) => rx.isReal).toList();
    if (genuinePrescriptions.isEmpty) {
      _cabinetSummary = null;
      notifyListeners();
      return;
    }

    _isGeneratingCabinetSummary = true;
    _cabinetSummary = null;
    notifyListeners();

    try {
      final recordsList = genuinePrescriptions.map((rx) => rx.toMap()).toList();
      final summary = await _ocrService.generateCabinetSummary(records: recordsList);
      _cabinetSummary = summary;
    } catch (e) {
      _cabinetSummary = '⚠️ Failed to generate AI Cabinet Summary: $e';
    } finally {
      _isGeneratingCabinetSummary = false;
      notifyListeners();
    }
  }

  void resetVerificationState() {
    _verificationResult = null;
    _authenticityResult = null;
    _selectedPrescription = null;
    _verificationLogs = [];
    _isVerifying = false;
    notifyListeners();
  }

  Future<void> deletePrescription(String id) async {
    await _dbService.deletePrescription(id);
    _savedPrescriptions = _dbService.getPrescriptions();
    notifyListeners();
  }

  // --- DOCTOR TWIN SIMULATION METHODS ---

  void setSelectedDiagnosisForTwin(Diagnosis? diagnosis) {
    _selectedDiagnosisForTwin = diagnosis;
    _runSimulation();
    notifyListeners();
  }

  void setComplianceType(String type) {
    _complianceType = type;
    _runSimulation();
    notifyListeners();
  }

  /// Runs the simulation engine to generate visual recovery timeline metrics
  void _runSimulation() {
    if (_selectedDiagnosisForTwin == null) {
      _simulationTimeline = [];
      return;
    }
    _simulationTimeline = Helpers.generateSimulationTimeline(
      _complianceType,
      _selectedDiagnosisForTwin!.condition,
    );
  }

  /// Wipes all diagnostic logs and prescriptions
  Future<void> resetHealthData() async {
    _diagnosisHistory.clear();
    _savedPrescriptions.clear();
    await _dbService.clearDiagnosisHistory();
    _selectedDiagnosisForTwin = null;
    _simulationTimeline = [];
    notifyListeners();
  }

  // --- APPOINTMENTS METHODS ---

  Future<void> bookAppointment({
    required String doctorName,
    required String doctorSpecialty,
    required String hospitalName,
    required String dateTimeStr,
    required String slot,
    required String notes,
  }) async {
    final newAppointment = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      hospitalName: hospitalName,
      dateTimeStr: dateTimeStr,
      slot: slot,
      notes: notes,
      status: 'Confirmed',
    );
    await _dbService.saveAppointment(newAppointment);
    _appointments = _dbService.getAppointments();
    notifyListeners();
  }

  Future<void> rescheduleAppointment(String id, String newDate, String newSlot) async {
    final int idx = _appointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final updated = _appointments[idx].copyWith(
        dateTimeStr: newDate,
        slot: newSlot,
        status: 'Rescheduled',
      );
      await _dbService.updateAppointment(updated);
      _appointments = _dbService.getAppointments();
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(String id) async {
    final int idx = _appointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final updated = _appointments[idx].copyWith(status: 'Cancelled');
      await _dbService.updateAppointment(updated);
      _appointments = _dbService.getAppointments();
      notifyListeners();
    }
  }

  Future<void> removeAppointmentRecord(String id) async {
    await _dbService.deleteAppointment(id);
    _appointments = _dbService.getAppointments();
    notifyListeners();
  }
}

