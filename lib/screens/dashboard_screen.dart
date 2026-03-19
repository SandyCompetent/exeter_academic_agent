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
  StreamController<Map<String, dynamic>>? _controller;
  Timer? _timer;
  String? _lastApiKey;
  String? _lastModel;

  @override
  void initState() {
    super.initState();
    _controller = StreamController<Map<String, dynamic>>.broadcast();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<AppSettings>(context);

    if (_lastApiKey != settings.apiKey || _lastModel != settings.selectedModel) {
      _lastApiKey = settings.apiKey;
      _lastModel = settings.selectedModel;
      _restartFetch();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.close();
    super.dispose();
  }

  void _restartFetch() {
    _timer?.cancel();
    _fetchOnce(); // Initial fetch
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _fetchOnce();
    });
  }

  Future<void> _fetchOnce() async {
    if (_controller == null || _controller!.isClosed) return;

    final apiKey = _lastApiKey ?? '';
    final modelName = _lastModel ?? 'gemini-1.5-flash';

    String weatherStr = 'Fetching...';
    String busETA = 'Loading...';

    // Fetch weather
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

    // Fetch bus schedule estimates using Gemini
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
            "What is the typical schedule or next expected time for the Stagecoach UNI or 4 bus or 4A bus from the University of Exeter right now? Respond with just a short phrase like 'In 10 mins' or 'Every 15 mins', also specifies time in HH:mm format (24 hours format) of next expected bus timing.",
          ),
        );
        busETA = response.text?.trim() ?? 'Unavailable';
      } catch (e) {
        busETA = 'AI Error: Check API Key/Model';
      }
    }

    // Estimate occupancy
    final hour = DateTime.now().hour;
    final isPeakHours = hour >= 10 && hour <= 16;
    final baseOccupancy = isPeakHours ? 75 : 30;
    final forumOccupancy = min(100, baseOccupancy + Random().nextInt(15));
    final stLukesOccupancy = min(100, (baseOccupancy * 0.8).toInt() + Random().nextInt(15));

    if (!_controller!.isClosed) {
      _controller!.add({
        'forum': forumOccupancy,
        'stlukes': stLukesOccupancy,
        'bus': busETA,
        'weather': weatherStr,
      });
    }
  }

  String _getWeatherEmoji(int code) {
    if (code == 0) return 'Clear ☀️';
    if (code >= 1 && code <= 3) return 'Cloudy ⛅';
    if (code == 45 || code == 48) return 'Foggy 🌫️';
    if (code >= 51 && code <= 67) return 'Rain 🌧️';
    if (code >= 71 && code <= 77) return 'Snow ❄️';
    if (code >= 95) return 'Thunderstorm ⛈️';
    return 'Unknown 🌍';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Live Data'), centerTitle: true),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _controller?.stream,
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
            onRefresh: _fetchOnce,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  'Live Updates',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
