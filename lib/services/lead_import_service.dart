import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_model.dart';
import 'supabase_service.dart';

class ImportResult {
  final int totalRows;
  final int successCount;
  final int duplicateCount;
  final int failedCount;
  final List<String> errorDetails;

  ImportResult({
    required this.totalRows,
    required this.successCount,
    required this.duplicateCount,
    required this.failedCount,
    required this.errorDetails,
  });
}

class LeadImportService {
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

  /// Process & Import Excel File Bytes into Supabase leads table
  Future<ImportResult> importLeadsFromExcel({
    required Uint8List bytes,
    String? branchId,
    Function(int current, int total)? onProgress,
  }) async {
    int successCount = 0;
    int duplicateCount = 0;
    int failedCount = 0;
    final List<String> errorDetails = [];

    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return ImportResult(
        totalRows: 0,
        successCount: 0,
        duplicateCount: 0,
        failedCount: 1,
        errorDetails: ['The selected Excel file contains no worksheets.'],
      );
    }

    final tableKey = excel.tables.keys.first;
    final sheet = excel.tables[tableKey];
    if (sheet == null || sheet.maxRows <= 1) {
      return ImportResult(
        totalRows: 0,
        successCount: 0,
        duplicateCount: 0,
        failedCount: 0,
        errorDetails: ['The selected worksheet is empty or only contains headers.'],
      );
    }

    // 1. Fetch existing phones from DB for duplicate checking
    final Set<String> existingPhones = {};
    try {
      final dbLeads = await _client.from('leads').select('phone').isFilter('deleted_at', null);
      if (dbLeads is List) {
        for (var l in dbLeads) {
          final p = _normalizePhone(l['phone']?.toString() ?? '');
          if (p.isNotEmpty) existingPhones.add(p);
        }
      }
    } catch (e) {
      debugPrint('Error loading existing phones for duplicate check: $e');
    }

    final Set<String> batchPhones = {};
    final totalRows = sheet.maxRows - 1;

    // 2. Loop through Excel rows (Row 0 is header)
    for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (row.isEmpty) continue;

      if (onProgress != null) {
        onProgress(rowIndex, totalRows);
      }

      final cellDate = _getCellValue(row, 0);
      final cellPhone = _getCellValue(row, 1);
      final cellCompany = _getCellValue(row, 2);
      final cellPersonName = _getCellValue(row, 3);
      final cellLocation = _getCellValue(row, 4);
      final cellService = _getCellValue(row, 5);
      final cellRemarks1 = _getCellValue(row, 6);
      final cellRemarks2 = _getCellValue(row, 7);
      final cellRemarks3 = _getCellValue(row, 8);
      final cellAmount = _getCellValue(row, 9);

      // Skip completely empty rows
      if (cellPhone.isEmpty &&
          cellCompany.isEmpty &&
          cellPersonName.isEmpty &&
          cellService.isEmpty) {
        continue;
      }

      final normalizedPhone = _normalizePhone(cellPhone);

      // Validate presence of contact info or person name
      if (normalizedPhone.isEmpty && cellPersonName.isEmpty && cellCompany.isEmpty) {
        failedCount++;
        errorDetails.add('Row ${rowIndex + 1}: Missing contact number and name.');
        continue;
      }

      // Check duplicate contact number
      if (normalizedPhone.isNotEmpty &&
          (existingPhones.contains(normalizedPhone) ||
              batchPhones.contains(normalizedPhone))) {
        duplicateCount++;
        errorDetails.add(
            'Row ${rowIndex + 1}: Duplicate contact number ($cellPhone) skipped.');
        continue;
      }

      // Add to tracked phones
      if (normalizedPhone.isNotEmpty) {
        batchPhones.add(normalizedPhone);
        existingPhones.add(normalizedPhone);
      }

      // Name parsing
      String firstName = cellPersonName;
      String lastName = '';
      if (cellPersonName.contains(' ')) {
        final parts = cellPersonName.split(' ');
        firstName = parts.first;
        lastName = parts.sublist(1).join(' ');
      }
      if (firstName.isEmpty) {
        firstName = cellCompany.isNotEmpty ? cellCompany : 'Lead #${rowIndex + 1}';
      }

      // Parse Amount
      double value = 0.0;
      if (cellAmount.isNotEmpty) {
        value = double.tryParse(cellAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      }

      // Infer Lead Status
      final combinedStatusStr = '$cellService $cellRemarks1 $cellRemarks2 $cellRemarks3'.toLowerCase();
      final status = _inferStatus(combinedStatusStr);

      // Construct Insert Data
      final Map<String, dynamic> insertData = {
        'first_name': firstName,
        'last_name': lastName,
        'email': normalizedPhone.isNotEmpty
            ? '$normalizedPhone@ecraftz.crm'
            : 'lead_${DateTime.now().millisecondsSinceEpoch}_$rowIndex@ecraftz.crm',
        'company': cellCompany,
        'phone': cellPhone.isNotEmpty ? cellPhone : normalizedPhone,
        'status': status.dbValue,
        'source': 'excel_import',
        'value': value,
        'organization_id': '00000000-0000-0000-0000-000000000000',
      };

      if (branchId != null && branchId.isNotEmpty) {
        insertData['branch_id'] = branchId;
      }

      try {
        await _client.from('leads').insert(insertData);
        successCount++;
      } catch (e) {
        failedCount++;
        errorDetails.add('Row ${rowIndex + 1}: DB Error - ${e.toString()}');
      }
    }

    return ImportResult(
      totalRows: totalRows,
      successCount: successCount,
      duplicateCount: duplicateCount,
      failedCount: failedCount,
      errorDetails: errorDetails,
    );
  }

  String _getCellValue(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null) return '';
    final val = row[index]!.value;
    if (val == null) return '';
    return val.toString().trim();
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  LeadStatus _inferStatus(String text) {
    if (text.contains('closed') || text.contains('converted') || text.contains('client')) {
      return LeadStatus.convertedClient;
    }
    if (text.contains('proposal') || text.contains('portfolio') || text.contains('details shared')) {
      return LeadStatus.proposalSent;
    }
    if (text.contains('not responding') || text.contains('no response') || text.contains('not connected')) {
      return LeadStatus.contacted;
    }
    if (text.contains('no requirements') || text.contains('closed lost')) {
      return LeadStatus.closedLost;
    }
    if (text.contains('qualified') || text.contains('interested')) {
      return LeadStatus.qualified;
    }
    return LeadStatus.newLead;
  }
}
