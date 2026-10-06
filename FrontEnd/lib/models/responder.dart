/// Represents the REAL /dispatch/{case_id} response.
///
/// The backend creates a pending dispatch request first.
/// The responder is only actually assigned after accepting the request.
class DispatchResult {
  final String message;
  final String caseId;
  final bool wasAssigned;
  final String? responderId;
  final String? responderName;
  final String? responderPhone;
  final double? distanceKm;
  final double? etaMinutes;
  final String? status;

  DispatchResult({
    required this.message,
    required this.caseId,
    required this.wasAssigned,
    this.responderId,
    this.responderName,
    this.responderPhone,
    this.distanceKm,
    this.etaMinutes,
    this.status,
  });

  factory DispatchResult.fromJson(Map<String, dynamic> json) {
    final responder = json['responder'];

    return DispatchResult(
      message: json['message'] as String? ?? '',
      caseId: json['case_id'] as String? ?? '',
      wasAssigned: json['responder_assigned'] as bool? ?? false,

      responderId: responder is Map
          ? responder['id'] as String?
          : null,

      responderName: responder is Map
          ? responder['name'] as String?
          : null,

      responderPhone: responder is Map
          ? responder['phone'] as String?
          : null,

      distanceKm: responder is Map
          ? (responder['distance_km'] as num?)?.toDouble()
          : null,

      etaMinutes: responder is Map
          ? (responder['eta_minutes'] as num?)?.toDouble()
          : null,

      status: responder is Map
          ? responder['status'] as String?
          : null,
    );
  }
}