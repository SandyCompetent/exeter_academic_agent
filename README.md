# Exeter Academic Agent

A production-ready Agentic Study Assistant built for students at the University of Exeter. This application combines the power of Google Gemini AI with real-time campus data to help students manage their academic life and navigate the campus efficiently.

## 🚀 Features

### 1. Agentic Study Assistant
- **Real-time Streaming**: Responses appear token-by-token for a smooth, interactive experience.
- **Smart Follow-ups**: The AI automatically generates three relevant follow-up questions after every response, allowing for one-tap deeper exploration.
- **Academic Specialist**: Pre-configured with system instructions to provide high-quality study plans, summaries, and concept explanations tailored for university-level education.
- **Thinking State**: A dynamic, agentic "thought process" indicator that shows you exactly what the AI is doing before it starts speaking.

### 2. Campus Live Dashboard
- **Live Weather**: Real-time weather updates specifically for Exeter (Streatham/St Luke's) using Open-Meteo data.
- **AI Bus ETA**: Uses Gemini to analyze current schedules and provide live estimates for Stagecoach routes (D and 4) to campus.
- **Library Occupancy**: Time-aware estimates for Forum and St Luke's library capacity to help you find a study spot.

### 3. Developer Features
- **Model Selector**: Easily switch between `gemini-1.5-pro`, `gemini-1.5-flash`, and the latest `gemini-3-flash-preview`.
- **Modular Architecture**: Clean separation of concerns (Services, Providers, Models, Widgets) making the code easy to maintain and scale.
- **Cross-Platform**: Fully responsive design that works on Android, iOS, and Web.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **AI Engine**: [Google Gemini API](https://ai.google.dev/) (google_generative_ai)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Formatting**: [Flutter Markdown Plus](https://pub.dev/packages/flutter_markdown_plus)
- **Live Data**: [Open-Meteo API](https://open-meteo.com/)

## 📦 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/exeter_academic_agent.git
   cd exeter_academic_agent
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up your API Key:**
   - The app comes with a default key for testing, but you can change it in the **Settings** tab within the app.
   - To get your own key, visit [Google AI Studio](https://aistudio.google.com/).

4. **Run the app:**
   ```bash
   # For Mobile
   flutter run

   # For Web
   flutter run -d chrome
   ```

## 📂 Project Structure

- `lib/models/`: Data structures (e.g., ChatMessage).
- `lib/services/`: API communication logic (Gemini, Weather).
- `lib/providers/`: State management for app settings and AI config.
- `lib/screens/`: High-level UI pages (Chat, Dashboard, Settings).
- `lib/widgets/`: Reusable UI components (Message Bubbles, Dashboard Cards).

## 📄 License

This project is intended for educational purposes at the University of Exeter. Feel free to fork and adapt it for your own academic needs.
