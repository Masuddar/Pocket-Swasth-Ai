import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';
import 'verify_screen.dart';
import 'doctors_screen.dart';
import 'profile_screen.dart';
import 'doctor_console_screen.dart';
import 'sos_screen.dart';
import '../core/theme/app_theme.dart';
import '../providers/mode_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/navbar/custom_bottom_nav.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  bool _isShortcutDrawerOpen = false; // Collapsed by default

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ChatScreen(onNavigateToTab: _navigateToTab),
      VerifyScreen(onNavigateToTab: _navigateToTab),
      const DoctorsScreen(),
      const ProfileScreen(),
    ];
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);

    // If active in clinical Doctor Mode, bypass normal patient tabs and show Doctor Portal directly
    if (modeProvider.isDoctorMode) {
      return const DoctorConsoleScreen();
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // --- COLLAPSIBLE SLIDER PANEL (SLEEK, TINY & Ergonomic) ---
          Positioned(
            right: 0,
            bottom: 145, // Adjusted slightly lower to sit perfectly above the chat bottom controls
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Minimal Trigger Tab (Premium, Highly Visible Teal Handle)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isShortcutDrawerOpen = !_isShortcutDrawerOpen;
                    });
                  },
                  child: Container(
                    width: 32, // Sleek minimalistic width
                    height: 60, // MATCHES THE SIDEBAR HEIGHT EXACTLY
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryTeal.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(-2, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isShortcutDrawerOpen ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Tiny Collapsible Animated Container Drawer Body
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  width: _isShortcutDrawerOpen ? 174 : 0, // Extremely small and slim
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0).withOpacity(_isShortcutDrawerOpen ? 1.0 : 0.0), 
                      width: 1
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(_isShortcutDrawerOpen ? 0.06 : 0.0),
                        blurRadius: 8,
                        offset: const Offset(-2, 2),
                      )
                    ],
                  ),
                  child: _isShortcutDrawerOpen
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: [
                               // Shortcut 1: Teal Scan Document (Tab 1)
                              _buildShortcutItem(
                                icon: Icons.document_scanner_outlined,
                                iconColor: AppTheme.primaryTeal,
                                bgColor: AppTheme.primaryLightTeal.withOpacity(0.12),
                                borderCol: AppTheme.primaryTeal.withOpacity(0.2),
                                isSquircle: false,
                                label: 'Scan',
                                onTap: () {
                                  _navigateToTab(1);
                                  setState(() => _isShortcutDrawerOpen = false);
                                },
                              ),
                              const SizedBox(width: 6),

                              // Shortcut 2: Purple bot head inside squircle (Tab 0)
                              _buildShortcutItem(
                                icon: Icons.smart_toy_rounded,
                                iconColor: const Color(0xFF6B4EE6),
                                bgColor: const Color(0xFFECEBFC),
                                borderCol: const Color(0xFF6B4EE6).withOpacity(0.1),
                                isSquircle: true,
                                label: 'AI Agent',
                                onTap: () {
                                  Provider.of<ModeProvider>(context, listen: false).setDiagnosisMode(true);
                                  
                                  final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                                  chatProvider.clearAccumulatedSymptoms();
                                  chatProvider.addSystemAiMessage(
                                    "🤖 **Swasth AI Agent Activated**\n\n"
                                    "I am ready to perform a clinical-grade medical triage assessment using free Cloud AI models.\n\n"
                                    "Please describe your active symptoms (e.g., *'I have a crushing chest pain'* or *'I have a sore throat'*)."
                                  );

                                  _navigateToTab(0);
                                  setState(() => _isShortcutDrawerOpen = false);
                                },
                              ),
                              const SizedBox(width: 6),

                              // Shortcut 3: Red Asterisk / Medical SOS Icon
                              _buildShortcutItem(
                                icon: Icons.emergency_rounded,
                                iconColor: const Color(0xFFEF4444),
                                bgColor: const Color(0xFFFEE2E2),
                                borderCol: const Color(0xFFEF4444).withOpacity(0.1),
                                isSquircle: false,
                                label: 'SOS',
                                onTap: () {
                                  setState(() => _isShortcutDrawerOpen = false);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SosScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateToTab,
      ),
    );
  }

  Widget _buildShortcutItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderCol,
    required bool isSquircle,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: 50, // Beautiful horizontal boundary
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, // Sleek circular background
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(isSquircle ? 8 : 18),
                  border: Border.all(color: borderCol, width: 1.0),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20, // Increased icon size for high clarity
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.secondaryBlue,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
