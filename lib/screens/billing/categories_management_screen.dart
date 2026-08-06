import 'package:flutter/material.dart';
import '../../models/financial_category_model.dart';
import '../../services/financials_service.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen> {
  int _selectedSubTab = 0; // 0: Income Categories, 1: Expense Categories
  List<FinancialCategoryModel> _incomeCategories = [];
  List<FinancialCategoryModel> _expenseCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final inc = await FinancialsService.getCategories(type: 'income');
    final exp = await FinancialsService.getCategories(type: 'expense');

    if (mounted) {
      setState(() {
        _incomeCategories = inc;
        _expenseCategories = exp;
        _isLoading = false;
      });
    }
  }

  void _showAddCategoryDialog(String type) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add New ${type == "income" ? "Income" : "Expense"} Category',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'e.g. ${type == "income" ? "Consulting Fees" : "Office Rent"}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Short summary of this category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final model = FinancialCategoryModel(
                organizationId: '',
                name: nameCtrl.text.trim(),
                type: type,
                description: descCtrl.text.trim(),
                color: type == 'income' ? 'emerald' : 'rose',
              );
              await FinancialsService.addCategory(model);
              _loadCategories();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'income' ? Colors.teal.shade700 : Colors.pink.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Save Category', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _selectedSubTab == 0;
    final activeList = isIncome ? _incomeCategories : _expenseCategories;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCategories,
          child: Column(
            children: [
              // Top Banner Header Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade800, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.shade700.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.category, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'FINANCIAL CATEGORY MANAGEMENT',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Organize custom income inflows and expense outflows taxonomy for accurate financial reporting.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Custom Segmented Pill Tab Toggle Bar (Responsive & Overflow-Free)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Sub Tab 1: Income Categories
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSubTab = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isIncome ? Colors.teal.shade700 : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isIncome
                                  ? [
                                      BoxShadow(
                                        color: Colors.teal.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 16,
                                  color: isIncome ? Colors.white : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Income (${_incomeCategories.length})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isIncome ? Colors.white : Colors.grey.shade800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Sub Tab 2: Expense Categories
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSubTab = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isIncome ? Colors.pink.shade700 : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !isIncome
                                  ? [
                                      BoxShadow(
                                        color: Colors.pink.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 16,
                                  color: !isIncome ? Colors.white : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Expense (${_expenseCategories.length})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: !isIncome ? Colors.white : Colors.grey.shade800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Categories Cards Listing Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : activeList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 54,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No ${isIncome ? "income" : "expense"} categories created yet.',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: activeList.length,
                            itemBuilder: (context, index) {
                              final cat = activeList[index];
                              final accentColor = isIncome ? Colors.teal : Colors.pink;

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    children: [
                                      // Leading Color Avatar Icon
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: accentColor.withOpacity(0.12),
                                        child: Icon(
                                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                          color: accentColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Category Name Badge & Description
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: accentColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: accentColor.withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                cat.name.toUpperCase(),
                                                style: TextStyle(
                                                  color: accentColor.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              cat.description != null && cat.description!.isNotEmpty
                                                  ? cat.description!
                                                  : 'Standard ${isIncome ? "income source" : "expense breakdown"} category.',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Edit / Delete Actions
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {},
                                            tooltip: 'Edit Category',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () {},
                                            tooltip: 'Delete Category',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(isIncome ? 'income' : 'expense'),
        icon: const Icon(Icons.add),
        label: Text('+ ADD ${isIncome ? "INCOME" : "EXPENSE"} CATEGORY'),
        backgroundColor: isIncome ? Colors.teal.shade700 : Colors.pink.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
