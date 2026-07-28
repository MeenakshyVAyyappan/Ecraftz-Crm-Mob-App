import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/document_vault/document_vault_bloc.dart';
import '../../blocs/client/client_bloc.dart';
import '../../models/document_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';

class DocumentVaultScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool showAppBar;

  const DocumentVaultScreen({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.showAppBar = true,
  });

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    context.read<DocumentVaultBloc>().add(LoadDocumentsEvent());
    context.read<ClientBloc>().add(LoadClientsEvent());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CrmDocument> _filtered(List<CrmDocument> docs) {
    return docs.where((doc) {
      final matchesSearch = _searchQuery.isEmpty ||
          doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (doc.clientName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (doc.category).toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _categoryFilter == 'All' ||
          doc.category.toLowerCase() == _categoryFilter.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showUploadDialog() {
    final titleCtrl = TextEditingController();
    String category = 'Contracts';
    String? selectedClientId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final clientsState = context.watch<ClientBloc>().state;
          return AlertDialog(
            title: const Text('Upload Document'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Document Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(hintText: 'E.g., Client Service Agreement'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: category,
                    isExpanded: true,
                    items: ['Contracts', 'Invoices', 'Proposals', 'Technical Specs', 'General']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Link to Client', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: selectedClientId,
                    isExpanded: true,
                    hint: const Text('Select Client (Optional)'),
                    items: clientsState.clients
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (val) => setDlgState(() => selectedClientId = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3)),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) {
                    AppSnackBar.showCustom(context, const SnackBar(content: Text('Please enter a document title.')));
                    return;
                  }
                  
                  // For demo/upload simulation, create a dummy temp file if no physical file picked
                  final tempFile = File('${Directory.systemTemp.path}/$title.pdf');
                  if (!tempFile.existsSync()) {
                    tempFile.writeAsStringSync('Sample document payload');
                  }

                  context.read<DocumentVaultBloc>().add(UploadDocumentEvent(
                    title: title,
                    file: tempFile,
                    category: category,
                    clientId: selectedClientId,
                  ));

                  Navigator.pop(ctx);
                  AppSnackBar.showCustom(context, const SnackBar(
                    content: Text('Document uploaded to Vault!'),
                    backgroundColor: Colors.green,
                  ));
                },
                child: const Text('Upload', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(CrmDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.title}" from Vault?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<DocumentVaultBloc>().add(DeleteDocumentEvent(doc.id));
              Navigator.pop(ctx);
              AppSnackBar.showCustom(context, const SnackBar(
                content: Text('Document deleted'),
                backgroundColor: Colors.red,
              ));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
            Text('Document Vault', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textTitle)),
            Text('Secure organization-wide document repository', style: TextStyle(fontSize: 11, color: textSub)),
          ],
        ),
      ) : null,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2196F3),
        onPressed: _showUploadDialog,
        child: const Icon(Icons.upload_file_rounded, color: Colors.white),
      ),
      body: BlocBuilder<DocumentVaultBloc, DocumentVaultState>(
        builder: (context, state) {
          if (state.status == DocumentVaultStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredDocs = _filtered(state.documents);

          return Column(
            children: [
              // Search and Category Chips
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search documents by title, client, or category...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Contracts', 'Invoices', 'Proposals', 'Technical Specs', 'General'].map((cat) {
                          final isSel = _categoryFilter == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(cat, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : textTitle)),
                              selected: isSel,
                              selectedColor: const Color(0xFF2196F3),
                              onSelected: (_) => setState(() => _categoryFilter = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(child: Text('No documents in Vault.', style: TextStyle(color: textSub, fontSize: 13)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredDocs.length,
                        itemBuilder: (ctx, idx) {
                          final doc = filteredDocs[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: isDark ? AppTheme.bgCardDark : Colors.white,
                            child: ListTile(
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF2196F3)),
                              ),
                              title: Text(
                                doc.title,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textTitle),
                              ),
                              subtitle: Text(
                                '${doc.category} • ${doc.clientName ?? "Internal"} • ${DateFormat("MMM d, yyyy").format(doc.createdAt)}',
                                style: TextStyle(fontSize: 11, color: textSub),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.download_rounded, color: Colors.blue, size: 20),
                                    onPressed: () {
                                      AppSnackBar.showCustom(context, SnackBar(
                                        content: Text('Downloading "${doc.title}"...'),
                                        backgroundColor: Colors.blue,
                                      ));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _confirmDelete(doc),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
