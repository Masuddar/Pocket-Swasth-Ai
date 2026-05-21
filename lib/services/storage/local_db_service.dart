import 'package:hive_flutter/hive_flutter.dart';
import '../../models/chat_message.dart';
import '../../models/user_profile.dart';
import '../../models/prescription.dart';
import '../../models/diagnosis.dart';
import '../../models/appointment.dart';

class LocalDbService {
  static const String _boxName = 'pocket_swasth_box';
  late Box _box;

  // Singleton setup
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  /// Initialize Hive and open the pocket swasth data box
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // --- USER PROFILE STORAGE ---

  Future<void> saveUserProfile(UserProfile profile) async {
    await _box.put('user_profile', profile.toMap());
  }

  UserProfile getUserProfile() {
    final rawProfile = _box.get('user_profile');
    if (rawProfile == null) {
      return UserProfile.empty();
    }
    return UserProfile.fromMap(rawProfile);
  }

  // --- CHAT HISTORY STORAGE ---

  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final List<Map<String, dynamic>> rawList = messages.map((m) => m.toMap()).toList();
    await _box.put('chat_history', rawList);
  }

  List<ChatMessage> getChatHistory() {
    final List<dynamic>? rawList = _box.get('chat_history');
    if (rawList == null) {
      return [];
    }
    return rawList.map((item) => ChatMessage.fromMap(Map<dynamic, dynamic>.from(item))).toList();
  }

  Future<void> clearChatHistory() async {
    await _box.delete('chat_history');
  }

  // --- DIAGNOSIS HISTORY STORAGE ---

  Future<void> saveDiagnosis(Diagnosis diagnosis) async {
    final List<Diagnosis> current = getDiagnosisHistory();
    current.insert(0, diagnosis); // Newest at top
    final List<Map<String, dynamic>> rawList = current.map((d) => d.toMap()).toList();
    await _box.put('diagnosis_history', rawList);
  }

  List<Diagnosis> getDiagnosisHistory() {
    final List<dynamic>? rawList = _box.get('diagnosis_history');
    if (rawList == null) {
      return [];
    }
    return rawList.map((item) => Diagnosis.fromMap(Map<dynamic, dynamic>.from(item))).toList();
  }

  Future<void> clearDiagnosisHistory() async {
    await _box.delete('diagnosis_history');
  }

  // --- PRESCRIPTION STORAGE ---

  Future<void> savePrescription(Prescription prescription) async {
    final List<Prescription> current = getPrescriptions();
    current.insert(0, prescription);
    final List<Map<String, dynamic>> rawList = current.map((p) => p.toMap()).toList();
    await _box.put('prescriptions', rawList);
  }

  List<Prescription> getPrescriptions() {
    final List<dynamic>? rawList = _box.get('prescriptions');
    if (rawList == null) {
      return [];
    }
    return rawList.map((item) => Prescription.fromMap(Map<dynamic, dynamic>.from(item))).toList();
  }

  Future<void> deletePrescription(String id) async {
    final List<Prescription> current = getPrescriptions();
    current.removeWhere((p) => p.id == id);
    final List<Map<String, dynamic>> rawList = current.map((p) => p.toMap()).toList();
    await _box.put('prescriptions', rawList);
  }

  // --- APPOINTMENTS STORAGE ---

  Future<void> saveAppointment(Appointment appointment) async {
    final List<Appointment> current = getAppointments();
    current.insert(0, appointment);
    final List<Map<String, dynamic>> rawList = current.map((a) => a.toMap()).toList();
    await _box.put('appointments', rawList);
  }

  List<Appointment> getAppointments() {
    final List<dynamic>? rawList = _box.get('appointments');
    if (rawList == null) {
      return [];
    }
    return rawList.map((item) => Appointment.fromMap(Map<dynamic, dynamic>.from(item))).toList();
  }

  Future<void> updateAppointment(Appointment appointment) async {
    final List<Appointment> current = getAppointments();
    final int idx = current.indexWhere((a) => a.id == appointment.id);
    if (idx != -1) {
      current[idx] = appointment;
      final List<Map<String, dynamic>> rawList = current.map((a) => a.toMap()).toList();
      await _box.put('appointments', rawList);
    }
  }

  Future<void> deleteAppointment(String id) async {
    final List<Appointment> current = getAppointments();
    current.removeWhere((a) => a.id == id);
    final List<Map<String, dynamic>> rawList = current.map((a) => a.toMap()).toList();
    await _box.put('appointments', rawList);
  }
}

