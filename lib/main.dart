import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'controllers/locale_controller.dart';
import 'services/downloader_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the saved language before the first frame, so the app starts
  // directly in English (default) or in the language chosen last time.
  final prefs = await SharedPreferences.getInstance();
  final localeController = await LocaleController.load(prefs);
  runApp(
    ViddownloaderApp(
      prefs: prefs,
      localeController: localeController,
      bridge: DownloaderBridge(),
    ),
  );
}
