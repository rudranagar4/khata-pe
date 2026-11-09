import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../../features/properties/domain/models/property.dart';
import '../../features/properties/domain/models/unit.dart';
import '../../features/tenants/domain/models/tenant.dart';
import '../../features/rent/domain/models/payment.dart';
import '../../features/rent/domain/models/rent_entry.dart';

class PdfReceiptService {
  /// Converts integer amount to Indian English words
  static String numberToWords(int number) {
    if (number == 0) return 'Zero Rupees Only';

    final units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];

    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    String convertBelowThousand(int n) {
      if (n == 0) return '';
      if (n < 20) return units[n];
      if (n < 100) {
        final unitStr = units[n % 10];
        return '${tens[n ~/ 10]}${n % 10 != 0 ? " $unitStr" : ""}';
      }
      final remStr = convertBelowThousand(n % 100);
      return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? " $remStr" : ""}';
    }

    int remaining = number;
    String result = '';

    // Crores
    final crores = remaining ~/ 10000000;
    if (crores > 0) {
      result += '${convertBelowThousand(crores)} Crore ';
      remaining %= 10000000;
    }

    // Lakhs
    final lakhs = remaining ~/ 100000;
    if (lakhs > 0) {
      result += '${convertBelowThousand(lakhs)} Lakh ';
      remaining %= 100000;
    }

    // Thousands
    final thousands = remaining ~/ 1000;
    if (thousands > 0) {
      result += '${convertBelowThousand(thousands)} Thousand ';
      remaining %= 1000;
    }

    // Below thousand
    if (remaining > 0) {
      result += convertBelowThousand(remaining);
    }

    return '${result.trim()} Rupees Only';
  }

  /// Builds PDF Receipt bytes
  static Future<Uint8List> buildReceiptPdf({
    required Payment payment,
    required RentEntry rentEntry,
    required Tenant tenant,
    required Property? property,
    required PropertyUnit? unit,
    required String ownerName,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#0F5132');
    final darkTextColor = PdfColor.fromHex('#0F172A');
    final greyTextColor = PdfColor.fromHex('#64748B');
    final lightBgColor = PdfColor.fromHex('#F8FAFC');

    final monthDate = DateFormatter.fromMonthKey(rentEntry.month);
    final monthName = DateFormatter.formatMonthYear(monthDate);
    final amountInWords = numberToWords(payment.amount);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: primaryColor, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'KHATA PE',
                          style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.Text(
                          'Rent Management & Records',
                          style: pw.TextStyle(fontSize: 10, color: greyTextColor),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: lightBgColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: primaryColor, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'RENT RECEIPT',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          pw.Text(
                            'Receipt No: ${payment.receiptNo}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: darkTextColor,
                            ),
                          ),
                          pw.Text(
                            'Date: ${DateFormatter.formatDate(payment.date)}',
                            style: pw.TextStyle(fontSize: 10, color: darkTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Divider(color: primaryColor, thickness: 1.5),
                pw.SizedBox(height: 16),

                // Amount Highlight Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E8F5E9'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Amount Received:',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                      pw.Text(
                        '₹ ${CurrencyFormatter.format(payment.amount, includeSymbol: false)}',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),
                pw.Text(
                  'Amount in Words: $amountInWords',
                  style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: darkTextColor),
                ),

                pw.SizedBox(height: 20),

                // Details Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 1),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.5),
                    1: const pw.FlexColumnWidth(4),
                  },
                  children: [
                    _buildTableRow('Received From (Tenant)', tenant.name, isBold: true),
                    _buildTableRow('Tenant Phone', tenant.phone),
                    _buildTableRow('Building Name', property?.name ?? '—'),
                    _buildTableRow('Room No.', unit?.roomDisplayName ?? '—'),
                    _buildTableRow('Rent Month', monthName, isBold: true),
                    _buildTableRow('Payment Mode', payment.mode.displayName),
                    if (payment.referenceNo != null && payment.referenceNo!.isNotEmpty)
                      _buildTableRow('Reference / Txn ID', payment.referenceNo!),
                    _buildTableRow('Total Month Payable', '₹ ${CurrencyFormatter.format(rentEntry.totalPayable, includeSymbol: false)}'),
                    _buildTableRow('Total Collected To Date', '₹ ${CurrencyFormatter.format(rentEntry.totalCollected, includeSymbol: false)}'),
                    _buildTableRow('Remaining Balance Due', '₹ ${CurrencyFormatter.format(rentEntry.balanceDue, includeSymbol: false)}'),
                  ],
                ),

                if (payment.note != null && payment.note!.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text('Note: ${payment.note}', style: pw.TextStyle(fontSize: 10, color: greyTextColor)),
                ],

                pw.Spacer(),

                // Footer & Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Payment Status: Verified',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor),
                        ),
                        pw.Text(
                          'Generated digitally via Khata Pe App',
                          style: pw.TextStyle(fontSize: 8, color: greyTextColor),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 140,
                          child: pw.Divider(color: darkTextColor, thickness: 1),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          ownerName.isNotEmpty ? ownerName : 'Property Owner',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkTextColor),
                        ),
                        pw.Text(
                          'Authorized Signature',
                          style: pw.TextStyle(fontSize: 9, color: greyTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(String label, String value, {bool isBold = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#475569')),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ),
      ],
    );
  }

  /// Print or share receipt directly
  static Future<void> printOrShareReceipt({
    required Payment payment,
    required RentEntry rentEntry,
    required Tenant tenant,
    required Property? property,
    required PropertyUnit? unit,
    required String ownerName,
  }) async {
    final pdfBytes = await buildReceiptPdf(
      payment: payment,
      rentEntry: rentEntry,
      tenant: tenant,
      property: property,
      unit: unit,
      ownerName: ownerName,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Receipt_${payment.receiptNo}.pdf',
    );
  }

  /// Share PDF receipt via WhatsApp / Mail / etc.
  static Future<void> shareReceipt({
    required Payment payment,
    required RentEntry rentEntry,
    required Tenant tenant,
    required Property? property,
    required PropertyUnit? unit,
    required String ownerName,
  }) async {
    final pdfBytes = await buildReceiptPdf(
      payment: payment,
      rentEntry: rentEntry,
      tenant: tenant,
      property: property,
      unit: unit,
      ownerName: ownerName,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Receipt_${payment.receiptNo}.pdf',
    );
  }
}

