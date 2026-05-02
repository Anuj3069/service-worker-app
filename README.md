# Airveat Worker App

Airveat Worker is the dedicated mobile application for service providers (workers) to manage their jobs, track earnings, and update their availability. Designed for professionals offering services like Queue Standing, Personal Assistance, Elderly Support, and Tour Guiding.

## Features

- **Dashboard**: A comprehensive overview of daily tasks, upcoming bookings, and recent earnings.
- **Profile Management**: Create and update your professional profile, manage your offered services, and set your pricing.
- **Job Tracking**: View assigned jobs, update job statuses (e.g., accepted, started, completed).
- **Earnings Tracker**: Keep track of completed jobs and revenue.
- **Secure Authentication**: Simple registration and login flow for service providers.
- **Dynamic UI**: A modern, glassmorphic UI built with Flutter, featuring smooth shimmer loading effects.

## Technology Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: Provider
- **Networking**: HTTP package
- **Local Storage**: Shared Preferences
- **UI & Typography**: Material Design, Google Fonts, Shimmer

## Getting Started

### Prerequisites
- Flutter SDK (`>=3.9.2`)
- Android Studio / VS Code with Flutter extension
- An Android Emulator or physical device

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Anuj3069/service-worker-app.git
   ```

2. Navigate to the project directory:
   ```bash
   cd service-worker-app
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

*(Note: The app requires the Airveat Node.js backend to be running locally or hosted. Update the API base URL in `lib/config/api_config.dart` accordingly.)*

## Project Structure

- `lib/models/`: Data models (User, ProviderProfile, Booking, etc.)
- `lib/providers/`: State management for authentication, jobs, and profile.
- `lib/screens/`: UI screens (Dashboard, Login, Profile Setup, etc.)
- `lib/services/`: API integration services.
- `lib/widgets/`: Reusable custom UI components (Glass cards, Gradient buttons).
- `lib/config/`: Theme and API configurations.
