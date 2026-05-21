import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../providers/mode_provider.dart';
import '../providers/user_provider.dart';

class PatientTwinProfile {
  String name;
  int age;
  double weight;
  String activeCondition;
  double baselineVital; // e.g. blood sugar or blood pressure
  String vitalUnit;

  PatientTwinProfile({
    required this.name,
    required this.age,
    required this.weight,
    required this.activeCondition,
    required this.baselineVital,
    required this.vitalUnit,
  });

  PatientTwinProfile copyWith({
    String? name,
    int? age,
    double? weight,
    String? activeCondition,
    double? baselineVital,
    String? vitalUnit,
  }) {
    return PatientTwinProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      activeCondition: activeCondition ?? this.activeCondition,
      baselineVital: baselineVital ?? this.baselineVital,
      vitalUnit: vitalUnit ?? this.vitalUnit,
    );
  }
}

class TrialSimulation {
  final String drugName;
  final String dosage;
  final double simulatedVitalResult;
  final double efficacyIndex; // 0 to 100
  final double toxicityIndex; // 0 to 100
  final List<String> warnings;
  final String time;
  final bool isExternalAi;

  TrialSimulation({
    required this.drugName,
    required this.dosage,
    required this.simulatedVitalResult,
    required this.efficacyIndex,
    required this.toxicityIndex,
    required this.warnings,
    required this.time,
    required this.isExternalAi,
  });
}

class DoctorConsoleScreen extends StatefulWidget {
  const DoctorConsoleScreen({super.key});

  @override
  State<DoctorConsoleScreen> createState() => _DoctorConsoleScreenState();
}

class _DoctorConsoleScreenState extends State<DoctorConsoleScreen> with SingleTickerProviderStateMixin {
  final _drugNameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  
  // High fidelity default patients with full CRUD operations
  final List<PatientTwinProfile> _patientProfiles = [
    PatientTwinProfile(name: 'Sarah Jenkins', age: 46, weight: 82.0, activeCondition: 'Type-2 Diabetes mellitus', baselineVital: 198.0, vitalUnit: 'mg/dL (HbA1c: 7.9%)'),
    PatientTwinProfile(name: 'Marcus Vance', age: 68, weight: 74.5, activeCondition: 'Stage II Hypertension', baselineVital: 155.0, vitalUnit: 'mmHg (Systolic)'),
    PatientTwinProfile(name: 'Elena Rostova', age: 29, weight: 61.2, activeCondition: 'Chronic Bronchial Asthma', baselineVital: 88.0, vitalUnit: '% SpO2'),
  ];

  late PatientTwinProfile _selectedPatient;
  List<TrialSimulation> _trials = [];
  bool _isSimulating = false;
  TrialSimulation? _activeResult;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedPatient = _patientProfiles[0];
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _drugNameCtrl.dispose();
    _dosageCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final hasApiKey = userProvider.profile.openRouterApiKey.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Beautiful Light Theme
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppTheme.primaryTeal),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: AppTheme.primaryTeal, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DR. PORTAL CONSOLE',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
                Text(
                  'Physiological Twin Sandbox',
                  style: TextStyle(color: AppTheme.primaryTeal, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              modeProvider.setDoctorMode(false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('🏡 Returned to Patient Mode.'),
                backgroundColor: AppTheme.primaryTeal,
              ));
            },
            icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.redAccent),
            label: const Text('Exit Portal', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 11)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryTeal,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.science_outlined, size: 18), text: 'Sim Sandbox'),
            Tab(icon: Icon(Icons.people_outline_rounded, size: 18), text: 'Twin Directory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSimSandboxTab(hasApiKey),
          _buildTwinDirectoryTab(),
        ],
      ),
    );
  }

  // --- TAB 1: SIMULATION SANDBOX ---
  Widget _buildSimSandboxTab(bool hasApiKey) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Patient Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SELECT CLINICAL MODEL',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              // API Key status indicator badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasApiKey ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: hasApiKey ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasApiKey ? Icons.auto_awesome : Icons.cloud_off,
                      size: 10,
                      color: hasApiKey ? const Color(0xFF047857) : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasApiKey ? 'Cloud AI Ready' : 'Local Heuristic AI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: hasApiKey ? const Color(0xFF047857) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPatientSelector(),
          const SizedBox(height: 16),

          // 2. Holographic Digital Twin Monitor Panel
          _buildDigitalTwinMonitor(),
          const SizedBox(height: 20),

          // 3. Treatment Sandbox Input Form
          _buildTreatmentSandboxForm(hasApiKey),
          const SizedBox(height: 20),

          // 4. Hit & Trial Results Dashboard
          if (_isSimulating) ...[
            _buildSimulationLoader(),
          ] else if (_activeResult != null) ...[
            _buildSimulationAnalysisResult(),
          ],

          // 5. Sim Log List
          if (_trials.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSimTrialHistory(),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButton<PatientTwinProfile>(
        value: _selectedPatient,
        isExpanded: true,
        dropdownColor: Colors.white,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryTeal),
        items: _patientProfiles.map((p) {
          return DropdownMenuItem(
            value: p,
            child: Text(
              '${p.name} (Age ${p.age} • ${p.activeCondition})',
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() {
              _selectedPatient = v;
              _activeResult = null;
              _trials.clear();
            });
          }
        },
      ),
    );
  }

  Widget _buildDigitalTwinMonitor() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFF1F5F9).withOpacity(0.5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryTeal.withOpacity(0.04),
                    border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.1)),
                  ),
                ),
                Icon(
                  Icons.person_outline_rounded,
                  size: 72,
                  color: _isSimulating ? AppTheme.primaryTeal : const Color(0xFF94A3B8),
                ),
                if (_isSimulating)
                  const SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppTheme.primaryTeal),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SIMULATED BIOMETRICS', style: TextStyle(color: AppTheme.primaryTeal, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                _buildTwinVitalRow('Vitals Baseline', '${_selectedPatient.baselineVital} ${_selectedPatient.vitalUnit}'),
                const SizedBox(height: 6),
                _buildTwinVitalRow('Model Name', _selectedPatient.name),
                const SizedBox(height: 6),
                _buildTwinVitalRow('Standard Weight', '${_selectedPatient.weight} kg'),
                const SizedBox(height: 6),
                _buildTwinVitalRow('Toxicity Tolerance', 'Medium-High'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwinVitalRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            val,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentSandboxForm(bool hasApiKey) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.science_outlined, color: AppTheme.primaryTeal, size: 16),
              SizedBox(width: 8),
              Text(
                'TRIAL TREATMENT INJECTION',
                style: TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('DRUG NAME', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          TextField(
            controller: _drugNameCtrl,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'e.g. Metformin HCL, Lisinopril',
              hintStyle: TextStyle(color: const Color(0xFF94A3B8).withOpacity(0.5), fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          const Text('DOSAGE & REGIMEN', style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          TextField(
            controller: _dosageCtrl,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'e.g. 500mg Twice Daily',
              hintStyle: TextStyle(color: const Color(0xFF94A3B8).withOpacity(0.5), fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _triggerHitAndTrialSimulation(hasApiKey),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline, size: 16),
                SizedBox(width: 8),
                Text('RUN HIT & TRIAL SIMULATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationLoader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryTeal),
          const SizedBox(height: 14),
          Text(
            'Injecting ${_drugNameCtrl.text} trial dose...',
            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Evaluating simulated patient kidney/liver response curve...',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationAnalysisResult() {
    final result = _activeResult!;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                result.isExternalAi ? Icons.auto_awesome : Icons.analytics_outlined, 
                color: AppTheme.primaryTeal, 
                size: 16
              ),
              const SizedBox(width: 8),
              Text(
                result.isExternalAi ? 'EXTERNAL CLOUD AI PREDICTION REPORT' : 'INTERNAL AI HEURISTIC CLINICAL REPORT',
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildReportGauge('Therapeutic Efficacy', '${result.efficacyIndex.round()}%', Colors.green),
              _buildReportGauge('Organ Toxicity Risk', '${result.toxicityIndex.round()}%', result.toxicityIndex > 50 ? Colors.redAccent : Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          const Text(
            'Simulated Vital Change Over 15 Days:',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Pathology baseline shifted from ${_selectedPatient.baselineVital.round()} to ${result.simulatedVitalResult.round()} ${_selectedPatient.vitalUnit.split(' ')[0]}',
            style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (result.warnings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.warnings.map((w) {
                  return Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          w,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                  SizedBox(width: 6),
                  Text('Zero drug-drug interaction warnings detected.', style: TextStyle(color: Colors.green, fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportGauge(String title, String val, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(color: col, fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildSimTrialHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'TRIAL SANDBOX RUN LOG (HIT & TRIAL RESULTS)',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _trials.length,
            itemBuilder: (_, i) {
              final t = _trials[_trials.length - 1 - i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t.drugName,
                              style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            if (t.isExternalAi) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.auto_awesome, color: AppTheme.primaryTeal, size: 10),
                            ],
                          ],
                        ),
                        Text(
                          t.dosage,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Efficacy: ${t.efficacyIndex.round()}%',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        Text(
                          'Toxicity: ${t.toxicityIndex.round()}%',
                          style: TextStyle(color: t.toxicityIndex > 50 ? Colors.redAccent : Colors.orange, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- TAB 2: TWIN DIRECTORY CRUD MANAGER ---
  Widget _buildTwinDirectoryTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REGISTERED CLINICAL TWINS (${_patientProfiles.length})',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              ElevatedButton.icon(
                onPressed: () => _showPatientCrudForm(null),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Patient Twin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _patientProfiles.length,
            itemBuilder: (ctx, idx) {
              final patient = _patientProfiles[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.name,
                                style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Age ${patient.age} • ${patient.weight} kg',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _showPatientCrudForm(patient),
                              icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryTeal, size: 18),
                              tooltip: 'Edit Parameters',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                            IconButton(
                              onPressed: () => _deletePatientProfile(patient),
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              tooltip: 'De-register Model',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildProfileMiniField('Condition', patient.activeCondition),
                        _buildProfileMiniField('Baseline Vital', '${patient.baselineVital.round()} ${patient.vitalUnit.split(' ')[0]}'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMiniField(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- CRUD ACTIONS ---

  void _showPatientCrudForm(PatientTwinProfile? existingProfile) {
    final nameCtrl = TextEditingController(text: existingProfile?.name ?? '');
    final ageCtrl = TextEditingController(text: existingProfile?.age.toString() ?? '');
    final weightCtrl = TextEditingController(text: existingProfile?.weight.toString() ?? '');
    final condCtrl = TextEditingController(text: existingProfile?.activeCondition ?? '');
    final vitalCtrl = TextEditingController(text: existingProfile?.baselineVital.toString() ?? '');
    final unitCtrl = TextEditingController(text: existingProfile?.vitalUnit ?? 'mg/dL');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bctx) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(bctx).viewInsets.bottom + 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(color: Color(0xFFE2E8F0), borderRadius: BorderRadius.all(Radius.circular(2))),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    existingProfile == null ? Icons.person_add_alt_rounded : Icons.edit_note_rounded,
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    existingProfile == null ? 'Register Clinical Twin' : 'Edit Clinical Twin Parameters',
                    style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              
              // Form Fields
              _buildCrudField('FULL NAME', nameCtrl, 'e.g. Sarah Jenkins'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildCrudField('AGE', ageCtrl, 'e.g. 45', isNum: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCrudField('WEIGHT (KG)', weightCtrl, 'e.g. 72', isNum: true)),
                ],
              ),
              const SizedBox(height: 12),
              _buildCrudField('ACTIVE DIAGNOSIS / CONDITION', condCtrl, 'e.g. Type-2 Diabetes'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildCrudField('BASELINE VITAL', vitalCtrl, 'e.g. 180', isNum: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCrudField('VITAL UNIT / METRIC', unitCtrl, 'e.g. mg/dL')),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final age = int.tryParse(ageCtrl.text.trim()) ?? 0;
                  final weight = double.tryParse(weightCtrl.text.trim()) ?? 0.0;
                  final condition = condCtrl.text.trim();
                  final baseline = double.tryParse(vitalCtrl.text.trim()) ?? 0.0;
                  final unit = unitCtrl.text.trim();

                  if (name.isEmpty || condition.isEmpty || unit.isEmpty || age == 0 || weight == 0.0 || baseline == 0.0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('⚠️ All clinical parameters must be correctly entered.'),
                      backgroundColor: Colors.orange,
                    ));
                    return;
                  }

                  setState(() {
                    if (existingProfile == null) {
                      // Create
                      final newTwin = PatientTwinProfile(
                        name: name,
                        age: age,
                        weight: weight,
                        activeCondition: condition,
                        baselineVital: baseline,
                        vitalUnit: unit,
                      );
                      _patientProfiles.add(newTwin);
                      _selectedPatient = newTwin;
                    } else {
                      // Update
                      existingProfile.name = name;
                      existingProfile.age = age;
                      existingProfile.weight = weight;
                      existingProfile.activeCondition = condition;
                      existingProfile.baselineVital = baseline;
                      existingProfile.vitalUnit = unit;
                      
                      // Refresh selection to ensure values update in simulated state
                      if (_selectedPatient == existingProfile) {
                        _selectedPatient = existingProfile;
                      }
                    }
                    _activeResult = null;
                  });

                  Navigator.pop(bctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(existingProfile == null ? '➕ Clinical twin registered!' : '✅ Twin parameters updated.'),
                    backgroundColor: AppTheme.primaryTeal,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  existingProfile == null ? 'CREATE TWIN MODEL' : 'SAVE TWIN PROFILE',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCrudField(String label, TextEditingController ctrl, String hint, {bool isNum = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF94A3B8).withOpacity(0.5), fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  void _deletePatientProfile(PatientTwinProfile profile) {
    if (_patientProfiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ Cannot delete. At least one twin profile must remain in register.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('De-register Twin?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Text('This will delete all simulated telemetry models for ${profile.name} permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _patientProfiles.remove(profile);
                if (_selectedPatient == profile) {
                  _selectedPatient = _patientProfiles[0];
                }
                _activeResult = null;
                _trials.clear();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('🗑️ Model de-registered successfully.'),
                backgroundColor: Colors.redAccent,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- HIT & TRIAL SIMULATOR (INTERNAL & EXTERNAL AI) ---

  void _triggerHitAndTrialSimulation(bool hasApiKey) {
    final drug = _drugNameCtrl.text.trim();
    final dosage = _dosageCtrl.text.trim();
    if (drug.isEmpty || dosage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ Enter active drug name and dosage regimen first.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() {
      _isSimulating = true;
    });

    if (hasApiKey) {
      _runExternalCloudSimulation(drug, dosage);
    } else {
      _runInternalHeuristicSimulation(drug, dosage);
    }
  }

  // A. Internal Offline Heuristic Simulator
  void _runInternalHeuristicSimulation(String drug, String dosage) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      double efficacy = 75.0;
      double toxicity = 15.0;
      double newVital = _selectedPatient.baselineVital;
      List<String> warnings = [];

      final String dLower = drug.toLowerCase();
      final String cLower = _selectedPatient.activeCondition.toLowerCase();

      if (cLower.contains('diabetes')) {
        if (dLower.contains('metformin')) {
          efficacy = 88.0;
          toxicity = 12.0;
          newVital = 125.0; 
        } else if (dLower.contains('insulin')) {
          efficacy = 92.0;
          toxicity = 28.0;
          newVital = 110.0;
        } else {
          efficacy = 20.0;
          toxicity = 45.0;
          warnings.add('Ineffective for glucose pathways.');
        }
      } else if (cLower.contains('hypertension')) {
        if (dLower.contains('lisinopril') || dLower.contains('amlodipine')) {
          efficacy = 85.0;
          toxicity = 10.0;
          newVital = 122.0; 
        } else if (dLower.contains('ibuprofen') || dLower.contains('nsaid')) {
          efficacy = 15.0;
          toxicity = 65.0;
          newVital = 162.0;
          warnings.add('NSAIDs aggravate hypertension.');
        } else {
          efficacy = 30.0;
          toxicity = 35.0;
        }
      } else if (cLower.contains('asthma')) {
        if (dLower.contains('albuterol') || dLower.contains('salbutamol')) {
          efficacy = 95.0;
          toxicity = 18.0;
          newVital = 98.0; 
        } else if (dLower.contains('propranolol') || dLower.contains('beta blocker')) {
          efficacy = 5.0;
          toxicity = 90.0;
          newVital = 82.0;
          warnings.add('Contraindicated: Beta-blockers cause bronchospasms!');
        } else {
          efficacy = 40.0;
          toxicity = 25.0;
        }
      }

      final sim = TrialSimulation(
        drugName: drug,
        dosage: dosage,
        simulatedVitalResult: newVital,
        efficacyIndex: efficacy,
        toxicityIndex: toxicity,
        warnings: warnings,
        time: 'Just now',
        isExternalAi: false,
      );

      setState(() {
        _isSimulating = false;
        _activeResult = sim;
        _trials.add(sim);
      });
    });
  }

  // B. External Cloud OpenRouter AI Simulator
  void _runExternalCloudSimulation(String drug, String dosage) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiKey = userProvider.profile.openRouterApiKey;

    final prompt = '''
    You are the Swasth AI Advanced Physiological Digital Twin Simulator.
    The doctor is performing a clinical trial on a simulated patient twin in a sandbox.
    
    Patient Profile:
    - Age: ${_selectedPatient.age}
    - Weight: ${_selectedPatient.weight} kg
    - Baseline Pathology Condition: ${_selectedPatient.activeCondition}
    - Baseline Vital Telemetry: ${_selectedPatient.baselineVital} ${_selectedPatient.vitalUnit}
    
    Injected Trial Regimen:
    - Drug Name: $drug
    - Dosage & Regimen: $dosage
    
    Predict the physiological trajectory outcome over 15 days of continuous treatment.
    
    You must output strictly in JSON format. Do not write markdown, code blocks, or explanations outside the JSON object.
    Required JSON Keys:
    - "efficacy": (a number from 0.0 to 100.0 indicating expected therapeutic alignment efficacy)
    - "toxicity": (a number from 0.0 to 100.0 indicating risk index of organ stress, liver/kidney toxicity)
    - "vitalShift": (a number indicating predicted vital value after 15 days, e.g. blood sugar drop to 125, blood pressure drop to 120, SpO2 restoration)
    - "warnings": (a JSON array of strings containing warning contraindications, interactions, or critical alerts - keep them concise, maximum 15 words per warning. Empty array if fully safe)
    
    Example output format:
    {"efficacy": 88.0, "toxicity": 12.0, "vitalShift": 125.0, "warnings": ["Renal filtration monitored: slight creatinine spike possible."]}
    ''';

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://pocketswasth.ai',
          'X-Title': 'Pocket Swasth Clinician Portal',
        },
        body: jsonEncode({
          'model': 'openrouter/free',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final content = resData['choices'][0]['message']['content'].toString().trim();
        
        // Sanitize LLM potential markdown fences
        String cleanJson = content;
        if (cleanJson.contains('```')) {
          cleanJson = cleanJson.split('```')[1];
          if (cleanJson.startsWith('json')) {
            cleanJson = cleanJson.substring(4);
          }
        }
        cleanJson = cleanJson.trim();

        final parsed = jsonDecode(cleanJson);
        
        final sim = TrialSimulation(
          drugName: drug,
          dosage: dosage,
          simulatedVitalResult: double.tryParse(parsed['vitalShift'].toString()) ?? _selectedPatient.baselineVital,
          efficacyIndex: double.tryParse(parsed['efficacy'].toString()) ?? 75.0,
          toxicityIndex: double.tryParse(parsed['toxicity'].toString()) ?? 15.0,
          warnings: List<String>.from(parsed['warnings'] ?? []),
          time: 'Just now',
          isExternalAi: true,
        );

        if (mounted) {
          setState(() {
            _isSimulating = false;
            _activeResult = sim;
            _trials.add(sim);
          });
        }
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Elegant fallback to Internal Heuristic AI if network / API key issue occurs
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚠️ Cloud AI query failed (${e.toString().split(' ').take(3).join(' ')}). Switched to Local AI.'),
          backgroundColor: Colors.orange,
        ));
        _runInternalHeuristicSimulation(drug, dosage);
      }
    }
  }
}
