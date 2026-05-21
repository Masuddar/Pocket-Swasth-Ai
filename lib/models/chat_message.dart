import 'dart:convert';
import 'dart:typed_data';

class ChatMessage {
  final String id;
  final String sender; // 'user' or 'ai'
  final String text; // Full markdown response
  final DateTime timestamp;
  
  // Structured medical findings (populated if sender is 'ai' and response parsed successfully)
  final bool isStructured;
  final String? possibleCondition;
  final String? severity; // 'Low', 'Medium', 'Emergency'
  final String? reasoning;
  final List<String>? nextSteps;
  final bool? hospitalUrgently;
  final String? doctorType;
  final List<String>? suggestions; // Dynamic symptom suggestions

  // Attachment fields
  final String? attachmentName;
  final String? attachmentType; // 'image' or 'pdf'
  final int? attachmentSize; // in KB
  final String? attachmentBytesBase64; // raw document bytes (base64) for persistence
  final String? ocrResultJson; // parsed OCR verification JSON payload

  // Smart Agent features
  final bool? isAmbulanceDispatch;
  final String? ambulanceDriverName;
  final String? ambulanceVehicleNo;
  final String? ambulanceDriverPhone;
  final int? ambulanceEtaMinutes;
  final String? bookingTicketJson;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isStructured = false,
    this.possibleCondition,
    this.severity,
    this.reasoning,
    this.nextSteps,
    this.hospitalUrgently,
    this.doctorType,
    this.suggestions,
    this.attachmentName,
    this.attachmentType,
    this.attachmentSize,
    this.attachmentBytesBase64,
    this.ocrResultJson,
    this.isAmbulanceDispatch,
    this.ambulanceDriverName,
    this.ambulanceVehicleNo,
    this.ambulanceDriverPhone,
    this.ambulanceEtaMinutes,
    this.bookingTicketJson,
  });

  Uint8List? get attachmentBytes {
    if (attachmentBytesBase64 == null) return null;
    try {
      return base64Decode(attachmentBytesBase64!);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isStructured': isStructured,
      'possibleCondition': possibleCondition,
      'severity': severity,
      'reasoning': reasoning,
      'nextSteps': nextSteps,
      'hospitalUrgently': hospitalUrgently,
      'doctorType': doctorType,
      'suggestions': suggestions,
      'attachmentName': attachmentName,
      'attachmentType': attachmentType,
      'attachmentSize': attachmentSize,
      'attachmentBytesBase64': attachmentBytesBase64,
      'ocrResultJson': ocrResultJson,
      'isAmbulanceDispatch': isAmbulanceDispatch,
      'ambulanceDriverName': ambulanceDriverName,
      'ambulanceVehicleNo': ambulanceVehicleNo,
      'ambulanceDriverPhone': ambulanceDriverPhone,
      'ambulanceEtaMinutes': ambulanceEtaMinutes,
      'bookingTicketJson': bookingTicketJson,
    };
  }

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    List<String>? steps;
    if (map['nextSteps'] != null) {
      steps = List<String>.from(map['nextSteps']);
    }
    List<String>? sug;
    if (map['suggestions'] != null) {
      sug = List<String>.from(map['suggestions']);
    }
    return ChatMessage(
      id: map['id'] ?? '',
      sender: map['sender'] ?? 'user',
      text: map['text'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      isStructured: map['isStructured'] ?? false,
      possibleCondition: map['possibleCondition'],
      severity: map['severity'],
      reasoning: map['reasoning'],
      nextSteps: steps,
      hospitalUrgently: map['hospitalUgly'] ?? map['hospitalUrgently'],
      doctorType: map['doctorType'],
      suggestions: sug,
      attachmentName: map['attachmentName'],
      attachmentType: map['attachmentType'],
      attachmentSize: map['attachmentSize'],
      attachmentBytesBase64: map['attachmentBytesBase64'],
      ocrResultJson: map['ocrResultJson'],
      isAmbulanceDispatch: map['isAmbulanceDispatch'],
      ambulanceDriverName: map['ambulanceDriverName'],
      ambulanceVehicleNo: map['ambulanceVehicleNo'],
      ambulanceDriverPhone: map['ambulanceDriverPhone'],
      ambulanceEtaMinutes: map['ambulanceEtaMinutes'],
      bookingTicketJson: map['bookingTicketJson'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatMessage.fromJson(String source) => ChatMessage.fromMap(json.decode(source));
}
