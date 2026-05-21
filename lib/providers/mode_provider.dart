import 'package:flutter/material.dart';

class ModeProvider extends ChangeNotifier {
  bool _forceOffline = false;
  String _activeStatus = 'Online AI Active';
  bool _isDiagnosisMode = false;
  String _selectedLanguage = 'English';
  bool _isDoctorMode = false;

  bool get forceOffline => _forceOffline;
  String get activeStatus => _activeStatus;
  bool get isDiagnosisMode => _isDiagnosisMode;
  String get selectedLanguage => _selectedLanguage;
  bool get isDoctorMode => _isDoctorMode;
  
  String _selectedLength = 'SHORT'; // Default to SHORT for optimal conversational brevity
  String get selectedLength => _selectedLength;

  void setSelectedLength(String length) {
    if (_selectedLength != length) {
      _selectedLength = length;
      notifyListeners();
    }
  }

  /// Toggle between online search and force offline simulation
  void toggleForceOffline() {
    _forceOffline = !_forceOffline;
    if (_forceOffline) {
      _activeStatus = 'Offline AI Active';
      _isDiagnosisMode = true; // In offline mode, default keep diagnostic ON by default
    } else {
      _activeStatus = 'Online AI Active';
    }
    notifyListeners();
  }

  /// Explicitly update the status label (called by AiRouter during execution)
  void updateActiveStatus(String newStatus) {
    if (_activeStatus != newStatus) {
      _activeStatus = newStatus;
      notifyListeners();
    }
  }

  /// Toggle strict medical triage formatting
  void toggleDiagnosisMode() {
    _isDiagnosisMode = !_isDiagnosisMode;
    notifyListeners();
  }

  /// Explicitly set strict medical triage formatting
  void setDiagnosisMode(bool value) {
    if (_isDiagnosisMode != value) {
      _isDiagnosisMode = value;
      notifyListeners();
    }
  }

  /// Change conversational language
  void setLanguage(String language) {
    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      notifyListeners();
    }
  }

  void setDoctorMode(bool value) {
    if (_isDoctorMode != value) {
      _isDoctorMode = value;
      notifyListeners();
    }
  }
}
