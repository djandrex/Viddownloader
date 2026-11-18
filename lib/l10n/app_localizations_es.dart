// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Viddownloader';

  @override
  String get homeHeadline => 'Descarga vídeos de Instagram';

  @override
  String get homeSubtitle =>
      'Pega el enlace de un Reel o una publicación y guarda el vídeo en tu galería.';

  @override
  String get urlFieldLabel => 'Enlace de Instagram';

  @override
  String get urlFieldHint => 'https://www.instagram.com/reel/…';

  @override
  String get pasteButton => 'Pegar';

  @override
  String get clearTooltip => 'Borrar';

  @override
  String get downloadButton => 'Descargar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get openButton => 'Abrir';

  @override
  String get shareButton => 'Compartir';

  @override
  String get dismissButton => 'Descartar';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get languageToggleTooltip => 'Cambiar idioma';

  @override
  String get shareTip =>
      'Consejo: en Instagram, toca Compartir → Viddownloader para descargar al instante.';

  @override
  String get clipboardBannerText =>
      'Hay un enlace de Instagram en tu portapapeles.';

  @override
  String get clipboardNoLink =>
      'No hay ningún enlace de Instagram en el portapapeles.';

  @override
  String get statusPreparing => 'Obteniendo el vídeo…';

  @override
  String statusDownloading(int percent) {
    return 'Descargando… $percent%';
  }

  @override
  String statusItem(int current, int total) {
    return 'Vídeo $current de $total';
  }

  @override
  String get statusSaving => 'Guardando en la galería…';

  @override
  String successMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vídeos guardados en tu galería',
      one: 'Vídeo guardado en tu galería',
    );
    return '$_temp0';
  }

  @override
  String get successLocation => 'Carpeta: Movies/Viddownloader';

  @override
  String get canceledMessage => 'Descarga cancelada.';

  @override
  String get openFailed => 'No hay ninguna app para abrir el vídeo.';

  @override
  String get errorInvalidUrl =>
      'Ese enlace no parece de un vídeo de Instagram. Usa el enlace de un Reel o una publicación.';

  @override
  String get errorPrivateOrDeleted =>
      'El vídeo es privado, se eliminó o la publicación no tiene vídeos.';

  @override
  String get errorLoginRequired =>
      'Instagram pide iniciar sesión para mostrar este vídeo.';

  @override
  String get errorRateLimited =>
      'Instagram está limitando las peticiones. Inténtalo en unos minutos.';

  @override
  String get errorNetwork =>
      'Sin conexión a internet. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get errorBusy => 'Ya hay una descarga en curso.';

  @override
  String get errorStoragePermission =>
      'Se necesita permiso de almacenamiento para guardar los vídeos.';

  @override
  String get errorUnknown =>
      'Algo salió mal. Inténtalo de nuevo o actualiza el motor de descarga en Ajustes.';

  @override
  String get loginButton => 'Iniciar sesión en Instagram';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsEngineSection => 'Motor de descarga';

  @override
  String settingsEngineVersion(String version) {
    return 'Versión de yt-dlp: $version';
  }

  @override
  String get settingsLoading => 'Cargando…';

  @override
  String get settingsUpdateEngine => 'Actualizar motor de descarga';

  @override
  String settingsEngineUpdated(String version) {
    return 'Motor de descarga actualizado a $version.';
  }

  @override
  String get settingsEngineUpToDate =>
      'El motor de descarga ya está actualizado.';

  @override
  String get settingsEngineUpdateFailed =>
      'No se pudo actualizar. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get settingsEngineBusy => 'Espera a que termine la descarga actual.';

  @override
  String get settingsSessionSection => 'Sesión de Instagram (opcional)';

  @override
  String get settingsSessionLoggedIn =>
      'Sesión iniciada. Solo se usa cuando Instagram lo exige.';

  @override
  String get settingsSessionLoggedOut =>
      'Sin sesión. Solo hace falta si Instagram la pide.';

  @override
  String get settingsSessionTip => 'Recomendamos usar una cuenta secundaria.';

  @override
  String get logoutButton => 'Cerrar sesión';

  @override
  String get settingsLoggedInMessage => 'Sesión guardada.';

  @override
  String get settingsLoggedOutMessage => 'Sesión cerrada.';

  @override
  String get settingsAboutSection => 'Acerca de';

  @override
  String settingsAppVersion(String version) {
    return 'Versión de la app: $version';
  }

  @override
  String get settingsLegalNote =>
      'Descarga solo contenido público y respeta los derechos de los creadores.';

  @override
  String get notifChannelName => 'Descargas';

  @override
  String get notifDownloading => 'Descargando vídeo…';

  @override
  String get notifFailed => 'La descarga falló';

  @override
  String get loginScreenTitle => 'Iniciar sesión en Instagram';
}
