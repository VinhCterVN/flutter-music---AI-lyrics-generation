# Flussic

Flussic is a Flutter-based music app focused on streamed playback, Spotify artist discovery, personal listening history, and a polished local-first listening experience.

This project combines mobile music UX with Supabase-backed data, Riverpod state management, and external metadata sources to create a personal music app inspired by modern streaming interfaces.

## Overview

Flussic includes:

- audio playback with `just_audio` and `audio_service`
- queue, repeat, shuffle, and local playback controls
- Spotify artist and music metadata enrichment
- Supabase-powered recent listening and personalization flows
- search, library, playlists, liked songs, and artist detail screens
- local media browsing and playback support
- responsive dark themed interface

## Features

- Play audio from app-managed queues and local sources
- Browse search, artist, and library pages
- View artist details with Spotify metadata and summaries
- Track recently played items and surface listening discovery sections
- Manage liked songs and playlist data through the app
- Support local folder audio with `on_audio_query` and `file_picker`
- Store user preferences and app state locally
- Use custom app theming and fonts for a branded music UI

## Tech Stack

- Flutter
- Dart
- Riverpod
- Go Router
- Supabase
- Spotify Web API
- `just_audio` and `audio_service`
- `sqflite`
- `flutter_dotenv`
- `cached_network_image`
- `shared_preferences`
- `flutter_secure_storage`

## Project Structure

```text
.
├── android/                 # Android project files
├── assets/                  # Animations, icons, images, videos, fonts
├── lib/
│   ├── data/                # Models, repositories, database helpers
│   ├── provider/            # Riverpod providers and app state
│   ├── service/             # API, audio, Spotify, Supabase, and utility services
│   ├── ui/                  # Screens, widgets, router, theme, layout
│   ├── utils/               # Shared helper functions and widgets
│   ├── main.dart            # App bootstrap and theme setup
├── test/                    # Tests
├── .env.example             # Environment variable template
├── schema.sql               # Database schema / SQL setup
├── pubspec.yaml             # Flutter package configuration
├── README.md                # Project documentation
└── analysis_options.yaml    # Lint configuration
```

## Requirements

Before running the app, make sure you have:

- Flutter SDK 3.9 or newer
- Android Studio / Xcode for device builds if needed
- A Supabase project
- Spotify API credentials
- A valid `.env` configuration

## Environment Setup

Copy the sample environment file and fill in the values:

```bash
cp .env.example .env
```

Then define the required variables:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
```

The project also includes support for additional integration variables in the sample template at [.env.example](.env.example).

## Getting Started

1. Install dependencies:

```bash
flutter pub get
```

2. Create your local environment file from [.env.example](.env.example).

3. Configure Supabase and ensure your database is initialized using [schema.sql](schema.sql).

4. Run the app:

```bash
flutter run
```

For Android builds, you can use:

```bash
flutter run -d android
```

## App Bootstrap and Backend Wiring

The app entry point initializes environment variables, sets up display mode, and starts Supabase in [lib/main.dart](lib/main.dart).

The database schema and related SQL setup are located in [schema.sql](schema.sql).

## Development Notes

- The app uses custom fonts such as `SpotifyMixUI` and `Klavika`.
- Assets live in the `assets/` directory, including animations, icons, images, and videos.
- Some screens rely on external backend data and configured API credentials.
- This app is best treated as a feature-rich personal project rather than a drop-in production SaaS starter.

## Testing

Run the project tests with:

```bash
flutter test
```

## Roadmap Ideas

- improve offline caching and fallback playback strategies
- expand playlist and album detail management
- add stronger test coverage for providers and services
- improve onboarding and authentication flows
- polish mobile UX details and accessibility improvements

## License

This project is distributed under the MIT License unless otherwise noted in the repository.
