import 'dart:math';
import '../../models/prescription.dart';

class Helpers {
  static final Random _random = Random();

  /// Generate a unique ID string
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + _random.nextInt(1000).toString();
  }

  /// Format date nicely
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// List of sample mock prescriptions that the user can "upload"
  static List<Prescription> getMockPrescriptions() {
    return [
      Prescription(
        id: 'rx_001',
        date: DateTime.now().subtract(const Duration(days: 3)),
        patientName: 'John Doe',
        medicines: ['Amoxicillin 500mg (Antibiotic) - 3 times a day', 'Paracetamol 650mg - As needed'],
        diagnosis: 'Bacterial Chest Infection / Bronchitis',
        imageUrl: 'assets/images/prescription_chest.png',
        doctorName: 'Dr. Anjali Sharma, MD',
        doctorRegistryNo: 'MCI-99238',
        hospitalName: 'Apollo Health Clinic',
        isReal: true,
        authenticityScore: 97.0,
        authenticityReport: 'AUTHENTICITY AUDIT: Verified with National Medical Council registry. Clinic stamp signature match confirmed. Issue date is recent.',
        extractedText: 
            "DR. ANJALI SHARMA, MD\n"
            "Apollo Health Clinic, New Delhi\n"
            "Reg No: MCI-99238\n"
            "Date: 15/05/2026\n"
            "Patient: John Doe (Age: 32)\n"
            "Rx:\n"
            "1. Cap. Amoxicillin 500mg ----- 1 Cap t.i.d (x 5 days)\n"
            "2. Tab. Paracetamol 650mg ----- 1 Tab p.r.n (SOS) for fever\n"
            "Diag: Acute Bronchitis / Cough\n"
            "Signature: Dr. A. Sharma\n"
            "Clinic Stamp: Apollo Health Care [VERIFIED]",
      ),
      Prescription(
        id: 'rx_002',
        date: DateTime.now().subtract(const Duration(days: 10)),
        patientName: 'John Doe',
        medicines: ['Amlodipine 5mg (Anti-hypertensive) - Once daily', 'Telmisartan 40mg - Once daily'],
        diagnosis: 'Essential Hypertension (High Blood Pressure)',
        imageUrl: 'assets/images/prescription_bp.png',
        doctorName: 'Dr. Vikram Roy, DM',
        doctorRegistryNo: 'MCI-88392',
        hospitalName: 'Metro Cardio Care Center',
        isReal: true,
        authenticityScore: 94.0,
        authenticityReport: 'AUTHENTICITY AUDIT: Verified with National Medical Council registry. License matches clinical cardiology specialization profile. Clinic signature matched.',
        extractedText: 
            "METRO CARDIO CARE CENTER\n"
            "Dr. Vikram Roy, DM (Cardiology)\n"
            "Reg No: MCI-88392\n"
            "Date: 08/05/2026\n"
            "Patient: John Doe (Age: 32)\n"
            "Rx:\n"
            "1. Tab. Telmisartan 40mg ----- 1 Tab OD (Morning)\n"
            "2. Tab. Amlodipine 5mg ----- 1 Tab OD (Bedtime)\n"
            "Note: Keep low sodium diet. Check BP daily.\n"
            "Diag: Stage II Hypertension\n"
            "Signature: Dr. Vikram Roy\n"
            "Clinic Stamp: Metro Cardio [VERIFIED]",
      ),
      Prescription(
        id: 'rx_003',
        date: DateTime.now().subtract(const Duration(days: 15)),
        patientName: 'John Doe',
        medicines: ['Metformin 500mg (Antidiabetic) - Twice daily', 'Glimepiride 1mg - Once daily'],
        diagnosis: 'Type 2 Diabetes Mellitus',
        imageUrl: 'assets/images/prescription_diabetes.png',
        doctorName: 'Dr. Rajesh Gupta, MD',
        doctorRegistryNo: 'MCI-77483',
        hospitalName: 'Diabetes & Endocrine Care',
        isReal: true,
        authenticityScore: 96.0,
        authenticityReport: 'AUTHENTICITY AUDIT: Verified with National Medical Council registry. License active and in good standing. Clinic signature and digital watermark authenticated.',
        extractedText: 
            "DIABETES & ENDOCRINE CARE\n"
            "Dr. Rajesh Gupta, MD (Endocrinology)\n"
            "Reg No: MCI-77483\n"
            "Date: 02/05/2026\n"
            "Patient: John Doe\n"
            "Rx:\n"
            "1. Tab. Metformin 500mg (Glucophage) ----- 1 Tab b.i.d (After meals)\n"
            "2. Tab. Glimepiride 1mg ----- 1 Tab OD (Before breakfast)\n"
            "Advice: Post-prandial blood sugar monitor twice weekly.\n"
            "Diag: Diabetes Mellitus Type II\n"
            "Signature: Dr. R. Gupta\n"
            "Clinic Stamp: Diabetes & Endocrine [VERIFIED]",
      ),
      Prescription(
        id: 'rx_004',
        date: DateTime.now().subtract(const Duration(days: 1200)),
        patientName: 'John Doe',
        medicines: ['Alprazolam 2mg (Sedative/Anxiolytic) - Twice daily', 'Codeine Linctus Syrup (Narcotic) - 3 times daily'],
        diagnosis: 'Severe Anxiety & Chronic Cough',
        imageUrl: 'assets/images/prescription_suspicious.png',
        doctorName: 'Dr. John M. Smith',
        doctorRegistryNo: 'UNKNOWN-9992',
        hospitalName: 'Quick Rx Online Shop',
        isReal: false,
        authenticityScore: 28.0,
        authenticityReport: 'CRITICAL WARNING: Doctor registration number UNKNOWN-9992 was NOT found in the National Medical Council database. Prescription issue date is expired (>3 years old). Document lacks official clinic seal and verification watermark. Contains restricted high-abuse-potential substances.',
        extractedText: 
            "QUICK RX ONLINE SHOP\n"
            "Dr. John M. Smith (General Practitioner)\n"
            "Reg No: UNKNOWN-9992 [NOT FOUND]\n"
            "Date: 12/10/2021 [ALERT: EXPIRED / ALIGNED ILLEGALLY]\n"
            "Patient: John Doe\n"
            "Rx:\n"
            "1. Tab. Alprazolam 2mg ----- 2 Tabs daily [RESTRICTED SUBSTANCE]\n"
            "2. Syr. Codeine Phosphate ----- 3 tsp daily [RESTRICTED SUBSTANCE]\n"
            "Note: Fast delivery, no physical visit required.\n"
            "Signature: [MISSING / PRINTED LOGO]\n"
            "Clinic Stamp: NONE DETECTED",
      ),
    ];
  }

  /// Dynamic 7-day health outcomes simulation points based on drug adherence
  /// complianceType: 'perfect' (100% adherence), 'poor' (misses days), 'abuse' (double dose/overdose)
  static List<Map<String, dynamic>> generateSimulationTimeline(String complianceType, String diagnosisName) {
    List<Map<String, dynamic>> data = [];
    double baseHealth = 60.0; // Start health percentage
    double baseSideEffects = 10.0; // Start side effects percentage

    for (int day = 1; day <= 7; day++) {
      double healthChange;
      double sideEffectChange;
      
      switch (complianceType) {
        case 'perfect':
          // Standard clinical improvement, low side effects
          healthChange = 4.0 + (day * 1.5) + _random.nextDouble(); // Standard rise
          sideEffectChange = (day > 3) ? -1.0 : 1.0; // peaking early, then settling
          break;
        case 'poor':
          // Slow/flat improvement, high fluctuation, infection might relapse
          healthChange = (day % 3 == 0) ? -3.0 : 1.0; 
          sideEffectChange = 0.5 * day;
          break;
        case 'abuse':
          // Rapid short term effect but skyrocketing side effects and organ stress, resulting in overall health drop
          healthChange = (day < 4) ? 8.0 - (day * 0.5) : -6.0; // quick drop after day 3 due to toxicity
          sideEffectChange = 6.0 * day + _random.nextDouble() * 5.0; // dangerous side effects
          break;
        default:
          healthChange = 1.0;
          sideEffectChange = 0.0;
      }
      
      baseHealth = (baseHealth + healthChange).clamp(10.0, 100.0);
      baseSideEffects = (baseSideEffects + sideEffectChange).clamp(0.0, 100.0);
      
      data.add({
        'day': 'Day $day',
        'health': baseHealth.toStringAsFixed(1),
        'side_effects': baseSideEffects.toStringAsFixed(1),
        'description': _getTimelineDescription(day, complianceType, diagnosisName, baseHealth, baseSideEffects),
      });
    }
    return data;
  }

  static String _getTimelineDescription(int day, String complianceType, String condition, double health, double sideEffects) {
    if (complianceType == 'perfect') {
      if (day == 1) return 'Treatment started. Medication levels stabilizing in system.';
      if (day == 3) return 'Symptoms significantly subside. Recovery is on track.';
      if (day == 7) return 'Treatment successfully completed! Optimal lung and blood health achieved.';
    } else if (complianceType == 'poor') {
      if (day == 1) return 'Treatment delayed or missed doses. Pathogens remain active.';
      if (day == 3) return 'Inconsistent dose. Symptoms flare up again with minor fever.';
      if (day == 7) return 'Incomplete recovery. High risk of developing bacterial resistance or relapse.';
    } else if (complianceType == 'abuse') {
      if (day == 1) return 'High dose in bloodstream. Heart rate elevated, drowsiness reported.';
      if (day == 3) return 'Toxicity warning. Mild kidney/liver strain. Severe nausea.';
      if (day == 7) return 'Critical toxicity! Liver enzymes abnormal. Emergency room consult recommended.';
    }
    return 'Patient health status at ${health.toStringAsFixed(0)}% with ${sideEffects.toStringAsFixed(0)}% drug toxicity.';
  }
}
