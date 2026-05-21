class MedicalKnowledgeUpdate {
  final String id;
  final String title;
  final String riskLevel; // Low, Medium, High, Critical
  final List<String> keywords;
  final List<String> causes;
  final List<String> actions;
  final String doctorWhen;
  final DateTime syncDate;
  final String version;
  final String source;

  MedicalKnowledgeUpdate({
    required this.id,
    required this.title,
    required this.riskLevel,
    required this.keywords,
    required this.causes,
    required this.actions,
    required this.doctorWhen,
    required this.syncDate,
    required this.version,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'riskLevel': riskLevel,
      'keywords': keywords,
      'causes': causes,
      'actions': actions,
      'doctorWhen': doctorWhen,
      'syncDate': syncDate.toIso8601String(),
      'version': version,
      'source': source,
    };
  }

  factory MedicalKnowledgeUpdate.fromMap(Map<dynamic, dynamic> map) {
    return MedicalKnowledgeUpdate(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Medical Update',
      riskLevel: map['riskLevel'] as String? ?? 'Medium',
      keywords: List<String>.from(map['keywords'] ?? []),
      causes: List<String>.from(map['causes'] ?? []),
      actions: List<String>.from(map['actions'] ?? []),
      doctorWhen: map['doctorWhen'] as String? ?? 'Consult a medical practitioner if symptoms persist.',
      syncDate: map['syncDate'] != null ? DateTime.parse(map['syncDate'] as String) : DateTime.now(),
      version: map['version'] as String? ?? '1.0',
      source: map['source'] as String? ?? 'Swasth Cloud',
    );
  }
}
