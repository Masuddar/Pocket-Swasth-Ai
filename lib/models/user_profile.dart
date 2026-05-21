import 'dart:convert';

class UserProfile {
  final String fullName;
  final int age;
  final String gender;
  final String bloodGroup;
  final double heightCm;
  final double weightKg;
  final List<String> medicalHistory;
  final List<String> allergies;
  final List<String> vaccinations;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String insuranceProvider;
  final String openRouterApiKey;

  UserProfile({
    this.fullName = '',
    required this.age,
    required this.gender,
    this.bloodGroup = 'Unknown',
    this.heightCm = 170,
    this.weightKg = 70,
    required this.medicalHistory,
    this.allergies = const [],
    this.vaccinations = const [],
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.insuranceProvider = '',
    this.openRouterApiKey = '',
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));
  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  UserProfile copyWith({
    String? fullName,
    int? age,
    String? gender,
    String? bloodGroup,
    double? heightCm,
    double? weightKg,
    List<String>? medicalHistory,
    List<String>? allergies,
    List<String>? vaccinations,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? insuranceProvider,
    String? openRouterApiKey,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      vaccinations: vaccinations ?? this.vaccinations,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      openRouterApiKey: openRouterApiKey ?? this.openRouterApiKey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'vaccinations': vaccinations,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'insuranceProvider': insuranceProvider,
      'openRouterApiKey': openRouterApiKey,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      fullName: map['fullName'] ?? '',
      age: map['age']?.toInt() ?? 30,
      gender: map['gender'] ?? 'Not Specified',
      bloodGroup: map['bloodGroup'] ?? 'Unknown',
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70,
      medicalHistory: List<String>.from(map['medicalHistory'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      vaccinations: List<String>.from(map['vaccinations'] ?? []),
      emergencyContactName: map['emergencyContactName'] ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] ?? '',
      insuranceProvider: map['insuranceProvider'] ?? '',
      openRouterApiKey: map['openRouterApiKey'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));

  factory UserProfile.empty() {
    return UserProfile(
      fullName: '',
      age: 28,
      gender: 'Male',
      bloodGroup: 'B+',
      heightCm: 170,
      weightKg: 70,
      medicalHistory: ['No known chronic illnesses'],
      allergies: [],
      vaccinations: ['COVID-19', 'Hepatitis B'],
      emergencyContactName: '',
      emergencyContactPhone: '',
      insuranceProvider: '',
      openRouterApiKey: '',
    );
  }
}
