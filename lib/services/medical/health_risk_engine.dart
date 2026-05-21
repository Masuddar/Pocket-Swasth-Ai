import '../../models/user_profile.dart';
import '../../models/diagnosis.dart';

class HealthRiskEngine {
  /// Evaluate overall health risk based on user profile and recent diagnoses
  Map<String, dynamic> evaluateRisk(UserProfile profile, List<Diagnosis> history) {
    int riskScore = 15; // Baseline healthy score
    List<String> contributingFactors = [];
    List<String> recommendations = [
      'Schedule an annual physical check-up with a general physician.',
      'Maintain a balanced diet rich in vegetables, lean proteins, and whole grains.',
      'Exercise at least 150 minutes a week (e.g. brisk walking, cycling).'
    ];

    // Factor 1: Age-related risk
    if (profile.age > 60) {
      riskScore += 25;
      contributingFactors.add('Advanced age (> 60 years) increases physiological vulnerability to acute conditions.');
      recommendations.add('Consult your cardiologist for regular age-based cardiovascular screenings.');
    } else if (profile.age > 45) {
      riskScore += 10;
      contributingFactors.add('Moderate age factor (45-60 years) requires screening for metabolic and vascular trends.');
    }

    // Factor 2: Chronic conditions in medical history
    bool hasHypertension = false;
    bool hasDiabetes = false;
    bool hasChronicIllness = false;

    for (final condition in profile.medicalHistory) {
      final cleanCond = condition.toLowerCase();
      if (cleanCond.contains('hypertension') || cleanCond.contains('blood pressure') || cleanCond.contains('bp')) {
        hasHypertension = true;
        hasChronicIllness = true;
      }
      if (cleanCond.contains('diabetes') || cleanCond.contains('sugar') || cleanCond.contains('diabetic')) {
        hasDiabetes = true;
        hasChronicIllness = true;
      }
    }

    if (hasChronicIllness) {
      riskScore += 20;
      contributingFactors.add('Pre-existing chronic illness increases risk for acute respiratory or cardiovascular complications.');
      
      if (hasHypertension) {
        recommendations.add('Monitor blood pressure daily; maintain sodium intake below 1500mg/day.');
      }
      if (hasDiabetes) {
        recommendations.add('Monitor fasting blood sugar; limit processed carbohydrates and keep sugar logs.');
      }
    } else {
      contributingFactors.add('No chronic co-morbidities detected. Great baseline status!');
    }

    // Factor 3: Recent Diagnosis History Severity
    if (history.isNotEmpty) {
      // Look at the latest diagnoses
      int emergencyCount = 0;
      int mediumCount = 0;
      
      for (final diag in history.take(5)) {
        if (diag.severity.toLowerCase() == 'emergency') {
          emergencyCount++;
        } else if (diag.severity.toLowerCase() == 'medium') {
          mediumCount++;
        }
      }

      if (emergencyCount > 0) {
        riskScore += 45;
        contributingFactors.add('Recent severe/emergency symptoms recorded (${emergencyCount} events) indicating high acute vulnerability.');
        recommendations.insert(0, 'Urgent: Follow up on recent emergency diagnostics with your specialist immediately.');
      } else if (mediumCount >= 2) {
        riskScore += 25;
        contributingFactors.add('Frequent moderate symptoms (${mediumCount} moderate events) suggest a recurring active inflammatory or metabolic cycle.');
        recommendations.insert(0, 'Schedule a comprehensive diagnostic panel with a physician to address persistent symptoms.');
      } else if (mediumCount == 1) {
        riskScore += 12;
        contributingFactors.add('Single recent moderate symptom check registered in diagnostic logs.');
      }
    }

    // Bind scores into ratings
    riskScore = riskScore.clamp(5, 99);
    String riskLevel;
    if (riskScore >= 70) {
      riskLevel = 'High Risk';
    } else if (riskScore >= 40) {
      riskLevel = 'Medium Risk';
    } else {
      riskLevel = 'Low Risk';
    }

    return {
      'level': riskLevel,
      'score': riskScore,
      'factors': contributingFactors,
      'recommendations': recommendations,
    };
  }
}
