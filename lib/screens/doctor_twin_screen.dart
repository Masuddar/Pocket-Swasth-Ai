import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/health_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/cards/medical_card.dart';

class DoctorTwinScreen extends StatefulWidget {
  const DoctorTwinScreen({super.key});

  @override
  State<DoctorTwinScreen> createState() => _DoctorTwinScreenState();
}

class _DoctorTwinScreenState extends State<DoctorTwinScreen> {
  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);
    final history = healthProvider.diagnosisHistory;
    final selectedDiag = healthProvider.selectedDiagnosisForTwin;
    final timeline = healthProvider.simulationTimeline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Twin Simulator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: history.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Selector Dropdown Card
                  MedicalCard(
                    title: '1. Select Diagnosis Case to Simulate',
                    icon: Icons.personal_injury_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedDiag?.id,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: history.map((diag) {
                            return DropdownMenuItem<String>(
                              value: diag.id,
                              child: Text(
                                diag.condition,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final matched = history.firstWhere((d) => d.id == val);
                              healthProvider.setSelectedDiagnosisForTwin(matched);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Select Compliance Selector Card
                  MedicalCard(
                    title: '2. Select Patient Compliance Strategy',
                    icon: Icons.playlist_add_check_circle_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Choose a medication compliance profile to project daily outcomes:',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildComplianceButton(
                              context,
                              healthProvider,
                              label: 'Perfect',
                              type: 'perfect',
                              activeColor: AppTheme.severityLow,
                            ),
                            const SizedBox(width: 8),
                            _buildComplianceButton(
                              context,
                              healthProvider,
                              label: 'Poor',
                              type: 'poor',
                              activeColor: AppTheme.severityMedium,
                            ),
                            const SizedBox(width: 8),
                            _buildComplianceButton(
                              context,
                              healthProvider,
                              label: 'Abuse',
                              type: 'abuse',
                              activeColor: AppTheme.severityEmergency,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Clinical Warning Banner
                  _buildComplianceAlertBanner(healthProvider.complianceType),
                  const SizedBox(height: 20),

                  // 4. Interactive Simulation Visual Graph
                  if (timeline.isNotEmpty) ...[
                    MedicalCard(
                      title: '3. Recovery Projection Timeline (7 Days)',
                      icon: Icons.query_stats_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCustomTimelineGraph(timeline),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem('Health Recovery', AppTheme.primaryTeal),
                              const SizedBox(width: 24),
                              _buildLegendItem('Drug Toxicity', AppTheme.severityEmergency),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Daily Progress Report Cards
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Text(
                        'Day-by-Day Forecast Logs:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.secondaryBlue),
                      ),
                    ),
                    ...timeline.map((dayMap) => _buildDayTimelineCard(dayMap)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.psychology_rounded, size: 80, color: AppTheme.primaryTeal.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'Medication Twin Offline',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
          ),
          const SizedBox(height: 12),
          const Text(
            'To run a digital medication simulation, you must first complete a symptom check inside the "Swasth AI" chat screen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceButton(
    BuildContext context,
    HealthProvider provider, {
    required String label,
    required String type,
    required Color activeColor,
  }) {
    final isSelected = provider.complianceType == type;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? activeColor : AppTheme.white,
          foregroundColor: isSelected ? AppTheme.white : AppTheme.textMuted,
          side: BorderSide(
            color: isSelected ? activeColor : AppTheme.borderLight,
            width: 1.5,
          ),
          elevation: isSelected ? 3 : 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () {
          provider.setComplianceType(type);
        },
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildComplianceAlertBanner(String compliance) {
    Color bg;
    Color border;
    IconData icon;
    String title;
    String desc;

    if (compliance == 'perfect') {
      bg = AppTheme.severityLow.withOpacity(0.08);
      border = AppTheme.severityLow;
      icon = Icons.check_circle_outline_rounded;
      title = 'OPTIMAL CLINICAL TRACK';
      desc = 'Perfect dose compliance. Minimizes microbial resistance, ensures organ protection, and delivers high-efficiency recovery.';
    } else if (compliance == 'poor') {
      bg = AppTheme.severityMedium.withOpacity(0.08);
      border = AppTheme.severityMedium;
      icon = Icons.warning_amber_rounded;
      title = 'RISK OF CRITICAL FLUSH / FLUX';
      desc = 'Dose omissions will result in drug dilution. Highly prone to bacterial mutation/relapses and chronic treatment failure.';
    } else {
      bg = AppTheme.severityEmergency.withOpacity(0.08);
      border = AppTheme.severityEmergency;
      icon = Icons.gavel_rounded;
      title = 'CRITICAL TOXICITY WARNING';
      desc = 'Overdosing causes heavy liver and renal strain. Dangerous blood pressure spikes or hypoglycemic shock possible. Seek immediate physician oversight!';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: border, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: border, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: AppTheme.textDark, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a responsive, animated custom bar graph for dual values (Health & Side Effects)
  Widget _buildCustomTimelineGraph(List<Map<String, dynamic>> timeline) {
    return Container(
      height: 180,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: timeline.map((dayMap) {
          final healthVal = double.tryParse(dayMap['health'].toString()) ?? 50.0;
          final toxicityVal = double.tryParse(dayMap['side_effects'].toString()) ?? 10.0;
          final dayLabel = dayMap['day'] as String;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Dual bars container
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Health bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 12,
                    height: (healthVal * 1.3).clamp(5.0, 130.0), // Scale height
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Toxicity bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 12,
                    height: (toxicityVal * 1.3).clamp(5.0, 130.0), // Scale height
                    decoration: BoxDecoration(
                      color: AppTheme.severityEmergency,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dayLabel,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildDayTimelineCard(Map<String, dynamic> dayMap) {
    final healthVal = dayMap['health'];
    final toxicityVal = dayMap['side_effects'];
    final dayLabel = dayMap['day'];
    final description = dayMap['description'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.background,
            child: Text(
              dayLabel.replaceAll('Day ', ''),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Forecast logs: $dayLabel',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      'HP: $healthVal%  Side: $toxicityVal%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppTheme.textDark, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
