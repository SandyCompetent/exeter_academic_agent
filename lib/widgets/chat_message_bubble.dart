import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';

// UI component that displays a single chat message bubble, including potential follow-up suggestions.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String)?
  onSuggestionTapped; // Callback when a suggestion button is pressed

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onSuggestionTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUser)
                  Text(
                    message.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                else if (message.isThinking)
                  // Shows the thinking state before tokens stream in
                  const _ThinkingIndicator()
                else
                  // Renders streamed markdown response
                  MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      theme,
                    ).copyWith(p: theme.textTheme.bodyLarge),
                  ),

                const SizedBox(height: 8),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Render Agent's follow-up suggestions as elevated buttons below the bubble
          if (!isUser &&
              message.suggestions != null &&
              message.suggestions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8, left: 12),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: message.suggestions!.map((suggestion) {
                  return FilledButton.tonalIcon(
                    onPressed: () {
                      if (onSuggestionTapped != null) {
                        onSuggestionTapped!(suggestion);
                      }
                    },
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// Private widget that handles the animated thinking text
class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator> {
  final List<String> _thinkingTexts = [
    'Analyzing query...',
    'Consulting knowledge base...',
    'Formulating response...',
  ];
  int _currentIndex = 0;
  late Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    // Cycles text every 1.5 seconds to feel like an agentic thought process
    _timerStream = Stream.periodic(
      const Duration(milliseconds: 1500),
      (x) => x,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _timerStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _currentIndex = snapshot.data! % _thinkingTexts.length;
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _thinkingTexts[_currentIndex],
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
