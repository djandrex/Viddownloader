import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/download_controller.dart';
import 'controllers/engine_controller.dart';
import 'controllers/locale_controller.dart';
import 'l10n/app_localizations.dart';
import 'services/downloader_bridge.dart';
import 'ui/home_screen.dart';

/// Root widget: creates the controllers and the MaterialApp.
class ViddownloaderApp extends StatelessWidget {
  const ViddownloaderApp({
    super.key,
    required this.prefs,
    required this.localeController,
    required this.bridge,
    this.autoUpdateEngine = true,
  });

  final SharedPreferences prefs;
  final LocaleController localeController;
  final DownloaderBridge bridge;

  /// Turned off in tests.
  final bool autoUpdateEngine;

  /// Instagram-like magenta used to generate the Material 3 palette.
  static const Color _seed = Color(0xFFC13584);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<DownloadController>(
          create: (_) => DownloadController(bridge),
        ),
        ChangeNotifierProvider<EngineController>(
          lazy: false, // Load right away so the daily update check runs.
          create: (_) {
            final engine = EngineController(bridge, prefs)..load();
            if (autoUpdateEngine) engine.autoUpdateIfDue();
            return engine;
          },
        ),
      ],
      child: Consumer<LocaleController>(
        builder: (context, locale, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          // Explicit locale: the app does not follow the phone language.
          locale: locale.locale,
          supportedLocales: LocaleController.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: ThemeMode.system,
          home: const HomeScreen(),
        ),
      ),
    );
  }

  static ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
  );
}
