import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_punch_model.dart';

class EsslSoapService {
  EsslSoapService._();
  static final EsslSoapService instance = EsslSoapService._();

  Future<List<AttendancePunch>> getTransactionsLog({
    required String apiUrl,
    required String serialNumber,
    required String username,
    required String password,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final endpointUrl = _cleanEndpoint(apiUrl);
    
    // Format dates to eSSL expected format 'YYYY-MM-DD HH:mm:ss'
    String fromDateTimeStr = "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')} 00:00:00";
    String toDateTimeStr = "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')} 23:59:59";

    final soapEnvelope = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetTransactionsLog xmlns="http://tempuri.org/">
      <FromDateTime>$fromDateTimeStr</FromDateTime>
      <ToDateTime>$toDateTimeStr</ToDateTime>
      <SerialNumber>$serialNumber</SerialNumber>
      <UserName>$username</UserName>
      <UserPassword>$password</UserPassword>
    </GetTransactionsLog>
  </soap:Body>
</soap:Envelope>''';

    final uri = Uri.parse(endpointUrl);
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': '"http://tempuri.org/GetTransactionsLog"',
        },
        body: utf8.encode(soapEnvelope),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AttendancePunch.parseXmlLogs(response.body);
      } else {
        throw Exception('Failed to fetch logs. HTTP Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  String _cleanEndpoint(String apiUrl) {
    String endpointUrl = apiUrl.trim();
    if (endpointUrl.endsWith('/')) {
      endpointUrl = endpointUrl.substring(0, endpointUrl.length - 1);
    }
    if (!endpointUrl.contains('.asmx')) {
      endpointUrl = '$endpointUrl/WebAPIService.asmx';
    }
    return endpointUrl;
  }
}
