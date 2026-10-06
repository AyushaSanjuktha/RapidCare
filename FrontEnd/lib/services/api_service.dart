import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/emergency_case.dart';
import '../models/responder.dart';

/// ONE centralized place for all HTTP calls — no screen talks to http:// directly.
///
/// IMPORTANT: this only implements the TWO endpoints that actually exist and
/// are tested on the real backend: POST /sos and POST /dispatch/{case_id}.
/// Methods for hospital hand-off, case-status timeline, analytics, and
/// offline fallback are intentionally NOT implemented here — building them
/// against endpoints that don't exist would create UI that silently fails
/// or has to fake data during a live demo. Add them here only once the
/// matching FastAPI route is built and tested.
class ApiService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Thrown for any API failure, with a message safe to show the user directly.
  static Exception _friendlyError(Object e) {
    if (e is http.ClientException || e.toString().contains('SocketException')) {
      return Exception(
        "Can't reach the server. Check that the FastAPI backend is running "
        "and the base URL in constants.dart is correct for how you're running the app.",
      );
    }
    return Exception("Something went wrong: $e");
  }

  /// POST /sos — creates the case; backend runs the severity classifier
  /// server-side and returns the result in the same response.
  static Future<EmergencyCase> createSOS({
    required String userId,
    required double latitude,
    required double longitude,
    required String emergencyType,
    required String symptoms,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/sos'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "user_id": userId,
              "latitude": latitude,
              "longitude": longitude,
              "emergency_type": emergencyType,
              "symptoms": symptoms,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return EmergencyCase.fromSosResponse(
        json,
        emergencyType: emergencyType,
        symptoms: symptoms,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      throw _friendlyError(e);
    }
  }

  /// POST /dispatch/{case_id} — finds and assigns the nearest available responder.
  static Future<DispatchResult> dispatchResponder(String caseId) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/dispatch/$caseId'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return DispatchResult.fromJson(json);
    } catch (e) {
      throw _friendlyError(e);
    }
  }
  static Future<void> acceptDispatchRequest(String requestId) async {
  try {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/dispatch-request/$requestId/accept'),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Server returned ${response.statusCode}: ${response.body}',
      );
    }
  } catch (e) {
    throw _friendlyError(e);
  }
}


  // ---------------------------------------------------------------------
  // NOT YET IMPLEMENTED — placeholders only, matching screens show a clear
  // "not connected yet" state rather than calling these. Wire these up once
  // the corresponding FastAPI endpoint exists and has been tested via
  // Swagger, the same way /sos and /dispatch were.
  // ---------------------------------------------------------------------
  // static Future<void> acceptDispatchRequest(String requestId) async {}
  // static Future<void> setResponderEnRoute(String caseId) async {}
  // static Future<void> selectHospital(String caseId) async {}
  // static Future<void> getHospitalPrebrief(String caseId) async {}
  // static Future<void> updateCaseStatus(String caseId, String status) async {}
  // static Future<void> getAnalytics() async {}
  // static Future<void> getEmergencyFallback(String caseId) async {}
}
