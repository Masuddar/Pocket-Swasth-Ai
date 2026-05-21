import 'dart:convert';

class Prescription {
  final String id;
  final DateTime date;
  final String patientName;
  final List<String> medicines;
  final String diagnosis;
  final String imageUrl;
  final String extractedText;
  
  // New authenticity and clinical metadata fields
  final String doctorName;
  final String doctorRegistryNo;
  final String hospitalName;
  final bool isReal;
  final double authenticityScore;
  final String authenticityReport;

  Prescription({
    required this.id,
    required this.date,
    required this.patientName,
    required this.medicines,
    required this.diagnosis,
    required this.imageUrl,
    required this.extractedText,
    this.doctorName = '',
    this.doctorRegistryNo = '',
    this.hospitalName = '',
    this.isReal = true,
    this.authenticityScore = 95.0,
    this.authenticityReport = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'patientName': patientName,
      'medicines': medicines,
      'diagnosis': diagnosis,
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'doctorName': doctorName,
      'doctorRegistryNo': doctorRegistryNo,
      'hospitalName': hospitalName,
      'isReal': isReal ? 1 : 0, // Hive compatibility/safe int conversion or boolean
      'authenticityScore': authenticityScore,
      'authenticityReport': authenticityReport,
    };
  }

  factory Prescription.fromMap(Map<dynamic, dynamic> map) {
    // Safely parse isReal boolean from dynamic value (could be boolean, integer or null)
    bool parsedIsReal = true;
    if (map['isReal'] != null) {
      if (map['isReal'] is bool) {
        parsedIsReal = map['isReal'];
      } else if (map['isReal'] is num) {
        parsedIsReal = map['isReal'] == 1;
      }
    }

    return Prescription(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      patientName: map['patientName'] ?? '',
      medicines: List<String>.from(map['medicines'] ?? []),
      diagnosis: map['diagnosis'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      extractedText: map['extractedText'] ?? '',
      doctorName: map['doctorName'] ?? '',
      doctorRegistryNo: map['doctorRegistryNo'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      isReal: parsedIsReal,
      authenticityScore: (map['authenticityScore'] as num?)?.toDouble() ?? 95.0,
      authenticityReport: map['authenticityReport'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Prescription.fromJson(String source) => Prescription.fromMap(json.decode(source));
}
