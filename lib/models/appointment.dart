import 'dart:convert';

class Appointment {
  final String id;
  final String doctorName;
  final String doctorSpecialty;
  final String hospitalName;
  final String dateTimeStr;
  final String slot;
  final String notes;
  final String status; // 'Confirmed', 'Rescheduled', 'Cancelled'

  Appointment({
    required this.id,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.hospitalName,
    required this.dateTimeStr,
    required this.slot,
    required this.notes,
    this.status = 'Confirmed',
  });

  Appointment copyWith({
    String? id,
    String? doctorName,
    String? doctorSpecialty,
    String? hospitalName,
    String? dateTimeStr,
    String? slot,
    String? notes,
    String? status,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      hospitalName: hospitalName ?? this.hospitalName,
      dateTimeStr: dateTimeStr ?? this.dateTimeStr,
      slot: slot ?? this.slot,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'hospitalName': hospitalName,
      'dateTimeStr': dateTimeStr,
      'slot': slot,
      'notes': notes,
      'status': status,
    };
  }

  factory Appointment.fromMap(Map<dynamic, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      doctorName: map['doctorName'] ?? '',
      doctorSpecialty: map['doctorSpecialty'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      dateTimeStr: map['dateTimeStr'] ?? '',
      slot: map['slot'] ?? '',
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'Confirmed',
    );
  }

  String toJson() => json.encode(toMap());

  factory Appointment.fromJson(String source) => Appointment.fromMap(json.decode(source));
}
