// client_onboarding_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/client/client_bloc.dart';
import '../../blocs/onboarding/onboarding_bloc.dart';
import '../../models/client_model.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_drawer.dart';
import '../../theme/app_theme.dart';
import '../../blocs/theme/theme_bloc.dart';

int _uniqueIdCounter = 0;
String _generateUniqueId() {
  _uniqueIdCounter++;
  return '${DateTime.now().microsecondsSinceEpoch}_$_uniqueIdCounter';
}

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

enum IntakeStatus { approved, pending, review, rejected }

extension IntakeStatusExt on IntakeStatus {
  String get label {
    switch (this) {
      case IntakeStatus.approved: return 'approved';
      case IntakeStatus.pending: return 'pending';
      case IntakeStatus.review: return 'needs review';
      case IntakeStatus.rejected: return 'rejected';
    }
  }

  Color get color {
    switch (this) {
      case IntakeStatus.approved: return const Color(0xFF10B981);
      case IntakeStatus.pending: return const Color(0xFFF59E0B);
      case IntakeStatus.review: return const Color(0xFF3B82F6);
      case IntakeStatus.rejected: return const Color(0xFFEF4444);
    }
  }
}

enum ServiceCategory { webDevelopment, digitalMarketing, contentCreation, seo, branding }

extension ServiceCategoryExt on ServiceCategory {
  String get label {
    switch (this) {
      case ServiceCategory.webDevelopment: return 'Web Development';
      case ServiceCategory.digitalMarketing: return 'Digital Marketing';
      case ServiceCategory.contentCreation: return 'Content Creation';
      case ServiceCategory.seo: return 'SEO';
      case ServiceCategory.branding: return 'Branding';
    }
  }

  Color get color {
    switch (this) {
      case ServiceCategory.webDevelopment: return const Color(0xFF3B82F6);
      case ServiceCategory.digitalMarketing: return const Color(0xFFF59E0B);
      case ServiceCategory.contentCreation: return const Color(0xFF8B5CF6);
      case ServiceCategory.seo: return const Color(0xFF10B981);
      case ServiceCategory.branding: return const Color(0xFFEF4444);
    }
  }
}

enum TemplateAvailability { active, draft, testing, archived }

extension TemplateAvailabilityExt on TemplateAvailability {
  String get label {
    switch (this) {
      case TemplateAvailability.active: return 'ACTIVE';
      case TemplateAvailability.draft: return 'DRAFT';
      case TemplateAvailability.testing: return 'TESTING';
      case TemplateAvailability.archived: return 'ARCHIVED';
    }
  }

  Color get color {
    switch (this) {
      case TemplateAvailability.active: return const Color(0xFF10B981);
      case TemplateAvailability.draft: return const Color(0xFF6B7280);
      case TemplateAvailability.testing: return const Color(0xFFF59E0B);
      case TemplateAvailability.archived: return const Color(0xFFEF4444);
    }
  }
}

enum FieldType { textInput, textArea, dropdown, multiSelect, radioToggle, urlValidation, fileUpload, dateInput }

extension FieldTypeExt on FieldType {
  String get label {
    switch (this) {
      case FieldType.textInput: return 'Text Input';
      case FieldType.textArea: return 'Text Area';
      case FieldType.dropdown: return 'Dropdown Options';
      case FieldType.multiSelect: return 'Multi-Select Choice';
      case FieldType.radioToggle: return 'Radio Toggles';
      case FieldType.urlValidation: return 'URL Validation';
      case FieldType.fileUpload: return 'File Upload';
      case FieldType.dateInput: return 'Date Input';
    }
  }
}

class FormQuestion {
  String id;
  String fieldCode;
  String questionLabel;
  FieldType fieldType;
  bool isRequired;
  bool isSensitive;
  String choices;

  FormQuestion({
    required this.id,
    this.fieldCode = '',
    this.questionLabel = '',
    this.fieldType = FieldType.textInput,
    this.isRequired = false,
    this.isSensitive = false,
    this.choices = '',
  });

  FormQuestion copy() => FormQuestion(
    id: _generateUniqueId(),
    fieldCode: fieldCode,
    questionLabel: questionLabel,
    fieldType: fieldType,
    isRequired: isRequired,
    isSensitive: isSensitive,
    choices: choices,
  );
}

class FormSection {
  String id;
  String title;
  String description;
  List<FormQuestion> questions;

  FormSection({
    required this.id,
    this.title = '',
    this.description = '',
    List<FormQuestion>? questions,
  }) : questions = questions ?? [];
}

class OnboardingTemplate {
  final String id;
  String name;
  String description;
  ServiceCategory category;
  TemplateAvailability availability;
  List<FormSection> sections;
  int version;

  OnboardingTemplate({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.availability = TemplateAvailability.active,
    List<FormSection>? sections,
    this.version = 1,
  }) : sections = sections ?? [];
}

class Submission {
  final String id;
  final String clientName;
  final String templateName;
  final double progress;
  final IntakeStatus status;
  final String submittedAgo;

  const Submission({
    required this.id,
    required this.clientName,
    required this.templateName,
    required this.progress,
    required this.status,
    required this.submittedAgo,
  });
}

// ─── MAIN PAGE ────────────────────────────────────────────────────────────────

class ClientOnboardingPage extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ClientOnboardingPage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<ClientOnboardingPage> createState() => _ClientOnboardingPageState();
}

class _ClientOnboardingPageState extends State<ClientOnboardingPage> {
  int _tabIndex = 0; // 0=submissions, 1=templates
  String _searchQuery = '';
  String _templateFilter = 'All Templates';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load data from Supabase via BLoC on page open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingBloc>().add(LoadOnboardingDataEvent());
    });
  }

  // ─── HELPERS: Convert DB maps → local model instances ──────────────────────

  /// Parse a raw DB submission row into a [Submission] view-model.
  Submission _parseSubmission(Map<String, dynamic> row) {
    final createdAt = row['created_at'] != null
        ? DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();
    final diff = DateTime.now().difference(createdAt);
    String ago;
    if (diff.inMinutes < 60) {
      ago = '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      ago = '${diff.inHours} hours ago';
    } else {
      ago = '${diff.inDays} days ago';
    }

    final statusStr = row['status']?.toString() ?? 'pending';
    final IntakeStatus status;
    switch (statusStr) {
      case 'approved':
        status = IntakeStatus.approved;
        break;
      case 'review':
      case 'needs_review':
        status = IntakeStatus.review;
        break;
      case 'rejected':
        status = IntakeStatus.rejected;
        break;
      default:
        status = IntakeStatus.pending;
    }

    // The joined template name lives in onboarding_templates relationship
    final templateJoin = row['onboarding_templates'] ?? row['form_templates'];
    final templateName = (templateJoin is Map)
        ? templateJoin['name']?.toString() ?? ''
        : '';

    // Handle nested client or lead names
    String clientName = 'Unknown Client';
    final clientJoin = row['clients'];
    final leadJoin = row['leads'];
    if (clientJoin is Map) {
      clientName = clientJoin['name']?.toString() ?? 'Unknown Client';
    } else if (leadJoin is Map) {
      clientName = leadJoin['company']?.toString() ?? 'Unknown Client';
    } else {
      // Look into form_submission_answers
      final answers = row['form_submission_answers'];
      if (answers is List && answers.isNotEmpty) {
        String? companyNameAnswer;
        String? contactNameAnswer;
        
        final templateJoin = row['onboarding_templates'] ?? row['form_templates'];
        if (templateJoin is Map) {
          var sectionsRaw = templateJoin['sections'];
          if (sectionsRaw is String && sectionsRaw.isNotEmpty) {
            try {
              sectionsRaw = jsonDecode(sectionsRaw);
            } catch (_) {}
          }
          
          final Map<String, String> fieldIdToCode = {};
          if (sectionsRaw is List) {
            for (var sec in sectionsRaw) {
              if (sec is Map) {
                final questions = sec['questions'] ?? sec['form_fields'];
                if (questions is List) {
                  for (var q in questions) {
                    if (q is Map) {
                      final qId = q['id']?.toString();
                      final qCode = (q['fieldCode'] ?? q['code'])?.toString();
                      if (qId != null && qCode != null) {
                        fieldIdToCode[qId] = qCode;
                      }
                    }
                  }
                }
              }
            }
          }
          
          for (var ans in answers) {
            if (ans is Map) {
              final fId = ans['field_id']?.toString();
              final val = ans['answer_value']?.toString();
              if (fId != null && val != null && val.trim().isNotEmpty) {
                final code = fieldIdToCode[fId];
                if (code == 'company_name') {
                  companyNameAnswer = val;
                } else if (code == 'contact_name') {
                  contactNameAnswer = val;
                }
              }
            }
          }
        }
        
        if (companyNameAnswer != null) {
          clientName = companyNameAnswer;
        } else if (contactNameAnswer != null) {
          clientName = contactNameAnswer;
        }
      }
    }

    final progressVal = row['completion_rate'];
    final double progress = (progressVal is num)
        ? (progressVal as num).toDouble() / 100.0
        : (double.tryParse(progressVal?.toString() ?? '') ?? 0.0) / 100.0;

    return Submission(
      id: row['id']?.toString() ?? '',
      clientName: clientName,
      templateName: templateName,
      progress: progress,
      status: status,
      submittedAgo: ago,
    );
  }

  /// Parse a raw DB template row into an [OnboardingTemplate] view-model.
  OnboardingTemplate _parseTemplate(Map<String, dynamic> row) {
    final catStr = row['service_type']?.toString() ?? row['category']?.toString() ?? '';
    ServiceCategory cat;
    switch (catStr) {
      case 'Digital Marketing':
      case 'digital_marketing':
        cat = ServiceCategory.digitalMarketing;
        break;
      case 'Content Creation':
      case 'content_creation':
        cat = ServiceCategory.contentCreation;
        break;
      case 'SEO':
      case 'seo':
        cat = ServiceCategory.seo;
        break;
      case 'Branding':
      case 'branding':
        cat = ServiceCategory.branding;
        break;
      default:
        cat = ServiceCategory.webDevelopment;
    }

    final availStr = row['status']?.toString() ?? row['availability']?.toString() ?? 'active';
    TemplateAvailability avail;
    switch (availStr) {
      case 'draft':
        avail = TemplateAvailability.draft;
        break;
      case 'testing':
        avail = TemplateAvailability.testing;
        break;
      case 'archived':
        avail = TemplateAvailability.archived;
        break;
      default:
        avail = TemplateAvailability.active;
    }

    // sections stored in form_sections table from nested select OR sections column as JSON list
    List<FormSection> sections = [];
    var sectionsRaw = row['form_sections'] ?? row['sections'];
    if (sectionsRaw is String && sectionsRaw.isNotEmpty) {
      try {
        sectionsRaw = jsonDecode(sectionsRaw);
      } catch (_) {}
    }
    if (sectionsRaw is List) {
      sections = sectionsRaw.map((s) {
        final sm = s as Map<String, dynamic>;
        final qRawList = (sm['questions'] ?? sm['form_fields']) as List? ?? [];
        final qList = qRawList.map((q) {
          final qm = q as Map<String, dynamic>;
          final ftStr = (qm['fieldType'] ?? qm['field_type'] ?? 'text').toString();
          FieldType ft;
          switch (ftStr) {
            case 'textarea': ft = FieldType.textArea; break;
            case 'dropdown': ft = FieldType.dropdown; break;
            case 'multiselect': ft = FieldType.multiSelect; break;
            case 'radio': ft = FieldType.radioToggle; break;
            case 'url': ft = FieldType.urlValidation; break;
            case 'file': ft = FieldType.fileUpload; break;
            case 'date': ft = FieldType.dateInput; break;
            default: ft = FieldType.textInput;
          }

          // Parse choices from config['options'] or direct string
          String choices = '';
          final choicesRaw = qm['choices'];
          if (choicesRaw is String) {
            choices = choicesRaw;
          } else {
            final config = qm['config'];
            if (config is Map) {
              final opts = config['options'];
              if (opts is List) {
                choices = opts.join(', ');
              }
            }
          }

          return FormQuestion(
            id: qm['id']?.toString() ?? _generateUniqueId(),
            fieldCode: (qm['fieldCode'] ?? qm['code'])?.toString() ?? '',
            questionLabel: (qm['questionLabel'] ?? qm['label'])?.toString() ?? '',
            fieldType: ft,
            isRequired: qm['isRequired'] == true || qm['is_required'] == true,
            isSensitive: qm['isSensitive'] == true || qm['is_sensitive'] == true,
            choices: choices,
          );
        }).toList();

        return FormSection(
          id: sm['id']?.toString() ?? _generateUniqueId(),
          title: sm['title']?.toString() ?? '',
          description: sm['description']?.toString() ?? '',
          questions: qList,
        );
      }).toList();
    }

    return OnboardingTemplate(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      category: cat,
      availability: avail,
      sections: sections,
      version: (row['version'] is int) ? row['version'] as int : int.tryParse(row['version']?.toString() ?? '') ?? 1,
    );
  }

  List<OnboardingTemplate> _filteredTemplates(List<Map<String, dynamic>> rawTemplates) {
    var list = rawTemplates.map(_parseTemplate).toList();
    // Filter out archived templates by default to hide duplicate versions
    list = list.where((t) => t.availability != TemplateAvailability.archived).toList();
    if (_templateFilter == 'Dynamic Only') {
      list = list.where((t) => t.sections.isNotEmpty).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((t) =>
          t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  List<Submission> _filteredSubmissions(List<Map<String, dynamic>> rawSubmissions) {
    final all = rawSubmissions.map(_parseSubmission).toList();
    if (_searchQuery.isEmpty) return all;
    return all.where((s) =>
        s.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.templateName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _viewSubmission(Submission s) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.description_outlined, color: Color(0xFF00BCD4)),
              SizedBox(width: 8),
              Text(
                'Submission Details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Client Name: ${s.clientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Template: ${s.templateName}'),
              const SizedBox(height: 6),
              Text('Status: ${s.status.label.toUpperCase()}'),
              const SizedBox(height: 6),
              Text('Progress: ${(s.progress * 100).toInt()}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if (s.status != IntakeStatus.approved)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  // 1. Approve the submission in Supabase
                  context.read<OnboardingBloc>().add(
                    UpdateSubmissionStatusEvent(s.id, 'approved', progress: 1.0),
                  );

                  // 2. Add to active clients in Supabase
                  final client = ActiveClient(
                    id: _generateUniqueId(),
                    name: s.clientName,
                    email: '${s.clientName.toLowerCase().replaceAll(' ', '')}@ecraftz.com',
                    services: [s.templateName.contains('Web') ? 'Web Development' : 'Digital Marketing'],
                    contractValue: 25000,
                    onboardedAt: DateTime.now(),
                    templateUsed: s.templateName,
                  );
                  context.read<ClientBloc>().add(AddClientEvent(client));

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Client "${s.clientName}" approved & onboarded successfully!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                child: const Text('Approve & Onboard Client'),
              ),
          ],
        );
      },
    );
  }

  void _openFormBuilder({OnboardingTemplate? template}) {
    // Capture bloc BEFORE navigation (context may be stale inside onSave callback)
    final onboardingBloc = context.read<OnboardingBloc>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FormBuilderPage(
          template: template,
          onSave: (t) {
            // Build sections and fields as a nested structure of lists and maps
            final sectionsData = t.sections.map((s) => {
              'title': s.title,
              'description': s.description,
              'questions': s.questions.map((q) => {
                'fieldCode': q.fieldCode,
                'questionLabel': q.questionLabel,
                'fieldType': q.fieldType.name,
                'isRequired': q.isRequired,
                'isSensitive': q.isSensitive,
                'choices': q.choices,
              }).toList(),
            }).toList();

            final catStr = _categoryToDbString(t.category);
            final availStr = t.availability.name;

            final data = {
              'name': t.name,
              'description': t.description,
              'service_type': catStr,
              'status': availStr,
              'sections': sectionsData,
              'version': t.version,
            };

            if (template != null && template.id.isNotEmpty) {
              onboardingBloc.add(UpdateTemplateEvent(template.id, data));
            } else {
              onboardingBloc.add(CreateTemplateEvent(data));
            }
          },
        ),
      ),
    ).then((_) {
      // Reload after returning from form builder
      onboardingBloc.add(LoadTemplatesEvent());
    });
  }

  /// Converts ServiceCategory enum to DB string value.
  String _categoryToDbString(ServiceCategory cat) {
    switch (cat) {
      case ServiceCategory.digitalMarketing: return 'Digital Marketing';
      case ServiceCategory.contentCreation: return 'Content Creation';
      case ServiceCategory.seo: return 'SEO';
      case ServiceCategory.branding: return 'Branding';
      case ServiceCategory.webDevelopment: return 'Web Development';
    }
  }

  void _deleteTemplate(OnboardingTemplate t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Delete "${t.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // Delete from Supabase
              context.read<OnboardingBloc>().add(DeleteTemplateEvent(t.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _duplicateTemplate(OnboardingTemplate t) {
    final sectionsJson = jsonEncode(t.sections.map((s) => {
      'id': _generateUniqueId(),
      'title': s.title,
      'description': s.description,
      'questions': s.questions.map((q) => {
        'id': _generateUniqueId(),
        'fieldCode': q.fieldCode,
        'questionLabel': q.questionLabel,
        'fieldType': q.fieldType.name,
        'isRequired': q.isRequired,
        'isSensitive': q.isSensitive,
        'choices': q.choices,
      }).toList(),
    }).toList());

    context.read<OnboardingBloc>().add(CreateTemplateEvent({
      'name': '${t.name} (Copy)',
      'description': t.description,
      'category': _categoryToDbString(t.category),
      'availability': 'draft',
      'sections': sectionsJson,
      'version': t.version,
    }));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template duplicated'), backgroundColor: Color(0xFF10B981)),
    );
  }

  void _showSendLinkDialog(BuildContext context, OnboardingTemplate template) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _GenerateLinkDialog(template: template);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: isWide
            ? null
            : IconButton(
                icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client Onboarding',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryOf(context))),
            Text('Design onboarding templates and manage intakes.',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
          ],
        ),
        actions: [
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isDarkTheme = themeState.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDarkTheme ? Colors.white : const Color(0xFF374151),
                ),
                onPressed: () {
                  context.read<ThemeBloc>().add(ToggleThemeEvent());
                },
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderOf(context)),
        ),
      ),
      body: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state.status == OnboardingStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: const Color(0xFFEF4444),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () =>
                      context.read<OnboardingBloc>().add(LoadOnboardingDataEvent()),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == OnboardingStatus.loading &&
              state.templates.isEmpty &&
              state.submissions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeroBanner()),
                SliverToBoxAdapter(child: _buildStatsRow(state)),
                SliverToBoxAdapter(child: _buildTabBar()),
                SliverToBoxAdapter(
                  child: _tabIndex == 0
                      ? _buildSubmissionsTab(_filteredSubmissions(state.submissions))
                      : _buildTemplatesTab(_filteredTemplates(state.templates)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── HERO BANNER ─────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🚀', style: TextStyle(fontSize: 11)),
                SizedBox(width: 5),
                Text('ENTERPRISE INTAKE',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (_, constraints) {
            final isNarrow = constraints.maxWidth < 400;
            return isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Onboarding & Forms Manager',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2)),
                      const SizedBox(height: 8),
                      const Text(
                          'Design dynamic onboarding portal experiences, customize fields per service vertical.',
                          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
                      const SizedBox(height: 14),
                      _createTemplateBtn(),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Onboarding & Forms Manager',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2)),
                            const SizedBox(height: 8),
                            const Text(
                                'Design dynamic onboarding portal experiences, customize fields per service vertical.',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 12, height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _createTemplateBtn(),
                    ],
                  );
          }),
        ],
      ),
    );
  }

  Widget _createTemplateBtn() {
    return ElevatedButton.icon(
      onPressed: () => _openFormBuilder(),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Create Form Template', style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  // ── STATS ROW ────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(OnboardingState state) {
    final templates = state.templates;
    final submissions = state.submissions;
    final needsReview = submissions.where((s) {
      final status = s['status']?.toString() ?? '';
      return status == 'review' || status == 'needs_review' || status == 'pending';
    }).length;
    final completionPct = submissions.isEmpty
        ? 0
        : (submissions
                .map((s) => (s['progress'] is num) ? (s['progress'] as num).toDouble() : 0.0)
                .fold(0.0, (a, b) => a + b) /
            submissions.length *
            100)
            .toInt();
    final stats = [
      _StatData(Icons.description_outlined, 'Total Forms', '${templates.length}', 'Active Service Templates', const Color(0xFF3B82F6)),
      _StatData(Icons.bar_chart_outlined, 'Completion Rate', '$completionPct%', 'Average Onboarding Progress', const Color(0xFF8B5CF6)),
      _StatData(Icons.access_time_outlined, 'Needs Review', '$needsReview', 'Pending Lead Conversion', const Color(0xFFF59E0B)),
      _StatData(Icons.people_outline, 'Submissions', '${submissions.length}', 'Total Onboarding Submissions', const Color(0xFF10B981)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 95,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stats.length,
        itemBuilder: (context, index) => _StatCard(data: stats[index]),
      ),
    );
  }

  // ── TABS ─────────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _TabButton(
                label: 'Requirements Submissions',
                isSelected: _tabIndex == 0,
                onTap: () => setState(() {
                  _tabIndex = 0;
                  _searchQuery = '';
                }),
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: 'Templates Library',
                isSelected: _tabIndex == 1,
                onTap: () => setState(() {
                  _tabIndex = 1;
                  _searchQuery = '';
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: _tabIndex == 0 ? 'Search submissions…' : 'Search templates…',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 18),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          if (_tabIndex == 1) ...[
            const SizedBox(height: 10),
            Row(
              children: ['All Templates', 'Dynamic Only'].map((f) {
                final selected = _templateFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _templateFilter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: selected ? const Color(0xFF0F172A) : const Color(0xFFE5E7EB)),
                      ),
                      child: Text(f,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : const Color(0xFF6B7280))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── SUBMISSIONS TAB ───────────────────────────────────────────────────────────

  Widget _buildSubmissionsTab(List<Submission> subs) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Table header
          if (isWide)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgCardDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: _TableHeader('CLIENT NAME / TEMPLATE')),
                  Expanded(flex: 2, child: _TableHeader('CURRENT PROGRESS')),
                  Expanded(flex: 2, child: _TableHeader('INTAKE STATUS')),
                  Expanded(flex: 2, child: _TableHeader('SUBMITTED AT')),
                  Expanded(flex: 2, child: _TableHeader('ACTION')),
                ],
              ),
            ),
          if (subs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgCardDark : Colors.white,
                borderRadius: isWide ? const BorderRadius.vertical(bottom: Radius.circular(10)) : BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: const Center(
                child: Text('No submissions found',
                    style: TextStyle(color: Color(0xFF6B7280))),
              ),
            )
          else
            ...subs.map((s) => _SubmissionRow(
              submission: s,
              isWide: isWide,
              isLast: s == subs.last,
              onView: () => _viewSubmission(s),
              onDelete: () {
                // Delete from Supabase via BLoC
                context.read<OnboardingBloc>().add(DeleteSubmissionEvent(s.id));
              },
            )).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── TEMPLATES TAB ─────────────────────────────────────────────────────────────

  Widget _buildTemplatesTab(List<OnboardingTemplate> templates) {
    if (templates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.description_outlined,
                  size: 48, color: AppTheme.textMutedOf(context)),
              const SizedBox(height: 12),
              Text('No templates yet. Create your first onboarding form!',
                  style: TextStyle(color: AppTheme.textMutedOf(context))),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          LayoutBuilder(builder: (_, constraints) {
            final crossCount = constraints.maxWidth > 600 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth > 600 ? 1.6 : 2.0,
              ),
              itemCount: templates.length,
              itemBuilder: (_, i) => _TemplateCard(
                template: templates[i],
                onEdit: () => _openFormBuilder(template: templates[i]),
                onDelete: () => _deleteTemplate(templates[i]),
                onDuplicate: () => _duplicateTemplate(templates[i]),
                onSendLink: () => _showSendLinkDialog(context, templates[i]),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────

class _StatData {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  const _StatData(this.icon, this.title, this.value, this.subtitle, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(data.title,
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondaryOf(context), fontWeight: FontWeight.w500)),
              ),
              Icon(data.icon, size: 18, color: data.color),
            ],
          ),
          const Spacer(),
          Text(data.value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryOf(context))),
          Text(data.subtitle,
              style: TextStyle(fontSize: 10, color: AppTheme.textMutedOf(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── TAB BUTTON ───────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A)) : (isDark ? AppTheme.bgCardDark : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? (isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A)) : AppTheme.borderOf(context)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondaryOf(context))),
      ),
    );
  }
}

// ─── TABLE HEADER ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondaryOf(context),
            letterSpacing: 0.4));
  }
}

// ─── SUBMISSION ROW ───────────────────────────────────────────────────────────

class _SubmissionRow extends StatelessWidget {
  final Submission submission;
  final bool isWide;
  final bool isLast;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _SubmissionRow({
    required this.submission,
    required this.isWide,
    required this.isLast,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isWide) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderOf(context)),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Client Name + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(submission.clientName,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryOf(context))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: submission.status.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 12, color: submission.status.color),
                      const SizedBox(width: 4),
                      Text(submission.status.label,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: submission.status.color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: Template Name
            Text(submission.templateName,
                style: const TextStyle(fontSize: 11, color: Color(0xFF00BCD4)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            // Row 3: Progress bar + Percentage
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: submission.progress,
                      backgroundColor: isDark ? AppTheme.borderDark : const Color(0xFFE5E7EB),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(submission.progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryOf(context))),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppTheme.borderOf(context)),
            const SizedBox(height: 12),
            // Row 4: Submitted Ago + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Submitted ${submission.submittedAgo}',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMutedOf(context))),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onView,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF00BCD4),
                                  fontWeight: FontWeight.w600)),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward, size: 12, color: Color(0xFF00BCD4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        border: Border(
          left: BorderSide(color: AppTheme.borderOf(context)),
          right: BorderSide(color: AppTheme.borderOf(context)),
          bottom: BorderSide(color: isLast ? Colors.transparent : AppTheme.borderOf(context)),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(10))
            : BorderRadius.zero,
      ),
      child: Row(
        children: [
          // Client + template
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(submission.clientName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryOf(context))),
                Text(submission.templateName,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF00BCD4)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Progress
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: submission.progress,
                    backgroundColor: isDark ? AppTheme.borderDark : const Color(0xFFE5E7EB),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${(submission.progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: submission.status.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 12, color: submission.status.color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(submission.status.label,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: submission.status.color)),
                  ),
                ],
              ),
            ),
          ),
          // Time
          Expanded(
            flex: 2,
            child: Text(submission.submittedAgo,
                style: TextStyle(fontSize: 11, color: AppTheme.textMutedOf(context))),
          ),
          // Action
          Expanded(
            flex: 2,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onView,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Submission',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF00BCD4),
                              fontWeight: FontWeight.w600)),
                      Icon(Icons.arrow_forward, size: 12, color: Color(0xFF00BCD4)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline, size: 16, color: AppTheme.textMutedOf(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TEMPLATE CARD ────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final OnboardingTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onSendLink;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onSendLink,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          Row(
            children: [
              _CategoryBadge(category: template.category),
              const SizedBox(width: 6),
              _AvailabilityBadge(availability: template.availability),
              const Spacer(),
              Text('V${template.version}',
                  style: TextStyle(
                      fontSize: 10, color: AppTheme.textMutedOf(context), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryOf(context),
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(template.description,
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context), height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Actions row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconActionBtn(Icons.copy_outlined, onTap: onDuplicate),
                  const SizedBox(width: 6),
                  _IconActionBtn(Icons.bar_chart_outlined, onTap: () {}),
                  const SizedBox(width: 6),
                  _IconActionBtn(Icons.delete_outline, onTap: onDelete, color: Colors.red),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderOf(context)),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Text('Edit',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryOf(context))),
                          const SizedBox(width: 4),
                          Icon(Icons.settings, size: 12, color: AppTheme.textSecondaryOf(context)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onSendLink,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Row(
                        children: [
                          Text('Send Link',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          SizedBox(width: 4),
                          Icon(Icons.send, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _IconActionBtn(this.icon,
      {required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderOf(context)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color ?? AppTheme.textSecondaryOf(context)),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final ServiceCategory category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(category.label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: category.color)),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final TemplateAvailability availability;
  const _AvailabilityBadge({required this.availability});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: availability.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(availability.label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: availability.color)),
    );
  }
}

// ─── FORM BUILDER PAGE ────────────────────────────────────────────────────────

class _FormBuilderPage extends StatefulWidget {
  final OnboardingTemplate? template;
  final Function(OnboardingTemplate) onSave;

  const _FormBuilderPage({this.template, required this.onSave});

  @override
  State<_FormBuilderPage> createState() => _FormBuilderPageState();
}

class _FormBuilderPageState extends State<_FormBuilderPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late ServiceCategory _category;
  late TemplateAvailability _availability;
  late List<FormSection> _sections;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _category = t?.category ?? ServiceCategory.webDevelopment;
    _availability = t?.availability ?? TemplateAvailability.draft;
    _sections = t?.sections.map((s) => FormSection(
          id: s.id,
          title: s.title,
          description: s.description,
          questions: s.questions.map((q) => q.copy()).toList(),
        )).toList() ?? [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    setState(() {
      _sections.clear();
      if (preset == 'Web Development') {
        _nameCtrl.text = 'Web Development Dynamic Specification v1';
        _category = ServiceCategory.webDevelopment;
        _sections.add(FormSection(
          id: 'p1',
          title: 'Company Information',
          description: 'Base coordinates of the organization',
          questions: [
            FormQuestion(id: 'p1q1', fieldCode: 'company_name', questionLabel: 'Company Name', fieldType: FieldType.textInput, isRequired: true),
            FormQuestion(id: 'p1q2', fieldCode: 'contact_name', questionLabel: 'Contact Person Name', fieldType: FieldType.textInput, isRequired: true),
            FormQuestion(id: 'p1q3', fieldCode: 'contact_email', questionLabel: 'Official Email', fieldType: FieldType.textInput, isRequired: true),
          ],
        ));
      } else if (preset == 'Digital Marketing') {
        _nameCtrl.text = 'Digital Marketing Premium Intake v1';
        _category = ServiceCategory.digitalMarketing;
        _sections.add(FormSection(
          id: 'p2',
          title: 'Business Overview',
          description: 'Company context and social presence',
          questions: [
            FormQuestion(id: 'p2q1', fieldCode: 'brand_name', questionLabel: 'Brand Name', fieldType: FieldType.textInput, isRequired: true),
            FormQuestion(id: 'p2q2', fieldCode: 'target_audience', questionLabel: 'Target Audience', fieldType: FieldType.textArea, isRequired: true),
          ],
        ));
      } else if (preset == 'Content Creation') {
        _nameCtrl.text = 'Content Creation Requirements Questionnaire';
        _category = ServiceCategory.contentCreation;
        _sections.add(FormSection(
          id: 'p3',
          title: 'Content Brief',
          description: 'Creative tone and publishing targets',
          questions: [
            FormQuestion(id: 'p3q1', fieldCode: 'content_type', questionLabel: 'Content Type', fieldType: FieldType.multiSelect, isRequired: true, choices: 'Blog Posts, Social Media, Video Scripts, Email Newsletters'),
          ],
        ));
      }
    });
  }

  void _addSection() {
    setState(() {
      _sections.add(FormSection(
        id: _generateUniqueId(),
        title: 'New Section',
        description: '',
      ));
    });
  }

  void _addQuestion(FormSection section) {
    setState(() {
      section.questions.add(FormQuestion(
        id: _generateUniqueId(),
      ));
    });
  }

  void _deleteSection(FormSection section) {
    setState(() => _sections.removeWhere((s) => s.id == section.id));
  }

  void _deleteQuestion(FormSection section, FormQuestion q) {
    setState(() => section.questions.removeWhere((x) => x.id == q.id));
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template name is required'), backgroundColor: Colors.red),
      );
      return;
    }
    final t = OnboardingTemplate(
      id: widget.template?.id ?? _generateUniqueId(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      availability: _availability,
      sections: _sections,
      version: widget.template?.version ?? 1,
    );
    widget.onSave(t);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template saved!'), backgroundColor: Color(0xFF10B981)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : const Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dynamic Onboarding Form Builder',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context))),
            Text('Design zero-code, fully reusable service questionnaires.',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined, size: 14),
              label: const Text('Save Template Layout', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderOf(context)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preset chips
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('⚡', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 6),
                    Text('INSTANTLY LOAD PREDEFINED CORE OUTLINES',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                            letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                    'Select one of our premium onboarding presets to populate all questions, fields, and structures dynamically instantly:',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _PresetChip('🎯', 'Digital Marketing Preset', () => _applyPreset('Digital Marketing')),
                    _PresetChip('💻', 'Web Development Preset', () => _applyPreset('Web Development')),
                    _PresetChip('✏️', 'Content Creation Preset', () => _applyPreset('Content Creation')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Section 1: General Settings
          _SectionCard(
            number: '1',
            title: 'Template General Settings',
            child: Column(
              children: [
                _BuilderField(
                  label: 'Template Name',
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDec(context, 'e.g. Premium Branding Requirements Form'),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final isWide = MediaQuery.of(context).size.width > 600;
                    final categoryField = _BuilderField(
                      label: 'Service Category',
                      child: DropdownButtonFormField<ServiceCategory>(
                        value: _category,
                        isExpanded: true,
                        decoration: _inputDec(context, ''),
                        items: ServiceCategory.values.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.label,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    );
                    final availabilityField = _BuilderField(
                      label: 'Intake Availability State',
                      child: DropdownButtonFormField<TemplateAvailability>(
                        value: _availability,
                        isExpanded: true,
                        decoration: _inputDec(context, ''),
                        items: TemplateAvailability.values.map((a) {
                          return DropdownMenuItem(
                            value: a,
                            child: Text(
                              a.label,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _availability = v!),
                      ),
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: categoryField),
                          const SizedBox(width: 12),
                          Expanded(child: availabilityField),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          categoryField,
                          const SizedBox(height: 12),
                          availabilityField,
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _BuilderField(
                  label: 'Onboarding Portal Description',
                  child: TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: _inputDec(context, 'Brief directions displayed to clients as they begin requirements submission…'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Section 2: Form Steps
          Row(
            children: [
              const Expanded(
                child: Text('2. Interactive Form Steps & Questions',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addSection,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Color(0xFF374151)),
                      SizedBox(width: 4),
                      Text('Add Section',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_sections.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    style: BorderStyle.solid),
              ),
              child: const Center(
                child: Text('No sections yet. Add a section or apply a preset.',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
              ),
            )
          else
            ..._sections.map((section) => _SectionBuilder(
              key: ValueKey(section.id),
              section: section,
              onDelete: () => _deleteSection(section),
              onAddQuestion: () => _addQuestion(section),
              onDeleteQuestion: (q) => _deleteQuestion(section, q),
              onUpdate: () => setState(() {}),
            )).toList(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

InputDecoration _inputDec(BuildContext context, String hint) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 13),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.borderOf(context))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.borderOf(context))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true,
    fillColor: isDark ? AppTheme.bgCardDark : Colors.white,
  );
}

class _SectionCard extends StatelessWidget {
  final String number;
  final String title;
  final Widget child;

  const _SectionCard({required this.number, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. $title',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryOf(context))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BuilderField extends StatelessWidget {
  final String label;
  final Widget child;

  const _BuilderField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryOf(context))),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _PresetChip(this.emoji, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C2B35) : const Color(0xFFF0FDFE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))),
          ],
        ),
      ),
    );
  }
}

// ─── SECTION BUILDER ─────────────────────────────────────────────────────────

class _SectionBuilder extends StatefulWidget {
  final FormSection section;
  final VoidCallback onDelete;
  final VoidCallback onAddQuestion;
  final Function(FormQuestion) onDeleteQuestion;
  final VoidCallback onUpdate;

  const _SectionBuilder({
    super.key,
    required this.section,
    required this.onDelete,
    required this.onAddQuestion,
    required this.onDeleteQuestion,
    required this.onUpdate,
  });

  @override
  State<_SectionBuilder> createState() => _SectionBuilderState();
}

class _SectionBuilderState extends State<_SectionBuilder> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.section.title);
    _descCtrl = TextEditingController(text: widget.section.description);
    _titleCtrl.addListener(() {
      widget.section.title = _titleCtrl.text;
      widget.onUpdate();
    });
    _descCtrl.addListener(() {
      widget.section.description = _descCtrl.text;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _titleCtrl,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryOf(context)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Section Title',
                      hintStyle: TextStyle(color: AppTheme.textMutedOf(context)),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.textMutedOf(context)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextFormField(
              controller: _descCtrl,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Section description…',
                hintStyle: TextStyle(color: AppTheme.textMutedOf(context), fontSize: 12),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          Divider(height: 1, color: AppTheme.borderOf(context)),
          // Questions
          ...widget.section.questions.map((q) => _QuestionBuilder(
            key: ValueKey(q.id),
            question: q,
            onDelete: () {
              widget.onDeleteQuestion(q);
              setState(() {});
            },
          )).toList(),
          // Add question button
          GestureDetector(
            onTap: () {
              widget.onAddQuestion();
              setState(() {});
            },
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.borderOf(context), style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 14, color: AppTheme.textSecondaryOf(context)),
                  const SizedBox(width: 6),
                  Text('Add Dynamic Question Input',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryOf(context),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QUESTION BUILDER ─────────────────────────────────────────────────────────

class _QuestionBuilder extends StatefulWidget {
  final FormQuestion question;
  final VoidCallback onDelete;

  const _QuestionBuilder({super.key, required this.question, required this.onDelete});

  @override
  State<_QuestionBuilder> createState() => _QuestionBuilderState();
}

class _QuestionBuilderState extends State<_QuestionBuilder> {
  late TextEditingController _codeCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _choicesCtrl;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _codeCtrl = TextEditingController(text: q.fieldCode);
    _labelCtrl = TextEditingController(text: q.questionLabel);
    _choicesCtrl = TextEditingController(text: q.choices);
    _codeCtrl.addListener(() => q.fieldCode = _codeCtrl.text);
    _labelCtrl.addListener(() => q.questionLabel = _labelCtrl.text);
    _choicesCtrl.addListener(() => q.choices = _choicesCtrl.text);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _labelCtrl.dispose();
    _choicesCtrl.dispose();
    super.dispose();
  }

  bool get _needsChoices =>
      widget.question.fieldType == FieldType.dropdown ||
      widget.question.fieldType == FieldType.multiSelect ||
      widget.question.fieldType == FieldType.radioToggle;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isWide = MediaQuery.of(context).size.width > 600;

    final fieldCodeWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FIELD CODE (UNIQUE ID)',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryOf(context),
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        TextField(
          controller: _codeCtrl,
          style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context)),
          decoration: _inputDec(context, 'field_code'),
        ),
      ],
    );

    final questionLabelWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUESTION LABEL',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryOf(context),
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        TextField(
          controller: _labelCtrl,
          style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context)),
          decoration: _inputDec(context, 'Question Label'),
        ),
      ],
    );

    final inputElementTypeWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INPUT ELEMENT TYPE',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryOf(context),
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        DropdownButtonFormField<FieldType>(
          value: q.fieldType,
          decoration: _inputDec(context, ''),
          isExpanded: true,
          style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context)),
          items: FieldType.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(t.label, style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context)), overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) => setState(() => q.fieldType = v!),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fieldCodeWidget),
                const SizedBox(width: 8),
                Expanded(child: questionLabelWidget),
                const SizedBox(width: 8),
                Expanded(child: inputElementTypeWidget),
                const SizedBox(width: 8),
                // Checkboxes + delete
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Checkbox(
                            value: q.isRequired,
                            onChanged: (v) => setState(() => q.isRequired = v!),
                            activeColor: const Color(0xFF00BCD4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('Required',
                            style: TextStyle(fontSize: 11, color: AppTheme.textPrimaryOf(context))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Checkbox(
                            value: q.isSensitive,
                            onChanged: (v) => setState(() => q.isSensitive = v!),
                            activeColor: const Color(0xFF00BCD4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('Sensitive Key',
                            style: TextStyle(fontSize: 11, color: AppTheme.textPrimaryOf(context))),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 16, color: AppTheme.textMutedOf(context)),
                  onPressed: widget.onDelete,
                  padding: const EdgeInsets.only(left: 4),
                  constraints: const BoxConstraints(),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fieldCodeWidget,
                const SizedBox(height: 8),
                questionLabelWidget,
                const SizedBox(height: 8),
                inputElementTypeWidget,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Checkbox(
                            value: q.isRequired,
                            onChanged: (v) => setState(() => q.isRequired = v!),
                            activeColor: const Color(0xFF00BCD4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('Required',
                            style: TextStyle(fontSize: 11, color: AppTheme.textPrimaryOf(context))),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Checkbox(
                            value: q.isSensitive,
                            onChanged: (v) => setState(() => q.isSensitive = v!),
                            activeColor: const Color(0xFF00BCD4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('Sensitive Key',
                            style: TextStyle(fontSize: 11, color: AppTheme.textPrimaryOf(context))),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFEF4444)),
                      onPressed: widget.onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          // Choices config
          if (_needsChoices) ...[
            const SizedBox(height: 8),
            Text('CHOICES CONFIGURATION (SEPARATED BY COMMAS)',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondaryOf(context),
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            TextField(
              controller: _choicesCtrl,
              style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context)),
              decoration: _inputDec(context, 'Option 1, Option 2, Option 3'),
            ),
          ],
          const SizedBox(height: 8),
          Divider(color: AppTheme.borderOf(context)),
        ],
      ),
    );
  }
}

class _GenerateLinkDialog extends StatefulWidget {
  final OnboardingTemplate template;

  const _GenerateLinkDialog({required this.template});

  @override
  State<_GenerateLinkDialog> createState() => _GenerateLinkDialogState();
}

class _GenerateLinkDialogState extends State<_GenerateLinkDialog> {
  bool _isGenerated = false;
  bool _isLoading = false;
  late String _portalUrl;

  @override
  void initState() {
    super.initState();
    _portalUrl = 'https://crm-dusky-two-65.vercel.app/crm/onboarding/portal/${widget.template.id}';
  }

  Future<void> _generateAndCopy() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await SupabaseService.client.from('form_submissions').insert({
        'template_id': widget.template.id,
        'organization_id': '00000000-0000-0000-0000-000000000000',
        'status': 'draft',
        'completion_rate': 0.0,
        'current_step': 0,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select('id').single();

      final submissionId = res['id'] as String;
      _portalUrl = 'https://crm-dusky-two-65.vercel.app/crm/onboarding/portal/$submissionId';

      await Clipboard.setData(ClipboardData(text: _portalUrl));

      if (mounted) {
        context.read<OnboardingBloc>().add(LoadSubmissionsEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portal link generated and copied to clipboard!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
      setState(() {
        _isGenerated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate intake link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareViaWhatsApp() async {
    final message = Uri.encodeComponent('Here is your client requirement onboarding portal link: $_portalUrl');
    final whatsappUri = Uri.parse('https://wa.me/?text=$message');
    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalNonBrowserApplication);
    } catch (_) {
      try {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch WhatsApp. Please copy the link instead.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareViaEmail() async {
    final subject = Uri.encodeComponent('Client Requirement Onboarding Form');
    final body = Uri.encodeComponent('Dear Client,\n\nPlease fill out the client requirement onboarding form at your earliest convenience:\n$_portalUrl\n\nBest regards,\nEcraftz Team');
    final emailUri = Uri.parse('mailto:?subject=$subject&body=$body');
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalNonBrowserApplication);
    } catch (_) {
      try {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch Email client. Please copy the link instead.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _previewPortal() async {
    final previewUri = Uri.parse(_portalUrl);
    try {
      await launchUrl(previewUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not preview portal link.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.borderOf(context), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF00BCD4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generate Onboarding Portal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create and share a secure, dynamic client intake path.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Template Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.template.category.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.template.category.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: widget.template.category.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'V${widget.template.version}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMutedOf(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.template.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Conditional view for Generate / Success states
                if (!_isGenerated) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _generateAndCopy,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.link_rounded, size: 18),
                    label: Text(
                      _isLoading ? 'Generating Link...' : 'Generate & Copy Intake Link',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure Portal Link Generated!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Successfully copied to your clipboard. Send this to the client to begin intake onboarding.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'INTAKE PORTAL URL:',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryOf(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.borderOf(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              _portalUrl,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textPrimaryOf(context),
                                  decoration: TextDecoration.underline),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: _portalUrl));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to clipboard!'),
                                  backgroundColor: Color(0xFF10B981),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(7),
                                bottomRight: Radius.circular(7),
                              ),
                            ),
                            child: const Text(
                              'Copy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _previewPortal,
                          icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF00BCD4)),
                          label: const Text(
                            'Preview Portal',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00BCD4)),
                          ),
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () {
                          setState(() {
                            _isGenerated = false;
                          });
                        },
                        child: const Text(
                          'Generate Another Portal',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: AppTheme.borderOf(context)),
                  const SizedBox(height: 12),
                  Text(
                    'SHARE INTAKE PORTAL LINK:',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryOf(context),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _shareViaWhatsApp,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: const Text(
                            'WhatsApp',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A84FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _shareViaEmail,
                          icon: const Icon(Icons.email_outlined, size: 16),
                          label: const Text(
                            'Email Link',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}