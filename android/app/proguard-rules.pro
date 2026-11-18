# R8 rules for release builds (applied automatically by the Flutter plugin).

# youtubedl-android: parses yt-dlp's JSON into these classes with Jackson
# (reflection), and loads native helpers by name.
-keep class com.yausername.** { *; }
-keepclassmembers class com.yausername.** { *; }

# Jackson (used by youtubedl-android).
-keep class com.fasterxml.jackson.** { *; }
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-dontwarn com.fasterxml.jackson.databind.**
-dontwarn java.beans.**
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry

# Apache Commons (used by youtubedl-android to unpack Python/FFmpeg).
-dontwarn org.apache.commons.**
-keep class org.apache.commons.compress.** { *; }

# WorkManager instantiates our worker by its class name.
-keep class io.github.djandrex.viddownloader.download.DownloadWorker { <init>(...); }
