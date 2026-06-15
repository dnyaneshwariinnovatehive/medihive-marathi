import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/patient.dart';
import '../providers/opd_provider.dart';

import 'highlighted_text.dart';

/// Patient card matching the web app's patient list item, with Draft indicators.
class PatientCard extends StatefulWidget {
  final Patient patient;
  final VoidCallback onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onPrescription;
  final String searchQuery;

  const PatientCard({
    super.key,
    required this.patient,
    required this.onViewDetails,
    this.onEdit,
    this.onPrescription,
    this.searchQuery = '',
  });

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _checkDraft();
  }

  @override
  void didUpdateWidget(covariant PatientCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patient.id != oldWidget.patient.id) {
      _checkDraft();
    }
  }

  Future<void> _checkDraft() async {
    final has = await OpdProvider.hasDraftForPatient(widget.patient.id);
    if (mounted) {
      setState(() {
        _hasDraft = has;
      });
    }
  }

  Widget _highlightText(String text, String query, TextStyle baseStyle) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final List<TextSpan> spans = [];
    final String lowercaseText = text.toLowerCase();
    final String lowercaseQuery = query.toLowerCase();

    int start = 0;
    int indexOfMatch;

    while ((indexOfMatch = lowercaseText.indexOf(lowercaseQuery, start)) != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfMatch),
          style: baseStyle,
        ));
      }

      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
          color: AppTheme.primary,
        ),
      ));

      start = indexOfMatch + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header: avatar + name + age badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  widget.patient.initial,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: HighlightedText(
                            text: widget.patient.name,
                            query: widget.searchQuery,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (_hasDraft) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'DRAFT',
                              style: TextStyle(
                                color: AppTheme.danger,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        _highlightText(
                          widget.patient.id,
                          widget.searchQuery,
                          TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          ' • ${widget.patient.gender}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Age ${widget.patient.age}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Info row: mobile + last visit + diagnosis
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mobile',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: AppTheme.textPrimary),
                        SizedBox(width: 4),
                        Expanded(
                          child: _highlightText(
                            widget.patient.mobile,
                            widget.searchQuery,
                            TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last Visit',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                    SizedBox(height: 2),
                    Text(
                      widget.patient.lastVisit,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.patient.diagnosis.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diagnosis',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                      SizedBox(height: 2),
                      _highlightText(
                        widget.patient.diagnosis,
                        widget.searchQuery,
                        TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              if (_hasDraft) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final opd = context.read<OpdProvider>();
                      await opd.loadDraft('opd_draft_${widget.patient.id}');
                      if (context.mounted) {
                        context.go('/app/opd');
                      }
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Resume Draft'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onViewDetails,
                  icon: Icon(Icons.visibility, size: 18),
                  label: Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              _actionButton(Icons.edit, widget.onEdit),
              SizedBox(width: 8),
              _actionButton(Icons.description, widget.onPrescription),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.actionButton,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, size: 18, color: AppTheme.textPrimary),
      ),
    );
  }
}
