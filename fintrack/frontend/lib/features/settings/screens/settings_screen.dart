import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/custom_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;

  final List<Map<String, String>> _currencies = [
    {'symbol': '\$', 'name': 'USD / Dollar (\$)'},
    {'symbol': '€', 'name': 'EUR / Euro (€)'},
    {'symbol': '£', 'name': 'GBP / British Pound (£)'},
    {'symbol': '₹', 'name': 'INR / Indian Rupee (₹)'},
    {'symbol': '¥', 'name': 'JPY / Japanese Yen (¥)'},
    {'symbol': 'C\$', 'name': 'CAD / Canadian Dollar (C\$)'},
    {'symbol': 'A\$', 'name': 'AUD / Australian Dollar (A\$)'},
  ];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _urlController = TextEditingController(text: settings.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveServerUrl() {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      ref.read(settingsProvider.notifier).updateBaseUrl(newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server endpoint updated to: $newUrl'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Backend API Connection
            Text(
              'Backend API Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Configure the FastAPI server URL for local emulator or physical device testing.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'API Base URL',
                        hintText: 'http://10.0.2.2:8000',
                        prefixIcon: Icon(Icons.dns_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Preset Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.android, size: 16),
                          label: const Text('Android (10.0.2.2)', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _urlController.text = 'http://10.0.2.2:8000';
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.computer, size: 16),
                          label: const Text('Localhost (127.0.0.1)', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _urlController.text = 'http://localhost:8000';
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.restart_alt, size: 16),
                          label: const Text('Reset', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            ref.read(settingsProvider.notifier).resetBaseUrl();
                            setState(() {
                              _urlController.text = ref.read(settingsProvider).baseUrl;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    CustomButton(
                      text: 'Save Server URL',
                      icon: Icons.save_outlined,
                      onPressed: _saveServerUrl,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Section: Preferences
            Text(
              'Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  // Currency Selector Tile
                  ListTile(
                    leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary),
                    title: const Text('Currency Symbol'),
                    subtitle: Text('Current: ${settings.currencySymbol}'),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: settings.currencySymbol,
                        items: _currencies.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['symbol']!,
                            child: Text(c['name']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(settingsProvider.notifier).updateCurrency(val);
                          }
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Dark Theme Toggle
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.secondary),
                    title: const Text('Dark Theme'),
                    subtitle: const Text('Enable dark mode interface'),
                    value: settings.isDarkMode,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).toggleDarkMode(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Section: About FinTrack
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'About FinTrack',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'FinTrack is a full-stack personal finance application powered by Flutter frontend and FastAPI backend with PostgreSQL / SQLite ORM, JWT security, and real-time analytics.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Version: 1.0.0',
                      style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
