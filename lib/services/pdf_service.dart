import 'package:read_pdf_text/read_pdf_text.dart';

class PdfService {
  Future<String> extractText(String filePath) async {
    try {
      final text = await ReadPdfText.getPDFtext(filePath);
      return text;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }
}
