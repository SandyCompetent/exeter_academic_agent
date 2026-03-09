import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  final String modelName;
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService({required this.apiKey, required this.modelName}) {
    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are an expert Agentic Study Assistant representing the University of Exeter. '
        'Your goal is to help students understand complex topics, generate study plans, '
        'summarize academic papers, and provide clear, step-by-step explanations. '
        'Always be encouraging, professional, and use Markdown for formatting.',
      ),
    );
    _chat = _model.startChat();
  }

  Stream<String> getResponseStream(String message) async* {
    try {
      final responseStream = _chat.sendMessageStream(Content.text(message));
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } on InvalidApiKey catch (_) {
      yield 'Error: Invalid API Key. Please check your configuration in Settings.';
    } on UnsupportedUserLocation catch (_) {
      yield 'Error: Gemini API is not supported in your location.';
    } catch (e) {
      yield 'Error: $e';
    }
  }

  Future<List<String>> generateSuggestions(String lastAssistantResponse) async {
    try {
      final suggestionModel = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
      );

      final prompt =
          '''
Based on the following explanation an AI study assistant just gave to a student:
"$lastAssistantResponse"

Provide exactly 3 short, relevant follow-up questions the student might want to ask next.
Format the output as a strict JSON array of strings, e.g. ["Question 1?", "Question 2?", "Question 3?"].
Do not include any markdown formatting like ```json or any other text. Just the array.
''';

      final response = await suggestionModel.generateContent([
        Content.text(prompt),
      ]);

      final text = response.text?.trim() ?? '[]';
      final cleanText = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final List<dynamic> decoded = jsonDecode(cleanText);
      return decoded.map((e) => e.toString()).take(3).toList();
    } catch (e) {
      return [];
    }
  }
}
