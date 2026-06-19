import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/import_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

enum ImportStatus { idle, fileSelected, importing, done, error }

class _ImportScreenState extends State<ImportScreen> {
  String? _filePath;
  String? _fileName;
  ImportStatus _status = ImportStatus.idle;
  ImportResult? _result;
  String _errorMessage = '';

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _filePath = result.files.single.path;
          _fileName = result.files.single.name;
          _status = ImportStatus.fileSelected;
          _result = null;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick file: $e');
    }
  }

  Future<void> _startImport() async {
    if (_filePath == null) return;

    setState(() => _status = ImportStatus.importing);

    try {
      final result = await ImportService.importFromDesktop(
        _filePath!,
        overwrite: false,
      );

      if (!mounted) return;

      if (result.error.isNotEmpty) {
        setState(() {
          _status = ImportStatus.error;
          _errorMessage = result.error;
        });
      } else {
        setState(() {
          _status = ImportStatus.done;
          _result = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = ImportStatus.error;
          _errorMessage = 'Import failed unexpectedly: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Desktop'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildFilePickerCard(),
            const SizedBox(height: 16),
            if (_status == ImportStatus.importing) _buildProgressCard(),
            if (_status == ImportStatus.done && _result != null)
              _buildResultCard(),
            if (_status == ImportStatus.error) _buildErrorCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Select the clinic.db file from your desktop app to import patients, OPD visits, clinic settings, and calendar notes.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storage_outlined, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Database File',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: _fileName != null
                ? Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fileName!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _filePath = null;
                            _fileName = null;
                            _status = ImportStatus.idle;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: _pickFile,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, color: AppTheme.textHint, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to select clinic.db file',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_status != ImportStatus.idle) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _status == ImportStatus.importing ? null : _startImport,
                icon: _status == ImportStatus.importing
                    ? SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textOnPrimary),
                      )
                    : const Icon(Icons.upload, size: 20),
                label: Text(_status == ImportStatus.importing ? 'Importing...' : 'Start Import'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'Importing data...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reading clinic.db and writing to MediHive',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppTheme.success, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Import Complete!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _statRow(Icons.people_outline, 'Patients', '${r.patientsImported} imported', '${r.patientsSkipped} skipped'),
          const SizedBox(height: 12),
          _statRow(Icons.medical_services_outlined, 'OPD Visits', '${r.opdVisitsImported} imported', '${r.opdVisitsSkipped} skipped'),
          const SizedBox(height: 12),
          _statRow(Icons.settings_outlined, 'Clinic Settings', r.settingsImported ? 'Yes' : 'No', ''),
          const SizedBox(height: 12),
          _statRow(Icons.calendar_today, 'Calendar Notes', '${r.notesImported} imported', ''),
          if (r.patientsImported > 0 || r.opdVisitsImported > 0) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/app/settings'),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Back to Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value, String sub) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
        if (sub.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text('($sub)', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
        ],
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, color: AppTheme.danger, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Import Failed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.danger),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
