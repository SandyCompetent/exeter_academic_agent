import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppSettings extends ChangeNotifier {
  // Use String.fromEnvironment to allow passing the key at build time
  // Run with: flutter run --dart-define=API_KEY=your_key_here
  static const String _defaultApiKey = String.fromEnvironment('API_KEY', defaultValue: '');
  
  String _apiKey = _defaultApiKey;

  String _selectedModel = 'gemini-1.5-flash';
  List<String> _availableModels = ['gemini-1.5-flash'];

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
              final name = (m['name'] as String).toLowerCase();
              final displayName = (m['displayName'] as String? ?? '').toLowerCase();
              final description = (m['description'] as String? ?? '').toLowerCase();

              // 1. Must support text generation
              final isContentGeneration = methods != null && methods.contains('generateContent');
              
              // 2. Filter out models explicitly for audio, image, or vision tasks
              final isAudioOrImageOrVision = name.contains('vision') || 
                                             name.contains('audio') || 
                                             name.contains('image') ||
                                             displayName.contains('vision') ||
                                             displayName.contains('audio') ||
                                             displayName.contains('image') ||
                                             description.contains('audio only') ||
                                             description.contains('image only');

              // 3. Filter out deprecated or legacy models
              // The API often marks them in description or uses old version names
              final isDeprecated = description.contains('deprecated') || 
                                   displayName.contains('deprecated') ||
                                   description.contains('legacy') ||
                                   name.contains('gemini-1.0'); // Strictly filter out very old versions

              return isContentGeneration && !isAudioOrImageOrVision && !isDeprecated;
            })
            .map((m) => (m['name'] as String).replaceFirst('models/', ''))
            .toList();

        if (validModels.isNotEmpty) {
          _availableModels = validModels;
          if (!_availableModels.contains(_selectedModel)) {
            // Try to default to a modern model if current choice is unavailable
            if (validModels.contains('gemini-2.0-flash')) {
              _selectedModel = 'gemini-2.0-flash';
            } else if (validModels.contains('gemini-1.5-flash')) {
              _selectedModel = 'gemini-1.5-flash';
            } else {
              _selectedModel = _availableModels.first;
            }
          }
        } else {
          _modelError = 'No valid text models found for this API key.';
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
