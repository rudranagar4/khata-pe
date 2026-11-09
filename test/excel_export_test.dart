import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:khatape/core/services/excel_export_service.dart';
import 'package:khatape/features/properties/domain/models/property.dart';
import 'package:khatape/features/properties/domain/models/unit.dart';
import 'package:khatape/features/tenants/domain/models/tenant.dart';
import 'package:khatape/features/rent/domain/models/rent_entry.dart';
import 'package:khatape/features/expenses/domain/models/expense.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Excel Export Format Tests', () {
    test('Generates Excel file matching user ledger image format', () {
      const propId = 'prop_new_14';
      final property = Property(
        id: propId,
        name: 'NEW 14',
        type: PropertyType.building,
        address: 'Plot 14, Main Road',
        city: 'Delhi',
        units: List.generate(
          14,
          (i) => PropertyUnit(
            id: 'unit_new14_${i + 1}',
            propertyId: propId,
            unitName: 'Room ${i + 1}',
            monthlyRent: [3, 5, 10, 12].contains(i) ? 2630 : 2430,
            securityDeposit: 5000,
            status: UnitStatus.occupied,
          ),
        ),
      );

      final tenantData = [
        ('MAHESH PAINTER', 5380, 2430, 0),
        ('MAHIPAL', 1220, 2430, 0),
        ('BABLU', 6760, 2430, 0),
        ('KIRAN', 0, 2630, 800),
        ('URMILA', 730, 2430, 300),
        ('KHAN', 0, 2630, 0),
        ('SHYAM LAL', 2430, 2430, 0),
        ('RINKU', 0, 2430, 0),
        ('JAI NARAYAN', 7160, 2430, 0),
        ('SANJAY', 30, 2430, 300),
        ('PRAMOD', 7880, 2630, 0),
        ('SHIV NANDAN', 0, 2430, 0),
        ('RAMANUJ', 5690, 2630, 300),
        ('SURAJ', 5500, 2430, 0),
      ];

      final tenants = <Tenant>[];
      final rentEntries = <RentEntry>[];
      const monthKey = '2026-10';

      for (int i = 0; i < 14; i++) {
        final tId = 'tenant_new14_${i + 1}';
        final t = tenantData[i];
        tenants.add(
          Tenant(
            id: tId,
            name: t.$1,
            phone: '98000000${(i + 1).toString().padLeft(2, '0')}',
            propertyId: propId,
            unitId: 'unit_new14_${i + 1}',
            monthlyRent: t.$3,
            securityDeposit: 5000,
            moveInDate: DateTime(2026, 8, 25),
            rentDueDay: 1,
          ),
        );

        rentEntries.add(
          RentEntry(
            id: 'entry_new14_${i + 1}',
            tenantId: tId,
            propertyId: propId,
            unitId: 'unit_new14_${i + 1}',
            month: monthKey,
            expectedAmount: t.$3,
            openingBalance: t.$2,
            extraCharges: t.$4,
            dueDate: DateTime(2026, 10, 1),
            amountReceived: 0,
            payments: [],
          ),
        );
      }

      // Generate the Excel document
      final excelDoc = ExcelExportService.buildExcelDocument(
        monthKey: monthKey,
        properties: [property],
        tenants: tenants,
        rentEntries: rentEntries,
        expenses: <Expense>[],
        selectedPropertyId: propId,
      );

      // Verify default sheet
      expect(excelDoc.getDefaultSheet(), equals('Room Khata'));

      final sheet = excelDoc['Room Khata'];
      expect(sheet, isNotNull);

      // Verify Title Banner in Row 1 (Row index 1)
      final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      expect(titleCell.value, isNotNull);
      final titleText = titleCell.value.toString();
      expect(titleText.contains('NEW 14'), isTrue);
      expect(titleText.contains('卐'), isTrue);
      expect(titleText.contains('OCT'), isTrue);
      expect(titleText.contains('PAID IN'), isTrue);
      expect(titleText.contains('NOV'), isTrue);
      expect(titleText.contains('2026'), isTrue);

      // Verify Headers in Row 3 (Row index 3)
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value.toString(), equals('S No'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value.toString(), equals('Date'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3)).value.toString(), equals('Particular'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3)).value.toString(), equals('Op.Bal'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 3)).value.toString(), equals('C.Mth'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 3)).value.toString(), equals('Total'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 3)).value.toString(), equals('E. CITY'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 3)).value.toString(), equals('G. Total'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 3)).value.toString(), equals('PAYMENTS'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: 3)).value.toString(), equals('Clo Bal'));

      // Verify Subheaders in Row 4 (Row index 4)
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 4)).value.toString(), equals('P - 1'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 4)).value.toString(), equals('DATE'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 4)).value.toString(), equals('P - 2'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 4)).value.toString(), equals('DATE'));

      // Verify first tenant row (MAHESH PAINTER)
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value.toString(), equals('1'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 6)).value.toString(), equals('MAHESH PAINTER'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 6)).value.toString(), equals('5380'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 6)).value.toString(), equals('2430'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 6)).value.toString(), equals('7810'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 6)).value.toString(), equals('0'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 6)).value.toString(), equals('7810'));

      // Verify row 4 (KIRAN with 800 electricity)
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 9)).value.toString(), equals('KIRAN'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 9)).value.toString(), equals('0'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 9)).value.toString(), equals('2630'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 9)).value.toString(), equals('2630'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 9)).value.toString(), equals('800'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 9)).value.toString(), equals('3430'));

      // Verify Totals Row (Row index 21: 14 rows + 6 header rows + 1 blank row)
      final totalRowIdx = 6 + 14 + 1;
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRowIdx)).value.toString(), equals('42780'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRowIdx)).value.toString(), equals('34820'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIdx)).value.toString(), equals('77600'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRowIdx)).value.toString(), equals('1700'));
      expect(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: totalRowIdx)).value.toString(), equals('79300'));

      // Verify that excel can be encoded to bytes and decoded back
      final bytes = excelDoc.save();
      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);

      final decoded = Excel.decodeBytes(bytes);
      expect(decoded.tables.containsKey('Room Khata'), isTrue);
      expect(decoded.tables.containsKey('Summary'), isTrue);
      expect(decoded.tables.containsKey('Rent Details'), isTrue);
    });
  });
}
