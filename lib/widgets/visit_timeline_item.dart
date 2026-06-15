import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/patient.dart';

/// Visit timeline item matching the web app's timeline dot + visit record pattern.
class VisitTimelineItem extends StatelessWidget {
  final VisitRecord visit;
  final bool isLast;

  const VisitTimelineItem({
    super.key,
    required this.visit,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12),
          // Visit card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        visit.date,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: visit.type == 'Follow-up'
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          visit.type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: visit.type == 'Follow-up'
                                ? const Color(0xFF15803D)
                                : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow('Diagnosis', visit.diagnosis),
                  SizedBox(height: 8),
                  _buildInfoRow('Clinical Notes', visit.notes),
                  SizedBox(height: 8),
                  Divider(height: 1, color: AppTheme.border),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Fees',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      Text(
                        '₹${visit.fees}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 13)),
        SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontSize: 14)),
      ],
    );
  }
}


