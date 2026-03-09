import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/app_settings.dart';
import '../services/gemini_service.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  GeminiService? _geminiService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final settings = Provider.of<AppSettings>(context, listen: false);

    if (settings.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your API Key in the Settings tab.'),
        ),
      );
      return;
    }

    if (_geminiService == null ||
        _geminiService!.apiKey != settings.apiKey ||
        _geminiService!.modelName != settings.selectedModel) {
      _geminiService = GeminiService(
        apiKey: settings.apiKey,
        modelName: settings.selectedModel,
      );
    }

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final assistantMessage = ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isThinking: true,
      suggestions: null,
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(assistantMessage);
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final stream = _geminiService!.getResponseStream(text);
      await for (final chunk in stream) {
        setState(() {
          if (assistantMessage.isThinking) {
            assistantMessage.isThinking = false;
          }
          assistantMessage.text += chunk;
        });
        _scrollToBottom();
      }

      if (assistantMessage.text.isNotEmpty &&
          !assistantMessage.text.startsWith('Error:')) {
        final followUpQuestions = await _geminiService!.generateSuggestions(
          assistantMessage.text,
        );
        if (followUpQuestions.isNotEmpty) {
          setState(() {
            assistantMessage.suggestions = followUpQuestions;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      setState(() {
        assistantMessage.isThinking = false;
        assistantMessage.text = 'Error generating response: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Assistant'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _WelcomeView(onSuggestionTapped: _handleSubmitted)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ChatMessageBubble(
                        message: _messages[index],
                        onSuggestionTapped: _handleSubmitted,
                      );
                    },
                  ),
          ),
          ChatInputField(
            controller: _textController,
            onSubmitted: _handleSubmitted,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final Function(String) onSuggestionTapped;

  const _WelcomeView({required this.onSuggestionTapped});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'How can I help you study?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => onSuggestionTapped('Summarize my paper'),
                icon: const Icon(Icons.summarize, size: 16),
                label: const Text('Summarize my paper'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => onSuggestionTapped('Explain a concept'),
                icon: const Icon(Icons.lightbulb, size: 16),
                label: const Text('Explain a concept'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => onSuggestionTapped('Create a study plan'),
                icon: const Icon(Icons.calendar_month, size: 16),
                label: const Text('Create a study plan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
