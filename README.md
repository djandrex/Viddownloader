# Viddownloader

App para **Android** (hecha con Flutter) que descarga vídeos **públicos** de Instagram
(Reels y publicaciones) a partir de su enlace. Una sola función, sin anuncios, sin
cuentas, sin servidor: todo ocurre en el móvil.

- Pega el enlace (o compártelo desde Instagram) → el vídeo se guarda en la galería,
  en `Movies/Viddownloader`, con calidad de hasta 720p.
- Interfaz en **inglés y español** (inglés por defecto; recuerda el último idioma elegido).
- La descarga sigue aunque salgas de la app, con notificación de progreso.
- Carruseles: descarga todos los vídeos e ignora las fotos.

> Uso personal: descarga solo contenido público o al que tengas acceso, y respeta los
> derechos de los creadores.

---

## Para tus amigos: instalar y usar

### Instalar
1. Abre el enlace de **Releases** del repositorio en el móvil y descarga el APK:
   - `Viddownloader-X.Y.Z.apk` → funciona en todos los móviles Android 8 o superior.
   - `Viddownloader-X.Y.Z-arm64.apk` → más pequeño, para móviles de 64 bits (casi todos los recientes).
     Si no se instala, usa el anterior.
2. Abre el archivo descargado. Android pedirá permiso para instalar apps de ese origen:
   acepta y vuelve atrás. La ruta exacta varía según la marca; normalmente es
   `Settings > Apps > Special app access > Install unknown apps` (en español:
   *Ajustes > Aplicaciones > Acceso especial > Instalar apps desconocidas*).
3. Si aparece un aviso de **Play Protect**, toca *Más detalles → Instalar de todas formas*.
   Es normal en apps que no vienen de Google Play.

Para actualizar, instala el APK nuevo encima del anterior (no hace falta desinstalar).

### Usar
- **Desde Instagram**: en el vídeo, toca *Compartir* → **Viddownloader**. La descarga empieza sola.
- **Copiando el enlace**: en Instagram toca *Copiar enlace*, abre la app y pulsa **Pegar** →
  **Descargar**. Si la app detecta un enlace en el portapapeles te ofrecerá pegarlo (nunca lo
  pega sola). En Android 12+ el sistema muestra un aviso cuando una app lee el portapapeles: es normal.
- **Idioma**: botón `EN / ES` arriba a la derecha (o en Ajustes).
- **Si un vídeo falla**: en *Ajustes* pulsa **Actualizar motor de descarga** (Instagram cambia a
  menudo y el motor se actualiza para seguir funcionando). Si Instagram pide iniciar sesión, puedes
  hacerlo en *Ajustes → Iniciar sesión en Instagram* (recomendado: una **cuenta secundaria**).

---

## Para el desarrollador

### Cómo funciona
- **Flutter (Dart)**: interfaz, idiomas, validación de enlaces y estado.
- **Kotlin (Android nativo)**: el motor de descarga usa
  [youtubedl-android](https://github.com/yausername/youtubedl-android) (yt-dlp + Python + FFmpeg
  empaquetados dentro de la app). Flutter y Kotlin hablan por un `MethodChannel` (comandos) y un
  `EventChannel` (progreso).
- La descarga corre en **WorkManager** como servicio en primer plano (`dataSync`) y se guarda con
  **MediaStore** (Android 10+) o en `Movies/Viddownloader` + escáner de medios (Android 8–9).

```
lib/
  main.dart, app.dart              Arranque: lee el idioma guardado antes del primer frame
  core/instagram_url.dart          Extrae, valida y limpia enlaces (testeado)
  core/download_state.dart         Estados y códigos de error compartidos con Kotlin
  controllers/                     Estado (provider + ChangeNotifier): idioma, descarga, ajustes
  services/downloader_bridge.dart  Canales Flutter ↔ Kotlin
  ui/                              Pantalla principal, Ajustes y widgets
  l10n/app_en.arb, app_es.arb      Textos en inglés y español (el código se genera solo)
android/app/src/main/kotlin/io/github/djandrex/viddownloader/
  MainActivity.kt                  Recibe enlaces de "Compartir" (singleTask)
  bridge/DownloaderChannel.kt      Implementa los canales, permisos, abrir/compartir
  download/DownloadWorker.kt       Ejecuta yt-dlp, progreso, cancelación, guardado
  download/ErrorMapper.kt          Traduce errores de yt-dlp a códigos (testeado)
  download/MediaSaver.kt           Copia el MP4 a la galería
  download/ShareLinkResolver.kt    Resuelve enlaces cortos instagram.com/share/...
  auth/                            Inicio de sesión opcional (WebView → cookies.txt)
  engine/Engine.kt                 Inicializa y actualiza yt-dlp
.github/workflows/                 CI y publicación automática del APK
```

### Requisitos
- Flutter **3.50** (canal stable) y Android Studio (o el Android SDK con la línea de comandos).
- JDK 17 o superior (los workflows usan 21).

### Ejecutar en tu móvil
1. Activa *Opciones de desarrollador → Depuración USB* en el móvil y conéctalo.
2. `flutter pub get`
3. `flutter run`

### Tests
```bash
flutter analyze
flutter test                                   # Dart: enlaces, idioma, flujo de descarga
flutter build apk --debug --target-platform android-arm64
cd android && ./gradlew :app:testDebugUnitTest -Ptarget-platform=android-arm64   # Kotlin
```

### Publicar una versión (APK en GitHub Releases)

**1. Crear la keystore (una sola vez).** Guárdala con copia de seguridad: si se pierde, tus amigos
tendrán que desinstalar la app para poder actualizar.
```bash
keytool -genkeypair -v -keystore viddownloader.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias viddownloader
```
No la subas nunca al repositorio (`*.jks` y `key.properties` ya están en `.gitignore`).
Evita la barra invertida `\` en las contraseñas.

**2. Configurar los Secrets en GitHub** (*Settings → Secrets and variables → Actions → New
repository secret*):

| Secret | Valor |
|---|---|
| `KEYSTORE_BASE64` | Salida de `base64 -w0 viddownloader.jks` (en macOS: `base64 -i viddownloader.jks`) |
| `KEYSTORE_PASSWORD` | Contraseña de la keystore |
| `KEY_ALIAS` | `viddownloader` (o el alias que usaste) |
| `KEY_PASSWORD` | Contraseña de la clave |

**3. Publicar:**
```bash
git tag v1.0.0
git push origin v1.0.0
```
El workflow *Release APK* ejecuta los tests, compila dos APK firmados (universal y arm64) y los
publica en *Releases*. El número de versión sale del tag y el `versionCode` del número de
ejecución, así que cada versión se instala encima de la anterior.

Para compilar una release en local, crea `android/key.properties`:
```properties
storeFile=app/viddownloader.jks
storePassword=...
keyAlias=viddownloader
keyPassword=...
```
y copia la keystore a `android/app/viddownloader.jks`. Sin ese archivo, la release se firma con la
clave de depuración (útil solo para pruebas).

### Notas
- **Tamaño**: el APK universal pesa unos 110 MB y el arm64 unos 60 MB porque incluyen Python,
  yt-dlp y FFmpeg para que todo funcione sin servidor.
- **Si Instagram cambia**: primero *Actualizar motor de descarga* en la app. Si sigue fallando,
  sube la versión de `youtubedl-android` en `android/app/build.gradle.kts`.
- **Verificación de desarrolladores de Google**: Google está empezando a exigir que las apps
  instaladas fuera de Play procedan de un desarrollador verificado (ya en algunos países desde
  septiembre de 2026; en el resto está anunciado para 2027). Para compartir con amigos existe una
  cuenta gratuita de "distribución limitada". Revisa
  [la documentación oficial](https://support.google.com/android-developer-console/answer/16561738)
  antes de repartir el APK.
