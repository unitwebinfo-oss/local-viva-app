import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/storage_helper.dart';

class ApiService {
  static http.Response? httpResponse; // Store last HTTP response for debugging
  
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageHelper.getToken();
    
    if (kDebugMode) {
      print('=== BUILDING HEADERS ===');
      print('Token from storage: $token');
      print('Token is null: ${token == null}');
      print('Token is empty: ${token?.isEmpty ?? true}');
    }
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      // Also send in alternative headers as fallback
      headers['X-Auth-Token'] = token;
      headers['X-API-Token'] = token;
      
      if (kDebugMode) {
        print('Added Authorization header: Bearer $token');
        print('Added X-Auth-Token: $token');
        print('Added X-API-Token: $token');
        print('Token length: ${token.length}');
        print('Token starts with Bearer: ${token.startsWith('Bearer ')}');
      }
    } else {
      if (kDebugMode) {
        print('WARNING: No token available, Authorization header NOT added');
      }
    }
    
    if (kDebugMode) {
      print('Final headers: $headers');
    }
    
    return headers;
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = '${ApiConfig.baseUrl}$endpoint';
    
    if (kDebugMode) {
      print('=== API GET REQUEST ===');
      print('URL: $url');
      print('Headers being sent: $headers');
      print('Has Authorization header: ${headers.containsKey('Authorization')}');
      if (headers.containsKey('Authorization')) {
        print('Authorization value: ${headers['Authorization']}');
        print('Authorization length: ${headers['Authorization']!.length}');
      }
      
      // Debug: Check StorageHelper token
      final storageToken = await StorageHelper.getToken();
      print('StorageHelper token: $storageToken');
      print('StorageHelper token length: ${storageToken?.length ?? 0}');
    }
    
    http.Response response;
    try {
      response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
    } catch (e) {
      if (kDebugMode) {
        print('=== API ERROR ===');
        print('Error: $e');
        print('Error type: ${e.runtimeType}');
        
        // Test basic connectivity
        try {
          final testResponse = await http.get(
            Uri.parse('https://httpbin.org/get'),
          ).timeout(Duration(seconds: 5));
          print('Basic connectivity test: ${testResponse.statusCode}');
        } catch (testError) {
          print('Basic connectivity failed: $testError');
        }
        
        // Test API base URL
        try {
          final apiTestResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/'),
          ).timeout(Duration(seconds: 5));
          print('API base URL test: ${apiTestResponse.statusCode}');
        } catch (apiTestError) {
          print('API base URL test failed: $apiTestError');
        }
        
        print('Falling back to all ads due to auth issue');
      }
      
      // Fallback: Get all ads when auth fails
      try {
        response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/ads'),
          headers: headers,
        );
        if (kDebugMode) {
          print('=== FALLBACK RESPONSE ===');
          print('Response: $response');
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('=== FALLBACK FAILED ===');
          print('Fallback error: $fallbackError');
        }
        rethrow;
      }
    }
    
    // Store response for debugging
    httpResponse = response;
    
    if (kDebugMode) {
      print('=== API GET RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Body: ${response.body}');
    }
    
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final url = '${ApiConfig.baseUrl}$endpoint';
    
    if (kDebugMode) {
      print('=== API POST REQUEST ===');
      print('URL: $url');
      print('Headers being sent: $headers');
      print('Data being sent: $data');
    }
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      );
      
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        print('Response headers: ${response.headers}');
      }
      
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('POST request failed: $e');
        print('Error type: ${e.runtimeType}');
      }
      
      // Return a proper error response instead of throwing
      return {
        'success': false,
        'error': 'Erro de conexão com o servidor',
        'debug': e.toString()
      };
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final url = '${ApiConfig.baseUrl}$endpoint';
    
    if (kDebugMode) {
      print('=== API PUT REQUEST ===');
      print('URL: $url');
      print('Headers being sent: $headers');
      print('Has Authorization header: ${headers.containsKey('Authorization')}');
      if (headers.containsKey('Authorization')) {
        print('Authorization value: ${headers['Authorization']}');
        print('Authorization length: ${headers['Authorization']!.length}');
      }
      print('Data being sent: $data');
    }
    
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(data),
    );
    
    if (kDebugMode) {
      print('=== API PUT RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Body: ${response.body}');
    }
    
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint, {Map<String, dynamic>? data}) async {
    final headers = await _getHeaders();
    final url = '${ApiConfig.baseUrl}$endpoint';
    
    if (kDebugMode) {
      print('=== API DELETE REQUEST ===');
      print('URL: $url');
      print('Headers being sent: $headers');
      print('Has Authorization header: ${headers.containsKey('Authorization')}');
      if (data != null) print('Data being sent: $data');
    }
    
    http.Response response;
    try {
      if (data != null) {
        response = await http.delete(
          Uri.parse(url),
          headers: headers,
          body: json.encode(data),
        );
      } else {
        response = await http.delete(
          Uri.parse(url),
          headers: headers,
        );
      }
      
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('DELETE request failed: $e');
        print('Error type: ${e.runtimeType}');
      }
      
      return {
        'success': false,
        'error': 'Erro de conexão com o servidor',
        'debug': e.toString()
      };
    }
  }

  static Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> filePaths,
  ) async {
    final headers = await _getHeaders();
    final url = '${ApiConfig.baseUrl}$endpoint';
    
    if (kDebugMode) {
      print('=== API MULTIPART REQUEST ===');
      print('URL: $url');
      print('Headers being sent: $headers');
      print('File paths: $filePaths');
    }
    
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers (but remove Content-Type as it's set automatically for multipart)
      request.headers.addAll(headers);
      request.headers.remove('Content-Type');
      
      // Add files
      for (final entry in filePaths.entries) {
        final file = File(entry.value);
        if (await file.exists()) {
          final fileBytes = await file.readAsBytes();
          final multipartFile = http.MultipartFile.fromBytes(
            entry.key,
            fileBytes,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
          
          if (kDebugMode) {
            print('Added file: ${entry.key} -> ${file.path}');
            print('File size: ${fileBytes.length} bytes');
          }
        } else {
          if (kDebugMode) {
            print('File not found: ${entry.value}');
          }
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Multipart request failed: $e');
        print('Error type: ${e.runtimeType}');
      }
      
      return {
        'success': false,
        'error': 'Erro de conexão com o servidor',
        'debug': e.toString()
      };
    }
  }

  static Future<Map<String, dynamic>> postMultipartBytes(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final headers = await _getHeaders();
    final url = '${ApiConfig.baseUrl}/$endpoint';
    
    if (kDebugMode) {
      print('=== API MULTIPART BYTES REQUEST ===');
      print('URL: $url');
      print('Headers being sent: $headers');
      print('Data keys: ${data.keys}');
    }
    
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers (but remove Content-Type as it's set automatically for multipart)
      request.headers.addAll(headers);
      request.headers.remove('Content-Type');
      
      // Add image bytes
      if (data.containsKey('image') && data.containsKey('filename')) {
        final imageBytes = data['image'] as List<int>;
        final filename = data['filename'] as String;
        
        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
        );
        request.files.add(multipartFile);
        
        if (kDebugMode) {
          print('Added image: $filename');
          print('Image size: ${imageBytes.length} bytes');
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Multipart bytes request failed: $e');
        print('Error type: ${e.runtimeType}');
      }
      
      return {
        'success': false,
        'error': 'Erro de conexão com o servidor',
        'debug': e.toString()
      };
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('=== HANDLING RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Body length: ${response.body.length}');
      print('Body: ${response.body}');
    }
    
    // Handle empty or invalid response body
    if (response.body.isEmpty) {
      if (kDebugMode) print('Empty response body');
      return {
        'success': false,
        'error': 'Resposta vazia do servidor',
        'status': response.statusCode
      };
    }
    
    try {
      final data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Erro desconhecido',
          'status': response.statusCode,
          'response_body': response.body
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('JSON decode error: $e');
        print('Response body was: ${response.body}');
      }
      
      return {
        'success': false,
        'error': 'Resposta inválida do servidor',
        'status': response.statusCode,
        'response_body': response.body,
        'json_error': e.toString()
      };
    }
  }
}
