import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/sos_button.dart';
import '../widgets/loading_indicator.dart';
import 'emergency_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'RapidCare',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sevLow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.sevLow, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        const Text('Services Online', style: TextStyle(fontSize: 11, color: AppColors.sevLow, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Emergency Assistance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Press and confirm to alert nearby responders immediately',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Center(
                child: SOSButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmergencyDetailsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 36),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.navy),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current Location', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Fetched automatically when SOS is pressed', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _QuickActionTile(
                    icon: Icons.contacts_outlined,
                    label: 'Emergency Contacts',
                    onTap: () => _openPlaceholder(context, 'Emergency Contacts',
                        'Manage trusted contacts notified during an SOS.'),
                  ),
                  _QuickActionTile(
                    icon: Icons.person_outline,
                    label: 'My Profile',
                    onTap: () => _openPlaceholder(context, 'My Profile',
                        'Manage your account and dependent profiles.'),
                  ),
                  _QuickActionTile(
                    icon: Icons.medical_information_outlined,
                    label: 'Medical Information',
                    onTap: () => _openPlaceholder(context, 'Medical Information',
                        'Blood group, allergies, medications — shared with responders during an active case.'),
                  ),
                  _QuickActionTile(
                    icon: Icons.history,
                    label: 'Emergency History',
                    onTap: () => _openPlaceholder(context, 'Emergency History',
                        'Past cases will appear here once the case-history endpoint is built.'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlaceholder(BuildContext context, String title, String desc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComingSoonPlaceholder(title: title, description: desc)),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.navy, size: 26),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
