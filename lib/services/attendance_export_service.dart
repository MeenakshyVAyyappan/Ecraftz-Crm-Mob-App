import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/attendance_register_model.dart';

class AttendanceExportService {
  AttendanceExportService._();
  static final AttendanceExportService instance = AttendanceExportService._();

  /// Exports current filtered attendance register data to PDF document
  Future<void> exportToPdf({
    required List<EmployeeAttendanceSummaryRow> rows,
    DateTime? startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final dateRangeStr = startDate != null
        ? '${DateFormat("dd-MM-yyyy").format(startDate)} to ${DateFormat("dd-MM-yyyy").format(endDate)}'
        : 'Up to ${DateFormat("dd-MM-yyyy").format(endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Ecraftz CRM — Biometric Attendance Register',
                        style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue900)),
                    pw.SizedBox(height: 4),
                    pw.Text('Date Range: $dateRangeStr',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Text('Generated: ${DateFormat("d MMM yyyy, h:mm a").format(DateTime.now())}',
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 12),

            // Employee Summary Table
            pw.TableHelper.fromTextArray(
              headers: ['#', 'Employee Name', 'Code', 'Shift', 'Work Hrs', 'Deficit', 'OT', 'Status'],
              data: List.generate(rows.length, (index) {
                final r = rows[index];
                final lastRec = r.dailyRecords.values.isNotEmpty ? r.dailyRecords.values.last : null;
                return [
                  '${index + 1}',
                  r.employeeName,
                  r.employeeCode,
                  r.shift.shiftName,
                  lastRec?.formattedWorkHours ?? '0.0 hrs',
                  lastRec?.formattedRemainingHours ?? '9.0 hrs',
                  lastRec?.formattedOvertimeHours ?? '0.0 hrs',
                  lastRec?.statusLabel ?? 'Absent',
                ];
              }),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              cellStyle: pw.TextStyle(font: font, fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Attendance_Register_${DateFormat("yyyyMMdd").format(endDate)}.pdf',
    );
  }

  /// Exports current filtered attendance register data to CSV / Excel compatible format
  Future<void> exportToExcelCsv({
    required List<EmployeeAttendanceSummaryRow> rows,
    DateTime? startDate,
    required DateTime endDate,
  }) async {
    final dateRangeStr = startDate != null
        ? '${DateFormat("dd-MM-yyyy").format(startDate)} to ${DateFormat("dd-MM-yyyy").format(endDate)}'
        : 'Up to ${DateFormat("dd-MM-yyyy").format(endDate)}';

    StringBuffer csv = StringBuffer();
    csv.writeln('Ecraftz CRM - Biometric Attendance Register');
    csv.writeln('Date Range: $dateRangeStr');
    csv.writeln('Export Date: ${DateFormat("d MMM yyyy, h:mm a").format(DateTime.now())}');
    csv.writeln();
    csv.writeln('Employee Name,Employee Code,Assigned Shift,Check In,Check Out,Work Hours,Deficit Hours,Overtime Hours,Status');

    for (final r in rows) {
      for (final rec in r.dailyRecords.values) {
        final wDate = DateFormat('dd-MM-yyyy').format(rec.workDate);
        csv.writeln(
          '"${r.employeeName} ($wDate)","${r.employeeCode}","${r.shift.shiftName}","${rec.checkIn ?? '-'}","${rec.checkOut ?? '-'}","${rec.formattedWorkHours}","${rec.formattedRemainingHours}","${rec.formattedOvertimeHours}","${rec.statusLabel}"',
        );
      }
    }

    final bytes = Uint8List.fromList(utf8.encode(csv.toString()));

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Attendance_Register_${DateFormat("yyyyMMdd").format(endDate)}.csv',
    );
  }
}
