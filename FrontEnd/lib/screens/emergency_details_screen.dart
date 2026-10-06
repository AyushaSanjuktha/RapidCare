import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'severity_screen.dart';

class EmergencyDetailsScreen extends StatefulWidget {
  const EmergencyDetailsScreen({super.key});

  @override
  State<EmergencyDetailsScreen> createState() => _EmergencyDetailsScreenState();
}

class _EmergencyDetailsScreenState extends State<EmergencyDetailsScreen> {
  String _selectedType = AppConstants.emergencyTypes.first;
  final _symptomsController = TextEditingController();
  XFile? _injuryPhoto; // CV teammate's model not ready — see note below
  bool _submitting = false;

  // TODO (CV module — not yet available): once the computer-vision teammate
  // exposes a /classify-injury endpoint, send _injuryPhoto to it here and
  // merge its result with the text-based severity response. Until then this
  // photo is captured in the UI but NOT sent anywhere — it's a ready-made
  // hook, not a live feature. Do not fake a CV result.
  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _injuryPhoto = picked);
  }

  // TODO (user auth — not yet available): replace with the real logged-in
  // user's id once an auth/profile flow exists. Using a fixed test UUID
  // (matching the row seeded in schema_fresh_setup.sql) so the demo works
  // today without inventing an auth system that doesn't exist.
  static const String _demoUserId = "de8d56bd-ac94-44ef-84c6-8eee356bddaa";

  Future<void> _sendSOS() async {
    // Confirm before sending, per the brief — a real SOS shouldn't fire on a stray tap.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Emergency SOS'),
        content: const Text('This will alert nearby responders immediately. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final loc = await LocationService.getCurrentLocation();

      final emergencyCase = await ApiService.createSOS(
        userId: _demoUserId,
        latitude: loc.lat,
        longitude: loc.lng,
        emergencyType: _selectedType,
        symptoms: _symptomsController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SeverityScreen(emergencyCase: emergencyCase)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.emergencyRed),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emergency Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items: AppConstants.emergencyTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 20),
            const Text('Symptoms (optional but helps prioritize)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. severe chest pain and difficulty breathing',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Injury Photo (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Captured for future computer-vision analysis — not yet connected to a live model.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickPhoto,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _injuryPhoto == null
                    ? const Center(child: Icon(Icons.add_a_photo_outlined, color: AppColors.textMuted))
                    : Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(Icons.check_circle, color: AppColors.sevLow),
                          const SizedBox(width: 8),
                          const Text('Photo attached'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed, size: 18, color: AppColors.navy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your current GPS location will be captured automatically when you send this SOS.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
                onPressed: _submitting ? null : _sendSOS,
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Send SOS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
