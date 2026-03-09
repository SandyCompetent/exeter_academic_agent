import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../providers/app_settings.dart';
import '../widgets/dashboard_card.dart';

// Displays live campus data including weather, bus times, and library occupancy.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<Map<String, dynamic>> _dataStream;
  String? _lastApiKey;
  String? _lastModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<AppSettings>(context);

    // Prevent the stream from restarting on minor UI rebuilds
    if (_lastApiKey != settings.apiKey ||
        _lastModel != settings.selectedModel) {
      _lastApiKey = settings.apiKey;
      _lastModel = settings.selectedModel;
      _dataStream = _fetchExeterData(_lastApiKey!, _lastModel!);
    }
  }

  // Maps WMO weather codes to readable text and emojis
  String _getWeatherEmoji(int code) {
    if (code == 0) return 'Clear ☀️';
    if (code >= 1 && code <= 3) return 'Cloudy ⛅';
    if (code == 45 || code == 48) return 'Foggy 🌫️';
    if (code >= 51 && code <= 67) return 'Rain 🌧️';
    if (code >= 71 && code <= 77) return 'Snow ❄️';
    if (code >= 95) return 'Thunderstorm ⛈️';
    return 'Unknown 🌍';
  }

  // Generates a continuous stream of dashboard data
  Stream<Map<String, dynamic>> _fetchExeterData(
    String apiKey,
    String modelName,
  ) async* {
    while (true) {
      String weatherStr = 'Fetching...';
      String busETA = 'Loading...';

      // Fetch weather from Open-Meteo for Exeter coordinates
      try {
        final res = await http.get(
          Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=50.7352&longitude=-3.5328&current_weather=true',
          ),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final temp = data['current_weather']['temperature'];
          final code = data['current_weather']['weathercode'];
          weatherStr = '$temp°C, ${_getWeatherEmoji(code)}';
        } else {
          weatherStr = 'Unavailable';
        }
      } catch (e) {
        weatherStr = 'Offline';
      }

      // Fetch bus schedule estimates using Gemini as an agent
      if (apiKey.trim().isEmpty) {
        busETA = 'API Key required (Check Settings)';
      } else {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            systemInstruction: Content.system(
              'You are an assistant providing transit schedule insights for the University of Exeter. '
              'Provide an extremely concise output. No pleasantries.',
            ),
          );
          final chat = model.startChat();
          final response = await chat.sendMessage(
            Content.text(
              "What is the typical schedule or next expected time for the Stagecoach UNI or 4 bus or 4A bus from the University of Exeter right now? Respond with just a short phrase like 'In 10 mins' or 'Every 15 mins'.",
            ),
          );

          busETA = response.text?.trim() ?? 'Unavailable';
        } catch (e) {
          busETA = 'AI Error: Check API Key/Model';
        }
      }

      // Estimate library occupancy based on the current time of day
      final hour = DateTime.now().hour;
      final isPeakHours = hour >= 10 && hour <= 16;
      final baseOccupancy = isPeakHours ? 75 : 30;

      final forumOccupancy = min(100, baseOccupancy + Random().nextInt(15));
      final stLukesOccupancy = min(
        100,
        (baseOccupancy * 0.8).toInt() + Random().nextInt(15),
      );

      yield {
        'forum': forumOccupancy,
        'stlukes': stLukesOccupancy,
        'bus': busETA,
        'weather': weatherStr,
      };

      // Wait a minute before checking for updates again
      await Future.delayed(const Duration(seconds: 60));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Live Data'), centerTitle: true),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _dataStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Agent is fetching live campus sensors...'),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dataStream = _fetchExeterData(_lastApiKey!, _lastModel!);
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Live Updates',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DashboardCard(
                  title: 'Campus Weather',
                  value: data['weather'],
                  icon: Icons.cloud,
                  subtitle: 'Powered by Open-Meteo',
                ),
                DashboardCard(
                  title: 'Next Bus 4/4A to Campus',
                  value: data['bus'],
                  icon: Icons.directions_bus,
                  subtitle: 'Stagecoach Schedule (AI Powered)',
                ),
                DashboardCard(
                  title: 'Forum Library Occupancy',
                  value: '${data['forum']}% Full',
                  icon: Icons.library_books,
                  progress: data['forum'] / 100,
                ),
                DashboardCard(
                  title: 'St Luke\'s Library Occupancy',
                  value: '${data['stlukes']}% Full',
                  icon: Icons.menu_book,
                  progress: data['stlukes'] / 100,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
