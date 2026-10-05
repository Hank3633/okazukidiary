import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'onboarding_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.onCreateBackup,
    required this.onRestoreBackup,
    required this.onCreateExcel,
  });

  final Future<Map<String, dynamic>> Function() onCreateBackup;
  final Future<void> Function(Map<String, dynamic> backup) onRestoreBackup;
  final Future<List<int>> Function() onCreateExcel;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _backupType = XTypeGroup(
    label: '小芽記帳本備份檔',
    extensions: ['json'],
    mimeTypes: ['application/json'],
  );
  static const _excelType = XTypeGroup(
    label: 'Excel 活頁簿',
    extensions: ['xlsx'],
    mimeTypes: [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ],
  );

  bool _working = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportBackup() async {
    setState(() => _working = true);
    try {
      final location = await getSaveLocation(
        acceptedTypeGroups: const [_backupType],
        suggestedName:
            'okazukidiary_backup_${DateTime.now().toIso8601String().split('T').first}.json',
      );
      if (location == null) return;
      final backup = await widget.onCreateBackup();
      await File(location.path).writeAsString(
        const JsonEncoder.withIndent('  ').convert(backup),
      );
      if (mounted) _showMessage(AppLocalizations.of(context)!.backupExported);
    } catch (_) {
      if (mounted) _showMessage(AppLocalizations.of(context)!.backupFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _working = true);
    try {
      final file = await openFile(acceptedTypeGroups: const [_backupType]);
      if (file == null || !mounted) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) throw const FormatException();
      final backup = Map<String, dynamic>.from(decoded);
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.restoreConfirmTitle),
          content: Text(l10n.restoreConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.restore),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await widget.onRestoreBackup(backup);
      if (mounted) _showMessage(l10n.restoreCompleted);
    } catch (_) {
      if (mounted) _showMessage(AppLocalizations.of(context)!.restoreFailed);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _working = true);
    try {
      final location = await getSaveLocation(
        acceptedTypeGroups: const [_excelType],
        suggestedName:
            'okazukidiary_records_${DateTime.now().toIso8601String().split('T').first}.xlsx',
      );
      if (location == null) return;
      await File(location.path).writeAsBytes(await widget.onCreateExcel());
      if (mounted) _showMessage('Excel 檔已匯出');
    } catch (_) {
      if (mounted) _showMessage('無法匯出 Excel 檔，請重試。');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showTutorial() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingPage(onCompleted: () async {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.dataBackupRestore,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.backupDescription),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('新手操作導覽'),
              subtitle: const Text('重新查看記帳、分類管理與備份功能。'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _working ? null : _showTutorial,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(l10n.exportBackup),
              subtitle: Text(l10n.exportBackupHint),
              trailing: _working
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _working ? null : _exportBackup,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.table_view_outlined),
              title: const Text('匯出 Excel'),
              subtitle: const Text('將收支紀錄匯出為可整理與計算的 Excel 檔。'),
              trailing: _working
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _working ? null : _exportExcel,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_backup_restore_outlined),
              title: Text(l10n.restoreBackup),
              subtitle: Text(l10n.restoreBackupHint),
              trailing: _working
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _working ? null : _restoreBackup,
            ),
          ),
        ],
      ),
    );
  }
}
