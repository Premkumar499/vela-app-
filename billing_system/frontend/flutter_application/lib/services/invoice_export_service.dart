import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;

/// Service to export invoices as images
class InvoiceExportService {
  static const String baseUrl = 'http://localhost:5000';

  /// Capture widget as image and save to backend
  static Future<Map<String, dynamic>> saveInvoiceAsImage({
    required GlobalKey widgetKey,
    required String invoiceNumber,
    required bool isCompanyInvoice,
  }) async {
    try {
      // Get the boundary from the widget key
      RenderRepaintBoundary? boundary =
          widgetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        return {
          'success': false,
          'message': 'Could not capture invoice. Please try again.',
        };
      }

      // Wait for widget to be fully rendered
      await Future.delayed(const Duration(milliseconds: 200));

      // Capture the widget as an image
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return {
          'success': false,
          'message': 'Failed to convert invoice to image',
        };
      }

      // Convert to base64
      final Uint8List bytes = byteData.buffer.asUint8List();
      final String base64Image = base64Encode(bytes);

      // Send to backend
      final response = await http.post(
        Uri.parse('$baseUrl/invoice-export/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'invoice_number': invoiceNumber,
          'image_data': base64Image,
          'is_company_invoice': isCompanyInvoice,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'fileName': data['file_name'],
          'folder': data['folder'],
          'path': data['path'],
          'size': data['size'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to save invoice',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}
