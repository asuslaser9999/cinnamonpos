import 'package:flutter/foundation.dart';

import '../models/printer_settings.dart';
import '../services/printer_settings_service.dart';

class PrinterSettingsNotifier extends ChangeNotifier {
  PrinterSettingsNotifier({PrinterSettingsService? settingsService})
    : _settingsService = settingsService ?? PrinterSettingsService();

  final PrinterSettingsService _settingsService;

  PrinterSettings _settings = const PrinterSettings();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  PrinterSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _settingsService.load();
    } catch (e) {
      _errorMessage = 'Gagal memuat pengaturan printer.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSettings(PrinterSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  Future<bool> save() async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _settingsService.save(_settings);
      _successMessage = 'Pengaturan printer disimpan.';
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan pengaturan.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
