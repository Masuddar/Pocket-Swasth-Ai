import '../../core/constants/app_constants.dart';

class DiagnosisEngine {
  /// Disease definitions and symptom keywords for offline matching
  static const List<Map<String, dynamic>> _clinicalKnowledgeBase = [
    {
      'condition': 'Acute Coronary Syndrome (Heart Attack Warning)',
      'severity': 'Emergency',
      'keywords': ['chest pain', 'crushing', 'radiating pain', 'left arm pain', 'jaw tightness', 'heart attack', 'cardiac pressure', 'angina'],
      'reasoning': 'User symptoms match acute coronary warning signs. Crushing pressure in the chest radiating to the arm or jaw is a classic sign of myocardial ischemia.',
      'next_steps': [
        'Call emergency ambulance services immediately.',
        'Chew 325mg of Aspirin if you are not allergic and have it available.',
        'Sit upright, remain calm, and avoid any physical exertion.',
        'Keep the door unlocked so paramedics can easily enter.'
      ],
      'hospital_urgently': true,
      'doctor_type': 'Cardiologist / ER Physician'
    },
    {
      'condition': 'Acute Stroke / Cerebrovascular Incident',
      'severity': 'Emergency',
      'keywords': ['stroke', 'facial droop', 'slurred speech', 'arm weakness', 'numbness face', 'paralysis', 'loss of speech'],
      'reasoning': 'Signs of sudden focal neurological deficits like facial asymmetry or difficulty speaking are highly suggestive of acute ischemic stroke.',
      'next_steps': [
        'Call emergency services immediately. Every minute counts (Time is Brain).',
        'Note the exact time symptoms started for treatment eligibility.',
        'Do not give the patient anything to eat or drink (choking hazard).',
        'Lie down flat, unless there is breathing difficulty, then elevate head slightly.'
      ],
      'hospital_urgently': true,
      'doctor_type': 'Neurologist / ER Physician'
    },
    {
      'condition': 'Anaphylaxis / Severe Systemic Allergic Reaction',
      'severity': 'Emergency',
      'keywords': ['throat swelling', 'allergic shock', 'anaphylaxis', 'severe hives breathing', 'swollen tongue', 'difficulty swallowing'],
      'reasoning': 'Exposure to an allergen followed by rapid onset of breathing issues or swallowing difficulty constitutes a medical emergency.',
      'next_steps': [
        'Administer Epinephrine auto-injector (EpiPen) immediately if available.',
        'Call emergency services right away.',
        'Lie flat with legs elevated to combat low blood pressure, unless breathing is too difficult.'
      ],
      'hospital_urgently': true,
      'doctor_type': 'Allergist / ER Physician'
    },
    {
      'condition': 'Acute Asthma Exacerbation / Bronchospasm',
      'severity': 'Medium',
      'keywords': ['breathing difficulty', 'shortness of breath', 'dyspnea', 'wheezing', 'chest tightness', 'cannot breathe'],
      'reasoning': 'Active wheezing and increased effort of breathing points towards acute airway constriction or asthma flare up.',
      'next_steps': [
        'Use rescue inhaler (Salbutamol/Albuterol) immediately: 2-4 puffs.',
        'Sit upright, loosen tight clothing around your chest.',
        'If breathing does not improve within 10 minutes, seek urgent medical care.',
        'Monitor oxygen levels using a pulse oximeter if available.'
      ],
      'hospital_urgently': false,
      'doctor_type': 'Pulmonologist / General Physician'
    },
    {
      'condition': 'Viral Bronchitis or Mild Pneumonia',
      'severity': 'Medium',
      'keywords': ['deep cough', 'wet cough', 'chest congestion', 'phlegm', 'fever', 'shivering', 'chills'],
      'reasoning': 'A persistent wet cough accompanied by fever and chest congestion suggests an inflammation of the bronchial tubes, which could be viral or bacterial.',
      'next_steps': [
        'Schedule an in-person consultation with a physician for lung auscultation.',
        'Maintain high hydration levels with warm fluids.',
        'Inhale steam twice a day to loosen phlegm.',
        'Monitor temperature and seek ER if breathing becomes shallow or fast.'
      ],
      'hospital_urgently': false,
      'doctor_type': 'Pulmonologist / General Physician'
    },
    {
      'condition': 'Gastroenteritis / Food Poisoning',
      'severity': 'Medium',
      'keywords': ['vomiting', 'diarrhea', 'stomach cramps', 'nausea', 'loose stools', 'food poisoning', 'belly pain'],
      'reasoning': 'Sudden onset of vomiting and watery diarrhea indicates digestive tract inflammation, usually due to bacterial toxins or viral pathogens.',
      'next_steps': [
        'Sip Oral Rehydration Salts (ORS) continuously to avoid severe dehydration.',
        'Follow a bland diet (banana, rice, applesauce, toast) once vomiting stops.',
        'Avoid milk, spicy foods, or caffeine.',
        'Consult a doctor if you develop high fever, bloody stools, or cannot keep fluids down for 24 hours.'
      ],
      'hospital_urgently': false,
      'doctor_type': 'Gastroenterologist'
    },
    {
      'condition': 'Migraine / Tension Headache',
      'severity': 'Low',
      'keywords': ['headache', 'migraine', 'throbbing head', 'one sided head', 'light sensitivity', 'noise sensitive', 'aura'],
      'reasoning': 'A throbbing headache, particularly if unilateral and accompanied by sensory sensitivities, points to a primary migraine episode.',
      'next_steps': [
        'Rest in a dark, quiet, well-ventilated room.',
        'Apply a cool compress to your forehead or temples.',
        'Take prescribed abortive medications or standard pain relievers.',
        'Avoid dietary triggers like chocolate, caffeine, or aged cheese.'
      ],
      'hospital_urgently': false,
      'doctor_type': 'Neurologist'
    },
    {
      'condition': 'Common Cold / Acute Rhinitis',
      'severity': 'Low',
      'keywords': ['cough', 'sore throat', 'runny nose', 'sneezing', 'mild fever', 'blocked nose'],
      'reasoning': 'Typical presentation of mild upper respiratory symptoms without signs of respiratory distress or high-grade systemic involvement.',
      'next_steps': [
        'Get plenty of bed rest.',
        'Take warm salt-water gargles for throat pain.',
        'Use saline nasal drops for congestion.',
        'Take paracetamol or ibuprofen if fever or body ache is bothersome.'
      ],
      'hospital_urgently': false,
      'doctor_type': 'General Physician'
    }
  ];

  /// Analyze symptoms offline using keyword matches and scoring
  Map<String, dynamic> analyzeSymptoms(String symptomText) {
    final cleanInput = symptomText.toLowerCase();
    
    // 1. Strict Emergency Keyword Check Override
    bool isEmergencyKeywordTriggered = false;
    String matchedEmergencyTrigger = '';
    for (final keyword in AppConstants.emergencyKeywords) {
      if (cleanInput.contains(keyword)) {
        isEmergencyKeywordTriggered = true;
        matchedEmergencyTrigger = keyword;
        break;
      }
    }

    // 2. Score Match against Knowledge Base
    Map<String, dynamic>? bestMatch;
    int maxScore = 0;

    for (final condition in _clinicalKnowledgeBase) {
      int score = 0;
      final keywords = condition['keywords'] as List<String>;
      for (final kw in keywords) {
        if (cleanInput.contains(kw)) {
          score++;
        }
      }

      if (score > maxScore) {
        maxScore = score;
        bestMatch = condition;
      }
    }

    // If an emergency is triggered, but no specific match or matching condition isn't emergency,
    // we override to the emergency cardiac/stroke block for maximum clinical safety.
    if (isEmergencyKeywordTriggered) {
      if (bestMatch == null || bestMatch['severity'] != 'Emergency') {
        // Find first emergency condition matching keywords or default to Heart Attack Warning
        for (final condition in _clinicalKnowledgeBase) {
          if (condition['severity'] == 'Emergency') {
            final keywords = condition['keywords'] as List<String>;
            if (keywords.any((k) => cleanInput.contains(k))) {
              return condition;
            }
          }
        }
        // General critical emergency fallback
        return _clinicalKnowledgeBase[0]; // ACS Cardiac warning
      }
    }

    // If a good symptom match is found
    if (bestMatch != null && maxScore > 0) {
      return bestMatch;
    }

    // 3. Fallback for non-specific, low severity symptoms
    return {
      'condition': 'Non-Specific Mild Indisposition',
      'severity': 'Low',
      'reasoning': 'The reported symptoms do not clearly match any major acute conditions. They appear consistent with a minor, self-limiting viral illness or general fatigue.',
      'next_steps': [
        'Rest and monitor your symptoms for 24-48 hours.',
        'Stay well-hydrated with water, clear broths, or herbal teas.',
        'Eat simple, easily digestible meals.',
        'Seek professional consultation if symptoms persist, worsen, or change.'
      ],
      'hospital_urgently': false,
      'doctor_type': 'General Physician'
    };
  }
}
