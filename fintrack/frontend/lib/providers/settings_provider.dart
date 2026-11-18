import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import 'api_providers.dart';

class SettingsState {
  final String baseUrl;
  final String currencySymbol;
  final bool isDarkMode;

  SettingsState({
    required this.baseUrl,
    required this.currencySymbol,
    required this.isDarkMode,
  });

  SettingsState copyWith({
    String? baseUrl,
    String? currencySymbol,
    bool? isDarkMode,
  }) {
    return SettingsState(
      baseUrl: baseUrl ?? this.baseUrl,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref ref;

  SettingsNotifier(this.ref)
      : super(
          SettingsState(
            baseUrl: ref.read(storageServiceProvider).getBaseUrl() ??
                ApiConstants.defaultBaseUrl,
            currencySymbol: ref.read(storageServiceProvider).getCurrency(),
            isDarkMode: ref.read(storageServiceProvider).isDarkMode(),
          ),
        );

  Future<void> updateBaseUrl(String url) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveBaseUrl(url);
    state = state.copyWith(baseUrl: url);
  }

  Future<void> resetBaseUrl() async {
    final defaultUrl = ApiConstants.defaultBaseUrl;
    final storage = ref.read(storageServiceProvider);
    await storage.saveBaseUrl(defaultUrl);
    state = state.copyWith(baseUrl: defaultUrl);
  }

  Future<void> updateCurrency(String symbol) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveCurrency(symbol);
    state = state.copyWith(currencySymbol: symbol);
  }

  Future<void> toggleDarkMode(bool isDark) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveDarkMode(isDark);
    state = state.copyWith(isDarkMode: isDark);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
