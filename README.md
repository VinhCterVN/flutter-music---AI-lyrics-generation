# Flussic

A Flutter music player app with Spotify-powered artist metadata, Supabase-backed data, realtime recent listening history, playlists, search, lyrics, and a polished now-playing experience.

## Overview

Flussic is a personal music app project built with Flutter. It combines:

- app-managed playback and queue control
- Spotify artist enrichment
- Supabase as the main backend/data source
- local caching with SQLite
- recent listening history and discovery sections
- playlist, liked songs, artist, search, and lyrics flows

## Preview

Place your screenshots or hosted media URLs below later.

### App Screens

<table>
  <tr>
    <td align="center">
      <img src="https://res.cloudinary.com/dtf1ao1ds/image/upload/v1778139026/dnojl6wth7lxlpliamty.jpg" alt="Home Screen" width="220" />
      <br />
      <sub>Home</sub>
    </td>
    <td align="center">
      <img src="https://res.cloudinary.com/dtf1ao1ds/image/upload/v1778139026/kkguuh3yeshtlbtfgwid.jpg" alt="Now Playing" width="220" />
      <br />
      <sub>Now Playing</sub>
    </td>
    <td align="center">
      <img src="https://res.cloudinary.com/dtf1ao1ds/image/upload/v1778139027/skp576ueorcrc0dniunq.jpg" alt="Artist Details" width="220" />
      <br />
      <sub>Artist Details</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="https://res.cloudinary.com/dtf1ao1ds/image/upload/v1778139026/tou1guk8u66pdqftkebn.jpg" alt="Search" width="220" />
      <br />
      <sub>Search</sub>
    </td>
    <td align="center">
      <img src="https://res.cloudinary.com/dtf1ao1ds/image/upload/v1778139027/mhpccwrdqqcrc7tpxikv.jpg" alt="Library / Playlists" width="220" />
      <br />
      <sub>Library / Playlists</sub>
    </td>
    <td align="center">
      <img src="IMAGE_URL_SETTINGS_OR_LIKED" alt="Settings or Liked Songs" width="220" />
      <br />
      <sub>Settings / Liked Songs</sub>
    </td>
  </tr>
</table>

## Features

- Stream and play tracks with `just_audio` and `audio_service`
- Manage playback queue, add-next behavior, repeat, and shuffle
- Show artist details using Spotify artist data
- Track listening history and surface unique recently played tracks
- Realtime recent tracks updates from Supabase
- Discovery sections for top listened and suggested tracks
- Search tracks and browse artist pages
- Liked songs and playlist flows
- Lyrics-related UI components
- Local storage and caching for tracks/artists
- Local folder audio support with `on_audio_query` and file picker

## Tech Stack

- Flutter
- Riverpod
- Supabase
- Spotify Web API
- just_audio
- audio_service
- SQLite (`sqflite`)
- Go Router

## Project Structure

```text
lib/
  data/         models, controllers, local database helpers
  provider/     Riverpod providers
  service/      backend, Spotify, audio, and search services
  ui/           pages, components, navigation, theme
  utils/        shared helpers
```

## Requirements

- Flutter SDK compatible with `sdk: ^3.9.0`
- A Supabase project
- Spotify API credentials
- Cloudinary credentials for media upload flows

## Environment Variables

Create a `.env` file in the project root.

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret

CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
CLOUDINARY_UPLOAD_PRESET=your_upload_preset
```

You can start from [.env.example](D:/Projects/flutter/flutter_ai_music/.env.example).

## Getting Started

1. Clone the repository.
2. Install Flutter dependencies:

```bash
flutter pub get
```

3. Create `.env` from `.env.example` and fill in your credentials.
4. Make sure your Supabase schema/data is available.
5. Run the app:

```bash
flutter run
```

## Backend Notes

- Supabase is initialized in [main.dart](D:/Projects/flutter/flutter_ai_music/lib/main.dart).
- Database structure/setup artifacts live in [schema.sql](D:/Projects/flutter/flutter_ai_music/schema.sql).
- Spotify artist metadata is fetched through the app service layer and cached locally.

## Main Screens

- Home
- Search
- Artist Details
- Liked Songs
- Playlist Details
- Recent Tracks
- Local Folder Songs
- Settings
- Now Playing

## Development Notes

- The app uses custom fonts such as `SpotifyMixUI` and `Klavika`.
- Assets are stored under `assets/animations`, `assets/icons`, `assets/images`, and `assets/videos`.
- Some features depend on backend data quality and configured external services.

## Roadmap Ideas

- Add tests for providers and service layers
- Improve offline playback and caching flows
- Add richer playlist management
- Expand track/album details
- Polish authentication and onboarding

## License

MIT License =))
