// lib/shared/widgets/request_status_stepper.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RequestStatusStepper extends StatelessWidget {
  final String status;
  const RequestStatusStepper({super.key, required this.status});

  static const _steps = [
    _Step('Submitted',    'SUBMITTED',    Icons.upload_file_outlined),
    _Step('Under Review', 'UNDER_REVIEW', Icons.find_in_page_outlined),
    _Step('For Payment',  'FOR_PAYMENT',  Icons.payment_outlined),
    _Step('Processing',   'PROCESSING',   Icons.sync_outlined),
    _Step('For Pickup',   'FOR_CLAIMING', Icons.event_available_outlined),
    _Step('Completed',    'COMPLETED',    Icons.task_alt_outlined),
  ];

  int _currentIndex() {
    if (status == 'PAYMENT_VERIFIED') return 3;
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].statusKey == status) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (status == 'REJECTED') {
      return _buildTerminal(LNUColors.black, Icons.cancel_outlined, 'Request Rejected');
    }
    if (status == 'INCOMPLETE') {
      return _buildTerminal(LNUColors.yellow, Icons.warning_amber_outlined, 'Requirements Incomplete — Action Required');
    }

    final current = _currentIndex();
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _steps.length,
        itemBuilder: (_, i) {
          final done = i < current;
          final active = i == current;
          final Color activeColor = LNUColors.forStatus(status);
          final Color doneColor = LNUColors.blue;
          final Color idleColor = LNUColors.border;

          final circleColor = active ? activeColor : done ? doneColor : idleColor;
          final circleBg = active
              ? activeColor
              : done
                  ? doneColor.withOpacity(0.12)
                  : LNUColors.background;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleBg,
                      border: Border.all(color: circleColor, width: active ? 2 : 1),
                    ),
                    child: Icon(
                      done ? Icons.check : _steps[i].icon,
                      size: 16,
                      color: active ? LNUColors.white : done ? doneColor : LNUColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 54,
                    child: Text(
                      _steps[i].label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        color: active ? activeColor : done ? LNUColors.blue : LNUColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (i < _steps.length - 1)
                Container(
                  width: 18, height: 2,
                  margin: const EdgeInsets.only(bottom: 22),
                  color: i < current ? LNUColors.blue.withOpacity(0.4) : LNUColors.border,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTerminal(Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Step {
  final String label;
  final String statusKey;
  final IconData icon;
  const _Step(this.label, this.statusKey, this.icon);
}
