import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/storage/local_db_service.dart';

class UserProvider extends ChangeNotifier {
  final LocalDbService _dbService = LocalDbService();
  late UserProfile _profile;

  UserProvider() {
    _profile = _dbService.getUserProfile();
    if (_profile.openRouterApiKey.isEmpty ||
        _profile.openRouterApiKey.contains('pocket-swasth-demo')) {
      saveApiKey('REDACTED_OPENROUTER_KEY');
    }
  }

  UserProfile get profile => _profile;

  /// Full profile update with all medical fields
  Future<void> updateProfile(UserProfile updated) async {
    _profile = updated;
    await _dbService.saveUserProfile(_profile);
    notifyListeners();
  }

  /// Quick API key save
  Future<void> saveApiKey(String key) async {
    _profile = _profile.copyWith(openRouterApiKey: key);
    await _dbService.saveUserProfile(_profile);
    notifyListeners();
  }

  /// Add a chronic condition chip
  Future<void> addChronicCondition(String condition) async {
    final clean = condition.trim();
    if (clean.isEmpty) return;
    final updated = List<String>.from(_profile.medicalHistory);
    updated.remove('No known chronic illnesses');
    if (!updated.contains(clean)) {
      updated.add(clean);
      await updateProfile(_profile.copyWith(medicalHistory: updated));
    }
  }

  /// Remove a chronic condition chip
  Future<void> removeChronicCondition(String condition) async {
    final updated = List<String>.from(_profile.medicalHistory);
    updated.remove(condition);
    if (updated.isEmpty) updated.add('No known chronic illnesses');
    await updateProfile(_profile.copyWith(medicalHistory: updated));
  }

  /// Add an allergy chip
  Future<void> addAllergy(String allergy) async {
    final clean = allergy.trim();
    if (clean.isEmpty) return;
    final updated = List<String>.from(_profile.allergies);
    if (!updated.contains(clean)) {
      updated.add(clean);
      await updateProfile(_profile.copyWith(allergies: updated));
    }
  }

  /// Remove an allergy chip
  Future<void> removeAllergy(String allergy) async {
    final updated = List<String>.from(_profile.allergies);
    updated.remove(allergy);
    await updateProfile(_profile.copyWith(allergies: updated));
  }

  /// Add a vaccination chip
  Future<void> addVaccination(String vaccine) async {
    final clean = vaccine.trim();
    if (clean.isEmpty) return;
    final updated = List<String>.from(_profile.vaccinations);
    if (!updated.contains(clean)) {
      updated.add(clean);
      await updateProfile(_profile.copyWith(vaccinations: updated));
    }
  }

  /// Remove a vaccination chip
  Future<void> removeVaccination(String vaccine) async {
    final updated = List<String>.from(_profile.vaccinations);
    updated.remove(vaccine);
    await updateProfile(_profile.copyWith(vaccinations: updated));
  }
}
