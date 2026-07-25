import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ETimeTrackAddEmployeeResult {
  final bool isSuccess;
  final bool isAuthError;
  final String statusMessage;
  final String commandId;
  final String rawRequest;
  final String rawResponse;

  ETimeTrackAddEmployeeResult({
    required this.isSuccess,
    this.isAuthError = false,
    required this.statusMessage,
    required this.commandId,
    required this.rawRequest,
    required this.rawResponse,
  });
}

class ETimeTrackApiService {
  ETimeTrackApiService._();
  static final ETimeTrackApiService instance = ETimeTrackApiService._();

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

  /// 1. AddEmployee Method (SOAPAction: "http://tempuri.org/AddEmployee")
  Future<ETimeTrackAddEmployeeResult> addEmployee({
    required String apiUrl,
    required String apiKey,
    required String employeeCode,
    required String employeeName,
    required String cardNumber,
    required String serialNumber,
    required String username,
    required String password,
    required String commandId,
  }) async {
    final endpointUrl = _cleanEndpoint(apiUrl);

    final soapEnvelope = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <AddEmployee xmlns="http://tempuri.org/">
      <APIKey>${_escapeXml(apiKey)}</APIKey>
      <EmployeeCode>${_escapeXml(employeeCode)}</EmployeeCode>
      <EmployeeName>${_escapeXml(employeeName)}</EmployeeName>
      <CardNumber>${_escapeXml(cardNumber)}</CardNumber>
      <SerialNumber>${_escapeXml(serialNumber)}</SerialNumber>
      <UserName>${_escapeXml(username)}</UserName>
      <UserPassword>${_escapeXml(password)}</UserPassword>
      <CommandId>${_escapeXml(commandId)}</CommandId>
    </AddEmployee>
  </soap:Body>
</soap:Envelope>''';

    return _postSoap(
      endpointUrl: endpointUrl,
      soapAction: 'http://tempuri.org/AddEmployee',
      soapEnvelope: soapEnvelope,
      commandId: commandId,
      resultTag: 'AddEmployeeResult',
    );
  }

  /// 2. BlockUnblockUser Method (SOAPAction: "http://tempuri.org/BlockUnblockUser")
  Future<ETimeTrackAddEmployeeResult> blockUnblockUser({
    required String apiUrl,
    required String apiKey,
    required String employeeCode,
    required String employeeName,
    required String serialNumber,
    required bool isBlock,
    required String username,
    required String password,
    required String commandId,
  }) async {
    final endpointUrl = _cleanEndpoint(apiUrl);

    final soapEnvelope = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <BlockUnblockUser xmlns="http://tempuri.org/">
      <APIKey>${_escapeXml(apiKey)}</APIKey>
      <EmployeeCode>${_escapeXml(employeeCode)}</EmployeeCode>
      <EmployeeName>${_escapeXml(employeeName)}</EmployeeName>
      <SerialNumber>${_escapeXml(serialNumber)}</SerialNumber>
      <IsBlock>${isBlock ? "true" : "false"}</IsBlock>
      <UserName>${_escapeXml(username)}</UserName>
      <UserPassword>${_escapeXml(password)}</UserPassword>
      <CommandId>${_escapeXml(commandId)}</CommandId>
    </BlockUnblockUser>
  </soap:Body>
</soap:Envelope>''';

    return _postSoap(
      endpointUrl: endpointUrl,
      soapAction: 'http://tempuri.org/BlockUnblockUser',
      soapEnvelope: soapEnvelope,
      commandId: commandId,
      resultTag: 'BlockUnblockUserResult',
    );
  }

  /// 3. DeleteUser Method (SOAPAction: "http://tempuri.org/DeleteUser")
  Future<ETimeTrackAddEmployeeResult> deleteUser({
    required String apiUrl,
    required String apiKey,
    required String employeeCode,
    required String serialNumber,
    required String username,
    required String password,
    required String commandId,
  }) async {
    final endpointUrl = _cleanEndpoint(apiUrl);

    final soapEnvelope = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <DeleteUser xmlns="http://tempuri.org/">
      <APIKey>${_escapeXml(apiKey)}</APIKey>
      <EmployeeCode>${_escapeXml(employeeCode)}</EmployeeCode>
      <SerialNumber>${_escapeXml(serialNumber)}</SerialNumber>
      <UserName>${_escapeXml(username)}</UserName>
      <UserPassword>${_escapeXml(password)}</UserPassword>
      <CommandId>${_escapeXml(commandId)}</CommandId>
    </DeleteUser>
  </soap:Body>
</soap:Envelope>''';

    return _postSoap(
      endpointUrl: endpointUrl,
      soapAction: 'http://tempuri.org/DeleteUser',
      soapEnvelope: soapEnvelope,
      commandId: commandId,
      resultTag: 'DeleteUserResult',
    );
  }

  /// 4. GetCommandStatus Method (SOAPAction: "http://tempuri.org/GetCommandStatus")
  Future<ETimeTrackAddEmployeeResult> getCommandStatus({
    required String apiUrl,
    required String commandId,
    required String username,
    required String password,
  }) async {
    final endpointUrl = _cleanEndpoint(apiUrl);

    final soapEnvelope = '''<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetCommandStatus xmlns="http://tempuri.org/">
      <CommandId>${_escapeXml(commandId)}</CommandId>
      <UserName>${_escapeXml(username)}</UserName>
      <UserPassword>${_escapeXml(password)}</UserPassword>
    </GetCommandStatus>
  </soap:Body>
</soap:Envelope>''';

    return _postSoap(
      endpointUrl: endpointUrl,
      soapAction: 'http://tempuri.org/GetCommandStatus',
      soapEnvelope: soapEnvelope,
      commandId: commandId,
      resultTag: 'GetCommandStatusResult',
    );
  }

  /// Generic helper to post SOAP 1.1 request & handle XML response
  Future<ETimeTrackAddEmployeeResult> _postSoap({
    required String endpointUrl,
    required String soapAction,
    required String soapEnvelope,
    required String commandId,
    required String resultTag,
  }) async {
    final uri = Uri.parse(endpointUrl);
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'text/xml; charset=utf-8');
      req.headers.set('SOAPAction', soapAction);
      req.add(utf8.encode(soapEnvelope));

      final res = await req.close();
      final responseBody = await res.transform(utf8.decoder).join();
      client.close();

      debugPrint('eTimeTrack SOAP Response [$soapAction] [${res.statusCode}]: $responseBody');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final parsedStatus = _parseSoapResponse(responseBody, commandId, resultTag);
        return ETimeTrackAddEmployeeResult(
          isSuccess: parsedStatus['isSuccess'] == true,
          isAuthError: parsedStatus['isAuthError'] == true,
          statusMessage: parsedStatus['statusMessage']?.toString() ?? 'Operation completed',
          commandId: parsedStatus['commandId']?.toString() ?? commandId,
          rawRequest: soapEnvelope,
          rawResponse: responseBody,
        );
      } else {
        final isAuth = res.statusCode == 401 ||
            responseBody.toLowerCase().contains('unauthorized') ||
            responseBody.toLowerCase().contains('invalid user');
        return ETimeTrackAddEmployeeResult(
          isSuccess: false,
          isAuthError: isAuth,
          statusMessage: isAuth
              ? 'Authentication Failed: Invalid device username or password.'
              : 'HTTP ${res.statusCode}: Device server returned error.',
          commandId: commandId,
          rawRequest: soapEnvelope,
          rawResponse: responseBody,
        );
      }
    } catch (e) {
      client.close();
      return ETimeTrackAddEmployeeResult(
        isSuccess: false,
        isAuthError: false,
        statusMessage: 'Connection failed: Unable to reach device Web API at $endpointUrl ($e)',
        commandId: commandId,
        rawRequest: soapEnvelope,
        rawResponse: e.toString(),
      );
    }
  }

  Map<String, dynamic> _parseSoapResponse(String xml, String fallbackCmdId, String resultTag) {
    final lowerXml = xml.toLowerCase();

    if (lowerXml.contains('authentication failed') ||
        lowerXml.contains('invalid username') ||
        lowerXml.contains('invalid user password') ||
        lowerXml.contains('invalid password') ||
        lowerXml.contains('unauthorized')) {
      return {
        'isSuccess': false,
        'isAuthError': true,
        'statusMessage': 'Authentication Failed: Invalid device user credentials.',
        'commandId': fallbackCmdId,
      };
    }

    final resultMatch = RegExp('<$resultTag>(.*?)</$resultTag>', dotAll: true, caseSensitive: false).firstMatch(xml);
    final returnStr = resultMatch != null ? resultMatch.group(1)! : xml;

    final cmdMatch = RegExp(r'<CommandId>(.*?)</CommandId>', caseSensitive: false).firstMatch(xml);
    final parsedCmdId = cmdMatch != null ? cmdMatch.group(1)!.trim() : fallbackCmdId;

    if (returnStr.toLowerCase().contains('success') || returnStr.contains('1') || returnStr.contains('0')) {
      return {
        'isSuccess': true,
        'isAuthError': false,
        'statusMessage': 'Device Operation Succeeded ($returnStr)',
        'commandId': parsedCmdId,
      };
    } else {
      final msgMatch = RegExp(r'<StatusMessage>(.*?)</StatusMessage>', caseSensitive: false).firstMatch(xml);
      final msg = msgMatch != null ? msgMatch.group(1)! : 'Device Result: $returnStr';
      return {
        'isSuccess': false,
        'isAuthError': false,
        'statusMessage': msg,
        'commandId': parsedCmdId,
      };
    }
  }

  Future<Map<String, dynamic>> testDeviceConnection({
    required String apiUrl,
    required String apiKey,
  }) async {
    final endpointUrl = _cleanEndpoint(apiUrl);
    final uri = Uri.parse(endpointUrl);
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      client.close();

      if (res.statusCode >= 200 && res.statusCode < 400) {
        return {
          'isSuccess': true,
          'message': 'Connection successful! Device Web API is online at $endpointUrl (HTTP ${res.statusCode}).',
        };
      } else {
        return {
          'isSuccess': false,
          'message': 'HTTP ${res.statusCode}: Device server URL reachable but returned unexpected response.',
        };
      }
    } catch (e) {
      client.close();
      return {
        'isSuccess': false,
        'message': 'Device connection failed: Could not connect to $endpointUrl ($e).',
      };
    }
  }

  String _escapeXml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
