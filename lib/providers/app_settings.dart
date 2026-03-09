import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppSettings extends ChangeNotifier {
  String _apiKey = 'AIzaSyBAMTHEpL48HZyPziu0_KYVSKSuBWoXqqo';

  String _selectedModel = 'gemini-3-flash-preview';
  List<String> _availableModels = ['gemini-3-flash-preview'];

  bool _isLoadingModels = false;
  String? _modelError;

  String get apiKey => _apiKey;

  String get selectedModel => _selectedModel;

  List<String> get availableModels => _availableModels;

  bool get isLoadingModels => _isLoadingModels;

  String? get modelError => _modelError;

  AppSettings() {
    if (_apiKey.isNotEmpty) {
      fetchModels();
    }
  }

  void setApiKey(String key) {
    _apiKey = key;
    notifyListeners();
  }

  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  Future<void> fetchModels() async {
    if (_apiKey.trim().isEmpty) {
      _modelError = 'Please enter an API Key first.';
      notifyListeners();
      return;
    }

    _isLoadingModels = true;
    _modelError = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;

        final validModels = models
            .where((m) {
              final methods = m['supportedGenerationMethods'] as List?;
              return methods != null && methods.contains('generateContent');
            })
            .map((m) => (m['name'] as String).replaceFirst('models/', ''))
            .toList();

        if (validModels.isNotEmpty) {
          _availableModels = validModels;
          if (!_availableModels.contains(_selectedModel)) {
            if (validModels.contains('gemini-3-flash-preview')) {
              _selectedModel = 'gemini-3-flash-preview';
            } else if (validModels.contains('gemini-2.0-flash')) {
              _selectedModel = 'gemini-2.0-flash';
            } else {
              _selectedModel = _availableModels.first;
            }
          }
        } else {
          _modelError = 'No valid models found for this API key.';
        }
      } else {
        _modelError = 'Failed to fetch models: HTTP ${response.statusCode}';
      }
    } catch (e) {
      _modelError = 'Error fetching models: $e';
    } finally {
      _isLoadingModels = false;
      notifyListeners();
    }
  }
}
