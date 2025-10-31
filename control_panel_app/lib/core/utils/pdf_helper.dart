import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper class for PDF operations without using printing package
class PdfHelper {
  PdfHelper._();

  /// Saves PDF bytes to a file and opens it
  static Future<File> savePdfFile({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      // Get the appropriate directory based on platform
      Directory directory;
      
      if (Platform.isAndroid) {
        // For Android, use external storage
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        // For iOS, use documents directory
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms (desktop)
        directory = await getDownloadsDirectory() ?? 
                    await getApplicationDocumentsDirectory();
      }

      // Create the file path
      final filePath = '${directory.path}/$fileName.pdf';
      final file = File(filePath);

      // Write the PDF bytes to the file
      await file.writeAsBytes(pdfBytes, flush: true);

      debugPrint('PDF saved to: $filePath');
      return file;
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      rethrow;
    }
  }

  /// Opens a PDF file using the default system application
  static Future<bool> openPdfFile(File file) async {
    try {
      final uri = Uri.file(file.path);
      
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Cannot launch PDF file: ${file.path}');
        return false;
      }
    } catch (e) {
      debugPrint('Error opening PDF: $e');
      return false;
    }
  }

  /// Saves and opens a PDF file
  static Future<void> saveAndOpenPdf({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      final file = await savePdfFile(
        pdfBytes: pdfBytes,
        fileName: fileName,
      );
      
      await openPdfFile(file);
    } catch (e) {
      debugPrint('Error in saveAndOpenPdf: $e');
      rethrow;
    }
  }

  /// Shares a PDF file (this would require share_plus package if needed)
  /// For now, it just saves and opens the file
  static Future<String> sharePdf({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      final file = await savePdfFile(
        pdfBytes: pdfBytes,
        fileName: fileName,
      );
      
      return file.path;
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      rethrow;
    }
  }

  /// Gets a temporary file path for preview purposes
  static Future<File> getTempPdfFile({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName.pdf';
      final file = File(filePath);
      
      await file.writeAsBytes(pdfBytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('Error creating temp PDF: $e');
      rethrow;
    }
  }

  /// Deletes a PDF file
  static Future<bool> deletePdfFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting PDF: $e');
      return false;
    }
  }

  /// Generates a unique file name for invoices
  static String generateInvoiceFileName(String bookingId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanId = bookingId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return 'invoice_${cleanId}_$timestamp';
  }
}
