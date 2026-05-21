import 'dart:convert';

class Diagnosis {
  final String id;
  final String symptoms;
  final String condition;
  final String severity; // Low / Medium / Emergency
  final List<String> nextSteps;
  final String doctorType;
  final DateTime timestamp;

  Diagnosis({
    required this.id,
    required this.symptoms,
    required this.condition,
    required this.severity,
    required this.nextSteps,
    required this.doctorType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symptoms': symptoms,
      'condition': condition,
      'severity': severity,
      'nextSteps': nextSteps,
      'doctorType': doctorType,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Diagnosis.fromMap(Map<dynamic, dynamic> map) {
    return Diagnosis(
      id: map['id'] ?? '',
      symptoms: map['symptoms'] ?? '',
      condition: map['condition'] ?? '',
      severity: map['severity'] ?? 'Low',
      nextSteps: List<String>.from(map['nextSteps'] ?? []),
      doctorType: map['doctorType'] ?? 'General Physician',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  String toJson() => json.encode(toMap());

  factory Diagnosis.fromJson(String source) => Diagnosis.fromMap(json.decode(source));
}
