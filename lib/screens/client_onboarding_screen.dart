// client_onboarding_page.dart
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

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

enum TemplateAvailability { active, draft, testing }

extension TemplateAvailabilityExt on TemplateAvailability {
  String get label {
    switch (this) {
      case TemplateAvailability.active: return 'ACTIVE';
      case TemplateAvailability.draft: return 'DRAFT';
      case TemplateAvailability.testing: return 'TESTING';
    }
  }

  Color get color {
    switch (this) {
      case TemplateAvailability.active: return const Color(0xFF10B981);
      case TemplateAvailability.draft: return const Color(0xFF6B7280);
      case TemplateAvailability.testing: return const Color(0xFFF59E0B);
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

  final List<Submission> _submissions = [
    const Submission(id: '1', clientName: 'arsenal', templateName: 'Digital Marketing Premium Intake v1', progress: 1.0, status: IntakeStatus.approved, submittedAgo: '3 days ago'),
    const Submission(id: '2', clientName: 'janani', templateName: 'Web Development Dynamic Specification v1', progress: 1.0, status: IntakeStatus.approved, submittedAgo: '6 days ago'),
  ];

  final List<OnboardingTemplate> _templates = [
    OnboardingTemplate(
      id: '1',
      name: 'Web Development Dynamic Specification v1',
      description: 'Structured system layout detailing server, database hosting, expected pages, and design style.',
      category: ServiceCategory.webDevelopment,
      availability: TemplateAvailability.active,
      version: 1,
      sections: [
        FormSection(id: 's1', title: 'Company Information', description: 'Base details for branding', questions: [
          FormQuestion(id: 'q1', fieldCode: 'company_name', questionLabel: 'Company Name', fieldType: FieldType.textInput, isRequired: true),
          FormQuestion(id: 'q2', fieldCode: 'contact_name', questionLabel: 'Contact Person Name', fieldType: FieldType.textInput, isRequired: true),
          FormQuestion(id: 'q3', fieldCode: 'contact_email', questionLabel: 'Official Email', fieldType: FieldType.textInput, isRequired: true),
          FormQuestion(id: 'q4', fieldCode: 'services_needed', questionLabel: 'Interested Services (Select all that apply)', fieldType: FieldType.multiSelect, isRequired: true, choices: 'Web Development, Digital Marketing, Content Creation, SEO Services, Branding & Design, Social Media Management'),
        ]),
        FormSection(id: 's2', title: 'Specification Detail', description: 'Hosting setups, preferred pages, design specifications', questions: [
          FormQuestion(id: 'q5', fieldCode: 'domain_status', questionLabel: 'Domain/Hosting Status', fieldType: FieldType.dropdown, isRequired: true, choices: 'Have Domain & Hosting, Need Both Domain & Hosting, Have Domain, Need Hosting'),
          FormQuestion(id: 'q6', fieldCode: 'existing_site', questionLabel: 'Existing Website URL', fieldType: FieldType.urlValidation),
          FormQuestion(id: 'q7', fieldCode: 'required_pages', questionLabel: 'Required Pages', fieldType: FieldType.textArea, isRequired: true),
          FormQuestion(id: 'q8', fieldCode: 'ecommerce_needed', questionLabel: 'Ecommerce Needed?', fieldType: FieldType.radioToggle, isRequired: true, choices: 'Yes, No'),
          FormQuestion(id: 'q9', fieldCode: 'payment_gateway', questionLabel: 'Preferred Payment Gateway?', fieldType: FieldType.textInput),
          FormQuestion(id: 'q10', fieldCode: 'admin_panel', questionLabel: 'Admin Panel Needed?', fieldType: FieldType.radioToggle, isRequired: true, choices: 'Yes, No'),
          FormQuestion(id: 'q11', fieldCode: 'booking_system', questionLabel: 'Booking System?', fieldType: FieldType.radioToggle, isRequired: true, choices: 'Yes, No'),
          FormQuestion(id: 'q12', fieldCode: 'design_style', questionLabel: 'Preferred Design Style', fieldType: FieldType.textInput, isRequired: true),
        ]),
      ],
    ),
    OnboardingTemplate(
      id: '2',
      name: 'Content Creation Requirements Questionnaire',
      description: 'Creative tone, assets availability, and publishing targets.',
      category: ServiceCategory.contentCreation,
      availability: TemplateAvailability.active,
      version: 1,
    ),
    OnboardingTemplate(
      id: '3',
      name: 'Digital Marketing Premium Intake v1',
      description: 'Comprehensive intake request encompassing Company context, Social channels, and Credential files.',
      category: ServiceCategory.digitalMarketing,
      availability: TemplateAvailability.active,
      version: 1,
    ),
  ];

  List<OnboardingTemplate> get _filteredTemplates {
    var list = _templates;
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

  List<Submission> get _filteredSubmissions {
    if (_searchQuery.isEmpty) return _submissions;
    return _submissions.where((s) =>
        s.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.templateName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _openFormBuilder({OnboardingTemplate? template}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FormBuilderPage(
          template: template,
          onSave: (t) {
            setState(() {
              final idx = _templates.indexWhere((x) => x.id == t.id);
              if (idx != -1) {
                _templates[idx] = t;
              } else {
                _templates.add(t);
              }
            });
          },
        ),
      ),
    );
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
              setState(() => _templates.removeWhere((x) => x.id == t.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _duplicateTemplate(OnboardingTemplate t) {
    setState(() {
      _templates.add(OnboardingTemplate(
        id: _generateUniqueId(),
        name: '${t.name} (Copy)',
        description: t.description,
        category: t.category,
        availability: TemplateAvailability.draft,
        sections: t.sections.map((s) => FormSection(
          id: _generateUniqueId(),
          title: s.title,
          description: s.description,
          questions: s.questions.map((q) => q.copy()).toList(),
        )).toList(),
        version: t.version,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template duplicated'), backgroundColor: Color(0xFF10B981)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: AppDrawer(
        selectedIndex: widget.selectedIndex,
        onItemSelected: (i) {
          widget.onItemSelected(i);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF374151)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client Onboarding',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827))),
            Text('Design onboarding templates and manage intakes.',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroBanner()),
            SliverToBoxAdapter(child: _buildStatsRow()),
            SliverToBoxAdapter(child: _buildTabBar()),
            SliverToBoxAdapter(
              child: _tabIndex == 0 ? _buildSubmissionsTab() : _buildTemplatesTab(),
            ),
          ],
        ),
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

  Widget _buildStatsRow() {
    final stats = [
      _StatData(Icons.description_outlined, 'Total Forms', '${_templates.length}', 'Active Service Templates', const Color(0xFF3B82F6)),
      _StatData(Icons.bar_chart_outlined, 'Completion Rate', '100%', 'Average Onboarding Progress', const Color(0xFF8B5CF6)),
      _StatData(Icons.access_time_outlined, 'Needs Review', '0', 'Pending Lead Conversion', const Color(0xFFF59E0B)),
      _StatData(Icons.people_outline, 'Drafts Saved', '0', 'Active Onboarding Sessions', const Color(0xFF10B981)),
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

  Widget _buildSubmissionsTab() {
    final subs = _filteredSubmissions;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Table header
          if (isWide)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                color: Colors.white,
                borderRadius: isWide ? const BorderRadius.vertical(bottom: Radius.circular(10)) : BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Center(
                child: Text('No submissions found',
                    style: TextStyle(color: Color(0xFF6B7280))),
              ),
            )
          else
            ...subs.map((s) => _SubmissionRow(submission: s, isWide: isWide, isLast: s == subs.last)).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── TEMPLATES TAB ─────────────────────────────────────────────────────────────

  Widget _buildTemplatesTab() {
    final templates = _filteredTemplates;
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
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
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
              ),
              Icon(data.icon, size: 18, color: data.color),
            ],
          ),
          const Spacer(),
          Text(data.value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          Text(data.subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE5E7EB)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6B7280))),
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
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            letterSpacing: 0.4));
  }
}

// ─── SUBMISSION ROW ───────────────────────────────────────────────────────────

class _SubmissionRow extends StatelessWidget {
  final Submission submission;
  final bool isWide;
  final bool isLast;

  const _SubmissionRow({
    required this.submission,
    required this.isWide,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
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
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
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
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(submission.progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            // Row 4: Submitted Ago + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Submitted ${submission.submittedAgo}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {},
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
                      onTap: () {},
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
        color: Colors.white,
        border: Border(
          left: const BorderSide(color: Color(0xFFE5E7EB)),
          right: const BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: isLast ? Colors.transparent : const Color(0xFFE5E7EB)),
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
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827))),
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
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${(submission.progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF374151))),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ),
          // Action
          Expanded(
            flex: 2,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
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
                  onTap: () {},
                  child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF9CA3AF)),
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

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
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
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(template.description,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4),
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
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Row(
                        children: [
                          Text('Edit',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151))),
                          SizedBox(width: 4),
                          Icon(Icons.settings, size: 12, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {},
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
  final Color color;

  const _IconActionBtn(this.icon,
      {required this.onTap, this.color = const Color(0xFF6B7280)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: color),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dynamic Onboarding Form Builder',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            Text('Design zero-code, fully reusable service questionnaires.',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
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
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
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
                    decoration: _inputDec('e.g. Premium Branding Requirements Form'),
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
                        decoration: _inputDec(''),
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
                        decoration: _inputDec(''),
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
                    decoration: _inputDec('Brief directions displayed to clients as they begin requirements submission…'),
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

InputDecoration _inputDec(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true,
    fillColor: Colors.white,
  );
}

class _SectionCard extends StatelessWidget {
  final String number;
  final String title;
  final Widget child;

  const _SectionCard({required this.number, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. $title',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
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
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDFE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0284C7))),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Section Title',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextFormField(
              controller: _descCtrl,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Section description…',
                hintStyle: TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
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
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 14, color: Color(0xFF6B7280)),
                  SizedBox(width: 6),
                  Text('Add Dynamic Question Input',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
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
        const Text('FIELD CODE (UNIQUE ID)',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        TextField(
          controller: _codeCtrl,
          style: const TextStyle(fontSize: 12),
          decoration: _inputDec('field_code'),
        ),
      ],
    );

    final questionLabelWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUESTION LABEL',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        TextField(
          controller: _labelCtrl,
          style: const TextStyle(fontSize: 12),
          decoration: _inputDec('Question Label'),
        ),
      ],
    );

    final inputElementTypeWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('INPUT ELEMENT TYPE',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        DropdownButtonFormField<FieldType>(
          value: q.fieldType,
          decoration: _inputDec(''),
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
          items: FieldType.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(t.label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
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
                        const Text('Required',
                            style: TextStyle(fontSize: 11, color: Color(0xFF374151))),
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
                        const Text('Sensitive Key',
                            style: TextStyle(fontSize: 11, color: Color(0xFF374151))),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Color(0xFF9CA3AF)),
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
                        const Text('Required',
                            style: TextStyle(fontSize: 11, color: Color(0xFF374151))),
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
                        const Text('Sensitive Key',
                            style: TextStyle(fontSize: 11, color: Color(0xFF374151))),
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
            const Text('CHOICES CONFIGURATION (SEPARATED BY COMMAS)',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            TextField(
              controller: _choicesCtrl,
              style: const TextStyle(fontSize: 12),
              decoration: _inputDec('Option 1, Option 2, Option 3'),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF3F4F6)),
        ],
      ),
    );
  }
}