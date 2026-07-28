import 'package:ecraftz_crm/widgets/app_snackbar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import '../models/employee_attendance_matrix.dart';

/// Aggregated summary row for an employee across the selected date range
class EmployeeAttendanceSummary {
  final String employeeName;
  final String employeeId;
  final String biometricPin;
  final int totalDays;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int wfhCount;
  final int totalWorkMinutes;

  const EmployeeAttendanceSummary({
    required this.employeeName,
    required this.employeeId,
    required this.biometricPin,
    required this.totalDays,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.wfhCount,
    required this.totalWorkMinutes,
  });

  String get totalHours {
    final h = totalWorkMinutes ~/ 60;
    final m = totalWorkMinutes % 60;
    return '${h}h ${m}m';
  }

  String get attendanceRate {
    if (totalDays == 0) return '0%';
    final attended = presentCount + lateCount + wfhCount;
    final pct = (attended / totalDays) * 100;
    return '${pct.toStringAsFixed(1)}%';
  }
}

/// Exported attendance data for one employee-day combination
class AttendanceExportRow {
  final String employeeName;
  final String employeeId;
  final String biometricPin;
  final DateTime date;
  final DailyStatus status;

  const AttendanceExportRow({
    required this.employeeName,
    required this.employeeId,
    required this.biometricPin,
    required this.date,
    required this.status,
  });

  String get statusLabel {
    switch (status.status) {
      case 'P':
        return 'Present';
      case 'L':
        return 'Late';
      case 'A':
        return 'Absent';
      case 'W':
        return 'WFH';
      default:
        return 'Absent';
    }
  }

  String get checkIn => status.firstPunchIn != null
      ? DateFormat('hh:mm a').format(status.firstPunchIn!)
      : '-';

  String get checkOut => status.lastPunchOut != null
      ? DateFormat('hh:mm a').format(status.lastPunchOut!)
      : '-';

  String get totalHours {
    if (status.firstPunchIn != null && status.lastPunchOut != null) {
      final diff = status.lastPunchOut!.difference(status.firstPunchIn!);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return '${h}h ${m}m';
    }
    return '-';
  }

  int get totalMinutes {
    if (status.firstPunchIn != null && status.lastPunchOut != null) {
      return status.lastPunchOut!.difference(status.firstPunchIn!).inMinutes;
    }
    return 0;
  }
}

class AttendanceExportService {
  AttendanceExportService._();
  static final AttendanceExportService instance = AttendanceExportService._();

  /// Builds the flat list of rows from matrix data for the selected date range
  List<AttendanceExportRow> buildExportRows({
    required List<Map<String, dynamic>> profiles,
    required Map<String, Map<String, DailyStatus>> matrixData,
    required List<DateTime> dates,
  }) {
    final rows = <AttendanceExportRow>[];
    for (final profile in profiles) {
      final pin = profile['biometric_id']?.toString() ?? '';
      final name = (profile['full_name'] as String?) ?? 'Unknown';
      final empId = (profile['id'] as String?) ?? '-';
      for (final date in dates) {
        final ds = DateFormat('yyyy-MM-dd').format(date);
        final status = matrixData[pin]?[ds] ?? DailyStatus(status: 'A');
        rows.add(AttendanceExportRow(
          employeeName: name,
          employeeId: empId,
          biometricPin: pin,
          date: date,
          status: status,
        ));
      }
    }
    return rows;
  }

  /// Builds per-employee summary statistics for the selected date range
  List<EmployeeAttendanceSummary> buildEmployeeSummaries({
    required List<Map<String, dynamic>> profiles,
    required Map<String, Map<String, DailyStatus>> matrixData,
    required List<DateTime> dates,
  }) {
    final summaries = <EmployeeAttendanceSummary>[];
    for (final profile in profiles) {
      final pin = profile['biometric_id']?.toString() ?? '';
      final name = (profile['full_name'] as String?) ?? 'Unknown';
      final empId = (profile['id'] as String?) ?? '-';

      int present = 0;
      int late = 0;
      int absent = 0;
      int wfh = 0;
      int totalMinutes = 0;

      for (final date in dates) {
        final ds = DateFormat('yyyy-MM-dd').format(date);
        final status = matrixData[pin]?[ds] ?? DailyStatus(status: 'A');
        switch (status.status) {
          case 'P':
            present++;
            break;
          case 'L':
            late++;
            break;
          case 'A':
            absent++;
            break;
          case 'W':
            wfh++;
            break;
          default:
            absent++;
        }

        if (status.firstPunchIn != null && status.lastPunchOut != null) {
          totalMinutes +=
              status.lastPunchOut!.difference(status.firstPunchIn!).inMinutes;
        }
      }

      summaries.add(EmployeeAttendanceSummary(
        employeeName: name,
        employeeId: empId,
        biometricPin: pin,
        totalDays: dates.length,
        presentCount: present,
        lateCount: late,
        absentCount: absent,
        wfhCount: wfh,
        totalWorkMinutes: totalMinutes,
      ));
    }
    return summaries;
  }

  // ──────────────────────── PDF Export ─────────────────────────────────────

  Future<void> exportToPdf({
    required BuildContext context,
    required List<Map<String, dynamic>> profiles,
    required Map<String, Map<String, DailyStatus>> matrixData,
    required List<DateTime> dates,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final ttf = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();

    final dateRangeLabel =
        '${DateFormat('d MMM yyyy').format(startDate)} – ${DateFormat('d MMM yyyy').format(endDate)}';
    final now = DateFormat('d MMM yyyy, hh:mm a').format(DateTime.now());

    final summaries = buildEmployeeSummaries(
      profiles: profiles,
      matrixData: matrixData,
      dates: dates,
    );

    final totalPresent =
        summaries.fold<int>(0, (sum, item) => sum + item.presentCount);
    final totalLate =
        summaries.fold<int>(0, (sum, item) => sum + item.lateCount);
    final totalAbsent =
        summaries.fold<int>(0, (sum, item) => sum + item.absentCount);
    final totalWfh =
        summaries.fold<int>(0, (sum, item) => sum + item.wfhCount);

    // Page 1: Executive Employee Attendance Summary
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        maxPages: 100,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Attendance Summary Report',
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('Generated: $now',
                    style: pw.TextStyle(font: ttf, fontSize: 9)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text('Selected Period: $dateRangeLabel',
                style: pw.TextStyle(
                    font: ttfBold, fontSize: 11, color: PdfColors.blueGrey800)),
            pw.Divider(thickness: 1),
          ],
        ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Ecraftz CRM – Attendance Module',
                style: pw.TextStyle(
                    font: ttf, fontSize: 8, color: PdfColors.grey500)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(
                    font: ttf, fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          // Overall Stat Badges
          widgets.add(
            pw.Row(
              children: [
                _pdfStat(ttf, ttfBold, 'Employees', '${profiles.length}', PdfColors.blue900),
                _pdfStat(ttf, ttfBold, 'Period Days', '${dates.length} Days', PdfColors.purple800),
                _pdfStat(ttf, ttfBold, 'Total Present', '$totalPresent', PdfColors.green700),
                _pdfStat(ttf, ttfBold, 'Total Late', '$totalLate', PdfColors.orange700),
                _pdfStat(ttf, ttfBold, 'Total Absent', '$totalAbsent', PdfColors.red700),
                _pdfStat(ttf, ttfBold, 'Total WFH', '$totalWfh', PdfColors.teal700),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 14));
          widgets.add(
            pw.Text('Employee Performance Breakdown',
                style: pw.TextStyle(
                    font: ttfBold, fontSize: 12, color: PdfColors.blueGrey900)),
          );
          widgets.add(pw.SizedBox(height: 6));

          // Summary Table per Employee
          const summaryColWidths = {
            0: pw.FixedColumnWidth(180), // Name
            1: pw.FixedColumnWidth(70),  // Bio ID
            2: pw.FixedColumnWidth(65),  // Present
            3: pw.FixedColumnWidth(65),  // Late
            4: pw.FixedColumnWidth(65),  // Absent
            5: pw.FixedColumnWidth(65),  // WFH
            6: pw.FixedColumnWidth(90),  // Hours
            7: pw.FixedColumnWidth(70),  // Rate
          };

          final tableData = summaries.map((s) {
            return [
              s.employeeName,
              s.biometricPin,
              '${s.presentCount}',
              '${s.lateCount}',
              '${s.absentCount}',
              '${s.wfhCount}',
              s.totalHours,
              s.attendanceRate,
            ];
          }).toList();

          // Add Summary Totals Row
          tableData.add([
            'TOTAL / AVERAGE',
            '-',
            '$totalPresent',
            '$totalLate',
            '$totalAbsent',
            '$totalWfh',
            '-',
            '-',
          ]);

          widgets.add(
            pw.TableHelper.fromTextArray(
              columnWidths: summaryColWidths,
              headers: [
                'Employee Name',
                'Bio ID',
                'Present',
                'Late',
                'Absent',
                'WFH',
                'Total Hours',
                'Rate %',
              ],
              data: tableData,
              headerStyle: pw.TextStyle(
                  font: ttfBold,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.indigo900),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 8),
              cellHeight: 18,
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
                7: pw.Alignment.center,
              },
              border: pw.TableBorder.all(
                  color: PdfColors.grey400, width: 0.5),
            ),
          );

          return widgets;
        },
      ),
    );

    // Page 2: Monthly Attendance Matrix Grid
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        maxPages: 100,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Attendance Matrix Grid',
                    style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('Period: $dateRangeLabel',
                    style: pw.TextStyle(font: ttfBold, fontSize: 10)),
              ],
            ),
            pw.Divider(thickness: 1),
          ],
        ),
        build: (ctx) {
          final matrixHeaders = [
            'Employee',
            ...dates.map((d) => DateFormat('d').format(d)),
            'P',
            'L',
            'A',
            'W',
          ];

          final matrixRows = profiles.map((profile) {
            final pin = profile['biometric_id']?.toString() ?? '';
            final empName = (profile['full_name'] as String?) ?? 'Unknown';

            int p = 0, l = 0, a = 0, w = 0;

            final dayCells = dates.map((date) {
              final ds = DateFormat('yyyy-MM-dd').format(date);
              final status = matrixData[pin]?[ds]?.status ?? 'A';
              if (status == 'P') p++;
              if (status == 'L') l++;
              if (status == 'A') a++;
              if (status == 'W') w++;
              return status;
            }).toList();

            return [
              empName,
              ...dayCells,
              '$p',
              '$l',
              '$a',
              '$w',
            ];
          }).toList();

          return [
            pw.TableHelper.fromTextArray(
              headers: matrixHeaders,
              data: matrixRows,
              headerStyle: pw.TextStyle(
                  font: ttfBold,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 7),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 6.5),
              cellHeight: 14,
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                for (int i = 1; i <= dates.length + 4; i++) i: pw.Alignment.center,
              },
              border: pw.TableBorder.all(
                  color: PdfColors.grey300, width: 0.4),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  pw.Widget _pdfStat(
      pw.Font ttf, pw.Font ttfBold, String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 3),
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 0.5),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    font: ttf, fontSize: 7.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(value,
                style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Excel Export ───────────────────────────────────

  Future<void> exportToExcel({
    required BuildContext context,
    required List<Map<String, dynamic>> profiles,
    required Map<String, Map<String, DailyStatus>> matrixData,
    required List<DateTime> dates,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();

    // ── Sheet 1: Employee Summary ──────────────────────────────────────────
    final Sheet summarySheet = excel['Summary'];
    if (excel.sheets.keys.contains('Sheet1')) {
      excel.delete('Sheet1');
    }

    final dateRangeLabel =
        '${DateFormat('d MMM yyyy').format(startDate)} – ${DateFormat('d MMM yyyy').format(endDate)}';

    // Title Row
    summarySheet.merge(
        CellIndex.indexByString('A1'), CellIndex.indexByString('H1'));
    final titleCell = summarySheet.cell(CellIndex.indexByString('A1'));
    titleCell.value =
        TextCellValue('Attendance Summary Report ($dateRangeLabel)');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      backgroundColorHex: ExcelColor.fromHexString('#0D47A1'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final summaryHeaders = [
      'Employee Name',
      'Employee ID',
      'Biometric ID',
      'Present Days',
      'Late Days',
      'Absent Days',
      'WFH Days',
      'Total Work Hours',
      'Attendance Rate',
    ];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1A237E'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    for (int i = 0; i < summaryHeaders.length; i++) {
      final cell = summarySheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      cell.value = TextCellValue(summaryHeaders[i]);
      cell.cellStyle = headerStyle;
    }

    final summaries = buildEmployeeSummaries(
      profiles: profiles,
      matrixData: matrixData,
      dates: dates,
    );

    final evenStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);
    final oddStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#E8EAF6'),
      horizontalAlign: HorizontalAlign.Center,
    );

    for (int i = 0; i < summaries.length; i++) {
      final s = summaries[i];
      final rIdx = i + 2;
      final style = i.isOdd ? oddStyle : evenStyle;

      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIdx))
        ..value = TextCellValue(s.employeeName)
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Left);
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIdx))
        ..value = TextCellValue(s.employeeId)
        ..cellStyle = style;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIdx))
        ..value = TextCellValue(s.biometricPin)
        ..cellStyle = style;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rIdx))
        ..value = IntCellValue(s.presentCount)
        ..cellStyle = style;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rIdx))
        ..value = IntCellValue(s.lateCount)
        ..cellStyle = style;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rIdx))
        ..value = IntCellValue(s.absentCount)
        ..cellStyle = style;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rIdx))
        ..value = IntCellValue(s.wfhCount)
        ..cellStyle = style;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rIdx))
        ..value = TextCellValue(s.totalHours)
        ..cellStyle = style;
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rIdx))
        ..value = TextCellValue(s.attendanceRate)
        ..cellStyle = style;
    }

    const sumWidths = [25.0, 18.0, 14.0, 14.0, 12.0, 12.0, 12.0, 16.0, 16.0];
    for (int i = 0; i < sumWidths.length; i++) {
      summarySheet.setColumnWidth(i, sumWidths[i]);
    }

    // ── Sheet 2: Monthly Matrix Grid ───────────────────────────────────────
    final Sheet matrixSheet = excel['Monthly Matrix'];
    matrixSheet.merge(CellIndex.indexByString('A1'),
        CellIndex.indexByColumnRow(columnIndex: dates.length + 5, rowIndex: 0));
    final matrixTitle = matrixSheet.cell(CellIndex.indexByString('A1'));
    matrixTitle.value = TextCellValue('Monthly Attendance Matrix ($dateRangeLabel)');
    matrixTitle.cellStyle = CellStyle(
      bold: true,
      fontSize: 13,
      backgroundColorHex: ExcelColor.fromHexString('#1B5E20'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final mHeaders = [
      'Employee Name',
      'Biometric ID',
      ...dates.map((d) => DateFormat('d MMM').format(d)),
      'Present',
      'Late',
      'Absent',
      'WFH',
    ];

    for (int i = 0; i < mHeaders.length; i++) {
      final cell = matrixSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      cell.value = TextCellValue(mHeaders[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#2E7D32'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    for (int i = 0; i < profiles.length; i++) {
      final profile = profiles[i];
      final pin = profile['biometric_id']?.toString() ?? '';
      final name = (profile['full_name'] as String?) ?? 'Unknown';
      final rIdx = i + 2;

      int p = 0, l = 0, a = 0, w = 0;

      matrixSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIdx))
        ..value = TextCellValue(name)
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Left);
      matrixSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIdx))
        ..value = TextCellValue(pin)
        ..cellStyle = evenStyle;

      for (int d = 0; d < dates.length; d++) {
        final ds = DateFormat('yyyy-MM-dd').format(dates[d]);
        final status = matrixData[pin]?[ds]?.status ?? 'A';
        if (status == 'P') p++;
        if (status == 'L') l++;
        if (status == 'A') a++;
        if (status == 'W') w++;

        matrixSheet.cell(
            CellIndex.indexByColumnRow(columnIndex: d + 2, rowIndex: rIdx))
          ..value = TextCellValue(status)
          ..cellStyle = evenStyle;
      }

      final endCol = dates.length + 2;
      matrixSheet.cell(CellIndex.indexByColumnRow(
          columnIndex: endCol, rowIndex: rIdx))
        ..value = IntCellValue(p)
        ..cellStyle = evenStyle;
      matrixSheet.cell(CellIndex.indexByColumnRow(
          columnIndex: endCol + 1, rowIndex: rIdx))
        ..value = IntCellValue(l)
        ..cellStyle = evenStyle;
      matrixSheet.cell(CellIndex.indexByColumnRow(
          columnIndex: endCol + 2, rowIndex: rIdx))
        ..value = IntCellValue(a)
        ..cellStyle = evenStyle;
      matrixSheet.cell(CellIndex.indexByColumnRow(
          columnIndex: endCol + 3, rowIndex: rIdx))
        ..value = IntCellValue(w)
        ..cellStyle = evenStyle;
    }

    // Save and notify
    final bytes = excel.encode();
    if (bytes == null) {
      if (context.mounted) {
        AppSnackBar.showCustom(context, 
          const SnackBar(content: Text('Failed to generate Excel file.')),
        );
      }
      return;
    }

    final dir = Directory.systemTemp;
    final fileName =
        'attendance_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      AppSnackBar.showCustom(context, 
        SnackBar(
          content: Text('Excel saved: $fileName'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }
}
