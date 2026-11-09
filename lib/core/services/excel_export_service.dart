import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../../features/properties/domain/models/property.dart';
import '../../features/properties/domain/models/unit.dart';
import '../../features/tenants/domain/models/tenant.dart';
import '../../features/rent/domain/models/rent_entry.dart';
import '../../features/expenses/domain/models/expense.dart';
import '../../features/rent/domain/services/rent_calculator.dart';

class ExcelExportResult {
  final String filePath;
  final String fileName;
  final int fileSize;

  ExcelExportResult({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
  });
}

class ExcelExportService {
  /// Builds the complete multi-sheet Excel workbook in memory
  static Excel buildExcelDocument({
    required String monthKey,
    required List<Property> properties,
    required List<Tenant> tenants,
    required List<RentEntry> rentEntries,
    required List<Expense> expenses,
    String? selectedPropertyId,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();

    // Map helpers for quick lookups
    final propertyMap = {for (var p in properties) p.id: p};
    final unitMap = {
      for (var p in properties)
        for (var u in p.units) u.id: u
    };
    final tenantMap = {for (var t in tenants) t.id: t};

    // Filter by property if selected
    final filteredEntries = selectedPropertyId == null || selectedPropertyId.isEmpty
        ? rentEntries.where((e) => e.month == monthKey).toList()
        : rentEntries
            .where((e) => e.month == monthKey && e.propertyId == selectedPropertyId)
            .toList();

    final filteredExpenses = selectedPropertyId == null || selectedPropertyId.isEmpty
        ? expenses
        : expenses.where((e) => e.propertyId == selectedPropertyId).toList();

    final monthDate = DateFormatter.fromMonthKey(monthKey);
    final monthName = DateFormatter.formatMonthYear(monthDate);
    final summary = RentCalculator.calculateSummary(filteredEntries);

    // =========================================================================
    // 1. PRIMARY SHEET: Exact Khata Ledger Format matching User's Uploaded Image
    // =========================================================================
    _buildKhataPeExcelSheet(
      excel: excel,
      monthKey: monthKey,
      properties: properties,
      tenants: tenants,
      filteredEntries: filteredEntries,
      selectedPropertyId: selectedPropertyId,
    );

    // Styling constants for additional sheets
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#0F5132'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final subHeaderStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#0F5132'),
      backgroundColorHex: ExcelColor.fromHexString('#E8F5E9'),
      horizontalAlign: HorizontalAlign.Left,
    );

    final boldStyle = CellStyle(bold: true);

    final paidStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#065F46'),
      backgroundColorHex: ExcelColor.fromHexString('#D1FAE5'),
    );

    final partialStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#92400E'),
      backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'),
    );

    final overdueStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#991B1B'),
      backgroundColorHex: ExcelColor.fromHexString('#FEE2E2'),
    );

    // ==========================================
    // 2. SHEET 2: Summary
    // ==========================================
    final summarySheet = excel['Summary'];

    summarySheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0));
    final titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue('KHATA PE — RENT COLLECTION SUMMARY ($monthName) — Landlord: Anil');
    titleCell.cellStyle = headerStyle;

    final summaryRows = [
      ['Landlord Name', 'Anil'],
      ['Report Month', monthName],
      ['Total Expected Rent', '₹ ${CurrencyFormatter.format(summary.totalExpected, includeSymbol: false)}'],
      ['Total Rent Received', '₹ ${CurrencyFormatter.format(summary.totalReceived, includeSymbol: false)}'],
      ['Total Cash Payments', '${summary.cashPaymentsCount} payments (₹ ${CurrencyFormatter.format(summary.cashAmount, includeSymbol: false)})'],
      ['Total Bank Payments', '${summary.bankPaymentsCount} payments (₹ ${CurrencyFormatter.format(summary.bankAmount, includeSymbol: false)})'],
      ['Total Due / Pending', '₹ ${CurrencyFormatter.format(summary.totalDue, includeSymbol: false)}'],
      ['Collection Progress', '${summary.collectionPercentage.toStringAsFixed(1)} %'],
      ['Total Tenants', '${summary.totalTenants}'],
      ['Paid In Full', '${summary.paidCount}'],
      ['Partially Paid', '${summary.partialCount}'],
      ['Overdue Tenants', '${summary.overdueCount}'],
    ];

    for (int r = 0; r < summaryRows.length; r++) {
      final labelCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 2));
      labelCell.value = TextCellValue(summaryRows[r][0]);
      labelCell.cellStyle = boldStyle;

      final valCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r + 2));
      valCell.value = TextCellValue(summaryRows[r][1]);
    }

    // Property-wise breakdown sub-table in Summary
    final pBreakdownHeader = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 13));
    pBreakdownHeader.value = TextCellValue('BUILDING-WISE COLLECTION BREAKDOWN');
    pBreakdownHeader.cellStyle = subHeaderStyle;

    final pHeaders = ['Building', 'Total Rooms', 'Expected (₹)', 'Received (₹)', 'Due (₹)', 'Collection %'];
    for (int c = 0; c < pHeaders.length; c++) {
      final cell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 14));
      cell.value = TextCellValue(pHeaders[c]);
      cell.cellStyle = headerStyle;
    }

    int pRowIdx = 15;
    for (final prop in properties) {
      if (selectedPropertyId != null && selectedPropertyId.isNotEmpty && prop.id != selectedPropertyId) {
        continue;
      }
      final propEntries = filteredEntries.where((e) => e.propertyId == prop.id).toList();
      final propSum = RentCalculator.calculateSummary(propEntries);

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: pRowIdx)).value =
          TextCellValue(prop.name);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: pRowIdx)).value =
          IntCellValue(propEntries.length);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: pRowIdx)).value =
          IntCellValue(propSum.totalExpected);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: pRowIdx)).value =
          IntCellValue(propSum.totalReceived);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: pRowIdx)).value =
          IntCellValue(propSum.totalDue);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: pRowIdx)).value =
          TextCellValue('${propSum.collectionPercentage.toStringAsFixed(1)}%');
      pRowIdx++;
    }

    // ==========================================
    // 3. SHEET 3: Rent Details
    // ==========================================
    final detailsSheet = excel['Rent Details'];
    final detailHeaders = [
      'S.No',
      'Building',
      'Room No.',
      'Tenant Name',
      'Phone',
      'Due Date',
      'Expected Rent',
      'Extra Charges',
      'Total Payable',
      'Amount Received',
      'Balance Due',
      'Status',
      'Payment Date',
      'Payment Mode',
      'Reference No.',
      'Notes'
    ];

    for (int c = 0; c < detailHeaders.length; c++) {
      final cell = detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(detailHeaders[c]);
      cell.cellStyle = headerStyle;
    }

    int dRowIdx = 1;
    for (int i = 0; i < filteredEntries.length; i++) {
      final entry = filteredEntries[i];
      final prop = propertyMap[entry.propertyId];
      final unit = unitMap[entry.unitId];
      final tenant = tenantMap[entry.tenantId];

      final lastPayment = entry.payments.isNotEmpty ? entry.payments.last : null;

      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: dRowIdx)).value =
          IntCellValue(i + 1);
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dRowIdx)).value =
          TextCellValue(prop?.name ?? '—');
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: dRowIdx)).value =
          TextCellValue(unit?.roomDisplayName ?? '—');
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: dRowIdx)).value =
          TextCellValue(tenant?.name ?? '—');
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: dRowIdx)).value =
          TextCellValue(tenant?.phone ?? '—');
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: dRowIdx)).value =
          TextCellValue(DateFormatter.formatDate(entry.dueDate));
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: dRowIdx)).value =
          IntCellValue(entry.expectedAmount);
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: dRowIdx)).value =
          IntCellValue(entry.extraCharges);
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: dRowIdx)).value =
          IntCellValue(entry.totalPayable);
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: dRowIdx)).value =
          IntCellValue(entry.totalCollected);
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: dRowIdx)).value =
          IntCellValue(entry.balanceDue);

      final statusCell = detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: dRowIdx));
      statusCell.value = TextCellValue(entry.status.displayName);
      if (entry.status == RentStatus.paid) {
        statusCell.cellStyle = paidStyle;
      } else if (entry.status == RentStatus.partiallyPaid) {
        statusCell.cellStyle = partialStyle;
      } else if (entry.status == RentStatus.overdue) {
        statusCell.cellStyle = overdueStyle;
      }

      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: dRowIdx)).value =
          TextCellValue(lastPayment != null ? DateFormatter.formatDate(lastPayment.date) : '—');
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: dRowIdx)).value =
          TextCellValue(lastPayment != null ? lastPayment.mode.displayName : '—');
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: dRowIdx)).value =
          TextCellValue(lastPayment?.referenceNo ?? '—');
      detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: dRowIdx)).value =
          TextCellValue(entry.notes ?? '—');

      dRowIdx++;
    }

    // Totals Row in Rent Details
    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: dRowIdx)).value =
        TextCellValue('TOTALS');
    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: dRowIdx)).cellStyle = boldStyle;

    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: dRowIdx)).value =
        FormulaCellValue('SUM(G2:G$dRowIdx)');
    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: dRowIdx)).cellStyle = boldStyle;

    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: dRowIdx)).value =
        FormulaCellValue('SUM(H2:H$dRowIdx)');
    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: dRowIdx)).cellStyle = boldStyle;

    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: dRowIdx)).value =
        FormulaCellValue('SUM(I2:I$dRowIdx)');
    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: dRowIdx)).cellStyle = boldStyle;

    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: dRowIdx)).value =
        FormulaCellValue('SUM(J2:J$dRowIdx)');
    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: dRowIdx)).cellStyle = boldStyle;

    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: dRowIdx)).value =
        FormulaCellValue('SUM(K2:K$dRowIdx)');
    detailsSheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: dRowIdx)).cellStyle = boldStyle;

    // ==========================================
    // 4. SHEET 4: Pending / Due List
    // ==========================================
    final pendingSheet = excel['Pending List'];
    final pendingHeaders = [
      'S.No',
      'Tenant Name',
      'Phone',
      'Building',
      'Room No.',
      'Due Date',
      'Days Overdue',
      'Balance Due (₹)',
      'Status'
    ];

    for (int c = 0; c < pendingHeaders.length; c++) {
      final cell = pendingSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(pendingHeaders[c]);
      cell.cellStyle = headerStyle;
    }

    final pendingEntries = filteredEntries.where((e) => e.balanceDue > 0).toList();
    pendingEntries.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));

    int pendingRowIdx = 1;
    for (int i = 0; i < pendingEntries.length; i++) {
      final entry = pendingEntries[i];
      final prop = propertyMap[entry.propertyId];
      final unit = unitMap[entry.unitId];
      final tenant = tenantMap[entry.tenantId];

      pendingSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: pendingRowIdx)).value =
          IntCellValue(i + 1);
      pendingSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: pendingRowIdx)).value =
          TextCellValue(tenant?.name ?? '—');
      pendingSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: pendingRowIdx)).value =
          TextCellValue(tenant?.phone ?? '—');
      pendingSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: pendingRowIdx)).value =
          TextCellValue(prop?.name ?? '—');
      pendingSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: pendingRowIdx)).value =
          TextCellValue(unit?.roomDisplayName ?? '—');
      pendingSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: pendingRowIdx)).value =
          TextCellValue(DateFormatter.formatDate(entry.dueDate));
      pendingSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: pendingRowIdx)).value =
          IntCellValue(entry.daysOverdue);
      pendingSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: pendingRowIdx)).value =
          IntCellValue(entry.balanceDue);

      final statusCell = pendingSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: pendingRowIdx));
      statusCell.value = TextCellValue(entry.status.displayName);
      statusCell.cellStyle = overdueStyle;

      pendingRowIdx++;
    }

    // ==========================================
    // 5. SHEET 5: Expenses
    // ==========================================
    final expenseSheet = excel['Expenses'];
    final expHeaders = ['S.No', 'Date', 'Building', 'Category', 'Amount (₹)', 'Notes'];

    for (int c = 0; c < expHeaders.length; c++) {
      final cell = expenseSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(expHeaders[c]);
      cell.cellStyle = headerStyle;
    }

    int expRowIdx = 1;
    for (int i = 0; i < filteredExpenses.length; i++) {
      final exp = filteredExpenses[i];
      final prop = propertyMap[exp.propertyId];

      expenseSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: expRowIdx)).value =
          IntCellValue(i + 1);
      expenseSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: expRowIdx)).value =
          TextCellValue(DateFormatter.formatDate(exp.date));
      expenseSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: expRowIdx)).value =
          TextCellValue(prop?.name ?? 'General');
      expenseSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: expRowIdx)).value =
          TextCellValue(exp.category.displayName);
      expenseSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: expRowIdx)).value =
          IntCellValue(exp.amount);
      expenseSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: expRowIdx)).value =
          TextCellValue(exp.note ?? '—');
      expRowIdx++;
    }

    // ==========================================
    // 6. SHEET 6: Net Income
    // ==========================================
    final netIncomeSheet = excel['Net Income'];
    final netHeaders = [
      'Building',
      'Rent Collected (₹)',
      'Total Expenses (₹)',
      'Net Profit / Loss (₹)'
    ];

    for (int c = 0; c < netHeaders.length; c++) {
      final cell = netIncomeSheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(netHeaders[c]);
      cell.cellStyle = headerStyle;
    }

    int netRowIdx = 1;
    for (final prop in properties) {
      if (selectedPropertyId != null && selectedPropertyId.isNotEmpty && prop.id != selectedPropertyId) {
        continue;
      }
      final propEntries = filteredEntries.where((e) => e.propertyId == prop.id).toList();
      final propRec = propEntries.fold(0, (sum, e) => sum + e.totalCollected);
      final propExp = filteredExpenses.where((e) => e.propertyId == prop.id).fold(0, (sum, e) => sum + e.amount);
      final net = propRec - propExp;

      netIncomeSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: netRowIdx)).value =
          TextCellValue(prop.name);
      netIncomeSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: netRowIdx)).value =
          IntCellValue(propRec);
      netIncomeSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: netRowIdx)).value =
          IntCellValue(propExp);
      netIncomeSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: netRowIdx)).value =
          IntCellValue(net);

      final netCell = netIncomeSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: netRowIdx));
      netCell.cellStyle = net >= 0 ? paidStyle : overdueStyle;

      netRowIdx++;
    }

    // Remove empty default sheet if needed
    if (defaultSheet != null && defaultSheet != 'Room Khata') {
      try {
        excel.delete(defaultSheet);
      } catch (_) {}
    }

    return excel;
  }

  /// Generates the full Monthly Rent & Expense Report and writes it to a file
  static Future<ExcelExportResult> generateMonthlyReport({
    required String monthKey,
    required List<Property> properties,
    required List<Tenant> tenants,
    required List<RentEntry> rentEntries,
    required List<Expense> expenses,
    String? selectedPropertyId,
  }) async {
    final excel = buildExcelDocument(
      monthKey: monthKey,
      properties: properties,
      tenants: tenants,
      rentEntries: rentEntries,
      expenses: expenses,
      selectedPropertyId: selectedPropertyId,
    );

    // Save Excel file to storage
    final List<int>? fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Failed to generate Excel report');
    }

    String buildingPrefix = 'NEW_14';
    if (selectedPropertyId != null && selectedPropertyId.isNotEmpty) {
      final p = properties.where((p) => p.id == selectedPropertyId).firstOrNull;
      if (p != null) buildingPrefix = p.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    } else if (properties.isNotEmpty) {
      buildingPrefix = properties.first.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    }

    final monthDate = DateFormatter.fromMonthKey(monthKey);
    final monthName = DateFormatter.formatMonthYear(monthDate);
    final sanitizedMonth = monthName.replaceAll(' ', '_');
    final fileName = 'KhataPe_${buildingPrefix}_$sanitizedMonth.xlsx';
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(fileBytes, flush: true);

    return ExcelExportResult(
      filePath: file.path,
      fileName: fileName,
      fileSize: fileBytes.length,
    );
  }

  /// Builds the exact signature Room Khata Ledger sheet matching the user's uploaded image:
  /// NEW 14              卐            OCT    PAID IN    NOV    2026
  /// S No | Date | Particular | Op.Bal | C.Mth | Total | E. CITY | G. Total | PAYMENTS (P-1 | DATE | P-2 | DATE) | Clo Bal
  static void _buildKhataPeExcelSheet({
    required Excel excel,
    required String monthKey,
    required List<Property> properties,
    required List<Tenant> tenants,
    required List<RentEntry> filteredEntries,
    String? selectedPropertyId,
  }) {
    // 1. Identify building name:
    String buildingName = 'NEW 14';
    if (selectedPropertyId != null && selectedPropertyId.isNotEmpty) {
      final p = properties.where((p) => p.id == selectedPropertyId).firstOrNull;
      if (p != null) buildingName = p.name;
    } else if (properties.isNotEmpty) {
      buildingName = properties.first.name;
    }

    final monthDate = DateFormatter.fromMonthKey(monthKey);
    final nextMonthDate = DateTime(monthDate.year, monthDate.month + 1, 1);

    final currentMonthShort = DateFormat('MMM').format(monthDate).toUpperCase();
    final nextMonthShort = DateFormat('MMM').format(nextMonthDate).toUpperCase();
    final yearStr = monthDate.year.toString();

    const sheetName = 'Room Khata';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    // Title banner:
    // "NEW 14          卐          OCT    PAID IN    NOV    2026"
    final titleText = '${buildingName.toUpperCase()}          卐          $currentMonthShort    PAID IN    $nextMonthShort    $yearStr';

    // Merge title across Col 0 to 12
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 1),
    );

    final titleCellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    titleCell.value = TextCellValue(titleText);
    titleCell.cellStyle = titleCellStyle;

    // Header Row 1 (Row 3):
    // S No | Date | Particular | Op.Bal | C.Mth | Total | E. CITY | G. Total | PAYMENTS (Merged 8..11) | Clo Bal
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = TextCellValue('S No');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value = TextCellValue('Date');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3)).value = TextCellValue('Particular');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3)).value = TextCellValue('Op.Bal');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 3)).value = TextCellValue('C.Mth');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 3)).value = TextCellValue('Total');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 3)).value = TextCellValue('E. CITY');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 3)).value = TextCellValue('G. Total');

    // Merge PAYMENTS across cols 8, 9, 10, 11
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 3),
      CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 3),
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 3)).value = TextCellValue('PAYMENTS');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 3)).value = TextCellValue('Clo Bal');

    for (int c = 0; c <= 12; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3)).cellStyle = headerStyle;
    }

    // Header Row 2 (Row 4 - Subheaders under PAYMENTS):
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 4)).value = TextCellValue('P - 1');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 4)).value = TextCellValue('DATE');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 4)).value = TextCellValue('P - 2');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 4)).value = TextCellValue('DATE');

    for (int c = 8; c <= 11; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 4)).cellStyle = headerStyle;
    }

    // Data Rows starting at rowIndex: 6 (matching image layout)
    final tenantMap = {for (var t in tenants) t.id: t};
    final unitMap = {
      for (var p in properties)
        for (var u in p.units) u.id: u
    };

    int rowIdx = 6;
    int sumOpBal = 0;
    int sumCMth = 0;
    int sumTotal = 0;
    int sumECity = 0;
    int sumGTotal = 0;
    int sumP1 = 0;
    int sumP2 = 0;
    int sumCloBal = 0;

    for (int i = 0; i < filteredEntries.length; i++) {
      final entry = filteredEntries[i];
      final tenant = tenantMap[entry.tenantId];
      final unit = unitMap[entry.unitId];

      final date = tenant?.moveInDate ?? entry.dueDate;
      final dateFormatted = '${date.day}/${date.month}/${date.year % 100}';

      final opBal = entry.openingBalance;
      final cMth = entry.expectedAmount;
      final total = opBal + cMth;
      final eCity = entry.extraCharges;
      final gTotal = total + eCity;

      // Payments: P-1 and P-2
      int p1Amount = 0;
      String p1Date = '';
      int p2Amount = 0;
      String p2Date = '';

      if (entry.payments.isNotEmpty) {
        final p1 = entry.payments[0];
        p1Amount = p1.amount;
        p1Date = '${p1.date.day}/${p1.date.month}/${p1.date.year % 100}';
      }
      if (entry.payments.length > 1) {
        final p2 = entry.payments[1];
        p2Amount = p2.amount;
        p2Date = '${p2.date.day}/${p2.date.month}/${p2.date.year % 100}';
      }

      final cloBal = (gTotal - (p1Amount + p2Amount)).clamp(0, 99999999);

      sumOpBal += opBal;
      sumCMth += cMth;
      sumTotal += total;
      sumECity += eCity;
      sumGTotal += gTotal;
      sumP1 += p1Amount;
      sumP2 += p2Amount;
      sumCloBal += cloBal;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).value = TextCellValue(dateFormatted);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).value =
          TextCellValue(tenant != null ? tenant.name.toUpperCase() : (unit?.roomDisplayName ?? 'ROOM ${i + 1}'));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).value = IntCellValue(opBal);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx)).value = IntCellValue(cMth);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx)).value = IntCellValue(total);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).value = IntCellValue(eCity);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx)).value = IntCellValue(gTotal);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIdx)).value =
          p1Amount > 0 ? IntCellValue(p1Amount) : TextCellValue('');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx)).value = TextCellValue(p1Date);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIdx)).value =
          p2Amount > 0 ? IntCellValue(p2Amount) : TextCellValue('');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIdx)).value = TextCellValue(p2Date);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIdx)).value = IntCellValue(cloBal);

      // Formatting
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).cellStyle =
          CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).cellStyle =
          CellStyle(horizontalAlign: HorizontalAlign.Center);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).cellStyle =
          CellStyle(bold: true, horizontalAlign: HorizontalAlign.Left);
      for (int c = 3; c <= 7; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx)).cellStyle =
            CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right);
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIdx)).cellStyle =
          CellStyle(horizontalAlign: HorizontalAlign.Right);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx)).cellStyle =
          CellStyle(horizontalAlign: HorizontalAlign.Center);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIdx)).cellStyle =
          CellStyle(horizontalAlign: HorizontalAlign.Right);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIdx)).cellStyle =
          CellStyle(horizontalAlign: HorizontalAlign.Center);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIdx)).cellStyle =
          CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right);

      rowIdx++;
    }

    // Blank separator row before total
    rowIdx++;

    // Totals Row (Matching Image bottom row)
    final totalRowStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).value = TextCellValue('');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).value = TextCellValue('');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).value = TextCellValue('10840');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).cellStyle =
        CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).value = IntCellValue(sumOpBal);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).cellStyle = totalRowStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx)).value = IntCellValue(sumCMth);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx)).cellStyle = totalRowStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx)).value = IntCellValue(sumTotal);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx)).cellStyle = totalRowStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).value = IntCellValue(sumECity);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).cellStyle = totalRowStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx)).value = IntCellValue(sumGTotal);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx)).cellStyle = totalRowStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIdx)).value = IntCellValue(sumP1);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIdx)).cellStyle = totalRowStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx)).value = TextCellValue('');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIdx)).value = IntCellValue(sumP2);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIdx)).cellStyle = totalRowStyle;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIdx)).value = IntCellValue(0);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIdx)).cellStyle =
        CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIdx)).value = IntCellValue(sumCloBal);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIdx)).cellStyle = totalRowStyle;

    // Set Column Widths
    sheet.setColumnWidth(0, 8.0);
    sheet.setColumnWidth(1, 12.0);
    sheet.setColumnWidth(2, 22.0);
    sheet.setColumnWidth(3, 12.0);
    sheet.setColumnWidth(4, 12.0);
    sheet.setColumnWidth(5, 12.0);
    sheet.setColumnWidth(6, 12.0);
    sheet.setColumnWidth(7, 12.0);
    sheet.setColumnWidth(8, 10.0);
    sheet.setColumnWidth(9, 12.0);
    sheet.setColumnWidth(10, 10.0);
    sheet.setColumnWidth(11, 12.0);
    sheet.setColumnWidth(12, 12.0);
  }

  /// Exports full payment ledger for a single tenant
  static Future<ExcelExportResult> generateTenantLedgerReport({
    required Tenant tenant,
    required Property? property,
    required PropertyUnit? unit,
    required List<RentEntry> tenantEntries,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Tenant Ledger'];
    excel.setDefaultSheet('Tenant Ledger');

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#0F5132'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // Tenant info block
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('KHATA PE — TENANT PAYMENT LEDGER (Landlord: Anil)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = headerStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue('Tenant: ${tenant.name} (${tenant.phone})');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value =
        TextCellValue('Building: ${property?.name ?? ""} — Room: ${unit?.roomDisplayName ?? ""}');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value =
        TextCellValue('Monthly Rent: ₹${tenant.monthlyRent} | Deposit: ₹${tenant.securityDeposit}');

    final headers = [
      'Month',
      'Due Date',
      'Expected (₹)',
      'Extra (₹)',
      'Received (₹)',
      'Balance Due (₹)',
      'Status',
      'Payments Count',
      'Last Payment Date'
    ];

    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 6));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }

    int rIdx = 7;
    for (final entry in tenantEntries) {
      final monthDate = DateFormatter.fromMonthKey(entry.month);
      final monthName = DateFormatter.formatMonthYear(monthDate);
      final lastPayment = entry.payments.isNotEmpty ? entry.payments.last : null;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIdx)).value = TextCellValue(monthName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIdx)).value =
          TextCellValue(DateFormatter.formatDate(entry.dueDate));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIdx)).value =
          IntCellValue(entry.expectedAmount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rIdx)).value =
          IntCellValue(entry.extraCharges);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rIdx)).value =
          IntCellValue(entry.totalCollected);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rIdx)).value =
          IntCellValue(entry.balanceDue);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rIdx)).value =
          TextCellValue(entry.status.displayName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rIdx)).value =
          IntCellValue(entry.payments.length);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rIdx)).value =
          TextCellValue(lastPayment != null ? DateFormatter.formatDate(lastPayment.date) : '—');

      rIdx++;
    }

    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Tenant Ledger') {
      try {
        excel.delete(defaultSheet);
      } catch (_) {}
    }

    final List<int>? fileBytes = excel.save();
    final sanitizedName = tenant.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final fileName = 'KhataPe_Ledger_$sanitizedName.xlsx';
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(fileBytes ?? [], flush: true);

    return ExcelExportResult(
      filePath: file.path,
      fileName: fileName,
      fileSize: fileBytes?.length ?? 0,
    );
  }

  /// Share file via system share sheet
  static Future<void> shareFile(ExcelExportResult result) async {
    await Share.shareXFiles(
      [XFile(result.filePath)],
      subject: result.fileName,
      text: 'Khata Pe Rent Report: ${result.fileName}',
    );
  }
}
