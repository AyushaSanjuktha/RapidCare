/// Maps exactly to what the REAL /sos endpoint returns:
///   { "case_id": ..., "status": ..., "severity": ..., "severity_confidence": ..., "classifier_note": ... }
/// Do not add fields here that the backend doesn't actually send — if you
/// need more fields later, add them to FastAPI's response first, then here.
class EmergencyCase {
  final String caseId;
  final String status;
  final String severity;
  final double severityConfidence;
  final String? classifierNote; // non-null only if the classifier had an issue

  // Fields the UI tracks locally (not returned by backend) so the severity
  // screen can display what the user submitted alongside the AI result.
  final String emergencyType;
  final String symptoms;
  final double latitude;
  final double longitude;

  EmergencyCase({
    required this.caseId,
    required this.status,
    required this.severity,
    required this.severityConfidence,
    this.classifierNote,
    required this.emergencyType,
    required this.symptoms,
    required this.latitude,
    required this.longitude,
  });

  factory EmergencyCase.fromSosResponse(
    Map<String, dynamic> json, {
    required String emergencyType,
    required String symptoms,
    required double latitude,
    required double longitude,
  }) {
    // Real backend shape (confirmed from actual response):
    //   { "message": ..., "severity": ..., "case": [ { "id": ..., "status": ..., "severity": ..., ... } ] }
    // The case data is wrapped in a "case" array, not flat at the top level.
    final caseList = json['case'];
    if (caseList == null || caseList is! List || caseList.isEmpty) {
      throw Exception('Backend /sos response has no "case" data. Got: $json');
    }
    final caseObj = caseList[0] as Map<String, dynamic>;

    final rawCaseId = caseObj['id'];
    if (rawCaseId == null || rawCaseId is! String) {
      throw Exception('Case object is missing a valid "id" field. Got: $caseObj');
    }

    // Severity can be null if no symptoms were given, or if the classifier
    // isn't wired into this endpoint yet. Check both the top-level and
    // nested value (backend sends it in both places), fall back if both null.
    final severityValue = (json['severity'] ?? caseObj['severity']) as String?;

    return EmergencyCase(
      caseId: rawCaseId,
      status: caseObj['status'] as String? ?? 'pending',
      severity: severityValue ?? 'Unclassified',
      // This backend doesn't appear to return a confidence score — default
      // to 0.0 so the UI doesn't show a misleading percentage.
      severityConfidence: (json['severity_confidence'] as num?)?.toDouble() ?? 0.0,
      classifierNote: json['classifier_note'] as String?,
      emergencyType: emergencyType,
      symptoms: symptoms,
      latitude: latitude,
      longitude: longitude,
    );
  }
}