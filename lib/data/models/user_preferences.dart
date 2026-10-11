enum PreferenceKey {
  showAnimatedLyrics('show_animated_lyrics'),
  equalizerEnabled('equalizer_enabled'),
  ambientColorEnabled('ambient_color_enabled'),
  autoDownloadEnabled('auto_download_enabled'),
  audioQuality('audio_quality');

  const PreferenceKey(this.column);
  final String column;

  bool accepts(Object? value) => this == audioQuality
      ? value is String && const ['Standard', 'High', 'Extreme'].contains(value)
      : value is bool;
}

class UserPreferences {
  const UserPreferences({
    this.showAnimatedLyrics = true,
    this.equalizerEnabled = false,
    this.ambientColorEnabled = true,
    this.autoDownloadEnabled = false,
    this.audioQuality = 'High',
  });

  final bool showAnimatedLyrics;
  final bool equalizerEnabled;
  final bool ambientColorEnabled;
  final bool autoDownloadEnabled;
  final String audioQuality;

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    bool boolean(PreferenceKey key, bool fallback) =>
        json[key.column] is bool ? json[key.column] as bool : fallback;
    return UserPreferences(
      showAnimatedLyrics: boolean(PreferenceKey.showAnimatedLyrics, true),
      equalizerEnabled: boolean(PreferenceKey.equalizerEnabled, false),
      ambientColorEnabled: boolean(PreferenceKey.ambientColorEnabled, true),
      autoDownloadEnabled: boolean(PreferenceKey.autoDownloadEnabled, false),
      audioQuality: PreferenceKey.audioQuality.accepts(json['audio_quality'])
          ? json['audio_quality'] as String
          : 'High',
    );
  }

  Map<String, Object> toJson() => {
    'show_animated_lyrics': showAnimatedLyrics,
    'equalizer_enabled': equalizerEnabled,
    'ambient_color_enabled': ambientColorEnabled,
    'auto_download_enabled': autoDownloadEnabled,
    'audio_quality': audioQuality,
  };

  UserPreferences withValue(PreferenceKey key, Object value) {
    if (!key.accepts(value)) throw ArgumentError.value(value, key.column);
    return UserPreferences.fromJson({...toJson(), key.column: value});
  }

  UserPreferences withPending(Map<PreferenceKey, Object> pending) =>
      UserPreferences.fromJson({
        ...toJson(),
        for (final entry in pending.entries) entry.key.column: entry.value,
      });
}

class CachedUserPreferences {
  CachedUserPreferences({
    required this.preferences,
    Map<PreferenceKey, Object> pending = const {},
  }) : pending = Map.unmodifiable(pending);

  final UserPreferences preferences;
  final Map<PreferenceKey, Object> pending;

  factory CachedUserPreferences.fromJson(Map<String, dynamic> json) {
    final rawPreferences = json['preferences'];
    if (rawPreferences is! Map<String, dynamic>) {
      throw const FormatException('Invalid preferences cache');
    }
    final rawPending = json['pending'];
    return CachedUserPreferences(
      preferences: UserPreferences.fromJson(rawPreferences),
      pending: {
        for (final key in PreferenceKey.values)
          if (rawPending is Map && key.accepts(rawPending[key.column]))
            key: rawPending[key.column] as Object,
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'preferences': preferences.toJson(),
    'pending': {
      for (final entry in pending.entries) entry.key.column: entry.value,
    },
  };
}

enum PreferenceSaveStatus { idle, saving, saved, localOnly, error }

class UserPreferencesState {
  const UserPreferencesState({
    this.preferences = const UserPreferences(),
    this.isReady = false,
    this.isRefreshing = false,
    this.statuses = const {},
    this.errorMessage,
    this.localStorageError,
  });

  final UserPreferences preferences;
  final bool isReady;
  final bool isRefreshing;
  final Map<PreferenceKey, PreferenceSaveStatus> statuses;
  final String? errorMessage;
  final String? localStorageError;

  PreferenceSaveStatus statusFor(PreferenceKey key) =>
      statuses[key] ?? PreferenceSaveStatus.idle;
  bool get isSaving => statuses.values.contains(PreferenceSaveStatus.saving);

  UserPreferencesState copyWith({
    UserPreferences? preferences,
    bool? isReady,
    bool? isRefreshing,
    Map<PreferenceKey, PreferenceSaveStatus>? statuses,
    String? errorMessage,
    String? localStorageError,
    bool clearError = false,
    bool clearLocalError = false,
  }) => UserPreferencesState(
    preferences: preferences ?? this.preferences,
    isReady: isReady ?? this.isReady,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    statuses: Map.unmodifiable(statuses ?? this.statuses),
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    localStorageError: clearLocalError
        ? null
        : localStorageError ?? this.localStorageError,
  );
}
