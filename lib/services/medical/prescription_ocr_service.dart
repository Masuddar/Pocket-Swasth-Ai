import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PrescriptionOcrService {
  static const String geminiApiKey = 'AIzaSyCUfpEUt2NDpz6mRqZVqWz-573fRTDBobY';
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Performs a multimodal AI OCR scan and medical validation on picked file bytes.
  /// Supports PDF, PNG, JPG, and JPEG.
  Future<Map<String, dynamic>> analyzePrescription({
    required Uint8List fileBytes,
    required String mimeType,
    required String symptoms,
    required String diagnosis,
  }) async {
    final base64Data = base64Encode(fileBytes);
    
    final prompt = """
You are an expert AI clinical OCR scanner and medical validation engine.
Analyze the provided medical prescription document and extract the critical clinical details.
Additionally, you must evaluate:
1. The structural credentials to check if the prescription is "Real" or "Fake/Suspicious". Audit:
   - Doctor registration registry details (ACTIVE MCI registration or empty/unverifiable).
   - Date recency (within 180 days limit).
   - Authorized handwritten signature presence.
   - Official clinic stamp or watermarks.
2. The alignment of the active medicines against the patient's reported symptoms: "${symptoms.isEmpty ? 'None' : symptoms}" and reported diagnosis: "${diagnosis.isEmpty ? 'None' : diagnosis}". Check if they are a perfect match or a dangerous therapeutic mismatch.

You MUST respond strictly in the following JSON format:
{
  "doctorName": "Doctor name with title",
  "doctorRegistryNo": "MCI license registry ID or UNKNOWN",
  "hospitalName": "Hospital or clinic name",
  "diagnosis": "Prescription diagnosis or active medical condition",
  "medicines": ["Medicine Name 1 with dosage", "Medicine Name 2 with dosage"],
  "isReal": true,
  "authenticityScore": 95.0,
  "authenticityReport": "Detailed textual summary report explaining your registry, stamp, signature and controlled substances findings.",
  "symptomAlignmentScore": 85.0,
  "symptomAlignmentStatus": "PERFECT ALIGNMENT",
  "symptomAdvisory": "Clear medical advisory checking if these medicines are standard treatment protocols for the reported symptoms/diagnosis.",
  "checkmarks": [
    {
      "title": "Doctor Credentials & Registry ID",
      "status": "success",
      "details": "Registry ID MCI-92384 is registered and active in national databases."
    },
    {
      "title": "Prescription Date Recency",
      "status": "success",
      "details": "Prescription is issued recently and within 180-days limit."
    },
    {
      "title": "Physician Handwritten Signature",
      "status": "success",
      "details": "Physician signature stroke validated."
    },
    {
      "title": "Official Clinic Stamp & Seal",
      "status": "success",
      "details": "Clinic authentication seal found."
    }
  ]
}

Ensure the output is valid raw JSON ONLY. Do not wrap the JSON in markdown formatting.
""";

    try {
      final response = await http.post(
        Uri.parse('$geminiApiUrl?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': mimeType,
                    'data': base64Data,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        }),
      ).timeout(const Duration(seconds: 22));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final rawJson = decoded['candidates'][0]['content']['parts'][0]['text'] as String;
        
        // Clean markdown wrapper if any
        String cleanedJson = rawJson.trim();
        if (cleanedJson.startsWith('```')) {
          cleanedJson = cleanedJson.replaceFirst(RegExp(r'^```(json)?'), '');
          cleanedJson = cleanedJson.replaceFirst(RegExp(r'```$'), '');
          cleanedJson = cleanedJson.trim();
        }

        return json.decode(cleanedJson);
      } else {
        throw Exception('Gemini API returned HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('PrescriptionOcrService Exception: $e');
      rethrow;
    }
  }

  /// Synthesizes and summarizes verified patient medical records stored in the Cabinet
  Future<String> generateCabinetSummary({
    required List<Map<String, dynamic>> records,
  }) async {
    final recordsText = records.map((r) {
      return "- Date: ${r['date']}\n"
             "  Diagnosis: ${r['diagnosis']}\n"
             "  Clinician: ${r['doctorName']} (Registry: ${r['doctorRegistryNo']})\n"
             "  Medicines/Details: ${r['medicines']}\n"
             "  AI Authenticity Audit: ${r['authenticityReport']}\n";
    }).join('\n\n');

    final prompt = """
You are a premium, expert AI clinical health synthesis engine for the Pocket Swasth platform.
Your task is to analyze the collective patient medical history (verified genuine prescriptions and lab/medical reports) listed below.
Provide a clear, cohesive medical summary, identify clinical patterns, progress trends or warnings, and provide proactive wellness guidelines and suggestions.

Here is the verified patient medical history:
$recordsText

You MUST structure your response into the following clear Markdown sections:
### 🧬 Collective Clinical Summary
[A synthesized, professional summary of their medical conditions, diagnoses, and what their record history indicates about their overall health profile.]

### 📈 Historical Patterns & Progress Trends
[Highlight any repeating patterns, therapeutic responses, worsening or improving trends, or drug alignment concerns.]

### 🔬 Proactive Wellness Guidelines & Suggestions
[Provide professional, friendly, preventive lifestyle modifications, dietary actions, or follow-up laboratory/diagnostic tests they should consider.]

Ensure your output is beautiful, empathetic, clear, and perfectly formatted in standard Markdown. Keep it structured and action-oriented.
""";

    try {
      final response = await http.post(
        Uri.parse('$geminiApiUrl?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
        }),
      ).timeout(const Duration(seconds: 22));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final rawText = decoded['candidates'][0]['content']['parts'][0]['text'] as String;
        return rawText.trim();
      } else {
        throw Exception('Gemini API returned HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('generateCabinetSummary Exception: $e');
      rethrow;
    }
  }
}
