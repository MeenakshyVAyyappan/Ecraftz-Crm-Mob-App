import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../screens/Super_Admin/asset_renewal.dart';
import 'supabase_service.dart';

class RenewalImportResult {
  final int totalRows;
  final int successCount;
  final int failedCount;
  final List<String> errorDetails;

  RenewalImportResult({
    required this.totalRows,
    required this.successCount,
    required this.failedCount,
    required this.errorDetails,
  });
}

class RenewalImportService {
  final SupabaseClient _client = SupabaseService.client;

  /// Pick an Excel file (.xlsx / .xls) from the device
  Future<FilePickerResult?> pickExcelFile() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Process & Import Excel File Bytes into Supabase renewals table
  Future<RenewalImportResult> importRenewalsFromExcel({
    required Uint8List bytes,
    Function(int current, int total)? onProgress,
  }) async {
    int successCount = 0;
    int failedCount = 0;
    final List<String> errorDetails = [];

    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return RenewalImportResult(
        totalRows: 0,
        successCount: 0,
        failedCount: 1,
        errorDetails: ['The selected Excel file contains no worksheets.'],
      );
    }

    final tableKey = excel.tables.keys.first;
    final sheet = excel.tables[tableKey];
    if (sheet == null || sheet.maxRows <= 1) {
      return RenewalImportResult(
        totalRows: 0,
        successCount: 0,
        failedCount: 0,
        errorDetails: ['The selected worksheet is empty or only contains headers.'],
      );
    }

    // 1. Fetch CRM Clients to automatically link them by name if matched
    List<Map<String, dynamic>> crmClients = [];
    try {
      final data = await _client.from('clients').select('id, name');
      crmClients = List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('Error loading CRM clients for linking: $e');
    }

    String? findClientIdByName(String name) {
      final clean = name.trim().toLowerCase();
      if (clean.isEmpty) return null;
      for (final c in crmClients) {
        if (c['name'].toString().toLowerCase() == clean) {
          return c['id'].toString();
        }
      }
      return null;
    }

    // 2. Identify column mappings based on headers (Row 0)
    int domainIdx = -1;
    int clientNameIdx = -1;
    int sourceIdx = -1;
    int categoryIdx = -1;
    int expiryIdx = -1;
    int amountIdx = -1;
    int statusIdx = -1;
    int remarksIdx = -1;

    final headerRow = sheet.rows[0];
    for (int i = 0; i < headerRow.length; i++) {
      final cellVal = headerRow[i]?.value?.toString().toLowerCase().trim() ?? '';
      if (cellVal.isEmpty) continue;

      if (cellVal.contains('domain') || cellVal.contains('asset') || cellVal.contains('service name') || cellVal.contains('description')) {
        domainIdx = i;
      } else if (cellVal.contains('client') || cellVal.contains('customer')) {
        clientNameIdx = i;
      } else if (cellVal.contains('source') || cellVal.contains('registrar') || cellVal.contains('provider')) {
        sourceIdx = i;
      } else if (cellVal.contains('category') || cellVal.contains('type')) {
        categoryIdx = i;
      } else if (cellVal.contains('expiry') || cellVal.contains('expiration') || cellVal.contains('due') || cellVal.contains('date')) {
        expiryIdx = i;
      } else if (cellVal.contains('amount') || cellVal.contains('price') || cellVal.contains('cost') || cellVal.contains('fee')) {
        amountIdx = i;
      } else if (cellVal.contains('status') || cellVal.contains('state')) {
        statusIdx = i;
      } else if (cellVal.contains('remark') || cellVal.contains('note') || cellVal.contains('upload')) {
        remarksIdx = i;
      }
    }

    // Fallbacks if not found by headers
    if (domainIdx == -1) domainIdx = 0;
    if (clientNameIdx == -1) clientNameIdx = 1 < headerRow.length ? 1 : -1;
    if (sourceIdx == -1) sourceIdx = 2 < headerRow.length ? 2 : -1;
    if (categoryIdx == -1) categoryIdx = 3 < headerRow.length ? 3 : -1;
    if (expiryIdx == -1) expiryIdx = 4 < headerRow.length ? 4 : -1;
    if (amountIdx == -1) amountIdx = 5 < headerRow.length ? 5 : -1;
    if (statusIdx == -1) statusIdx = 6 < headerRow.length ? 6 : -1;
    if (remarksIdx == -1) remarksIdx = 7 < headerRow.length ? 7 : -1;

    final totalRows = sheet.maxRows - 1;

    // 3. Process each data row
    for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (row.isEmpty) continue;

      if (onProgress != null) {
        onProgress(rowIndex, totalRows);
      }

      final cellDomain = _getCellValue(row, domainIdx);
      // Skip row if domain/asset description is blank
      if (cellDomain.isEmpty) {
        failedCount++;
        errorDetails.add('Row ${rowIndex + 1}: Skip - DOMAIN / ASSET NAME is required.');
        continue;
      }

      final rawClientName = clientNameIdx != -1 ? _getCellValue(row, clientNameIdx) : '';
      final finalClientName = rawClientName.isNotEmpty ? rawClientName : cellDomain;

      final cellSource = sourceIdx != -1 ? _getCellValue(row, sourceIdx) : '';
      final cellCategory = categoryIdx != -1 ? _getCellValue(row, categoryIdx) : '';
      final cellExpiry = expiryIdx != -1 ? row[expiryIdx]?.value : null;
      final cellAmount = amountIdx != -1 ? _getCellValue(row, amountIdx) : '';
      final cellStatus = statusIdx != -1 ? _getCellValue(row, statusIdx) : '';
      final cellRemarks = remarksIdx != -1 ? _getCellValue(row, remarksIdx) : '';

      // Try parsing date
      final parsedDate = _parseExcelDate(cellExpiry);
      if (parsedDate == null) {
        failedCount++;
        errorDetails.add('Row ${rowIndex + 1}: Invalid or missing EXPIRATION DATE.');
        continue;
      }

      // Try parsing amount
      double value = 0.0;
      if (cellAmount.isNotEmpty) {
        value = double.tryParse(cellAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      }

      // Check for CRM Client match
      final linkedClientId = findClientIdByName(finalClientName);

      // Parse Category & Status
      final cat = _parseCategory(cellCategory);
      final stat = _parseStatus(cellStatus);

      // Construct metadata
      final Map<String, dynamic> metadata = {
        'service_name': cellDomain,
        'client_name': finalClientName,
        'project_name': 'Independent Service',
        'source': cellSource,
        'remarks': cellRemarks,
      };

      // Construct Insert Data
      final Map<String, dynamic> insertData = {
        'organization_id': '00000000-0000-0000-0000-000000000000',
        'client_id': linkedClientId,
        'project_id': null,
        'category': cat.name,
        'description': cellDomain,
        'amount': value,
        'expiry_date': parsedDate.toIso8601String(),
        'status': stat.name,
        'reminders_sent': 0,
        'metadata': metadata,
      };

      try {
        await _client.from('renewals').insert(insertData);
        successCount++;
      } catch (e) {
        failedCount++;
        errorDetails.add('Row ${rowIndex + 1}: Database Error - ${e.toString()}');
      }
    }

    return RenewalImportResult(
      totalRows: totalRows,
      successCount: successCount,
      failedCount: failedCount,
      errorDetails: errorDetails,
    );
  }

  String _getCellValue(List<Data?> row, int index) {
    if (index < 0 || index >= row.length || row[index] == null) return '';
    final val = row[index]!.value;
    if (val == null) return '';
    return val.toString().trim();
  }

  DateTime? _parseExcelDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is num) {
      // Excel serial date starting from 30 Dec 1899 due to 1900 leap bug
      return DateTime(1899, 12, 30).add(Duration(days: val.toInt()));
    }
    final str = val.toString().trim();
    if (str.isEmpty) return null;

    // Clean any ordinal suffixes
    var cleanStr = str.replaceAll(RegExp(r'(st|nd|rd|th),?'), '');

    var parsed = DateTime.tryParse(cleanStr);
    if (parsed != null) return parsed;

    final formats = [
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'MM/dd/yyyy',
      'MM-dd-yyyy',
      'dd-MMM-yyyy',
      'dd MMM yyyy',
      'MMMM dd, yyyy',
    ];
    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parse(cleanStr);
      } catch (_) {}
    }
    return null;
  }

  ServiceCategory _parseCategory(String val) {
    final clean = val.toLowerCase().trim();
    if (clean.contains('hosting') && clean.contains('domain')) return ServiceCategory.hostingDomain;
    if (clean.contains('hosting')) return ServiceCategory.hosting;
    if (clean.contains('domain')) return ServiceCategory.domain;
    if (clean.contains('email') || clean.contains('mail')) return ServiceCategory.email;
    if (clean.contains('ssl')) return ServiceCategory.ssl;
    if (clean.contains('maintenance')) return ServiceCategory.maintenance;
    return ServiceCategory.other;
  }

  RenewalStatus _parseStatus(String val) {
    final clean = val.toLowerCase().trim();
    if (clean.contains('paid') || clean.contains('active')) return RenewalStatus.paid;
    if (clean.contains('pending') || clean.contains('unpaid')) return RenewalStatus.pending;
    if (clean.contains('overdue') || clean.contains('expired')) return RenewalStatus.overdue;
    if (clean.contains('cancel')) return RenewalStatus.cancelled;
    return RenewalStatus.pending;
  }
}
