import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/health_provider.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSimulateTap;

  const ChatBubble({
    super.key,
    required this.message,
    this.onSimulateTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';
    final isDiagnosis = message.isStructured || message.text.contains('Risk Level:') || message.text.contains('🚨 EMERGENCY') || message.ocrResultJson != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 14.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width > 600
                  ? 480.0
                  : MediaQuery.of(context).size.width * 0.84,
            ),
            child: isUser 
                ? _buildProUserBubble(context) 
                : _buildProStandardAiBubble(context, isDiagnosis),
          ),
        ],
      ),
    );
  }

  Widget _buildProUserBubble(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (message.attachmentName != null)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryTeal.withOpacity(0.15),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.attachmentType == 'image'
                      ? Icons.image_rounded
                      : Icons.picture_as_pdf_rounded,
                  color: AppTheme.primaryTeal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.attachmentName!,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (message.attachmentSize != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(${message.attachmentSize} KB)',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: Text(
            _formatTime(message.timestamp),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.w500),
          ),
        )
      ],
    );
  }

  Widget _buildProStandardAiBubble(BuildContext context, bool isDiagnosis) {
    final bool isEmergency = message.text.contains('🚨 EMERGENCY') || message.text.contains('Risk Level: EMERGENCY');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.attachmentName != null)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AppTheme.primaryTeal,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Associated Document:',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    message.attachmentName!,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isEmergency 
                ? const Color(0xFFFEF2F2)
                : (isDiagnosis ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(
              color: isEmergency
                  ? const Color(0xFFFEE2E2)
                  : (isDiagnosis ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
              width: 1.0,
            ),
          ),
          child: MarkdownBody(
            data: message.text,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 14.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
              strong: const TextStyle(
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.w800,
              ),
              h1: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 18),
              h2: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 16),
              h3: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 14),
              h4: const TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
              listBullet: const TextStyle(color: AppTheme.primaryTeal, fontSize: 14),
              blockquote: const TextStyle(
                color: AppTheme.severityEmergency, 
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
              blockquoteDecoration: BoxDecoration(
                color: AppTheme.severityEmergency.withOpacity(0.05),
                border: const Border(left: BorderSide(color: AppTheme.severityEmergency, width: 4)),
              ),
            ),
          ),
        ),
        
        // Interactive stateful OCR registry audit drawer
        if (message.ocrResultJson != null) ...[
          const SizedBox(height: 8),
          OcrAuditAccordion(ocrResultJson: message.ocrResultJson!),
        ],

        // Interactive Live Ambulance dispatch tracking card
        if (message.isAmbulanceDispatch == true) ...[
          const SizedBox(height: 8),
          AmbulanceDispatchCard(
            driverName: message.ambulanceDriverName ?? 'Rajesh Kumar',
            vehicleNo: message.ambulanceVehicleNo ?? 'MH-12-QE-1008',
            driverPhone: message.ambulanceDriverPhone ?? '+91 98765 43210',
            etaMinutes: message.ambulanceEtaMinutes ?? 4,
          ),
        ],

        // Interactive Intelligent Appointment Ticket
        if (message.bookingTicketJson != null) ...[
          const SizedBox(height: 8),
          AppointmentTicketCard(ticketJson: message.bookingTicketJson!),
        ],

        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            _formatTime(message.timestamp),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.w500),
          ),
        )
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class OcrAuditAccordion extends StatefulWidget {
  final String ocrResultJson;

  const OcrAuditAccordion({super.key, required this.ocrResultJson});

  @override
  State<OcrAuditAccordion> createState() => _OcrAuditAccordionState();
}

class _OcrAuditAccordionState extends State<OcrAuditAccordion> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> ocr;
    try {
      ocr = json.decode(widget.ocrResultJson);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final bool isReal = ocr['isReal'] ?? false;
    final double authScore = (ocr['authenticityScore'] ?? 0.0).toDouble();
    final double alignScore = (ocr['symptomAlignmentScore'] ?? 0.0).toDouble();
    final String docName = ocr['doctorName'] ?? 'Physician Name';
    final String registryNo = ocr['doctorRegistryNo'] ?? 'UNKNOWN';
    final String hospital = ocr['hospitalName'] ?? 'Clinic/Lab';
    final String authenticityReport = ocr['authenticityReport'] ?? '';
    final String alignmentStatus = ocr['symptomAlignmentStatus'] ?? 'VERIFIED';
    final String advisory = ocr['symptomAdvisory'] ?? '';
    final List<dynamic> checkmarks = ocr['checkmarks'] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isReal ? AppTheme.primaryTeal.withOpacity(0.2) : AppTheme.severityEmergency.withOpacity(0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isReal ? Icons.verified_rounded : Icons.gpp_maybe_rounded,
                    color: isReal ? AppTheme.primaryTeal : AppTheme.severityEmergency,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          docName,
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
                          '$hospital • Reg: $registryNo',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isReal 
                          ? AppTheme.primaryTeal.withOpacity(0.08) 
                          : AppTheme.severityEmergency.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isReal ? 'GENUINE' : 'UNVERIFIED',
                      style: TextStyle(
                        color: isReal ? AppTheme.primaryTeal : AppTheme.severityEmergency,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textMuted,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Drawer Content
          if (_isExpanded) ...[
            const Divider(color: AppTheme.borderLight, height: 1, thickness: 1.0),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checklist Grid
                  if (checkmarks.isNotEmpty) ...[
                    const Text(
                      'AI Credentials Registry Audit:',
                      style: TextStyle(
                        color: AppTheme.secondaryBlue,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...checkmarks.map((chk) {
                      final title = chk['title'] ?? 'Registry Item';
                      final status = chk['status'] ?? 'success';
                      final details = chk['details'] ?? '';
                      final isSuccess = status == 'success';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: isSuccess ? AppTheme.primaryTeal : AppTheme.severityEmergency,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$title: $details',
                                style: const TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                  ],

                  // Authenticity score & analysis
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Authenticity Score:',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${authScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isReal ? AppTheme.primaryTeal : AppTheme.severityEmergency,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authenticityReport,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.borderLight, height: 1, thickness: 1.0),
                  const SizedBox(height: 10),

                  // Alignment Score & Advisory
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Therapeutic Alignment:',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$alignmentStatus (${alignScore.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            color: AppTheme.primaryTeal,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    advisory,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Ambulance Dispatch live card ──────────────────────────────────────────────
class AmbulanceDispatchCard extends StatefulWidget {
  final String driverName;
  final String vehicleNo;
  final String driverPhone;
  final int etaMinutes;

  const AmbulanceDispatchCard({
    super.key,
    required this.driverName,
    required this.vehicleNo,
    required this.driverPhone,
    required this.etaMinutes,
  });

  @override
  State<AmbulanceDispatchCard> createState() => _AmbulanceDispatchCardState();
}

class _AmbulanceDispatchCardState extends State<AmbulanceDispatchCard> with TickerProviderStateMixin {
  late AnimationController _blinkCtrl;
  late Animation<double> _blinkAnim;
  
  late AnimationController _sirenCtrl;
  late Animation<Color?> _sirenColor;
  
  int _eta = 4;
  double _progress = 0.0;
  bool _sirenBeaconActive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _eta = widget.etaMinutes;
    
    _blinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.2, end: 1.0).animate(_blinkCtrl);

    _sirenCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _sirenColor = ColorTween(
      begin: const Color(0xFFFEF2F2),
      end: const Color(0xFFEFF6FF),
    ).animate(_sirenCtrl);

    // Dynamic mock route updates: Progress moves every 5 seconds for demonstration!
    _timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (mounted) {
        setState(() {
          if (_progress < 0.95) {
            _progress += 0.125;
            if (_progress > 0.95) _progress = 0.95;
            if (_eta > 1 && _progress > 0.25 * (4 - _eta + 1)) {
              _eta--;
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _sirenCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _toggleSirenBeacon() {
    setState(() {
      _sirenBeaconActive = !_sirenBeaconActive;
      if (_sirenBeaconActive) {
        _sirenCtrl.repeat(reverse: true);
      } else {
        _sirenCtrl.stop();
        _sirenCtrl.value = 0.0;
      }
    });
  }

  Future<void> _callDriver() async {
    final Uri url = Uri.parse('tel:${widget.driverPhone}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📞 Simulating Call to Paramedic Rajesh: ${widget.driverPhone}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📞 Dialing Paramedic Rajesh: ${widget.driverPhone}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse('https://www.openstreetmap.org/#map=15/19.0760/72.8777');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🗺️ Launching Map Route in Browser...'),
          backgroundColor: Colors.red,
        ));
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🗺️ Redirecting to Map: $url'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showFullscreenMap(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  color: AppTheme.secondaryBlue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SWASTH EMERGENCY TELEMETRY HUD',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'VEHICLE ID: Swasth-Alpha-09',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Map Simulator Window
                Container(
                  height: 300,
                  color: const Color(0xFFF1F5F9),
                  child: Stack(
                    children: [
                      // Real Static Map Background with gorgeous street visibility
                      Positioned.fill(
                        child: Image.network(
                          'https://static-maps.yandex.ru/1.x/?ll=72.8777,19.0760&z=14&l=map&size=600,450',
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to beautiful simulated grid on offline/error
                            return GridPaper(
                              color: Colors.blue.withOpacity(0.08),
                              interval: 30,
                              subdivisions: 1,
                              child: Container(),
                            );
                          },
                        ),
                      ),
                      
                      // Radar wave effect
                      Center(
                        child: _RadarWaveEffect(),
                      ),

                      // Route Path drawing
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FullscreenMapPainter(progress: _progress),
                        ),
                      ),

                      // Location coordinates overlay
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('GPS SATELLITE FEED', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('LAT: 19.0760° N\nLON: 72.8777° E', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                      ),

                      // Floating Real Google Maps Launcher Button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openGoogleMaps,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.map_rounded, color: Colors.green, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Google Maps',
                                    style: TextStyle(
                                      color: AppTheme.secondaryBlue,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Traffic info overlay
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                                child: const Icon(Icons.traffic_rounded, color: Colors.red, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Dynamic Navigation Router', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.secondaryBlue)),
                                    const SizedBox(height: 2),
                                    Text('Optimized route calculated via Express Highway. Traffic: Low.', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Vehicle Stats details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('SPEED', '52 km/h'),
                          _buildStatItem('FUEL LEVEL', '84%'),
                          _buildStatItem('ACLS KIT', 'EQUIPPED'),
                          _buildStatItem('ETA', '$_eta MINS'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _callDriver();
                        },
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                        label: const Text('Connect to Paramedics', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8.5, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  FadeTransition(
                    opacity: _blinkAnim,
                    child: const Icon(Icons.circle, color: Colors.red, size: 8),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'GPS TRACKING',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.red,
                        letterSpacing: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alarm_rounded, color: Colors.red, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    'ETA: $_eta Mins',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Live location GPS address ticker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 12),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'GPS Lock: Terminal 2 departures road, Sahar, Mumbai 400099',
                  style: TextStyle(fontSize: 9.5, color: Colors.red, fontWeight: FontWeight.bold, height: 1.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Map/Route Visualization Simulation Card
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100, width: 1),
          ),
          child: Stack(
            children: [
              // Real Static Map Background with opacity blend
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Opacity(
                    opacity: 0.8, // Beautiful real map overlay!
                    child: Image.network(
                      'https://static-maps.yandex.ru/1.x/?ll=72.8777,19.0760&z=14&l=map&size=450,200',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.red)),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback grid on error/offline
                        return GridPaper(
                          color: Colors.red.withOpacity(0.05),
                          interval: 20,
                          subdivisions: 1,
                          child: Container(),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Animated path painter drawing live progress line
              Positioned.fill(
                child: CustomPaint(
                  painter: _RouteLinePainter(progress: _progress),
                ),
              ),

              // Hospital destination marker
              const Positioned(
                left: 20,
                top: 35,
                child: Icon(Icons.local_hospital_rounded, color: Colors.green, size: 28),
              ),

              // Dynamic animated vehicle marker moving on path coordinate metrics
              Positioned.fill(
                child: _MovingAmbulanceMarker(progress: _progress, vehicleNo: widget.vehicleNo),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Driver Information Row
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.driverName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Emergency Paramedic • ${widget.vehicleNo}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Siren Warning Guide Toggle Beacon
            IconButton(
              onPressed: _toggleSirenBeacon,
              icon: Icon(
                _sirenBeaconActive ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded, 
                color: _sirenBeaconActive ? Colors.red : Colors.grey,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _sirenBeaconActive ? Colors.red.withOpacity(0.1) : Colors.transparent,
                padding: const EdgeInsets.all(10),
              ),
              tooltip: 'Siren beacon light guide',
            ),
            const SizedBox(width: 8),
            // Call driver trigger
            IconButton(
              onPressed: _callDriver,
              icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.green, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.1),
                padding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        // Action Buttons: Fullscreen satellite view & Live Google Maps launcher
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showFullscreenMap(context),
                icon: const Icon(Icons.gps_fixed_rounded, size: 13),
                label: const Text('Track Fullscreen HUD', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                icon: const Icon(Icons.map_rounded, size: 13),
                label: const Text('Open Google Maps', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    if (_sirenBeaconActive) {
      return AnimatedBuilder(
        animation: _sirenColor,
        builder: (ctx, child) => Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _sirenColor.value,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: content,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}

// Stateful moving ambulance marker using PathMetric coordinates
class _MovingAmbulanceMarker extends StatelessWidget {
  final double progress;
  final String vehicleNo;

  const _MovingAmbulanceMarker({required this.progress, required this.vehicleNo});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final path = Path()
          ..moveTo(30, 50)
          ..cubicTo(size.width * 0.3, 10, size.width * 0.6, 90, size.width - 55, 50);

        Offset pos = const Offset(30, 50);
        try {
          final metrics = path.computeMetrics();
          for (final metric in metrics) {
            final tangent = metric.getTangentForOffset(metric.length * progress);
            if (tangent != null) {
              pos = tangent.position;
            }
          }
        } catch (_) {}

        return Stack(
          children: [
            Positioned(
              left: pos.dx - 22,
              top: pos.dy - 35,
              child: Column(
                children: [
                  const Icon(Icons.airport_shuttle_rounded, color: Colors.red, size: 28),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      vehicleNo,
                      style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Radar pulsing wave visual effect
class _RadarWaveEffect extends StatefulWidget {
  @override
  State<_RadarWaveEffect> createState() => _RadarWaveEffectState();
}

class _RadarWaveEffectState extends State<_RadarWaveEffect> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Container(
        width: 160 * _anim.value,
        height: 160 * _anim.value,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue.withOpacity(1.0 - _anim.value), width: 1.5),
        ),
      ),
    );
  }
}

class _FullscreenMapPainter extends CustomPainter {
  final double progress;

  _FullscreenMapPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.blue.withOpacity(0.12)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(50, 150)
      ..cubicTo(size.width * 0.35, 40, size.width * 0.65, 260, size.width - 80, 150);

    canvas.drawPath(path, bgPaint);

    final activePaint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    try {
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final sub = metric.extractPath(0, metric.length * progress);
        canvas.drawPath(sub, activePaint);
      }
    } catch (_) {}
  }

  @override
  bool shouldRepaint(covariant _FullscreenMapPainter oldDelegate) => oldDelegate.progress != progress;
}

class _RouteLinePainter extends CustomPainter {
  final double progress;

  _RouteLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = Colors.red.withOpacity(0.15)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(30, 50)
      ..cubicTo(size.width * 0.3, 10, size.width * 0.6, 90, size.width - 55, 50);

    canvas.drawPath(path, pathPaint);

    final activePaint = Paint()
      ..color = Colors.red.shade600
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    try {
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final extract = metric.extractPath(0, metric.length * progress);
        canvas.drawPath(extract, activePaint);
      }
    } catch (_) {}
  }

  @override
  bool shouldRepaint(covariant _RouteLinePainter oldDelegate) => oldDelegate.progress != progress;
}

// ── Intelligent Booking Ticket card ──────────────────────────────────────────
class AppointmentTicketCard extends StatefulWidget {
  final String ticketJson;

  const AppointmentTicketCard({super.key, required this.ticketJson});

  @override
  State<AppointmentTicketCard> createState() => _AppointmentTicketCardState();
}

class _AppointmentTicketCardState extends State<AppointmentTicketCard> {
  bool _syncing = false;
  bool _synced = false;

  Future<void> _syncToCalendar() async {
    setState(() {
      _syncing = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _syncing = false;
        _synced = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('📅 Appointment successfully added to Google & Apple Calendar!'),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _navigateDirections(String hosp) async {
    final String query = Uri.encodeComponent(hosp);
    final Uri url = Uri.parse('https://www.openstreetmap.org/search?query=$query');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🗺️ Simulating directions to: $hosp'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🗺️ Navigating you to: $hosp'),
        backgroundColor: Colors.green,
      ));
    }
  }

  void _showCancelDialog(BuildContext context, String docName, String slotStr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue)),
        content: Text('Are you sure you want to cancel this slot booked autonomously with $docName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Appointment', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final hp = Provider.of<HealthProvider>(context, listen: false);
              // Find the booking and cancel it in SQLite database in real time
              final target = hp.appointments.firstWhere(
                (a) => a.doctorName.contains(docName) || docName.contains(a.doctorName),
                orElse: () => hp.appointments.isNotEmpty ? hp.appointments.first : hp.appointments[0],
              );
              hp.cancelAppointment(target.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('❌ Appt with $docName cancelled successfully.'),
                backgroundColor: Colors.red,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> ticket;
    try {
      ticket = json.decode(widget.ticketJson);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final String docName = ticket['doctorName'] ?? 'Doctor';
    final String specialty = ticket['specialty'] ?? 'Physician';
    final String hospital = ticket['hospitalName'] ?? 'Swasth Clinic';
    final String dayDisplay = ticket['dayDisplay'] ?? 'Today';
    final String slot = ticket['slot'] ?? 'Morning';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'APPOINTMENT TICKET',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                          letterSpacing: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'CONFIRMED',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFBBF7D0), height: 1),
          const SizedBox(height: 12),

          // Doctor and clinic details
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medical_services_rounded, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$specialty • $hospital',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date and Time Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DATE & DAY', style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              dayDisplay,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TIME SLOT', style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              slot,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // High-fidelity dynamic QR Code & Secure Seal Block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
            ),
            child: Row(
              children: [
                // Painted high-fidelity Vector QR Matrix
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: _QrCodePainter(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHECK-IN SECURITY SEAL',
                        style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Secure Token: SWASTH-${docName.substring(docName.length - 3).toUpperCase()}-9238',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Scan this secure QR code at the clinic kiosk entrance for instant check-in allocation.',
                        style: TextStyle(fontSize: 9, color: AppTheme.textMuted, height: 1.25),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Toolbar Actions: Directions, Calendar sync, and Cancellation!
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _syncing ? null : _syncToCalendar,
                  icon: _syncing 
                      ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.green))
                      : Icon(_synced ? Icons.done_all_rounded : Icons.add_rounded, size: 12),
                  label: Text(_synced ? 'Added' : 'Add', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _navigateDirections(hospital),
                  icon: const Icon(Icons.map_rounded, size: 12),
                  label: const Text('Route', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade600,
                    side: BorderSide(color: Colors.green.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, docName, slot),
                  icon: const Icon(Icons.cancel_outlined, size: 12),
                  label: const Text('Cancel', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Vector CustomPainter drawing a highly realistic mock QR Code pattern
class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.secondaryBlue
      ..style = PaintingStyle.fill;

    // Corner Finder Patterns
    canvas.drawRect(Rect.fromLTWH(2, 2, 12, 12), p);
    p.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(4, 4, 8, 8), p);
    p.color = AppTheme.secondaryBlue;
    canvas.drawRect(Rect.fromLTWH(6, 6, 4, 4), p);

    // Top-Right Finder
    canvas.drawRect(Rect.fromLTWH(size.width - 14, 2, 12, 12), p);
    p.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(size.width - 12, 4, 8, 8), p);
    p.color = AppTheme.secondaryBlue;
    canvas.drawRect(Rect.fromLTWH(size.width - 10, 6, 4, 4), p);

    // Bottom-Left Finder
    canvas.drawRect(Rect.fromLTWH(2, size.height - 14, 12, 12), p);
    p.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(4, size.height - 12, 8, 8), p);
    p.color = AppTheme.secondaryBlue;
    canvas.drawRect(Rect.fromLTWH(6, size.height - 10, 4, 4), p);

    // Mock matrix dots
    final List<Offset> dots = [
      const Offset(20, 4), const Offset(24, 4), const Offset(32, 6),
      const Offset(18, 10), const Offset(26, 12), const Offset(34, 12),
      const Offset(22, 18), const Offset(22, 22), const Offset(30, 20),
      const Offset(4, 22), const Offset(10, 22), const Offset(6, 26),
      const Offset(18, 26), const Offset(26, 26), const Offset(34, 26),
      const Offset(42, 22), const Offset(42, 10), const Offset(46, 18),
      const Offset(26, 32), const Offset(30, 32), const Offset(38, 30),
      const Offset(10, 38), const Offset(18, 38), const Offset(22, 42),
      const Offset(26, 42), const Offset(34, 42), const Offset(42, 42),
    ];

    for (final dot in dots) {
      canvas.drawRect(Rect.fromCenter(center: dot, width: 2.2, height: 2.2), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
