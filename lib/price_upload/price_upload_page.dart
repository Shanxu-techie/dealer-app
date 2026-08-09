import 'dart:typed_data';

import 'package:dealer_app/login/login_service.dart';
import 'package:dealer_app/price_upload/price_upsert_service.dart';
import 'package:dealer_app/price_upload/widgets/price_upload_file_selected.dart';
import 'package:dealer_app/price_upload/widgets/price_upload_idle.dart';
import 'package:dealer_app/price_upload/widgets/price_upload_parse_error.dart';
import 'package:dealer_app/price_upload/widgets/price_upload_success.dart';
import 'package:dealer_app/price_upload/widgets/price_upload_upload_error.dart';
import 'package:dealer_app/price_upload/widgets/price_upload_uploading.dart';
import 'package:dealer_app/price_upload/widgets/price_upload_validated.dart';
import 'package:dealer_app/price_upload/widgets/price_upload_validating.dart';
import 'package:dealer_app/shared/models/app_user_role.dart';
import 'package:dealer_app/shared/utils/dimensions.dart';
import 'package:dealer_app/shared/widgets/app_shared_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'price_importer_parser.dart';

enum PriceUploadState {
  idle,
  fileSelected,
  validating,
  validated,
  uploading,
  success,
  error,
}

class PriceUploadPage extends StatefulWidget {
  final SupabaseClient supabase;

  const PriceUploadPage({super.key, required this.supabase});

  @override
  State<PriceUploadPage> createState() => _PriceUploadPageState();
}

class _PriceUploadPageState extends State<PriceUploadPage> {
  PriceUploadState _state = PriceUploadState.idle;
  PlatformFile? _selectedFile;
  Uint8List? _selectedFileBytes;
  DateTime? _effectiveDate;
  ParseResult? _parseResult;
  String? _uploadError;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;

    if (file.bytes == null) {
      return;
    }

    setState(() {
      _selectedFile = file;
      _selectedFileBytes = file.bytes;
      _effectiveDate = null;
      _parseResult = null;
      _uploadError = null;
      _state = PriceUploadState.fileSelected;
    });
  }

  Future<void> _pickEffectiveDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _effectiveDate = selectedDate;
    });
  }

  Future<void> _parseSelectedFile() async {
    final bytes = _selectedFileBytes;
    final effectiveDate = _effectiveDate;

    if (bytes == null || effectiveDate == null) {
      return;
    }

    setState(() {
      _state = PriceUploadState.validating;
    });

    const parser = PriceImportParser();

    final result = parser.parse(bytes, effectiveDate: effectiveDate);

    if (!mounted) {
      return;
    }

    if (result.hasErrors) {
      setState(() {
        _parseResult = result;
        _state = PriceUploadState.error;
      });
      return;
    }

    debugPrint('Parsed ${result.rows.length} rows successfully.');

    setState(() {
      _parseResult = result;
      _state = PriceUploadState.validated;
    });
  }

  void _resetUpload() {
    setState(() {
      _state = PriceUploadState.idle;
      _selectedFile = null;
      _selectedFileBytes = null;
      _effectiveDate = null;
      _parseResult = null;
      _uploadError = null;
    });
  }

  Future<void> _uploadPrices() async {
    final result = _parseResult;

    if (result == null || result.rows.isEmpty) {
      return;
    }

    setState(() {
      _state = PriceUploadState.uploading;
      _uploadError = null;
    });

    try {
      final summary = await upsertDealerPrices(widget.supabase, result.rows);

      if (!mounted) {
        return;
      }

      if (summary.allSucceeded) {
        setState(() {
          _state = PriceUploadState.success;
        });
        return;
      }

      final failedBatch = summary.batchResults.firstWhere(
        (batch) => !batch.success,
      );

      setState(() {
        _uploadError =
            'Batch ${failedBatch.batchNumber} '
            '(${failedBatch.sheet}, rows ${failedBatch.startRow}-'
            '${failedBatch.endRow}) failed: '
            '${failedBatch.errorMessage ?? 'Unknown upload error.'}';

        _state = PriceUploadState.error;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint('Price upload failed: $e');

      setState(() {
        _uploadError = 'Failed to upload prices: $e';
        _state = PriceUploadState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppSharedBar(
        title: 'Price Upload',
        role: AppUserRole.publisher,
        onLogoutTap: () async {
          await LoginService().signOut();
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case PriceUploadState.idle:
        return PriceUploadIdle(onPickFile: _pickFile);

      case PriceUploadState.fileSelected:
        return PriceUploadFileSelected(
          fileName: _selectedFile!.name,
          effectiveDate: _effectiveDate,
          onPickFile: _pickFile,
          onPickEffectiveDate: _pickEffectiveDate,
          onValidate: _parseSelectedFile,
        );

      case PriceUploadState.validating:
        return const PriceUploadValidating();

      case PriceUploadState.validated:
        return ValidatedPriceUploadView(
          fileName: _selectedFile!.name,
          effectiveDate: _effectiveDate!,
          result: _parseResult!,
          onUpload: _uploadPrices,
          onChooseAnotherFile: _pickFile,
        );

      case PriceUploadState.uploading:
        return const PriceUploadUploading();

      case PriceUploadState.success:
        return PriceUploadSuccess(
          fileName: _selectedFile!.name,
          effectiveDate: _effectiveDate!,
          result: _parseResult!,
          onUploadAnother: _resetUpload,
        );

      case PriceUploadState.error:
        final result = _parseResult;

        if (_uploadError != null) {
          return PriceUploadUploadError(
            message: _uploadError!,
            onTryAgain: _uploadPrices,
            onChooseAnotherFile: _pickFile,
          );
        }

        if (result == null || result.errors.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Dimensions.paddingMedium),
              child: Text('Unable to validate file.'),
            ),
          );
        }

        return PriceUploadErrorView(
          result: result,
          onChooseAnotherFile: _pickFile,
        );
    }
  }
}
