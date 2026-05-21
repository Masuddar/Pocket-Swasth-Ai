// Pure clinical unit tests for Pocket Swasth medical engines.

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_swasth/services/medical/diagnosis_engine.dart';

void main() {
  group('DiagnosisEngine Clinical Tests', () {
    late DiagnosisEngine engine;

    setUp(() {
      engine = DiagnosisEngine();
    });

    test('Should analyze cardiac emergency symptoms correctly', () {
      final result = engine.analyzeSymptoms('I have crushing chest pain and left arm numbness');
      expect(result['severity'], equals('Emergency'));
      expect(result['hospital_urgently'], isTrue);
      expect(result['condition'], contains('Acute Coronary'));
    });

    test('Should analyze mild flu symptoms correctly', () {
      final result = engine.analyzeSymptoms('Just have a mild running nose and sneezing');
      expect(result['severity'], equals('Low'));
      expect(result['hospital_urgently'], isFalse);
      expect(result['doctor_type'], equals('General Physician'));
    });
  });
}
