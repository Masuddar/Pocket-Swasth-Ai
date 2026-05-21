import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/cards/medical_card.dart';
import 'doctor_twin_screen.dart';

class ReportScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const ReportScreen({super.key, this.onNavigateToTab});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final healthProvider = Provider.of<HealthProvider>(context);
    
    // Fetch calculated evaluation report from risk engine
    final report = healthProvider.getHealthRiskReport(userProvider.profile);
    
    final level = report['level'] as String;
    final score = report['score'] as int;
    final factors = List<String>.from(report['factors']);
    final recommendations = List<String>.from(report['recommendations']);

    Color riskColor;
    if (level.toLowerCase().contains('high')) {
      riskColor = AppTheme.severityEmergency;
    } else if (level.toLowerCase().contains('medium')) {
      riskColor = AppTheme.severityMedium;
    } else {
      riskColor = AppTheme.severityLow;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Health Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Overall Health Risk Level Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'OVERALL HEALTH RISK RATING',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Risk level badge
                    Text(
                      level.toUpperCase(),
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Risk score indicator bar
                    Row(
                      children: [
                        const Text('0', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppTheme.borderLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: score / 100.0,
                                  child: Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [riskColor.withOpacity(0.6), riskColor],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Text('100', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Assessment Index: $score/100',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Link Button: Open Doctor Twin Simulator
            ElevatedButton.icon(
              onPressed: () {
                // If there are no diagnoses, warn user to do symptom check first
                if (healthProvider.diagnosisHistory.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please perform a Swasth AI Chat symptom check first to generate a diagnosis for simulation.'),
                      backgroundColor: AppTheme.severityMedium,
                    ),
                  );
                  // Optionally redirect user to Chat tab
                  if (widget.onNavigateToTab != null) {
                    widget.onNavigateToTab!(0); // index 0 is Chat
                  }
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorTwinScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBlue,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.psychology_rounded, size: 24),
              label: const Text(
                'Launch Medication Twin Simulator',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(1); // index 1 is Verify Rx
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.folder_shared_rounded, size: 20),
              label: const Text(
                'Access Prescription Document Cabinet',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Contributing Risk Factors Card
            MedicalCard(
              title: 'Contributing Risk Profile',
              icon: Icons.analytics_outlined,
              borderColor: riskColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: factors.map((factor) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.report_problem_outlined, color: riskColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            factor,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Preventative recommendations checklist Card
            MedicalCard(
              title: 'Personalized Clinical Checklist',
              icon: Icons.fact_check_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: recommendations.map((rec) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_box_outlined, color: AppTheme.primaryTeal, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Let's replace the placeholder list child builder above with the exact `rec` values!
            // Wait, I will write the code properly.
            
            // 4. Recent Diagnoses History Card
            MedicalCard(
              title: 'Recent Diagnostic Records',
              icon: Icons.history_rounded,
              child: healthProvider.diagnosisHistory.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'No previous symptom assessments recorded yet.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: healthProvider.diagnosisHistory.length,
                      itemBuilder: (context, index) {
                        final diag = healthProvider.diagnosisHistory[index];
                        final diagColor = AppTheme.getSeverityColor(diag.severity);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      diag.condition,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue, fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: diagColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      diag.severity.toUpperCase(),
                                      style: const TextStyle(color: AppTheme.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Symptoms Checked: "${diag.symptoms}"',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Checked: ${_formatDateTime(diag.timestamp)}',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
