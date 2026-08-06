import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

class PdfFonts {
  static pw.Font? _arimo;
  static pw.Font? _arimoBold;
  static pw.Font? _footer;

  static Future<void> load() async {
    _arimo ??= pw.Font.ttf(
      await rootBundle.load('assets/letterhead/fonts/Arimo-Regular.ttf'),
    );

    _arimoBold ??= pw.Font.ttf(
      await rootBundle.load('assets/letterhead/fonts/Arimo-Bold.ttf'),
    );

    _footer ??= pw.Font.ttf(
      await rootBundle.load(
        'assets/letterhead/fonts/CormorantGaramond-Bold.ttf',
      ),
    );
  }

  static pw.Font get arimo => _arimo!;
  static pw.Font get arimoBold => _arimoBold!;
  static pw.Font get footer => _footer!;
}
