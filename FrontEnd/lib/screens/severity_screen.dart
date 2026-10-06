import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/emergency_case.dart';
import '../models/responder.dart';
import '../services/api_service.dart';
import '../widgets/severity_card.dart';
import '../widgets/responder_card.dart';
import '../widgets/loading_indicator.dart';

/// Shows the AI severity result immediately (from /sos), then automatically
/// triggers /dispatch/{case_id} to find a responder — this merges what the
/// original brief called "Severity Screen" + "Responder Search Screen" into
/// one real flow, since that's what your actual two-endpoint backend does
/// in sequence. Splitting it into two separate screens would just add a
/// manual "next" tap with nothing real happening in between.
class SeverityScreen extends StatefulWidget {
  final EmergencyCase emergencyCase;
  const SeverityScreen({super.key, required this.emergencyCase});

  @override
  State<SeverityScreen> createState() => _SeverityScreenState();
}

class _SeverityScreenState extends State<SeverityScreen> {
  bool _dispatching = true;
  DispatchResult? _dispatchResult;
  String? _dispatchError;

  @override
  void initState() {
    super.initState();
    _runDispatch();
  }

  Future<void> _runDispatch() async {
    try {
      final result =
          await ApiService.dispatchResponder(widget.emergencyCase.caseId);
      if (!mounted) return;
      setState(() {
        _dispatchResult = result;
        _dispatching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dispatchError = e.toString().replaceFirst('Exception: ', '');
        _dispatching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.emergencyCase;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Status'),
        automaticallyImplyLeading:
            false, // no back-nav mid-emergency, per brief's "active state" guidance
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SeverityCard(
              severity: c.severity,
              confidence: c.severityConfidence,
              classifierNote: c.classifierNote,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Case Details',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _detailRow('Case ID', c.caseId),
                    _detailRow('Emergency Type', c.emergencyType),
                    _detailRow('Symptoms',
                        c.symptoms.isEmpty ? '— not provided —' : c.symptoms),
                    _detailRow('Location',
                        '${c.latitude.toStringAsFixed(5)}, ${c.longitude.toStringAsFixed(5)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Responder Dispatch',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            if (_dispatching)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: LoadingIndicator(
                        message: 'Finding nearest available responder...'),
                  ),
                ),
              )
            else if (_dispatchError != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.emergencyRed),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(_dispatchError!,
                              style: const TextStyle(
                                  color: AppColors.emergencyRed))),
                    ],
                  ),
                ),
              )
            else if (_dispatchResult != null && _dispatchResult!.wasAssigned)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponderCard(
                    responderName:
                        _dispatchResult!.responderName ?? 'Available Responder',
                    distanceKm: _dispatchResult!.distanceKm ?? 0,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dispatch Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Status: ${_dispatchResult!.status ?? 'Pending'}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ETA: ${_dispatchResult!.etaMinutes?.toStringAsFixed(1) ?? '--'} minutes',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Responder ID: ${_dispatchResult!.responderId ?? '--'}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_dispatchResult?.message ??
                      'No responder could be assigned right now.'),
                ),
              ),
            const SizedBox(height: 16),
            
            if (_dispatchResult != null && _dispatchResult!.wasAssigned)
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Calling is a placeholder — wire to real responder phone once available.')),
                  );
                },
                icon: const Icon(Icons.call_outlined),
                label: const Text('Call Responder'),
              ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }
}
