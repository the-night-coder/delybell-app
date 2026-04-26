import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import 'draft_place_page.dart';

class DraftOrderSuccessPage extends StatelessWidget {
  const DraftOrderSuccessPage({
    super.key,
    required this.token,
    required this.serviceType,
  });

  final String token;
  final String serviceType;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (colors?.primary ?? const Color(0xFF66258E)).withOpacity(0.1),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: colors?.primary ?? const Color(0xFF66258E),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Drafted',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your draft has been saved. You can review it in Dashboard > Orders > Draft.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: colors?.primary ?? const Color(0xFF66258E),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Add More',
                        style: TextStyle(
                          color: colors?.primary ?? const Color(0xFF66258E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: colors?.primary ?? const Color(0xFF66258E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.popUntil((route) => route.isFirst);
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => DraftPlacePage(
                              token: token,
                              serviceType: serviceType,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Finish Order',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
