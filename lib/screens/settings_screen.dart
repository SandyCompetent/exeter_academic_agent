import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_settings.dart';

// Allows the user to configure their API key and switch AI models.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<AppSettings>(context, listen: false);
    _keyController = TextEditingController(text: settings.apiKey);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  // Helper method to safely launch external URLs (like LinkedIn, GitHub, or APK downloads)
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $urlString')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Configuration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            decoration: const InputDecoration(
              labelText: 'Gemini API Key',
              border: OutlineInputBorder(),
              hintText: 'AIzaSy...',
              prefixIcon: Icon(Icons.key),
            ),
            obscureText: true,
            onChanged: (val) => context.read<AppSettings>().setApiKey(val),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: settings.isLoadingModels
                ? null
                : () => context.read<AppSettings>().fetchModels(),
            icon: settings.isLoadingModels
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.cloud_download),
            label: const Text('Fetch Available Models'),
          ),
          if (settings.modelError != null) ...[
            const SizedBox(height: 8),
            Text(
              settings.modelError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Select Model',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: settings.selectedModel,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.smart_toy),
            ),
            items: settings.availableModels.map((model) {
              return DropdownMenuItem(
                value: model,
                child: Text(model, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null)
                context.read<AppSettings>().setSelectedModel(val);
            },
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          const Text(
            'About & Downloads',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Developer Information
          ListTile(
            leading: const Icon(Icons.person_pin, size: 32),
            title: const Text('Developed by Sandeep Malviya'),
            subtitle: const Text('Software Engineer & AI Enthusiast'),
            contentPadding: EdgeInsets.zero,
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () =>
                    _launchUrl('https://www.linkedin.com/in/sandy-competent/'),
                icon: const Icon(Icons.link),
                label: const Text('LinkedIn'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () =>
                    _launchUrl('https://github.com/SandyCompetent'),
                icon: const Icon(Icons.code),
                label: const Text('GitHub'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // APK Download Option
          Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.android, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download Android APK',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get the latest mobile version directly to your device.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  // Currently directs to your GitHub releases page, where you can host the built .apk file
                  onPressed: () => _launchUrl(
                    'https://github.com/SandyCompetent/exeter_academic_agent/releases/latest/download/app-release.apk',
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('APK'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
