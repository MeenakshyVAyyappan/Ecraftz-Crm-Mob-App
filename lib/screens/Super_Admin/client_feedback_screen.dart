import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../blocs/client_feedback/client_feedback_bloc.dart';
import '../../blocs/client/client_bloc.dart';
import '../../models/client_feedback_model.dart';
import '../../models/client_model.dart';
import '../../services/audio_recording_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/audio_player_widget.dart';
import '../Public/shared_client_feedback_form_screen.dart';

class ClientFeedbackScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;

  const ClientFeedbackScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<ClientFeedbackScreen> createState() => _ClientFeedbackScreenState();
}

class _ClientFeedbackScreenState extends State<ClientFeedbackScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _ratingFilter = 'All';
  String? _selectedClientFilter;
  String _typeFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<ClientFeedbackBloc>().add(LoadClientFeedbackEvent());
    context.read<ClientBloc>().add(LoadClientsEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClientFeedback> _filtered(List<ClientFeedback> items) {
    return items.where((fb) {
      final matchesSearch = _searchQuery.isEmpty ||
          (fb.clientName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (fb.projectName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          fb.comments.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (fb.feedbackType ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'All' ||
          fb.status.toLowerCase() == _statusFilter.toLowerCase();

      final matchesRating = _ratingFilter == 'All' ||
          fb.rating.round().toString() == _ratingFilter;

      final matchesClient = _selectedClientFilter == null ||
          fb.clientId == _selectedClientFilter;

      final matchesType = _typeFilter == 'All' ||
          (fb.feedbackType ?? '').toLowerCase() == _typeFilter.toLowerCase();

      return matchesSearch && matchesStatus && matchesRating && matchesClient && matchesType;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'approved':
        return Colors.green;
      case 'in_progress':
      case 'in progress':
      case 'needs review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Screenshot 3: Record Client Feedback Dialog
  void _showRecordFeedbackSheet({ClientFeedback? existing}) {
    final isEdit = existing != null;
    String? selectedClientId = existing?.clientId;
    String? selectedProjectId = existing?.projectId;
    String status = existing?.status ?? 'pending';
    final commentsCtrl = TextEditingController(text: existing?.comments ?? '');

    final categories = context.read<ClientFeedbackBloc>().state.categories;
    final Map<String, double> categoryRatings = {};

    if (existing != null && existing.categoryRatings.isNotEmpty) {
      categoryRatings.addAll(existing.categoryRatings);
    } else {
      for (final c in categories) {
        categoryRatings[c.name] = 5.0;
      }
      if (categoryRatings.isEmpty) {
        categoryRatings['Service Quality'] = 5.0;
        categoryRatings['Communication'] = 5.0;
        categoryRatings['Timeliness & Delivery'] = 5.0;
      }
    }

    bool isRecording = false;
    int recordSeconds = 0;
    File? audioFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final clientsState = context.watch<ClientBloc>().state;

          void toggleAudioRecord() async {
            if (!isRecording) {
              final ok = await AudioRecordingService.instance.startRecording();
              if (ok) {
                setDlgState(() {
                  isRecording = true;
                  recordSeconds = 0;
                });
                AudioRecordingService.instance.durationStream.listen((sec) {
                  setDlgState(() => recordSeconds = sec);
                });
              }
            } else {
              final file = await AudioRecordingService.instance.stopRecording();
              setDlgState(() {
                isRecording = false;
                audioFile = file;
              });
            }
          }

          return AlertDialog(
            backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(16),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Client Feedback' : 'Record Client Feedback',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manually record feedback collected over phone, email, or meeting.',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]),
                ),
              ],
            ),
            content: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Client * Dropdown
                    RichText(
                      text: TextSpan(
                        text: 'Client ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF374151)),
                        children: const [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedClientId,
                      decoration: InputDecoration(
                        hintText: 'Select active client',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: clientsState.clients.map((c) {
                        return DropdownMenuItem<String>(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) => setDlgState(() => selectedClientId = val),
                    ),
                    const SizedBox(height: 12),

                    // Project Dropdown
                    Text('Project (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF374151))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedProjectId,
                      decoration: InputDecoration(
                        hintText: 'No Specific Project',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem<String>(value: null, child: Text('No Specific Project')),
                      ],
                      onChanged: (val) => setDlgState(() => selectedProjectId = val),
                    ),
                    const SizedBox(height: 16),

                    // Rate client's satisfaction for each category
                    Text(
                      'Rate satisfaction for each category:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: categoryRatings.keys.map((catName) {
                        final ratingVal = categoryRatings[catName] ?? 5.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(catName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF374151))),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: List.generate(5, (idx) {
                                      final starVal = idx + 1.0;
                                      return GestureDetector(
                                        onTap: () {
                                          setDlgState(() => categoryRatings[catName] = starVal);
                                        },
                                        child: Icon(
                                          starVal <= ratingVal ? Icons.star_rounded : Icons.star_border_rounded,
                                          color: Colors.amber,
                                          size: 22,
                                        ),
                                      );
                                    }),
                                  ),
                                  Text('${ratingVal.toInt()} / 5', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Comments / Details
                    Text('Comments / Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF374151))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: commentsCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Record client comments here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Voice Note Recording Control
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                              color: isRecording ? Colors.red : const Color(0xFF2196F3),
                              size: 24,
                            ),
                            onPressed: toggleAudioRecord,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isRecording
                                  ? 'Recording... ${recordSeconds}s'
                                  : (audioFile != null ? 'Voice note ready!' : 'Record voice note (Optional)'),
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (selectedClientId == null) {
                    AppSnackBar.showCustom(context, const SnackBar(content: Text('Please select a client.')));
                    return;
                  }
                  if (commentsCtrl.text.trim().isEmpty) {
                    AppSnackBar.showCustom(context, const SnackBar(content: Text('Please enter feedback comments.')));
                    return;
                  }

                  double overallSum = 0.0;
                  if (categoryRatings.isNotEmpty) {
                    categoryRatings.forEach((_, v) => overallSum += v);
                    overallSum /= categoryRatings.length;
                  } else {
                    overallSum = 5.0;
                  }

                  if (isEdit) {
                    context.read<ClientFeedbackBloc>().add(UpdateClientFeedbackEvent(
                          id: existing.id,
                          clientId: selectedClientId,
                          rating: overallSum,
                          categoryRatings: Map.from(categoryRatings),
                          feedbackType: 'General',
                          comments: commentsCtrl.text.trim(),
                          status: status,
                          audioFile: audioFile,
                        ));
                  } else {
                    context.read<ClientFeedbackBloc>().add(AddClientFeedbackEvent(
                          clientId: selectedClientId!,
                          projectId: selectedProjectId,
                          rating: overallSum,
                          categoryRatings: Map.from(categoryRatings),
                          feedbackType: 'General',
                          comments: commentsCtrl.text.trim(),
                          status: status,
                          audioFile: audioFile,
                        ));
                  }
                  Navigator.pop(ctx);
                  AppSnackBar.showCustom(context, SnackBar(
                    content: Text(isEdit ? 'Feedback updated!' : 'Feedback saved successfully!'),
                    backgroundColor: Colors.green,
                  ));
                },
                child: Text(isEdit ? 'Update Feedback' : 'Save Feedback', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showManageResponseSheet(ClientFeedback fb) {
    final responseCtrl = TextEditingController(text: fb.internalResponse ?? fb.actionNotes ?? '');
    String status = fb.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Manage Response & Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Update Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: ['pending', 'in_progress', 'resolved', 'approved', 'rejected'].contains(status.toLowerCase()) ? status.toLowerCase() : 'pending',
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('PENDING')),
                    DropdownMenuItem(value: 'in_progress', child: Text('IN PROGRESS')),
                    DropdownMenuItem(value: 'resolved', child: Text('RESOLVED')),
                    DropdownMenuItem(value: 'rejected', child: Text('REJECTED')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => status = val);
                  },
                ),
                const SizedBox(height: 12),
                Text('Internal Resolution Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
                const SizedBox(height: 6),
                TextField(
                  controller: responseCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter response action notes...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      context.read<ClientFeedbackBloc>().add(UpdateClientFeedbackEvent(
                        id: fb.id,
                        status: status,
                        internalResponse: responseCtrl.text.trim(),
                        actionNotes: responseCtrl.text.trim(),
                      ));
                      Navigator.pop(ctx);
                      AppSnackBar.showCustom(context, const SnackBar(content: Text('Response updated!'), backgroundColor: Colors.green));
                    },
                    child: const Text('Save Response', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCategoryManagerSheet() {
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final categories = context.watch<ClientFeedbackBloc>().state.categories;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Manage Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            hintText: 'New category name...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
                        onPressed: () {
                          if (nameCtrl.text.trim().isNotEmpty) {
                            context.read<ClientFeedbackBloc>().add(AddCategoryEvent(nameCtrl.text.trim()));
                            nameCtrl.clear();
                          }
                        },
                        child: const Text('Add', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (c, i) {
                      final cat = categories[i];
                      return ListTile(
                        dense: true,
                        title: Text(cat.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            context.read<ClientFeedbackBloc>().add(DeleteCategoryEvent(cat.id));
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showShareLinkSheet() {
    final clientsState = context.read<ClientBloc>().state;
    String? selectedClientId = clientsState.clients.isNotEmpty ? clientsState.clients.first.id : null;
    bool showCopiedBanner = false;
    // Inline banner state for WhatsApp errors (null = hidden, non-null = message to show)
    String? whatsappErrorMsg;

    // Clear any previously generated link so the sheet always starts fresh
    context.read<ClientFeedbackBloc>().add(ClearGeneratedLinkEvent());

    final ScrollController sheetScrollController = ScrollController();

    // Reliably scroll to the bottom after a short delay so layout is complete
    void scrollToBottom() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (sheetScrollController.hasClients &&
            sheetScrollController.position.maxScrollExtent > 0) {
          sheetScrollController.animateTo(
            sheetScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final sharedLink = context.watch<ClientFeedbackBloc>().state.generatedShareLink;

          ActiveClient? selectedClient;
          if (selectedClientId != null && clientsState.clients.isNotEmpty) {
            try {
              selectedClient = clientsState.clients.firstWhere((c) => c.id == selectedClientId);
            } catch (_) {}
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.bgCardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: sheetScrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Share Feedback Link',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Client dropdown ──────────────────────────────────────
                  Text(
                    'Select Client *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedClientId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: clientsState.clients.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setSheetState(() {
                        selectedClientId = v;
                        showCopiedBanner = false;
                        whatsappErrorMsg = null;
                      });
                    },
                    hint: const Text('Select Client'),
                  ),
                  const SizedBox(height: 14),

                  // ── Generate button ──────────────────────────────────────
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.link_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'Generate Secure Link',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (selectedClientId != null) {
                        setSheetState(() {
                          showCopiedBanner = false;
                          whatsappErrorMsg = null;
                        });
                        context.read<ClientFeedbackBloc>().add(
                          GenerateSharedLinkEvent(clientId: selectedClientId!),
                        );
                        // Scroll after the bloc emits and the new widgets are laid out
                        scrollToBottom();
                      } else {
                        AppSnackBar.showCustom(ctx, 
                          const SnackBar(content: Text('Please select a client.')),
                        );
                      }
                    },
                  ),

                  // ── "Link copied" inline banner (Copy Link only) ─────────
                  if (showCopiedBanner) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Feedback link copied to clipboard successfully!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── WhatsApp inline error banner ──────────────────────────
                  if (whatsappErrorMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              whatsappErrorMsg!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setSheetState(() => whatsappErrorMsg = null),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Generated link + action buttons ──────────────────────
                  if (sharedLink != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: SelectableText(
                        sharedLink,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // ── Copy Link ── shows "Link copied" banner ────────
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'Copy Link',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: sharedLink));
                              setSheetState(() {
                                showCopiedBanner = true;
                                whatsappErrorMsg = null;
                              });
                              Future.delayed(const Duration(seconds: 4), () {
                                if (mounted) setSheetState(() => showCopiedBanner = false);
                              });
                            },
                          ),
                          const SizedBox(width: 8),

                          // ── Share on WhatsApp ── shows inline error banner ──
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.white),
                            label: Text(
                              (selectedClient?.phone != null && selectedClient!.phone!.isNotEmpty)
                                  ? 'WhatsApp Client'
                                  : 'Share on WhatsApp',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final clientName = selectedClient?.name ?? 'Client';
                              final rawPhone = selectedClient?.phone;
                              String? cleanPhone;
                              if (rawPhone != null && rawPhone.trim().isNotEmpty) {
                                cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
                              }

                              final msgText = Uri.encodeComponent(
                                'Dear $clientName,\n\nPlease share your feedback on our services using this link:\n$sharedLink\n\nThank you,\nEcraftz Team',
                              );

                              final nativeUri = Uri.parse(
                                'whatsapp://send?${cleanPhone != null ? "phone=$cleanPhone&" : ""}text=$msgText',
                              );
                              final webUri = Uri.parse(
                                'https://api.whatsapp.com/send?${cleanPhone != null ? "phone=$cleanPhone&" : ""}text=$msgText',
                              );

                              try {
                                if (await canLaunchUrl(nativeUri)) {
                                  await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
                                } else if (await canLaunchUrl(webUri)) {
                                  await launchUrl(webUri, mode: LaunchMode.externalApplication);
                                } else {
                                  // Show error INSIDE the sheet — visible on top of everything
                                  setSheetState(() {
                                    showCopiedBanner = false;
                                    whatsappErrorMsg = 'WhatsApp is not installed on this device.';
                                  });
                                }
                              } catch (_) {
                                setSheetState(() {
                                  showCopiedBanner = false;
                                  whatsappErrorMsg = 'Could not open WhatsApp. Please try again.';
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8),

                          // ── Preview Form ─────────────────────────────────
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Preview Form'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SharedClientFeedbackFormScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => sheetScrollController.dispose());
  }

  void _confirmDelete(ClientFeedback fb) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: Text('Remove feedback record from ${fb.clientName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<ClientFeedbackBloc>().add(DeleteClientFeedbackEvent(fb.id));
              Navigator.pop(ctx);
              AppSnackBar.showCustom(context, const SnackBar(content: Text('Feedback deleted'), backgroundColor: Colors.red));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 100% RESPONSIVE DASHBOARD METRICS CARD (Fixes 35px overflow!)
  Widget _buildDashboardMetricsCard(FeedbackDashboardMetrics metrics, bool isDark, bool isTablet) {
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSub = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];

    // Tablet layout: Side-by-Side 3-column row
    if (isTablet) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AVERAGE RATING
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AVERAGE RATING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSub, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        metrics.averageRating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textTitle),
                      ),
                      Text(' / 5.0', style: TextStyle(fontSize: 14, color: textSub)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (i) => const Icon(Icons.star_rounded, color: Colors.amber, size: 16)),
                      ),
                      const SizedBox(width: 4),
                      Text('(${metrics.totalReviews} reviews)', style: TextStyle(fontSize: 10, color: textSub)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // RATING DISTRIBUTION
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RATING DISTRIBUTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSub, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  _buildRatingRow('5', metrics.fiveStarCount, metrics.totalReviews),
                  _buildRatingRow('4', metrics.fourStarCount, metrics.totalReviews),
                  _buildRatingRow('3', metrics.threeStarCount, metrics.totalReviews),
                  _buildRatingRow('2', metrics.twoStarCount, metrics.totalReviews),
                  _buildRatingRow('1', metrics.oneStarCount, metrics.totalReviews),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // FEEDBACK ACTIONS
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FEEDBACK ACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSub, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pending', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600)),
                              Text('${metrics.pendingCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Resolved', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                              Text('${metrics.resolvedCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 12, color: Colors.teal),
                      const SizedBox(width: 4),
                      Expanded(child: Text('Active monitoring enabled', style: TextStyle(fontSize: 9, color: textSub), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout: Stacked sections (Fixes overflow completely!)
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Average Rating (Left) & Feedback Action Cards (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AVERAGE RATING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSub, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          metrics.averageRating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textTitle),
                        ),
                        Text(' / 5.0', style: TextStyle(fontSize: 12, color: textSub)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (i) => const Icon(Icons.star_rounded, color: Colors.amber, size: 14)),
                        ),
                        const SizedBox(width: 4),
                        Text('(${metrics.totalReviews})', style: TextStyle(fontSize: 10, color: textSub)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FEEDBACK ACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSub, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pending', style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w600)),
                                Text('${metrics.pendingCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Resolved', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.w600)),
                                Text('${metrics.resolvedCount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Rating Distribution Section (Full Width on Mobile)
          Text('RATING DISTRIBUTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSub, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          _buildRatingRow('5', metrics.fiveStarCount, metrics.totalReviews),
          _buildRatingRow('4', metrics.fourStarCount, metrics.totalReviews),
          _buildRatingRow('3', metrics.threeStarCount, metrics.totalReviews),
          _buildRatingRow('2', metrics.twoStarCount, metrics.totalReviews),
          _buildRatingRow('1', metrics.oneStarCount, metrics.totalReviews),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 12, color: Colors.teal),
              const SizedBox(width: 4),
              Text('Active monitoring enabled', style: TextStyle(fontSize: 10, color: textSub)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String starLabel, int count, int total) {
    final double pct = total > 0 ? (count / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(starLabel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
          const Icon(Icons.star, size: 10, color: Colors.amber),
          const SizedBox(width: 4),
          Expanded(
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 5,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 14,
            child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTitle = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSub = isDark ? const Color(0xFF8E9CB8) : Colors.grey[600];
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 650;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: widget.showAppBar ? AppDrawer(selectedIndex: widget.selectedIndex, onItemSelected: widget.onItemSelected) : null,
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF374151)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textTitle)),
            Text('Monitor customer satisfaction, gather reviews, and resolve service issues.', style: TextStyle(fontSize: 11, color: textSub), overflow: TextOverflow.ellipsis),
          ],
        ),
      ) : null,
      body: BlocBuilder<ClientFeedbackBloc, ClientFeedbackState>(
        builder: (context, state) {
          if (state.status == ClientFeedbackStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredList = _filtered(state.feedbacks);
          final clientsList = context.watch<ClientBloc>().state.clients;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ClientFeedbackBloc>().add(LoadClientFeedbackEvent());
            },
            child: ListView(
              children: [
                // Top Control Buttons Row (Scrollable horizontally to prevent 25px overflow!)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.tune_outlined, size: 16),
                        label: const Text('Manage Categories', style: TextStyle(fontSize: 11)),
                        onPressed: _showCategoryManagerSheet,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Share Link', style: TextStyle(fontSize: 11)),
                        onPressed: _showShareLinkSheet,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text('+ Record Feedback', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => _showRecordFeedbackSheet(),
                      ),
                    ],
                  ),
                ),

                // Responsive Analytical Dashboard Metrics Card
                _buildDashboardMetricsCard(state.metrics, isDark, isTablet),

                // Search & Filter Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search by client, project, or comments...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            DropdownButton<String?>(
                              value: _selectedClientFilter,
                              hint: const Text('All Clients', style: TextStyle(fontSize: 11)),
                              style: TextStyle(fontSize: 11, color: textTitle),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('All Clients')),
                                ...clientsList.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                              ],
                              onChanged: (v) => setState(() => _selectedClientFilter = v),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: _ratingFilter,
                              style: TextStyle(fontSize: 11, color: textTitle),
                              items: ['All', '5', '4', '3', '2', '1'].map((r) => DropdownMenuItem(value: r, child: Text(r == 'All' ? 'All Ratings' : '$r Stars'))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _ratingFilter = v);
                              },
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: _statusFilter,
                              style: TextStyle(fontSize: 11, color: textTitle),
                              items: ['All', 'pending', 'in_progress', 'resolved', 'rejected'].map((st) => DropdownMenuItem(value: st, child: Text(st == 'All' ? 'All Statuses' : st.toUpperCase()))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _statusFilter = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Feedback Cards Feed
                if (filteredList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text('No client feedback records found.', style: TextStyle(color: textSub, fontSize: 13)),
                    ),
                  )
                else
                  ListView.builder(
                    padding: const EdgeInsets.all(12),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (ctx, idx) {
                      final item = filteredList[idx];
                      final stColor = _statusColor(item.status);
                      final avatarInitials = (item.clientName != null && item.clientName!.isNotEmpty)
                          ? item.clientName!.substring(0, item.clientName!.length >= 2 ? 2 : 1).toUpperCase()
                          : 'AM';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        color: isDark ? AppTheme.bgCardDark : Colors.white,
                        elevation: isDark ? 0 : 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card Header: Avatar + Client Name + Days Ago + Status Badge
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF38BDF8).withOpacity(0.2),
                                    child: Text(
                                      avatarInitials,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.clientName ?? 'AMRITHAKRIPA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textTitle), overflow: TextOverflow.ellipsis),
                                        Text('${item.daysSinceSubmission} days ago', style: TextStyle(fontSize: 10, color: textSub)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: stColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                        child: Text(item.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: stColor)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Multi-Category Review', style: TextStyle(fontSize: 9, color: textSub)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Overall Star Rating e.g. ★★★★★ 5.0
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(5, (i) => Icon(i < item.rating.floor() ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 18)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(item.rating.toStringAsFixed(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textTitle)),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Category Ratings Grid
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black12 : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: item.categoryRatings.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(entry.key, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey[700]), overflow: TextOverflow.ellipsis),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                                              const SizedBox(width: 4),
                                              Text(entry.value.toStringAsFixed(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textTitle)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Client Comment in Quotes
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '"${item.comments}"',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textTitle),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Linked Project Tag
                              Text(
                                'PROJECT: ${item.projectName ?? "No Project"}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),

                              // Voice Note Audio Player (if present)
                              if (item.audioUrl != null && item.audioUrl!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                AudioPlayerWidget(audioUrl: item.audioUrl!, title: 'Voice Note'),
                              ],

                              const Divider(height: 20),

                              // Bottom Actions: Delete & Manage Response
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.redAccent),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      icon: const Icon(Icons.delete_outline, size: 14),
                                      label: const Text('Delete', style: TextStyle(fontSize: 11)),
                                      onPressed: () => _confirmDelete(item),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      icon: const Icon(Icons.edit_outlined, size: 14),
                                      label: const Text('Manage Response', style: TextStyle(fontSize: 11)),
                                      onPressed: () => _showManageResponseSheet(item),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
