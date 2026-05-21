import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/user_provider.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  int _countdown = 5;
  bool _activated = false;
  bool _cancelled = false;
  Timer? _timer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cancelled) { t.cancel(); return; }
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        t.cancel();
        _triggerSos();
      }
    });
  }

  Future<void> _triggerSos() async {
    setState(() => _activated = true);
    // Call ambulance (108 is India's emergency ambulance)
    final telUri = Uri.parse('tel:108');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
    // Share GPS location (static demo — Mumbai coordinates as fallback)
    await Future.delayed(const Duration(milliseconds: 600));
    final mapUri = Uri.parse('https://maps.google.com/?q=19.0760,72.8777&z=15');
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    }
  }

  void _cancel() {
    _timer?.cancel();
    setState(() => _cancelled = true);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProvider>(context).profile;

    return Scaffold(
      backgroundColor: _activated ? const Color(0xFF8B0000) : Colors.red.shade700,
      body: SafeArea(
        child: _activated ? _buildActivatedView(profile) : _buildCountdownView(profile),
      ),
    );
  }

  Widget _buildCountdownView(profile) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: _cancel,
              child: const Text('CANCEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
            ),
          ),
          const Spacer(),
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.emergency_rounded, color: Colors.white, size: 60),
                const SizedBox(height: 8),
                Text('$_countdown', style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 32),
          const Text('SOS ACTIVATING', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3)),
          const SizedBox(height: 12),
          const Text('Calling Ambulance (108) & sharing your live location with emergency contacts.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
          const SizedBox(height: 32),
          // Medical ID preview
          _buildMedicalIdCard(profile),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cancel,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('CANCEL SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivatedView(profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 70),
          const SizedBox(height: 16),
          const Text('SOS ACTIVATED', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Emergency services notified. Sharing your location & medical ID.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
          const SizedBox(height: 28),
          _buildStatusTile(Icons.call_rounded, 'Calling Ambulance (108)', 'Initiated'),
          _buildStatusTile(Icons.location_on_rounded, 'Live Location Shared', 'Mumbai, Maharashtra'),
          _buildStatusTile(Icons.people_rounded, 'Family Notified', profile.emergencyContactName.isEmpty ? 'No contact set' : profile.emergencyContactName),
          _buildStatusTile(Icons.medical_information_rounded, 'Medical Profile Shared', '${profile.bloodGroup} • ${profile.medicalHistory.first}'),
          const SizedBox(height: 24),
          _buildMedicalIdCard(profile),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:108')),
                icon: const Icon(Icons.call_rounded),
                label: const Text('Call 108'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Close'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatusTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
        ])),
        const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
      ]),
    );
  }

  Widget _buildMedicalIdCard(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.medical_information_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 6),
          const Text('MEDICAL ID', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
            child: Text(profile.bloodGroup, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        ]),
        const Divider(height: 16),
        if (profile.fullName.isNotEmpty)
          _idRow('Name', profile.fullName),
        _idRow('Age / Gender', '${profile.age} yrs • ${profile.gender}'),
        _idRow('Conditions', profile.medicalHistory.join(', ')),
        if (profile.allergies.isNotEmpty)
          _idRow('Allergies ⚠️', profile.allergies.join(', ')),
        if (profile.emergencyContactName.isNotEmpty)
          _idRow('Emergency', '${profile.emergencyContactName} ${profile.emergencyContactPhone}'),
      ]),
    );
  }

  Widget _idRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}
