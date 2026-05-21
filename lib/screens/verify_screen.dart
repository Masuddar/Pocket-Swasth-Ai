import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/prescription.dart';
import '../../providers/health_provider.dart';
import '../../providers/chat_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/medical/prescription_ocr_service.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../widgets/cards/medical_card.dart';

class VerifyScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const VerifyScreen({super.key, this.onNavigateToTab});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  Prescription? _selectedMockRx;
  final List<Prescription> _mockList = Helpers.getMockPrescriptions();

  int _activeTab = 1; // 0 = Cabinet List, 1 = Verify/Scan Screen
  int _selectedTrack = 0; // 0 = Mode Selector, 1 = Compare Symptoms/Diagnosis, 2 = Verify Real/Fake
  int _resultTrackRun = 0; // 1 = Alignment results, 2 = Authenticity results

  // Real Uploaded File States (under 1MB)
  Uint8List? _uploadedFileBytes;
  String? _uploadedFileName;
  String? _uploadedMimeType;
  bool _isScanningReport = false;

  @override
  void initState() {
    super.initState();
    _selectedMockRx = _mockList.first;
    
    // Autofill symptoms from latest user message if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final userMessages = chatProvider.messages.where((m) => m.sender == 'user');
      if (userMessages.isNotEmpty) {
        setState(() {
          _symptomController.text = userMessages.last.text;
        });
      }
    });
  }

  Future<void> _pickDocument() async {
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
          setState(() {
            _uploadedFileBytes = bytes;
            _uploadedFileName = file.name;
            final ext = file.extension?.toLowerCase() ?? 'jpg';
            if (ext == 'pdf') {
              _uploadedMimeType = 'application/pdf';
            } else if (ext == 'png') {
              _uploadedMimeType = 'image/png';
            } else {
              _uploadedMimeType = 'image/jpeg';
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📄 Successfully loaded: "${file.name}" (${(file.size / 1024).toStringAsFixed(1)} KB)'),
                backgroundColor: AppTheme.primaryTeal,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('File Picker Exception: $e');
    }
  }

  Future<void> _capturePhoto() async {
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
                content: Text('⚠️ Max photo size limit is 1MB. Please try capturing again with lower settings.'),
                backgroundColor: AppTheme.severityEmergency,
              ),
            );
          }
          return;
        }

        setState(() {
          _uploadedFileBytes = bytes;
          _uploadedFileName = image.name;
          _uploadedMimeType = 'image/jpeg';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📸 Captured photo: "${image.name}" (${(size / 1024).toStringAsFixed(1)} KB)'),
              backgroundColor: AppTheme.primaryTeal,
            ),
          );
        }
      }
    } catch (e) {
      print('Camera Capture Exception: $e');
    }
  }

  Future<void> _pickSymptomTextFile() async {
    try {
      final fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          final content = utf8.decode(bytes);
          setState(() {
            _symptomController.text = content;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📄 Symptoms loaded from text file: "${file.name}"'),
                backgroundColor: AppTheme.primaryTeal,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Symptom text file picker error: $e');
    }
  }

  Future<void> _pickReportPdfFile() async {
    try {
      final fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        
        if (file.size > 1048576) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Max file size limit is 1MB. Please pick a smaller lab report PDF.'),
                backgroundColor: AppTheme.severityEmergency,
              ),
            );
          }
          return;
        }

        if (bytes != null) {
          setState(() {
            _isScanningReport = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🧬 Scanning lab report: "${file.name}" via Gemini API...'),
                backgroundColor: AppTheme.primaryTeal,
              ),
            );
          }

          final ext = file.extension?.toLowerCase() ?? 'pdf';
          final mimeType = (ext == 'pdf') ? 'application/pdf' : 'image/jpeg';
          
          final base64Data = base64Encode(bytes);
          final prompt = """
You are an expert AI clinical report analyst.
Analyze the provided medical lab report / diagnostic report and extract the primary clinical diagnosis, finding, or patient condition.
Provide a concise, clear diagnosis description (maximum 4-5 words).

You MUST respond strictly in the following JSON format:
{
  "diagnosis": "concise extracted diagnosis/condition"
}
Ensure the output is valid raw JSON only.
""";

          final response = await http.post(
            Uri.parse('${PrescriptionOcrService.geminiApiUrl}?key=${PrescriptionOcrService.geminiApiKey}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {
                      'inlineData': {
                        'mimeType': mimeType,
                        'data': base64Data,
                      }
                    }
                  ]
                }
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
              }
            }),
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final decoded = json.decode(response.body);
            final rawJson = decoded['candidates'][0]['content']['parts'][0]['text'] as String;
            
            String cleanedJson = rawJson.trim();
            if (cleanedJson.startsWith('```')) {
              cleanedJson = cleanedJson.replaceFirst(RegExp(r'^```(json)?'), '');
              cleanedJson = cleanedJson.replaceFirst(RegExp(r'```$'), '');
              cleanedJson = cleanedJson.trim();
            }

            final parsed = json.decode(cleanedJson);
            final extractedDiagnosis = parsed['diagnosis'] as String;

            setState(() {
              _diagnosisController.text = extractedDiagnosis;
              _isScanningReport = false;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✨ Lab report scanned! Auto-filled Diagnosis: "$extractedDiagnosis"'),
                  backgroundColor: AppTheme.primaryTeal,
                ),
              );
            }
          } else {
            throw Exception('HTTP ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      setState(() {
        _isScanningReport = false;
      });
      print('Report PDF scanning error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Lab report scan failed: $e'),
            backgroundColor: AppTheme.severityEmergency,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  // Prefill Example Presets for Instant UI Demonstrations
  void _applyPreset({
    required String symptoms,
    required String diagnosis,
    required String rxId,
  }) {
    setState(() {
      _symptomController.text = symptoms;
      _diagnosisController.text = diagnosis;
      _selectedMockRx = _mockList.firstWhere((element) => element.id == rxId, orElse: () => _mockList.first);
    });
  }

  void _triggerAlignmentScan(HealthProvider healthProvider) {
    final symptoms = _symptomController.text.trim();
    final diagnosis = _diagnosisController.text.trim();
    
    if (symptoms.isEmpty || diagnosis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter symptoms and active diagnosis to compare alignment.'),
          backgroundColor: AppTheme.severityEmergency,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _resultTrackRun = 1;
    });

    if (_uploadedFileBytes != null) {
      healthProvider.runRealApiVerification(
        fileBytes: _uploadedFileBytes!,
        mimeType: _uploadedMimeType ?? 'image/jpeg',
        symptoms: symptoms,
        diagnosis: diagnosis,
      ).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Live AI scan failed: $e'),
              backgroundColor: AppTheme.severityEmergency,
            ),
          );
        }
      });
    } else if (_selectedMockRx != null) {
      final updatedRx = Prescription(
        id: _selectedMockRx!.id,
        date: _selectedMockRx!.date,
        patientName: _selectedMockRx!.patientName,
        medicines: _selectedMockRx!.medicines,
        diagnosis: diagnosis, // Dynamic symptom diagnosis override
        imageUrl: _selectedMockRx!.imageUrl,
        extractedText: _selectedMockRx!.extractedText,
        doctorName: _selectedMockRx!.doctorName,
        doctorRegistryNo: _selectedMockRx!.doctorRegistryNo,
        hospitalName: _selectedMockRx!.hospitalName,
        isReal: _selectedMockRx!.isReal,
        authenticityScore: _selectedMockRx!.authenticityScore,
        authenticityReport: _selectedMockRx!.authenticityReport,
      );
      healthProvider.runPrescriptionVerification(
        prescription: updatedRx,
        activeSymptoms: symptoms,
      );
    }
  }

  void _triggerAuthenticityScan(HealthProvider healthProvider) {
    FocusScope.of(context).unfocus();
    setState(() {
      _resultTrackRun = _selectedTrack;
    });

    if (_uploadedFileBytes != null) {
      healthProvider.runRealApiVerification(
        fileBytes: _uploadedFileBytes!,
        mimeType: _uploadedMimeType ?? 'image/jpeg',
        symptoms: _symptomController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
      ).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Live AI scan failed: $e'),
              backgroundColor: AppTheme.severityEmergency,
            ),
          );
        }
      });
    } else if (_selectedMockRx != null) {
      healthProvider.runPrescriptionVerification(
        prescription: _selectedMockRx!,
        activeSymptoms: _selectedMockRx!.diagnosis,
      );
    }
  }

  void _saveToCabinet(HealthProvider healthProvider) async {
    await healthProvider.saveCurrentPrescriptionToCabinet();
    
    if (mounted) {
      final isSuspicious = !(healthProvider.authenticityResult?['isReal'] ?? true);
      
      showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Icon(
              isSuspicious ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: isSuspicious ? AppTheme.severityMedium : AppTheme.severityLow,
              size: 56,
            ),
            title: Text(
              isSuspicious ? 'Reference Record Saved' : 'Cabinet Upload Complete',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
            ),
            content: Text(
              isSuspicious
                ? 'The document was saved to your cabinet. Note: It remains flagged as SUSPICIOUS due to registry discrepancies.'
                : 'Your medical record has been digitized and verified as GENUINE. Pocket Swasth AI is now fully synced with this record for future consultations!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  healthProvider.resetVerificationState();
                  setState(() {
                    _activeTab = 0;
                    _selectedTrack = 0;
                  });
                },
                child: const Text('View Stored Cabinet', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
      ),
      body: Column(
        children: [
          // iOS Glass Segmented Tabs (Verify New vs Cabinet)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.borderLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == 1 ? AppTheme.primaryTeal : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: _activeTab == 1
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryTeal.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.document_scanner_rounded,
                                size: 16,
                                color: _activeTab == 1 ? AppTheme.white : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Verify New Rx',
                                style: TextStyle(
                                  color: _activeTab == 1 ? AppTheme.white : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        healthProvider.resetVerificationState();
                        setState(() {
                          _activeTab = 0;
                          _selectedTrack = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTab == 0 ? AppTheme.primaryTeal : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: _activeTab == 0
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryTeal.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_shared_rounded,
                                size: 16,
                                color: _activeTab == 0 ? AppTheme.white : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cabinet (${healthProvider.savedPrescriptions.length})',
                                style: TextStyle(
                                  color: _activeTab == 0 ? AppTheme.white : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              physics: const BouncingScrollPhysics(),
              child: _activeTab == 0
                  ? _buildCabinetTab(healthProvider)
                  : _buildVerifyTab(healthProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabinetTab(HealthProvider healthProvider) {
    final prescriptions = healthProvider.savedPrescriptions;

    if (prescriptions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.borderLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_rounded, size: 64, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Medical Cabinet is Empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload and verify prescriptions in the "Verify New Rx" tab to save them securely on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _activeTab = 1),
              icon: const Icon(Icons.document_scanner_rounded, size: 18),
              label: const Text('Scan Prescription Now'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stats header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryTeal, AppTheme.accentCyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🗃️ Device Cabinet',
                    style: TextStyle(color: AppTheme.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${prescriptions.length} Records',
                      style: const TextStyle(color: AppTheme.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Prescriptions are stored safely offline on this device. AI chatbot is fully aware of these files to guide your future health consultations.',
                style: TextStyle(color: AppTheme.white, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _handleDirectCabinetUpload(healthProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.white,
                  foregroundColor: AppTheme.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  elevation: 0,
                ),
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: const Text(
                  '➕ Upload & Verify Medical Document',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI Health Cabinet Summary Panel
        _buildCabinetSummaryCard(healthProvider),
        const SizedBox(height: 16),

        // List of stored records
        ...prescriptions.map((rx) {
          final isSuspicious = !rx.isReal;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSuspicious ? AppTheme.severityEmergency.withOpacity(0.2) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                )
              ],
            ),
            padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSuspicious 
                              ? AppTheme.severityEmergency.withOpacity(0.1) 
                              : AppTheme.primaryLightTeal.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSuspicious ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                          color: isSuspicious ? AppTheme.severityEmergency : AppTheme.primaryTeal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    rx.diagnosis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppTheme.secondaryBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSuspicious 
                                        ? AppTheme.severityEmergency.withOpacity(0.12) 
                                        : AppTheme.severityLow.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isSuspicious ? '🚨 NOT REAL / SUSPICIOUS' : '✨ VERIFIED GENUINE',
                                    style: TextStyle(
                                      color: isSuspicious ? AppTheme.severityEmergency : AppTheme.severityLow,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient: ${rx.patientName} • Date: ${Helpers.formatDate(rx.date)}',
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.severityEmergency, size: 20),
                        onPressed: () {
                          healthProvider.deletePrescription(rx.id);
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.borderLight, height: 1),
                  const SizedBox(height: 12),

                  if (rx.doctorName.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Clinician: ${rx.doctorName} (${rx.doctorRegistryNo.isNotEmpty ? rx.doctorRegistryNo : "No License Registered"})',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (rx.hospitalName.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_outlined, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Facility: ${rx.hospitalName}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  const Text(
                    'EXTRACTED MEDICINES:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: rx.medicines.map((med) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: isSuspicious 
                              ? AppTheme.severityEmergency.withOpacity(0.05) 
                              : AppTheme.primaryLightTeal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSuspicious 
                              ? AppTheme.severityEmergency.withOpacity(0.15) 
                              : AppTheme.primaryTeal.withOpacity(0.15)
                          ),
                        ),
                        child: Text(
                          med.split(' ')[0],
                          style: TextStyle(
                            color: isSuspicious ? AppTheme.severityEmergency : AppTheme.primaryTeal,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
        }),
      ],
    );
  }

  Widget _buildVerifyTab(HealthProvider healthProvider) {
    if (healthProvider.isVerifying) {
      return _buildScanningOverlay(healthProvider);
    }
    
    if (healthProvider.verificationResult != null && healthProvider.authenticityResult != null) {
      return _buildResultDashboard(healthProvider);
    }

    if (_selectedTrack == 0) {
      return _buildModeSelectionMenu();
    }

    if (_selectedTrack == 1) {
      return _buildCompareSymptomsInputs(healthProvider);
    } else if (_selectedTrack == 2) {
      return _buildVerifyRealFakeInputs(healthProvider, isReport: false);
    } else {
      return _buildVerifyRealFakeInputs(healthProvider, isReport: true);
    }
  }

  // --- TRACK SELECTOR MENU (3 HUGE PRIMARY CALL-TO-ACTION CARDS) ---
  Widget _buildModeSelectionMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Select Verification Analysis Track:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: AppTheme.secondaryBlue,
            letterSpacing: 0.3
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pocket Swasth provides three distinct AI clinical safety audits for your medical records.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 24),

        // CARD 1: COMPARE SYMPTOMS ALIGNMENT
        GestureDetector(
          onTap: () => setState(() => _selectedTrack = 1),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryTeal.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightTeal.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics_rounded, color: AppTheme.primaryTeal, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '🧬 Compare Symptoms Alignment',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Compare Symptoms ➔ Diagnosis ➔ Prescriptions. Checks if the prescribed drugs match your active complaints or are a critical mismatch.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryTeal, size: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // CARD 2: VERIFY REAL OR FAKE PRESCRIPTION
        GestureDetector(
          onTap: () => setState(() => _selectedTrack = 2),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentCyan.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentCyan.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: AppTheme.accentCyan, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '🛡️ Verify Prescription Real/Fake',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Audit clinician registry licenses, signatures, clinic stamps, and issue dates against national medical databases.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.accentCyan, size: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // CARD 3: VERIFY REAL OR FAKE LAB REPORT (NEW)
        GestureDetector(
          onTap: () => setState(() => _selectedTrack = 3),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.science_rounded, color: Colors.deepPurple, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '🔬 Verify Medical Report Real/Fake',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Audit clinical lab sheets, blood tests, or diagnostic scans for digital manipulation, forged doctor seals, or registry inconsistencies.',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.deepPurple, size: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- SCANNING SIMULATION HUD ---
  Widget _buildScanningOverlay(HealthProvider healthProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 36.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryTeal, width: 2),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, size: 64, color: AppTheme.primaryTeal),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Positioned(
                      top: 10 + (160 * value),
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          boxShadow: [
                            BoxShadow(color: Colors.greenAccent.withOpacity(0.8), blurRadius: 10, spreadRadius: 2)
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(color: AppTheme.primaryTeal),
            const SizedBox(height: 16),
            Text(
              _resultTrackRun == 1 ? 'Comparing Drug Alignment...' : 'Checking Doctor Registry & Stamps...',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.secondaryBlue),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'AI OCR PROCESS LOGS:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: healthProvider.verificationLogs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      healthProvider.verificationLogs[index],
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11.5,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
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

  // --- REAL FILE UPLOADING AND CAPTURING CARD ---
  Widget _buildUploadZoneCard(HealthProvider healthProvider) {
    final hasFile = _uploadedFileBytes != null;
    return Container(
      decoration: BoxDecoration(
        color: hasFile ? AppTheme.primaryLightTeal.withOpacity(0.08) : AppTheme.primaryLightTeal.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile ? AppTheme.primaryTeal : AppTheme.primaryTeal.withOpacity(0.2), 
          style: BorderStyle.solid, 
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          if (hasFile) ...[
            const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal, size: 42),
            const SizedBox(height: 10),
            Text(
              _uploadedFileName ?? 'document.pdf',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Size: ${(_uploadedFileBytes!.length / 1024).toStringAsFixed(1)} KB (Ready for Gemini OCR scan)',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _uploadedFileBytes = null;
                      _uploadedFileName = null;
                      _uploadedMimeType = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.severityEmergency, size: 18),
                  label: const Text('Remove File', style: TextStyle(color: AppTheme.severityEmergency, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ] else ...[
            const Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryTeal, size: 40),
            const SizedBox(height: 10),
            const Text(
              'Upload Real Prescription (Under 1MB)',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Capture image or pick PDF to run real-time OCR checks',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryBlue,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.file_present_rounded, size: 16),
                    label: const Text('Pick PDF/Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _capturePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: const Text('Take Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  // --- INPUTS FOR TRACK 1: COMPARE SYMPTOMS ---
  Widget _buildCompareSymptomsInputs(HealthProvider healthProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.secondaryBlue),
              onPressed: () => setState(() => _selectedTrack = 0),
            ),
            const Text(
              'Compare Symptoms Alignment',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.secondaryBlue),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Preset Chips
        const Text(
          'Quick Demo Presets:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Text('🩺'),
              label: const Text('Kidney Stone (Mismatch Demo)'),
              onPressed: () {
                _applyPreset(
                  symptoms: 'Severe sharp radiating kidney pain, vomiting, burning urine',
                  diagnosis: 'Stone in Kidney',
                  rxId: 'rx_003', // Metformin diabetes Rx - will mismatch!
                );
              },
            ),
            ActionChip(
              avatar: const Text('🫁'),
              label: const Text('Bronchitis (Perfect Match)'),
              onPressed: () {
                _applyPreset(
                  symptoms: 'Deep wet chesty cough, fever, thick green mucus, breathlessness',
                  diagnosis: 'Bacterial Chest Infection / Bronchitis',
                  rxId: 'rx_001', // Amoxicillin Chest Rx - perfect alignment!
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        MedicalCard(
          title: 'Symptoms ➔ Diagnosis ➔ Prescription Comparator',
          icon: Icons.compare_arrows_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUploadZoneCard(healthProvider),
              const SizedBox(height: 18),
              
              const Text('1. Enter Symptoms:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryBlue)),
              const SizedBox(height: 6),
              TextField(
                controller: _symptomController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Kidney pain, nausea, blood in urine...',
                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _pickSymptomTextFile,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryTeal,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: const Text('Upload Symptoms .txt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              const Text('2. Enter Diagnosis/Report:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryBlue)),
              const SizedBox(height: 6),
              TextField(
                controller: _diagnosisController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Stone in Kidney',
                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isScanningReport) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
                    ),
                    const SizedBox(width: 8),
                    const Text('Scanning PDF via Gemini AI...', style: TextStyle(fontSize: 11, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                  ] else ...[
                    TextButton.icon(
                      onPressed: _pickReportPdfFile,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Upload Lab Report .pdf', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              const Text('3. Select Prescription to Compare:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryBlue)),
              const SizedBox(height: 4),
              
              if (_uploadedFileBytes != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.stars_rounded, color: AppTheme.primaryTeal, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your uploaded prescription file will be analyzed. (To test mock presets instead, select one below)',
                          style: TextStyle(color: AppTheme.primaryTeal, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              ..._mockList.map((rx) {
                final isSelected = _selectedMockRx?.id == rx.id && _uploadedFileBytes == null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryLightTeal.withOpacity(0.3) : AppTheme.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? AppTheme.primaryTeal : AppTheme.borderLight),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? AppTheme.primaryTeal : AppTheme.textMuted,
                    ),
                    title: Text(
                      rx.diagnosis,
                      style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primaryTeal : AppTheme.textDark),
                    ),
                    subtitle: Text('Medicines: ${rx.medicines.map((m) => m.split(' ')[0]).join(', ')}'),
                    onTap: () {
                      setState(() {
                        _selectedMockRx = rx;
                        _uploadedFileBytes = null;
                        _uploadedFileName = null;
                        _uploadedMimeType = null;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: () => _triggerAlignmentScan(healthProvider),
          icon: const Icon(Icons.rocket_launch_rounded),
          label: const Text('Analyze Symptoms-Prescription Alignment'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- INPUTS FOR TRACK 2 & 3: VERIFY REAL/FAKE ---
  Widget _buildVerifyRealFakeInputs(HealthProvider healthProvider, {required bool isReport}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.secondaryBlue),
              onPressed: () => setState(() => _selectedTrack = 0),
            ),
            Expanded(
              child: Text(
                isReport ? 'Verify Medical Report (Real/Fake)' : 'Verify Prescription (Real or Fake)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.secondaryBlue),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        MedicalCard(
          title: isReport ? 'Report Credentials Audit' : 'Document Credentials Audit',
          icon: isReport ? Icons.science_rounded : Icons.verified_user_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUploadZoneCard(healthProvider),
              const SizedBox(height: 18),

              const Text('Select Scan Template:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 8),

              if (_uploadedFileBytes != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppTheme.primaryTeal, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your uploaded ${isReport ? "medical report" : "prescription"} file will be analyzed. (To test mock presets instead, select one below)',
                          style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              ..._mockList.map((rx) {
                final isSelected = _selectedMockRx?.id == rx.id && _uploadedFileBytes == null;
                final isSuspicious = !rx.isReal;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? (isSuspicious ? AppTheme.severityEmergency.withOpacity(0.08) : AppTheme.primaryLightTeal.withOpacity(0.3))
                      : AppTheme.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? (isSuspicious ? AppTheme.severityEmergency : AppTheme.primaryTeal) : AppTheme.borderLight),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? (isSuspicious ? AppTheme.severityEmergency : AppTheme.primaryTeal) : AppTheme.textMuted,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            rx.diagnosis,
                            style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? (isSuspicious ? AppTheme.severityEmergency : AppTheme.primaryTeal) : AppTheme.textDark),
                          ),
                        ),
                        if (isSuspicious)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.severityEmergency.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: const Text('SUSPICIOUS SCAN', style: TextStyle(color: AppTheme.severityEmergency, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    subtitle: Text('Clinician: ${rx.doctorName} • Registry: ${rx.doctorRegistryNo}'),
                    onTap: () {
                      setState(() {
                        _selectedMockRx = rx;
                        _uploadedFileBytes = null;
                        _uploadedFileName = null;
                        _uploadedMimeType = null;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

         ElevatedButton.icon(
          onPressed: () => _triggerAuthenticityScan(healthProvider),
          icon: const Icon(Icons.security_rounded),
          label: Text(isReport ? 'Verify Medical Report Real or Fake' : 'Verify Prescription Real or Fake'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- RESULT VIEWPORT (WITH FLOWCHARTS AND HIGH CALL-TO-ACTION UPLOAD BUTTONS) ---
  Widget _buildResultDashboard(HealthProvider healthProvider) {
    final authResult = healthProvider.authenticityResult!;
    final alignResult = healthProvider.verificationResult!;

    final isReal = authResult['isReal'] as bool;
    final double authScore = authResult['score'] as double;
    final double alignScore = double.tryParse(alignResult['confidence'] ?? '50') ?? 50.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isReal) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.severityEmergency.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.severityEmergency, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.gpp_bad_rounded, color: AppTheme.severityEmergency, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '🚨 SAFETY AUDIT ALERT: FAKE DOCUMENT DETECTED',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.severityEmergency, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pocket Swasth AI audit indicates this document registry/clinician stamp is fraudulent, altered, or unverified. Standard upload is locked.',
                        style: const TextStyle(color: AppTheme.textDark, fontSize: 11, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_resultTrackRun == 1) ...[
          // TRACK 1 VIEWPORT: COMPARATOR & ALIGNMENT FLOW
          const Text(
            '🧬 Symptoms ➔ Diagnosis ➔ Prescription Flowchart',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMuted, letterSpacing: 0.2),
          ),
          const SizedBox(height: 12),
          
          _buildHorizontalFlowchart(
            symptoms: _symptomController.text,
            diagnosis: _diagnosisController.text,
            prescription: _selectedMockRx?.diagnosis ?? '',
            isAligned: alignScore >= 60,
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${alignScore.toStringAsFixed(0)}% ALIGNMENT',
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.w900, 
                            color: alignScore >= 60 ? AppTheme.severityLow : AppTheme.severityEmergency
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (alignScore >= 60 ? AppTheme.severityLow : AppTheme.severityEmergency).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            alignResult['status'] as String,
                            style: TextStyle(
                              color: alignScore >= 60 ? AppTheme.severityLow : AppTheme.severityEmergency,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.borderLight),
                  const SizedBox(height: 12),
                  const Text('AI CLINICAL ADVISORY:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Text(
                    alignResult['explanation'] as String,
                    style: const TextStyle(fontSize: 13.5, color: AppTheme.textDark, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // TRACK 2 VIEWPORT: AUTHENTICITY AUDIT
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          isReal ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                          color: isReal ? AppTheme.severityLow : AppTheme.severityEmergency,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isReal 
                            ? (_resultTrackRun == 3 ? 'VERIFIED GENUINE MEDICAL REPORT' : 'VERIFIED GENUINE PRESCRIPTION') 
                            : (_resultTrackRun == 3 ? 'SUSPICIOUS MEDICAL REPORT DETECTED' : 'SUSPICIOUS PRESCRIPTION DETECTED'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15, 
                            fontWeight: FontWeight.bold, 
                            color: isReal ? AppTheme.severityLow : AppTheme.severityEmergency
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Authenticity Rating: ${authScore.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.borderLight, height: 24),
                  
                  const Text('AI SECURITY CHECKLIST AUDIT:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 10),

                  ...(authResult['checkmarks'] as List<dynamic>? ?? []).map((item) {
                    final status = item['status'] as String;
                    final title = item['title'] as String;
                    
                    Color color = AppTheme.severityLow;
                    IconData icon = Icons.check_circle_rounded;
                    if (status == 'warning') {
                      color = AppTheme.severityMedium;
                      icon = Icons.warning_rounded;
                    } else if (status == 'fail') {
                      color = AppTheme.severityEmergency;
                      icon = Icons.cancel_rounded;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                            ),
                          ),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const Divider(color: AppTheme.borderLight, height: 24),
                  const Text('SECURITY REPORT:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Text(
                    authResult['reportSummary'] ?? '',
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textDark, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // --- DYNAMIC CALL TO ACTION ACTIONS ---
        if (isReal) ...[
          if (alignScore >= 60) ...[
            // BOTH AUTHENTIC AND ALIGNED - Pulsing highly attractive CTA button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _saveToCabinet(healthProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.cloud_upload_rounded, size: 24, color: Colors.white),
                label: const Text(
                  '⚡ UPLOAD SECURELY TO CABINET',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            // Genuine but alignment is low - allow upload but show warning/advisory
            ElevatedButton.icon(
              onPressed: () => _saveToCabinet(healthProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.cloud_upload_rounded, size: 20, color: Colors.white),
              label: const Text(
                'UPLOAD TO CABINET ANYWAY',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Discuss Alignment callback to Chat AI Agent
          ElevatedButton.icon(
            onPressed: () {
              // 1. Switch to Chat tab
              if (widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(0);
              }
              // 2. Pre-populate chat with verified prescription details to ask questions
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              chatProvider.clearAccumulatedSymptoms();
              
              // Extract medicines list
              final List<dynamic> meds = authResult['medicines'] as List<dynamic>? ?? [];
              final medsText = meds.isNotEmpty 
                  ? meds.map((m) => '• $m').join('\n') 
                  : '• Active consultation record';

              chatProvider.addSystemAiMessage(
                "🤖 **Discussing Verified Prescription: ${authResult['doctorName'] ?? 'Physician'}**\n\n"
                "I have imported your verified prescription. Here are the active medications identified:\n"
                "$medsText\n\n"
                "**Doctor Registry Status:** ${authResult['doctorRegistryNo'] ?? 'UNKNOWN'} (Verified)\n"
                "**Clinical Stamp Authenticated:** Genuine\n"
                "**Symptom Alignment Score:** ${alignScore.toStringAsFixed(0)}%\n\n"
                "How can I assist you with these medications today? Feel free to ask about drug interactions, side effects, or wellness advisory!"
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EE6), // Elegant premium purple
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
            icon: const Icon(Icons.forum_rounded, color: Colors.white),
            label: const Text(
              '💬 DISCUSS ALIGNMENT WITH AI AGENT',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white, letterSpacing: 0.2),
            ),
          ),
        ] else if (!isReal) ...[
          // SUSPICIOUS Rx UPLOAD WARNING
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.severityEmergency.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.severityEmergency.withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppTheme.severityEmergency, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SECURITY CRITICAL WARNING: AI scans flagged this document as suspicious. Uploading is blocked or restricted for clinical safety.',
                    style: TextStyle(color: AppTheme.severityEmergency, fontSize: 11.5, fontWeight: FontWeight.bold, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              healthProvider.resetVerificationState();
              setState(() {
                _selectedTrack = 0;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryBlue,
              foregroundColor: AppTheme.white,
            ),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Scan Another Document'),
          ),
        ] else ...[
          // MISALIGNED RX BUTTONS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.severityMedium.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.severityMedium.withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Icon(Icons.help_outline_rounded, color: AppTheme.severityMedium, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ALIGNMENT MISMATCH ALERT: The drugs in this prescription do not match the symptoms you checked. Please consult your physician.',
                    style: TextStyle(color: AppTheme.severityMedium, fontSize: 11.5, fontWeight: FontWeight.bold, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => healthProvider.resetVerificationState(),
                  child: const Text('FIX SYMPTOMS'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _saveToCabinet(healthProvider),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.severityMedium),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('FORCE SAVE ANYWAY'),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            healthProvider.resetVerificationState();
            setState(() {
              _selectedTrack = 0;
            });
          },
          child: const Text('Cancel & Choose Another Track', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- PREMIUM HORIZONTAL FLOWCHART WIDGET ---
  Widget _buildHorizontalFlowchart({
    required String symptoms,
    required String diagnosis,
    required String prescription,
    required bool isAligned,
  }) {
    final cleanSymptoms = symptoms.length > 18 ? '${symptoms.substring(0, 15)}...' : symptoms;
    final cleanDiagnosis = diagnosis.length > 18 ? '${diagnosis.substring(0, 15)}...' : diagnosis;
    final cleanRx = prescription.length > 15 ? '${prescription.substring(0, 12)}...' : prescription;

    final color = isAligned ? AppTheme.severityLow : AppTheme.severityEmergency;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Symptoms block
          _buildFlowBlock(
            title: 'SYMPTOMS',
            value: cleanSymptoms.isEmpty ? 'Kidney Pain' : cleanSymptoms,
            icon: Icons.healing_rounded,
            color: Colors.amber.shade700,
          ),

          // Arrow 1
          Icon(Icons.arrow_forward_rounded, color: color.withOpacity(0.4), size: 20),

          // 2. Diagnosis block
          _buildFlowBlock(
            title: 'DIAGNOSIS',
            value: cleanDiagnosis.isEmpty ? 'Kidney Stone' : cleanDiagnosis,
            icon: Icons.assignment_rounded,
            color: AppTheme.secondaryBlue,
          ),

          // Arrow 2 (Visual checkmark or cross indicator)
          Icon(
            isAligned ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
            color: color,
            size: 22,
          ),

          // 3. Prescription block
          _buildFlowBlock(
            title: 'MEDICINES',
            value: cleanRx.isEmpty ? 'Prescription Rx' : cleanRx,
            icon: Icons.medication_rounded,
            color: AppTheme.primaryTeal,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowBlock({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCabinetSummaryCard(HealthProvider healthProvider) {
    final summary = healthProvider.cabinetSummary;
    final loading = healthProvider.isGeneratingCabinetSummary;
    final genuinePrescriptions = healthProvider.savedPrescriptions.where((rx) => rx.isReal).toList();

    if (genuinePrescriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.08), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.deepPurple, size: 16),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Health Cabinet Summary',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryBlue,
                  ),
                ),
              ),
              if (summary != null && !loading)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.deepPurple, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => healthProvider.generateCabinetSummary(),
                ),
            ],
          ),
          const Divider(height: 16, color: AppTheme.borderLight),
          if (loading) ...[
            const SizedBox(height: 8),
            const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Synthesizing collective trends and suggestions across verified records...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic, height: 1.3),
            ),
            const SizedBox(height: 4),
          ] else if (summary == null) ...[
            const Text(
              'Synthesize all verified reports and prescriptions into a cohesive AI wellness clinical summary.',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted, height: 1.35),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => healthProvider.generateCabinetSummary(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              icon: const Icon(Icons.rocket_launch_rounded, size: 12),
              label: const Text(
                'Generate AI Insights',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ] else ...[
            MarkdownBody(
              data: summary,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 11.5, color: AppTheme.textDark, height: 1.4),
                h3: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  height: 1.6,
                ),
                listBullet: const TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleDirectCabinetUpload(HealthProvider healthProvider) async {
    try {
      final fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

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
      if (bytes == null) return;

      final ext = file.extension?.toLowerCase() ?? 'jpg';
      String mimeType = 'image/jpeg';
      if (ext == 'pdf') {
        mimeType = 'application/pdf';
      } else if (ext == 'png') {
        mimeType = 'image/png';
      }

      // Show non-dismissible clinical validation progress dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: AppTheme.primaryTeal),
                    SizedBox(height: 20),
                    Text(
                      '🔍 AI Authenticity Audit',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.secondaryBlue),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Verifying credentials, stamps, and clinic registration databases using Gemini Generative Vision...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Run live AI verification
      await healthProvider.runRealApiVerification(
        fileBytes: bytes,
        mimeType: mimeType,
        symptoms: 'Cabinet direct upload wellness check',
        diagnosis: 'General health history overview',
      );

      // Dismiss the progress dialog
      if (mounted) {
        Navigator.pop(context);
      }

      final resultAudit = healthProvider.authenticityResult;
      if (resultAudit != null) {
        final isReal = resultAudit['isReal'] as bool;
        if (isReal) {
          _showDirectUploadSuccess();
          // Automatically trigger synthesis update
          healthProvider.generateCabinetSummary();
        } else {
          _showDirectUploadFailed();
        }
      }
    } catch (e) {
      // Dismiss progress dialog if still showing
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Verification failed: $e'),
            backgroundColor: AppTheme.severityEmergency,
          ),
        );
      }
    }
  }

  void _showDirectUploadSuccess() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 40),
          ),
          title: const Text(
            'Verification Successful',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          content: const Text(
            'This medical record has been verified as 100% genuine and has been securely stored in your local Device Cabinet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDirectUploadFailed() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.severityEmergency.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.gpp_bad_rounded, color: AppTheme.severityEmergency, size: 40),
          ),
          title: const Text(
            'Verification Failed',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.severityEmergency),
          ),
          content: const Text(
            'This medical document failed authenticity audits. Suspicious signatures, altered parameters, or missing registration credentials were detected. Upload blocked for clinical safety.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Acknowledge Warning', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.severityEmergency)),
            ),
          ],
        );
      },
    );
  }
}
