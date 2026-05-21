import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llamadart/llamadart.dart';
import '../../models/user_profile.dart';
import '../../core/constants/app_constants.dart';
import '../../models/prescription.dart';

class ConditionInfo {
  final String title;
  final String riskLevel; // Low, Medium, High, Critical
  final List<String> keywords;
  final List<String> causes;
  final List<String> actions;
  final String doctorWhen;

  const ConditionInfo({
    required this.title,
    required this.riskLevel,
    required this.keywords,
    required this.causes,
    required this.actions,
    required this.doctorWhen,
  });
}

class OfflineLlmService {
  bool _isModelLoaded = false;
  LlamaService? _service;
  String _activeModelName = '';

  // Pre-loaded Medical Database (Local Matcher)
  static const List<ConditionInfo> _medicalDatabase = [
    ConditionInfo(
      title: "Fever / Pyrexia",
      riskLevel: "Medium",
      keywords: ["fever", "temperature", "bukhar", "hot body", "chills", "sweating"],
      causes: ["Viral infection (influenza)", "Bacterial infection", "Dehydration", "Immunological reaction"],
      actions: [
        "Rest adequately and drink plenty of fluids (water, ORS, coconut water).",
        "Monitor your body temperature using a thermometer every 4 hours.",
        "Take Paracetamol (500mg-650mg) if temperature exceeds 38.5°C (101.3°F)."
      ],
      doctorWhen: "Fever persists for more than 3 consecutive days, rises above 39.5°C (103°F), or is accompanied by a severe stiff neck.",
    ),
    ConditionInfo(
      title: "Common Cold & Cough",
      riskLevel: "Low",
      keywords: ["cold", "cough", "runny nose", "sneezing", "congestion", "throat pain", "khasi"],
      causes: ["Rhinovirus or seasonal flu strain", "Allergies to dust/pollen", "Mild throat irritation"],
      actions: [
        "Perform steam inhalation twice daily to clear nasal passages.",
        "Drink warm water, honey-ginger teas, and avoid chilled foods/drinks.",
        "Use saline nasal drops for congestion relief."
      ],
      doctorWhen: "Symptoms last longer than 10 days, or you develop chest congestion and difficulty breathing.",
    ),
    ConditionInfo(
      title: "Tension Headache / Migraine",
      riskLevel: "Low",
      keywords: ["headache", "head pain", "migraine", "sir dard", "temple pain", "throbbing"],
      causes: ["Stress or anxiety", "Lack of sleep or physical fatigue", "Eyestrain (long screen times)", "Mild dehydration"],
      actions: [
        "Drink 2 large glasses of water immediately to resolve potential dehydration.",
        "Rest in a quiet, completely dark room and apply a cold compress to your forehead.",
        "Consider over-the-counter pain relief (Paracetamol or Ibuprofen) if severe."
      ],
      doctorWhen: "Headache is sudden and extremely severe (a 'thunderclap' headache), or is accompanied by blurry vision, numbness, or dizziness.",
    ),
    ConditionInfo(
      title: "Acute Gastritis / Indigestion",
      riskLevel: "Low",
      keywords: ["stomach pain", "stomach", "acidity", "indigestion", "pet dard", "nausea", "vomiting", "ulti", "cramp"],
      causes: ["Acid reflux or gastritis", "Food poisoning from contaminated food", "Excessive oily or spicy food consumption"],
      actions: [
        "Sip on clear fluids or ORS slowly; avoid heavy or solid foods for 12 hours.",
        "Stick to a bland diet (bananas, white rice, curd, toast) once stomach settles.",
        "Take a mild antacid if you experience a burning sensation in the upper chest."
      ],
      doctorWhen: "Severe acute pain localized in the lower right abdomen, persistent vomiting, or blood in stool/vomit.",
    ),
    ConditionInfo(
      title: "Diarrhea / Gastroenteritis",
      riskLevel: "Medium",
      keywords: ["diarrhea", "loose motion", "dast", "stool", "watery poop", "loose stool"],
      causes: ["Gastrointestinal viral or bacterial infection", "Food poisoning or water contamination", "Mild lactose intolerance"],
      actions: [
        "Drink ORS solution after every loose motion to prevent dangerous dehydration.",
        "Avoid dairy, greasy foods, caffeine, and raw vegetables.",
        "Eat bananas, boiled potatoes, and curd-rice to help bind stools."
      ],
      doctorWhen: "Passing more than 10 watery stools in 24 hours, showing severe dry mouth/dizziness, or blood in stool.",
    ),
    ConditionInfo(
      title: "Blood Pressure Imbalance",
      riskLevel: "Medium",
      keywords: ["bp", "blood pressure", "hypertension", "dizzy bp", "high bp", "low bp"],
      causes: ["Genetic predisposition", "High sodium intake or physical stress", "Chronic anxiety", "Severe dehydration (for low BP)"],
      actions: [
        "Rest quietly in a sitting position for 10 minutes and measure BP again.",
        "Avoid all high-sodium foods, smoking, and caffeine immediately.",
        "Keep yourself hydrated with water if experiencing low BP."
      ],
      doctorWhen: "BP reading exceeds 160/100 mmHg or drops below 90/60 mmHg, especially if accompanied by chest pressure or blurred vision.",
    ),
  ];

  Future<void> _ensureModelLoaded() async {
    if (_isModelLoaded) return;

    final dir = await getApplicationDocumentsDirectory();
    
    // Dynamic Model Scanner: Auto-detects any .gguf file you placed in assets/models/
    String modelName = 'SmolLM2-135M.Q4_K_M.gguf'; // default fallback
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final ggufAssets = manifestMap.keys
          .where((key) => key.endsWith('.gguf') && key.contains('assets/models/'))
          .toList();
      if (ggufAssets.isNotEmpty) {
        // Prioritize Qwen chat model over SmolLM if both are present in assets
        final qwenModel = ggufAssets.firstWhere((k) => k.toLowerCase().contains('qwen'), orElse: () => ggufAssets.first);
        modelName = qwenModel.split('/').last;
        print('OfflineLlmService Dynamic Scanner: Auto-detected GGUF asset prioritized (Name: $modelName)');
      }
    } catch (e) {
      print('OfflineLlmService Scanner: Error parsing assets manifest, using fallback: $e');
    }

    _activeModelName = modelName;
    final modelFile = File('${dir.path}/$modelName');

    if (!await modelFile.exists()) {
      print('OfflineLlmService: Copying model $modelName from assets to documents...');
      try {
        final byteData = await rootBundle.load('assets/models/$modelName');
        final buffer = byteData.buffer;
        await modelFile.writeAsBytes(
            buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        print('OfflineLlmService: Model $modelName copied successfully.');
      } catch (e) {
        print('OfflineLlmService: Failed to copy model $modelName: $e');
        return;
      }
    }

    print('OfflineLlmService: Loading model $modelName via llamadart...');
    try {
      _service = LlamaService();
      await _service!.init(modelFile.path, modelParams: const ModelParams(
        gpuLayers: 0, // Force CPU to prevent tensor memory corruption on simulators/buggy GPUs
        preferredBackend: GpuBackend.cpu,
        contextSize: 2048, // Double the context size for premium multi-turn memory
      ));
      
      _isModelLoaded = true;
      print('OfflineLlmService: LLM ($modelName) successfully loaded.');
    } catch (e) {
      print('OfflineLlmService: Exception loading LLM ($modelName): $e');
    }
  }

  Future<String> generateDynamicOfflineResponse({
    required String symptoms,
    required UserProfile profile,
    required String language,
    required bool isDiagnosisMode,
    required String length,
    List<Prescription> savedPrescriptions = const [],
  }) async {
    final cleanInput = symptoms.toLowerCase().trim();

    // ==========================================
    // NORMAL CHAT COMPANION MODE (Toggled OFF)
    // ==========================================
    if (!isDiagnosisMode) {
      print('OfflineLlmService: Running in Normal Chat Mode (Friendly Companion)...');
      await _ensureModelLoaded();
      if (!_isModelLoaded || _service == null) {
        return "⚠️ **Offline AI is unavailable.** The native LLM could not be loaded into memory. Please switch to online mode.";
      }
      try {
        final bool isChatModel = _activeModelName.toLowerCase().contains('qwen') || 
                                 _activeModelName.toLowerCase().contains('chat') || 
                                 _activeModelName.toLowerCase().contains('instruct');

        final String prompt;
        final List<String> stopSeqs;

        if (isChatModel) {
          // Format using the robust dynamic clinical system prompt for instruct models (Qwen)
          final sysPrompt = AppConstants.buildSystemPrompt(
            mode: 'CHAT',
            isOffline: true,
            length: length,
            language: language,
          );

          final rxBrief = savedPrescriptions.isNotEmpty
              ? savedPrescriptions.map((rx) => "${rx.diagnosis} (Medicines: ${rx.medicines.join(', ')})").join('; ')
              : 'None';

          prompt = 
              "<|im_start|>system\n"
              "$sysPrompt\n"
              "Patient Medical Records Stored on Device: $rxBrief\n"
              "<|im_end|>\n"
              "<|im_start|>user\n"
              "$symptoms\n"
              "<|im_end|>\n"
              "<|im_start|>assistant\n";
          stopSeqs = const ["<|im_end|>", "<|im_start|>", "\n<|im_start|>", "\n<|im_end|>", "Human:", "AI:", "\nHuman:", "\nAI:"];
        } else {
          // Natural Transcript Autocomplete fallback for base models (SmolLM2 Base)
          prompt = 
              "The following is a friendly conversation between a Human and a brilliant AI Assistant.\n"
              "Human: Hello! How was your day?\n"
              "AI: I am doing wonderful, my friend! Thanks for asking. How is your day going?\n"
              "Human: $symptoms\n"
              "AI:";
          stopSeqs = const ["\nHuman:", "\nAI:", "Human:", "AI:"];
        }
        
        print('OfflineLlmService Formatted Chat Prompt:\n$prompt');

        final StringBuffer responseBuffer = StringBuffer();
        final params = GenerationParams(
          maxTokens: 80,
          temp: 0.4, // Increased temperature for vocabulary diversity (prevents loops)
          topP: 0.9,
          penalty: 1.15, // Restored penalty to explicitly prevent repeating phrases
          stopSequences: stopSeqs,
        );
        
        await for (final token in _service!.generate(prompt, params: params)) {
          responseBuffer.write(token);
        }
        
        var output = responseBuffer.toString().trim();
        
        // Manual aggressive stop-sequence trimming for production safety
        if (output.contains('Human:')) {
          output = output.split('Human:').first.trim();
        }
        if (output.contains('AI:')) {
          output = output.split('AI:').first.trim();
        }
        if (output.contains('<|im_end|>')) {
          output = output.split('<|im_end|>').first.trim();
        }
        if (output.contains('<|im_start|>')) {
          output = output.split('<|im_start|>').first.trim();
        }
        print('OfflineLlmService Raw LLM Output: "$output"');
        final bool isRubbish = _checkIsRubbish(output);
            
        if (!isRubbish) {
          return output;
        } else {
          print('OfflineLlmService Layer 5: Rubbish detected in Normal Mode! Loading contextual friendly fallback.');
          return _getFriendlyFallback(symptoms);
        }
      } catch (e) {
        print('OfflineLlmService Error generating normal chat: $e');
        return _getFriendlyFallback(symptoms);
      }
    }

    // ==========================================
    // LAYER 1: 🛑 EMERGENCY RULES (Hard Override)
    // ==========================================
    final bool isEmergency = AppConstants.emergencyKeywords.any((kw) => cleanInput.contains(kw));
    if (isEmergency) {
      print('OfflineLlmService Layer 1: Triggered hard emergency override.');
      return _buildEmergencyResponse(symptoms, language);
    }

    // ==========================================
    // LAYER 2 & 3: 📊 SYMPTOM SCORING & 📚 DB MATCHING
    // ==========================================
    ConditionInfo? matchedCondition;
    int highestScore = 0;

    for (final condition in _medicalDatabase) {
      int score = 0;
      for (final keyword in condition.keywords) {
        if (cleanInput.contains(keyword)) {
          score++;
        }
      }
      if (score > highestScore) {
        highestScore = score;
        matchedCondition = condition;
      }
    }

    // If no matching condition is found in the database, return a generic safe response
    if (matchedCondition == null || highestScore == 0) {
      print('OfflineLlmService Layer 3: No specific condition matched in local DB.');
      final clean = symptoms.toLowerCase().trim();
      final casualWords = {'hi', 'hello', 'hey', 'howdy', 'greetings', 'thanks', 'thank you', 'ok', 'okay', 'yes', 'no', 'cool', 'awesome'};
      if (casualWords.contains(clean) || clean.contains('hello') || clean.contains('hi ') || clean.contains('hey') || clean.length < 3) {
        return "Hello! I am Pocket Swasth, your supportive health companion. How are you feeling today? Please describe any physical symptoms you are experiencing so I can help triage them safely!";
      }
      return _buildGenericSafeResponse(symptoms, language);
    }

    print('OfflineLlmService Layer 3: Matched condition: ${matchedCondition.title} (Score: $highestScore)');

    // ==========================================
    // LAYER 4: 🤖 LOCAL DETERMINISTIC EXPLANATION WITH COMPANION SUMMARIZATION
    // ==========================================
    String llmSummary = "Based on your reported symptoms, this matches '${matchedCondition.title}' in our knowledge database. It is commonly caused by environmental factors, mild systemic infections, or stress.";
    
    // If the model is loaded, we can use the Qwen model to explain the symptoms briefly and warmly!
    if (_isModelLoaded && _service != null) {
      try {
        final cleanInput = symptoms.toLowerCase().trim();
        final bool isEmergency = AppConstants.emergencyKeywords.any((kw) => cleanInput.contains(kw));
        final String resolvedMode = isEmergency ? 'EMERGENCY_DIAGNOSIS' : 'DIAGNOSIS';

        final sysPrompt = AppConstants.buildSystemPrompt(
          mode: resolvedMode,
          isOffline: true,
          length: length,
          language: language,
        );
        final rxBrief = savedPrescriptions.isNotEmpty
            ? savedPrescriptions.map((rx) => "${rx.diagnosis} (Medicines: ${rx.medicines.join(', ')})").join('; ')
            : 'None';

        final prompt = 
            "<|im_start|>system\n"
            "$sysPrompt\n"
            "Patient Medical Records Stored on Device: $rxBrief\n"
            "<|im_end|>\n"
            "<|im_start|>user\n"
            "Explain briefly: ${matchedCondition.title} caused by $symptoms\n"
            "<|im_end|>\n"
            "<|im_start|>assistant\n";
            
        print('OfflineLlmService Formatted Diagnostic Prompt:\n$prompt');
        final StringBuffer summaryBuffer = StringBuffer();
        
        await for (final token in _service!.generate(prompt, params: GenerationParams(
          maxTokens: 100,
          temp: 0.3,
          topP: 0.9,
          penalty: 1.15,
          stopSequences: const ["<|im_end|>", "<|im_start|>", "\n<|im_start|>", "\n<|im_end|>"],
        ))) {
          summaryBuffer.write(token);
        }
        var cleanSum = summaryBuffer.toString().trim();
        if (cleanSum.contains('<|im_end|>')) cleanSum = cleanSum.split('<|im_end|>').first.trim();
        if (cleanSum.contains('<|im_start|>')) cleanSum = cleanSum.split('<|im_start|>').first.trim();
        
        if (!_checkIsRubbish(cleanSum)) {
          llmSummary = cleanSum;
        }
        print('OfflineLlmService Dynamic Diagnostic Summary: "$llmSummary"');
      } catch (e) {
        print('Offline diagnostic explanation fall back: $e');
      }
    }

    // ==========================================
    // LAYER 6: 📱 OUTPUT: RISK LEVEL + ACTIONS (Premium Glassmorphic Card)
    // ==========================================
    return _buildStructuredResponseCard(matchedCondition, llmSummary, language);
  }

  // Multi-Criteria Advanced Rubbish Protection Shield
  static bool _checkIsRubbish(String output) {
    final clean = output.trim();
    if (clean.isEmpty) return true;

    // 1. Length check: Response should be at least 4 characters
    if (clean.length < 4) return true;

    // 2. Unicode Word check: Must contain at least one valid language word (of 2 letters or more)
    // Prevents garbage symbols like '//%(&%1.)75' or repeating marks
    final hasRealWords = RegExp(r'[\p{L}]{2,}', unicode: true).hasMatch(clean);
    if (!hasRealWords) return true;

    // 3. Web/Social Spam indicators
    if (clean.contains('@') ||
        clean.contains('www.') ||
        clean.contains('http') ||
        clean.contains(',,,') ||
        clean.contains('facebook') ||
        clean.contains('<br')) {
      return true;
    }

    // 4. Abnormal Symbol Density check
    // Count letters, numbers, spaces, and normal punctuation
    final normalMatches = RegExp(r'[a-zA-Z0-9\s.,!?;:"()\-\u0900-\u097F]').allMatches(clean).length;
    final abnormalCharRatio = (clean.length - normalMatches) / clean.length;
    if (abnormalCharRatio > 0.25) {
      return true; // Over 25% weird symbols is rubbish
    }

    // 5. English/Local Grammar Connector Filter (Gibberish Shield)
    // Coherent human answers contain standard connecting words (is, the, in, to, for, and, etc.)
    // If output is longer than 15 chars but doesn't have a single connector, it's 100% training data gibberish
    if (clean.length > 15) {
      final hasGrammarConnectors = RegExp(
        r'\b(the|is|are|am|was|were|in|on|at|of|to|for|with|by|from|about|and|but|or|so|you|he|she|it|we|they|me|him|her|us|them|my|your|his|its|our|their|this|that|who|which|what|why|how|where|when|can|will|would|should|has|have|had|do|did|hello|hi|hey|yes|no|ok|okay)\b',
        caseSensitive: false
      ).hasMatch(clean);
      if (!hasGrammarConnectors) {
        return true; // Flag word salad
      }
    }

    return false;
  }

  // Dynamic context-based fallback for normal friendly chat (acts purely as structural backup)
  static String _getFriendlyFallback(String input) {
    final clean = input.toLowerCase().trim();

    // 1. Casual Greetings & Politeness
    if (clean.contains('hello') || clean.contains('hi ') || clean.contains('hey') || clean.contains('bro') || clean.contains('buddy')) {
      return "Hello my friend! I am so glad you reached out. How is your day going? Feel free to share anything with me!";
    }
    if (clean.contains('thank') || clean.contains('thanks') || clean.contains('welcome')) {
      return "You are so welcome, my friend! Always happy to support you. What else is on your mind?";
    }

    // 2. Dynamic Pseudo-Random General Buddy Fallbacks (Covers all other topics: math, coding, life, geography, etc.)
    final fallbacks = [
      "That is a really cool question! As your offline chat buddy, I find that super fascinating. Tell me more about your thoughts on it!",
      "That's a wonderful topic, my friend! I love talking about things like this. What else would you like to share about it?",
      "I'm listening closely, buddy! That sounds really interesting. How are you feeling about that?",
      "That's a great point! As your companion, I'm always here to learn and chat with you. What do you want to talk about next?"
    ];
    return fallbacks[clean.length % fallbacks.length];
  }

  // Helper: Structured Response Card Builder
  String _buildStructuredResponseCard(ConditionInfo condition, String explanation, String language) {
    final causesStr = condition.causes.map((c) => "- $c").join('\n');
    final actionsStr = condition.actions.map((a) => "- $a").join('\n');

    final String conclusion = condition.riskLevel == "Low" 
        ? "🟢 **SAFE (No need to worry)**" 
        : "🟡 **MODERATE (Monitor closely)**";

    return """### 🏥 Supportive Triage: ${condition.title}
Conclusion: $conclusion

**1. 🩺 Doctor's Assessment:**
$explanation

**2. 🔍 Probable Causes:**
$causesStr

**3. 💊 Actionable First-Aid Plan:**
$actionsStr

**4. 🚨 Red Flags (When to see a Doctor):**
${condition.doctorWhen}

---
> ⚠️ *This offline assessment is for supportive triage matching. If symptoms worsen, consult a physical medical practitioner.*""";
  }

  // Helper: Emergency override triage
  String _buildEmergencyResponse(String symptoms, String language) {
    return """### 🏥 Urgent Alert: Critical Risk Detected
Conclusion: 🚨 **EMERGENCY (Need to worry - go to hospital immediately!)**

Your symptoms ("$symptoms") represent a possible life-threatening cardiovascular, neurological, or respiratory emergency. Do not wait for self-assessment. 

**Immediate Actions:**
- Go to the nearest emergency room immediately.
- Call local emergency services (e.g. 102 / 112 / 911).
- Remain calm, sit down, and do not exert yourself.

---
> 🚨 *Do not ignore severe symptoms. Immediate medical attention can save lives.*""";
  }

  // Helper: Generic Safe Response
  String _buildGenericSafeResponse(String symptoms, String language) {
    return """### 🏥 Supportive Triage: Health Assessment
Conclusion: 🟢 **SAFE (No need to worry)**

**1. 🩺 Assessment:**
Your symptoms ("$symptoms") represent a broad set of clinical complaints. Offline database matching requires more specific inputs (e.g. fever, head pain, stomach cramp).

**2. 💊 General Recommendations:**
- Remain well-hydrated and rest adequately.
- Monitor your temperature and symptoms closely for the next 12 hours.
- If symptoms persist or pain increases, see a doctor.

---
> ⚠️ *For personalized clinical matching, please list specific physical symptoms or switch to Online Mode for full AI reasoning.*""";
  }
}
