import 'dart:convert';
import 'package:http/http.dart' as http;

class BilingualApiService {
  // Update this to match your backend URL
  static const String baseUrl = "http://localhost:5000/api/bilingual";

  // Create a new bill
  static Future<Map<String, dynamic>> createBill(
      Map<String, dynamic> billData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/bills"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(billData),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Error creating bill: ${e.toString()}"
      };
    }
  }

  // Get all bills
  static Future<Map<String, dynamic>> getAllBills() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/bills"));
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Error fetching bills: $e"};
    }
  }

  // Get a specific bill
  static Future<Map<String, dynamic>> getBill(String billNo) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/bills/$billNo"));
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Error fetching bill: $e"};
    }
  }

  // Delete a bill
  static Future<Map<String, dynamic>> deleteBill(String billNo) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/bills/$billNo"));
      return json.decode(response.body);
    } catch (e) {
      return {"success": false, "message": "Error deleting bill: $e"};
    }
  }

  // Generate next bill number
  static Future<Map<String, dynamic>> generateBillNumber() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/generate-bill-number"));
      return json.decode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": "Error generating bill number: $e"
      };
    }
  }
}
