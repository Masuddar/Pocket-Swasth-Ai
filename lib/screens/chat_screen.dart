import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/mode_provider.dart';
import '../../providers/health_provider.dart';
import '../../models/chat_message.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';
import 'doctor_twin_screen.dart';
import 'sos_screen.dart';
import 'doctors_screen.dart';

class ChatScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const ChatScreen({super.key, this.onNavigateToTab});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _lastMessageCount = 0;
  GlobalKey? _latestAiMessageKey;
  GlobalKey? _latestUserMessageKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        _lastMessageCount = chatProvider.messages.length;
        chatProvider.addListener(_onChatProviderChanged);
        _scrollToLatestAiOrBottom();
      }
    });
  }

  @override
  void dispose() {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.removeListener(_onChatProviderChanged);
    } catch (_) {}
    _symptomController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatProviderChanged() {
    if (!mounted) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (chatProvider.messages.length > _lastMessageCount || chatProvider.isAnalyzing) {
      _lastMessageCount = chatProvider.messages.length;
      _scrollToLatestAiOrBottom();
    }
  }

  void _scrollToLatestAiOrBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      if (chatProvider.messages.isNotEmpty && chatProvider.messages.last.sender == 'ai') {
        // AI just replied! Focus the viewport on the user's last query bubble so both question and answer are perfectly visible!
        if (_latestUserMessageKey?.currentContext != null) {
          Scrollable.ensureVisible(
            _latestUserMessageKey!.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuad,
            alignment: 0.0, // Aligns top of user's query directly below the AppBar!
          );
          return;
        }
      }

      // Fallback for user typing, loading, or general bottom scroll
      if (_latestAiMessageKey?.currentContext != null) {
        Scrollable.ensureVisible(
          _latestAiMessageKey!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuad,
          alignment: 0.0,
        );
      } else if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _handleSend(
    ChatProvider chatProvider,
    UserProvider userProvider,
    ModeProvider modeProvider,
    HealthProvider healthProvider,
  ) {
    if (chatProvider.isAnalyzing) return; // Prevent double submits while field is active
    final text = _symptomController.text.trim();
    if (text.isEmpty) return;

    _symptomController.clear();
    chatProvider.sendMessage(
      text: text,
      profile: userProvider.profile,
      modeProvider: modeProvider,
      healthProvider: healthProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final healthProvider = Provider.of<HealthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: _buildHistoryDrawer(context, chatProvider, modeProvider),
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.04),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppTheme.secondaryBlue),
            tooltip: 'Open Chat History',
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Pocket Swasth AI',
          style: TextStyle(
            color: AppTheme.secondaryBlue,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          // Simplified Wifi Triage Mode Switcher
          IconButton(
            tooltip: modeProvider.forceOffline ? 'Switch to Cloud Mode' : 'Switch to Offline Mode',
            icon: Icon(
              modeProvider.forceOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              color: modeProvider.forceOffline ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
              size: 22,
            ),
            onPressed: () {
              final bool nextOffline = !modeProvider.forceOffline;
              modeProvider.toggleForceOffline();
              _showSafeNotification(
                context,
                nextOffline ? 'Switched to Local Mode (Offline).' : 'Switched to Cloud Mode (Online).',
              );
            },
          ),
          IconButton(
            tooltip: 'Clear Chat Log',
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textMuted),
            onPressed: () {
              _showClearConfirmDialog(context, chatProvider);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 2. Chat Conversation Viewport
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10.0),
                    itemCount: chatProvider.messages.length + (chatProvider.isAnalyzing ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatProvider.messages.length && chatProvider.isAnalyzing) {
                        return const TypingIndicator();
                      }
                      
                      final message = chatProvider.messages[index];
                      
                      final bool isLatestAi = index == chatProvider.messages.length - 1 && message.sender == 'ai';
                      if (isLatestAi) {
                        _latestAiMessageKey = GlobalKey();
                      }

                      bool isLatestUser = false;
                      if (message.sender == 'user') {
                        final lastUserIdx = chatProvider.messages.lastIndexWhere((m) => m.sender == 'user');
                        isLatestUser = index == lastUserIdx;
                        if (isLatestUser) {
                          _latestUserMessageKey = GlobalKey();
                        }
                      }

                      return ChatBubble(
                        key: isLatestAi 
                            ? _latestAiMessageKey 
                            : (isLatestUser ? _latestUserMessageKey : null),
                        message: message,
                        onSimulateTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DoctorTwinScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          
          // Dynamic Symptom Suggestion Chips
          if (chatProvider.messages.isNotEmpty && !chatProvider.isAnalyzing) ...[
            _buildSuggestionChipsRow(context, chatProvider, userProvider, modeProvider, healthProvider),
          ],
          
          // 3. Floating Input Cockpit
          _buildInputPanel(chatProvider, userProvider, modeProvider, healthProvider),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isOffline = status.toLowerCase().contains('offline');
    return Text(
      isOffline ? '🔴 Offline' : '🟢 Online',
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            // Glowing Stethoscope/Heart Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.12), width: 2),
              ),
              child: const Icon(
                Icons.medical_information_rounded,
                size: 64,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'How are you feeling today?',
              style: TextStyle(
                color: AppTheme.secondaryBlue,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Describe your symptoms below to begin a quick medical assessment.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            

            _buildSampleChipRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleChipRow() {
    final list = [
      {'label': 'Chest Pain ⚠️', 'text': 'I have sharp crushing chest pain and left arm numbness.'},
      {'label': 'Wet Cough 😷', 'text': 'I have a deep wet cough, thick phlegm, and high fever.'},
      {'label': 'Belly Cramps 🤢', 'text': 'I have vomiting, stomach cramps, and severe diarrhea.'},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Or select a common symptom to start:',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: list.map((item) {
            return InkWell(
              onTap: () {
                setState(() {
                  _symptomController.text = item['text']!;
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderLight, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.015),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  item['label']!,
                  style: const TextStyle(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputPanel(
    ChatProvider chatProvider,
    UserProvider userProvider,
    ModeProvider modeProvider,
    HealthProvider healthProvider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Integrated Control Toolbar
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 2, right: 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // Unified iOS-Style Segmented Mode Selector
                    Container(
                      height: 38,
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Normal Mode Segment
                          GestureDetector(
                            onTap: () {
                              if (modeProvider.isDiagnosisMode) {
                                modeProvider.toggleDiagnosisMode();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: !modeProvider.isDiagnosisMode ? AppTheme.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: !modeProvider.isDiagnosisMode ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  )
                                ] : [],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.forum_rounded,
                                    color: !modeProvider.isDiagnosisMode ? AppTheme.secondaryBlue : AppTheme.textMuted,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Normal Mode',
                                    style: TextStyle(
                                      color: !modeProvider.isDiagnosisMode ? AppTheme.secondaryBlue : AppTheme.textMuted,
                                      fontSize: 11.5,
                                      fontWeight: !modeProvider.isDiagnosisMode ? FontWeight.w900 : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Help Mode Segment
                          GestureDetector(
                            onTap: () {
                              if (!modeProvider.isDiagnosisMode) {
                                modeProvider.toggleDiagnosisMode();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: modeProvider.isDiagnosisMode ? AppTheme.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: modeProvider.isDiagnosisMode ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  )
                                ] : [],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.healing_rounded,
                                    color: modeProvider.isDiagnosisMode ? AppTheme.primaryTeal : AppTheme.textMuted,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Help Mode',
                                    style: TextStyle(
                                      color: modeProvider.isDiagnosisMode ? AppTheme.primaryTeal : AppTheme.textMuted,
                                      fontSize: 11.5,
                                      fontWeight: modeProvider.isDiagnosisMode ? FontWeight.w900 : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Premium Response Length Pill
                    GestureDetector(
                      onTap: () {
                        final lengths = ['SHORT', 'MEDIUM', 'LONG'];
                        final nextIdx = (lengths.indexOf(modeProvider.selectedLength) + 1) % lengths.length;
                        modeProvider.setSelectedLength(lengths[nextIdx]);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.primaryTeal.withOpacity(0.15),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.format_align_left_rounded,
                              size: 13,
                              color: AppTheme.primaryTeal,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              modeProvider.selectedLength,
                              style: const TextStyle(
                                color: AppTheme.primaryTeal,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
            const SizedBox(width: 8),
            
            // Premium Language Pill Dropdown
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryTeal.withOpacity(0.15),
                  width: 1.0,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: modeProvider.selectedLanguage,
                  icon: const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryTeal, size: 14),
                  ),
                  dropdownColor: AppTheme.white,
                  style: const TextStyle(
                    color: AppTheme.primaryTeal,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      modeProvider.setLanguage(newValue);
                    }
                  },
                  items: <String>['English', 'Hindi', 'Bengali', 'Spanish', 'French']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    
    // Floating Attachment Preview Tray
    if (chatProvider.selectedFileName != null)
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10.0, left: 2, right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.primaryTeal.withOpacity(0.15),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              chatProvider.selectedMimeType?.startsWith('image') == true
                  ? Icons.image_rounded
                  : Icons.picture_as_pdf_rounded,
              color: AppTheme.primaryTeal,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chatProvider.selectedFileName!,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${chatProvider.selectedFileSize} KB • Ready for Clinical Scan',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => chatProvider.clearSelectedAttachment(),
            ),
          ],
        ),
      ),

    Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.borderLight, width: 1.2),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                const SizedBox(width: 4),
                // Integrated Attach Button
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: AppTheme.primaryTeal, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Verify Medical Document',
                  onPressed: () => _showAttachmentOptions(context, chatProvider),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _symptomController,
                    textInputAction: TextInputAction.send,
                    enabled: true, // Keep enabled to prevent Flutter simulator keyboard focus drops
                    onSubmitted: (_) => _handleSend(chatProvider, userProvider, modeProvider, healthProvider),
                    style: const TextStyle(color: AppTheme.textDark, fontSize: 14.5, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Enter symptoms (e.g. wet cough, fever)...',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13.5, fontWeight: FontWeight.w600),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Premium Glowing Send Button
        GestureDetector(
          onTap: chatProvider.isAnalyzing 
              ? null 
              : () => _handleSend(chatProvider, userProvider, modeProvider, healthProvider),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryTeal, Color(0xFF0F766E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.send_rounded,
                color: AppTheme.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    ),
  ],
),
),
);
  }

  void _showAttachmentOptions(BuildContext context, ChatProvider chatProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify Medical Document',
              style: TextStyle(
                color: AppTheme.secondaryBlue,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload a prescription or lab report. Our AI Agent will extract registry data, clinical medicines, and audit authenticity.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument(chatProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderLight, width: 1.2),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryTeal, size: 32),
                          SizedBox(height: 10),
                          Text(
                            'Upload PDF/Image',
                            style: TextStyle(
                              color: AppTheme.primaryTeal,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _capturePhoto(chatProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderLight, width: 1.2),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded, color: AppTheme.secondaryBlue, size: 32),
                          SizedBox(height: 10),
                          Text(
                            'Take Photo',
                            style: TextStyle(
                              color: AppTheme.secondaryBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocument(ChatProvider chatProvider) async {
    try {
      final fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 1048576) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Max file size limit is 1MB. Please pick a smaller document.'),
                backgroundColor: AppTheme.severityEmergency,
              ),
            );
          }
          return;
        }

        final bytes = file.bytes;
        if (bytes != null) {
          final ext = file.extension?.toLowerCase() ?? 'jpg';
          String mime = 'image/jpeg';
          if (ext == 'pdf') mime = 'application/pdf';
          else if (ext == 'png') mime = 'image/png';

          chatProvider.selectAttachment(bytes, file.name, mime, file.size);
        }
      }
    } catch (e) {
      print('Attachment file picker error: $e');
    }
  }

  Future<void> _capturePhoto(ChatProvider chatProvider) async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final size = bytes.length;
        if (size > 1048576) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Max photo size limit is 1MB. Please try capturing with lower settings.'),
                backgroundColor: AppTheme.severityEmergency,
              ),
            );
          }
          return;
        }
        chatProvider.selectAttachment(bytes, image.name, 'image/jpeg', size);
      }
    } catch (e) {
      print('Attachment camera capture error: $e');
    }
  }

  void _showClearConfirmDialog(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Wipe Consultation Log?',
          style: TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: const Text(
          'This will permanently wipe all conversational history of this session from your local interface cache. Prescriptions and medical database records remain intact.',
          style: TextStyle(color: AppTheme.textDark, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.4),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text(
              'Clear Log',
              style: TextStyle(color: AppTheme.severityEmergency, fontWeight: FontWeight.w900),
            ),
            onPressed: () {
              chatProvider.clearHistory();
              Navigator.pop(ctx);
            },
          )
        ],
      ),
    );
  }

  Widget _buildSuggestionChipsRow(
    BuildContext context,
    ChatProvider chatProvider,
    UserProvider userProvider,
    ModeProvider modeProvider,
    HealthProvider healthProvider,
  ) {
    final latestMsg = chatProvider.messages.last;
    if (latestMsg.sender != 'ai' || latestMsg.suggestions == null || latestMsg.suggestions!.isEmpty) {
      return const SizedBox.shrink();
    }

    final suggestions = latestMsg.suggestions!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Text(
              "Quick Suggestions:",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryBlue.withOpacity(0.6),
                letterSpacing: 0.3,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: suggestions.map((symptom) {
                final bool isAction = symptom.contains('📋');
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      chatProvider.sendMessage(
                        text: symptom,
                        profile: userProvider.profile,
                        modeProvider: modeProvider,
                        healthProvider: healthProvider,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isAction
                            ? AppTheme.severityEmergency.withOpacity(0.1)
                            : AppTheme.secondaryBlue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAction
                              ? AppTheme.severityEmergency.withOpacity(0.3)
                              : AppTheme.secondaryBlue.withOpacity(0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAction) ...[
                            Icon(Icons.assignment_turned_in_rounded, size: 14, color: AppTheme.severityEmergency),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            symptom,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isAction ? FontWeight.bold : FontWeight.w500,
                              color: isAction ? AppTheme.severityEmergency : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(BuildContext context, ChatProvider chatProvider, ModeProvider modeProvider) {
    return Drawer(
      backgroundColor: AppTheme.white, // Ultra-clean premium white!
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clean Minimalist Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your History',
                    style: TextStyle(
                      color: AppTheme.secondaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 22),
                    tooltip: 'Close Sidebar',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(color: AppTheme.borderLight, height: 1),
          
          // Minimalist New Assessment Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () async {
                await chatProvider.clearHistory();
                Navigator.pop(context);
                _showSafeNotification(context, 'Started a fresh clinical session.');
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.15), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_rounded, color: AppTheme.primaryTeal, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'New Assessment',
                      style: TextStyle(
                        color: AppTheme.primaryTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Historical Chats List
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildHistoryItem(
                  context,
                  title: 'Chest Pain Triage',
                  date: 'Today',
                  urgencyColor: AppTheme.severityEmergency,
                  onTap: () {
                    _loadMockHistory(context, chatProvider, [
                      ChatMessage(
                        id: 'hist_1_1',
                        sender: 'user',
                        text: 'I am feeling sharp squeezing chest pain.',
                        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
                      ),
                      ChatMessage(
                        id: 'hist_1_2',
                        sender: 'ai',
                        text: '⚠️ CRITICAL MEDICAL ALERT: Sharp, squeezing chest pain can indicate a cardiac emergency.\n\nImmediate Actions Required:\n- Call emergency services (108 / 911) immediately.\n- Keep calm and sit upright.\n- Do not perform physical activity.',
                        timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
                        isStructured: true,
                        severity: 'Emergency',
                        possibleCondition: 'Cardiac Arrest Risk',
                      ),
                    ]);
                  },
                ),
                _buildHistoryItem(
                  context,
                  title: 'Wet Cough & Fever',
                  date: 'Yesterday',
                  urgencyColor: AppTheme.severityLow,
                  onTap: () {
                    _loadMockHistory(context, chatProvider, [
                      ChatMessage(
                        id: 'hist_2_1',
                        sender: 'user',
                        text: 'I have a heavy wet cough and mild fever.',
                        timestamp: DateTime.now().subtract(const Duration(days: 1)),
                      ),
                      ChatMessage(
                        id: 'hist_2_2',
                        sender: 'ai',
                        text: 'Based on your symptoms (wet cough, mild fever), it matches a Common Cold & Cough pattern.\n\nRecommended Home Care:\n- Stay well-hydrated with warm fluids.\n- Rest and avoid cold exposures.\n- Monitor your temperature closely.',
                        timestamp: DateTime.now().subtract(const Duration(days: 1)),
                        isStructured: true,
                        severity: 'Low',
                        possibleCondition: 'Common Cold & Cough',
                      ),
                    ]);
                  },
                ),
                _buildHistoryItem(
                  context,
                  title: 'Migraine Headache',
                  date: '16 May',
                  urgencyColor: AppTheme.severityLow,
                  onTap: () {
                    _loadMockHistory(context, chatProvider, [
                      ChatMessage(
                        id: 'hist_3_1',
                        sender: 'user',
                        text: 'I have a persistent throbbing headache.',
                        timestamp: DateTime.now().subtract(const Duration(days: 2)),
                      ),
                      ChatMessage(
                        id: 'hist_3_2',
                        sender: 'ai',
                        text: 'This corresponds to a Tension Headache or Migraine pattern.\n\nSupportive Actions:\n- Rest in a quiet, dark room.\n- Apply a cool compress to your forehead.\n- Reduce screen time immediately.',
                        timestamp: DateTime.now().subtract(const Duration(days: 2)),
                        isStructured: true,
                        severity: 'Low',
                        possibleCondition: 'Tension Headache',
                      ),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context, {
    required String title,
    required String date,
    required Color urgencyColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: AppTheme.background, // Slate-50 background for items
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight, width: 0.8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              // Minimal urgency status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: urgencyColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSafeNotification(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppTheme.primaryTeal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Simple compact padding
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 220, // Shifted a bit further downwards!
          left: 64,  // Centered, compact width - not big at all!
          right: 64,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Perfect curvy capsule
      ),
    );
  }

  void _loadMockHistory(BuildContext context, ChatProvider chatProvider, List<ChatMessage> mockMessages) async {
    await chatProvider.clearHistory();
    for (final msg in mockMessages) {
      chatProvider.messages.add(msg);
    }
    chatProvider.notifyListeners();
    Navigator.pop(context); // Close sidebar smoothly
    _showSafeNotification(context, 'Loaded past triage assessment history.');
  }

  // ── AI Booking Agent ──────────────────────────────────────────────────────
  void _showAiBookingAgent(BuildContext context) {
    final issueCtrl = TextEditingController();
    String? _matchedSpecialty;
    DoctorModel? _matchedDoctor;
    bool _searching = false;
    String _agentStatus = '';

    // Simple specialty matcher
    DoctorModel? _findBestDoctor(String issue) {
      final lower = issue.toLowerCase();
      String specialty = 'General Physician';
      if (lower.contains('heart') || lower.contains('chest') || lower.contains('cardiac')) specialty = 'Cardiologist';
      else if (lower.contains('skin') || lower.contains('rash') || lower.contains('acne')) specialty = 'Dermatologist';
      else if (lower.contains('bone') || lower.contains('joint') || lower.contains('knee') || lower.contains('back')) specialty = 'Orthopedic';
      else if (lower.contains('brain') || lower.contains('migraine') || lower.contains('neuro') || lower.contains('seizure')) specialty = 'Neurologist';
      else if (lower.contains('child') || lower.contains('baby') || lower.contains('infant') || lower.contains('kid')) specialty = 'Pediatrician';
      else if (lower.contains('stomach') || lower.contains('gastro') || lower.contains('ibs') || lower.contains('liver')) specialty = 'Gastroenterologist';
      else if (lower.contains('lung') || lower.contains('breath') || lower.contains('asthma') || lower.contains('tb')) specialty = 'Pulmonologist';
      else if (lower.contains('ear') || lower.contains('nose') || lower.contains('throat') || lower.contains('sinus')) specialty = 'ENT Specialist';
      
      return doctors.firstWhere((d) => d.specialty == specialty, orElse: () => doctors.first);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, top: 20, left: 20, right: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.deepPurple, size: 22)),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('🤖 AI Booking Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.deepPurple)),
                  Text('Describe your issue and I\'ll find the best doctor', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ])),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: issueCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. "I have severe chest pain and shortness of breath..."',
                  hintStyle: const TextStyle(fontSize: 12.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 14),
              if (_searching)
                const Center(child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(children: [
                    CircularProgressIndicator(color: Colors.deepPurple),
                    SizedBox(height: 10),
                    Text('Finding best available doctor...', style: TextStyle(color: Colors.deepPurple, fontSize: 13)),
                  ]),
                ))
              else if (_matchedDoctor != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.deepPurple.withOpacity(0.2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('✅ Best match for: $_matchedSpecialty', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(children: [
                      CircleAvatar(radius: 22, backgroundColor: Colors.deepPurple.withOpacity(0.1), child: Text(_matchedDoctor!.imageInitials, style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_matchedDoctor!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${_matchedDoctor!.hospital} • ${_matchedDoctor!.fee}', style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                        Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 13), Text(' ${_matchedDoctor!.rating} • ${_matchedDoctor!.experienceYears} yrs exp', style: const TextStyle(fontSize: 11))]),
                      ])),
                    ]),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showBookingSheet(context, _matchedDoctor!);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('📅 Book This Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ),
              ] else
                ElevatedButton.icon(
                  onPressed: () async {
                    if (issueCtrl.text.trim().isEmpty) return;
                    setS(() { _searching = true; });
                    await Future.delayed(const Duration(milliseconds: 1400));
                    final doc = _findBestDoctor(issueCtrl.text);
                    setS(() { _searching = false; _matchedDoctor = doc; _matchedSpecialty = doc?.specialty; });
                  },
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Find Best Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

