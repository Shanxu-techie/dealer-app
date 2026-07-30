import 'dart:typed_data';

import 'package:dealer_app/services/pdf_fonts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'price_letter_service.dart';

Future<Uint8List> generatePriceLetterPdf(PriceLetterData data) async {
  await PdfFonts.load();

  final pdf = pw.Document();

  final bgBytes = await rootBundle.load(
    'assets/letterhead/pgl_letterhead_bg.jpeg',
  );

  final background = pw.MemoryImage(bgBytes.buffer.asUint8List());

  final customerCodeStyle = pw.TextStyle(
    font: PdfFonts.arimo,
    fontSize: 20,
    color: PdfColor.fromHex('#2F5496'),
  );

  final bodyStyle = pw.TextStyle(font: PdfFonts.arimo, fontSize: 12);

  final tableStyle = pw.TextStyle(font: PdfFonts.arimoBold, fontSize: 11);

  final tableBodyStyle = pw.TextStyle(font: PdfFonts.arimo, fontSize: 11);

  final subjectLabelStyle = pw.TextStyle(
    font: PdfFonts.arimoBold,
    fontSize: 11,
  );

  final subjectStyle = pw.TextStyle(
    font: PdfFonts.arimoBold,
    fontSize: 11,
    decoration: pw.TextDecoration.underline,
  );

  final footerStyle = pw.TextStyle(font: PdfFonts.footer, fontSize: 24);

  final dateStr = DateFormat('MMMM dd, yyyy').format(data.effectiveDate);

  const subjectText = 'MS and Diesel Indent and Retail / Selling Price';

  const greetingText = 'Dear Customer,';

  const introText =
      "Your Retail Outlet's indent and selling price shall be as under effective ";
  const thanksText = 'Thanks for compliance.';

  const ograParagraph =
      'Adherence of above prices is required; please note that OGRA personnel are actively checking fuel prices that are being charged at various sites against the official list that Total PARCO Pakistan Limited provides them on each price change.';

  const systemGeneratedFooter =
      'This is a system generated document and does not require any signature.';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Image(background, fit: pw.BoxFit.fill),
            ),
            pw.Positioned.fill(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(72),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 38),
                    pw.Text(
                      'Customer Code: ${data.dealerCode}',
                      style: customerCodeStyle,
                    ),
                    pw.SizedBox(height: 100),
                    pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: 'Subject: ',
                            style: subjectLabelStyle,
                          ),
                          pw.TextSpan(text: subjectText, style: subjectStyle),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 30),

                    pw.Text(greetingText, style: bodyStyle),

                    pw.SizedBox(height: 8),

                    pw.Text('$introText$dateStr.', style: bodyStyle),
                    pw.SizedBox(height: 50),

                    pw.Table(
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('', style: tableStyle),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Indent Price (Rs/Liter)',
                                style: tableStyle,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                'Fixed Selling Price (Rs/Liter)',
                                style: tableStyle,
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('MS :', style: tableStyle),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                data.ms?.indentPrice.toStringAsFixed(2) ?? '-',
                                style: tableBodyStyle,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                data.ms?.sellingPrice.toStringAsFixed(2) ?? '-',
                                style: tableBodyStyle,
                              ),
                            ),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Diesel :', style: tableStyle),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                data.hsd?.indentPrice.toStringAsFixed(2) ?? '-',
                                style: tableBodyStyle,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                data.hsd?.sellingPrice.toStringAsFixed(2) ??
                                    '-',
                                style: tableBodyStyle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 32),
                    pw.Text(ograParagraph, style: bodyStyle),

                    pw.SizedBox(height: 44),
                    pw.Text(thanksText, style: bodyStyle),
                    pw.SizedBox(height: 72),
                    pw.Text(systemGeneratedFooter, style: footerStyle),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
