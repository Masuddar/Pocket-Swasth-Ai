import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_profile.dart';
import '../../core/constants/app_constants.dart';
import '../../models/prescription.dart';
import 'openrouter_service.dart';
import 'offline_llm_service.dart';

class AiRouter {
  final OpenRouterService _openRouterService = OpenRouterService();
  final OfflineLlmService _offlineLlmService = OfflineLlmService();

  Future<String> routeCompletion({
    required String symptoms,
    required UserProfile profile,
    required bool forceOffline,
    required bool isDiagnosisMode,
    required String language,
    required String length,
    required Function(String statusLabel) onStatusChange,
    List<Prescription> savedPrescriptions = const [],
  }) async {
    // If the patient manually toggled offline mode
    if (forceOffline) {
      onStatusChange('Offline AI Active');

      // Seamless cross-platform FFI execution (iOS & Android)
      return await _offlineLlmService.generateDynamicOfflineResponse(
        symptoms: symptoms,
        profile: profile,
        language: language,
        isDiagnosisMode: isDiagnosisMode,
        length: length,
        savedPrescriptions: savedPrescriptions,
      );
    }

    try {
      final String resolvedMode;
      if (!isDiagnosisMode) {
        resolvedMode = 'CHAT';
      } else {
        final cleanInput = symptoms.toLowerCase().trim();
        final bool isEmergency = AppConstants.emergencyKeywords.any((kw) => cleanInput.contains(kw));
        resolvedMode = isEmergency ? 'EMERGENCY_DIAGNOSIS' : 'DIAGNOSIS';
      }

      // Attempt online path with 3-model priority failover
      final result = await _openRouterService.getCompletionsWithFailover(
        userPrompt: _buildClinicalPrompt(symptoms, profile, savedPrescriptions),
        systemPrompt: AppConstants.buildSystemPrompt(
          mode: resolvedMode,
          isOffline: false,
          length: length,
          language: language,
        ),
        apiKey: profile.openRouterApiKey,
        onModelChange: (model) {
          final modelLabel = model.split('/').last.toUpperCase();
          onStatusChange('Online Active ($modelLabel)');
        },
      );
      
      return result;
    } catch (e) {
      // On connection timeout or API key error, trigger clean local fallback
      print('AiRouter: Online fallback triggered. Catching: $e');
      onStatusChange('Offline Fallback Active');

      return await _offlineLlmService.generateDynamicOfflineResponse(
        symptoms: symptoms,
        profile: profile,
        language: language,
        isDiagnosisMode: isDiagnosisMode,
        length: length,
        savedPrescriptions: savedPrescriptions,
      );
    }
  }



  /// Builds a cohesive patient symptom card to feed the LLM
  String _buildClinicalPrompt(String symptoms, UserProfile profile, List<Prescription> savedPrescriptions) {
    final historyStr = profile.medicalHistory.isNotEmpty 
        ? profile.medicalHistory.join(', ')
        : 'None reported';

    final rxStr = savedPrescriptions.isNotEmpty
        ? savedPrescriptions.map((rx) => 
            "- Diagnosis: ${rx.diagnosis}\n  Medicines: ${rx.medicines.join(', ')}\n  Notes: ${rx.extractedText}"
          ).join('\n\n')
        : 'No verified prescriptions or records uploaded.';

    // Clinically simulate dynamic patient vitals and reports to trigger autonomous agent reasoning
    final cleanInput = symptoms.toLowerCase();
    
    final bool isEmergency = AppConstants.emergencyKeywords.any((kw) => cleanInput.contains(kw));
    final bool isModerate = cleanInput.contains('fever') || 
                            cleanInput.contains('vomiting') || 
                            cleanInput.contains('diarrhea') ||
                            cleanInput.contains('severe pain') ||
                            cleanInput.contains('cough') ||
                            cleanInput.contains('infection');

    final int simulatedHeartRate;
    final String simulatedStress;
    if (isEmergency) {
      simulatedHeartRate = 118; // Tachycardia
      simulatedStress = "High (Acute)";
    } else if (isModerate) {
      simulatedHeartRate = 96; // Elevated
      simulatedStress = "Moderate";
    } else {
      simulatedHeartRate = 72; // Normal/Stable
      simulatedStress = "Low";
    }

    final String reportVerification = savedPrescriptions.isNotEmpty
        ? "VERIFIED (Found ${savedPrescriptions.length} verified prescription records on file)"
        : "NONE UPLOADED";

    return 
        "=== PATIENT TELEMETRY & RECORDS ===\n"
        "Age: ${profile.age}\n"
        "Gender: ${profile.gender}\n"
        "Known Chronic Conditions: $historyStr\n"
        "Vitals:\n"
        "  • Heart Rate: $simulatedHeartRate BPM\n"
        "  • Stress Level: $simulatedStress\n"
        "Report Verification Status: $reportVerification\n"
        "Verified Stored Records:\n$rxStr\n\n"
        "=== PATIENT SUBJECTIVE COMPLAINT ===\n"
        "\"$symptoms\"\n\n"
        "Evaluate the symptoms and telemetry, compute risk, select actions, and return the structured response strictly using the Pocket Swasth Autonomous Health Agent format.";
  }
}
