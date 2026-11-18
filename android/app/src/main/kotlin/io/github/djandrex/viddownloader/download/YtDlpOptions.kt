package io.github.djandrex.viddownloader.download

import java.io.File

/** yt-dlp command-line options used for every download. */
object YtDlpOptions {
    /**
     * Prefer a single MP4 with audio up to 720p (no merging needed); otherwise
     * merge the best video up to 720p with the best audio; otherwise anything.
     */
    const val FORMAT = "best[ext=mp4][height<=720]/bestvideo[height<=720]+bestaudio/best"

    /**
     * File name template. In yt-dlp's Instagram extractor `channel` is the
     * username (`uploader` is the display name, with spaces/emojis). The
     * playlist index is added only for carousels: `_1`, `_2`...
     */
    const val OUTPUT_TEMPLATE =
        "instagram_%(channel,uploader_id|unknown)s_%(id)s%(playlist_index&_{}|)s.%(ext)s"

    /** Arguments as (option, value?) pairs, in order. */
    fun arguments(outputDir: File, cookies: File?): List<Pair<String, String?>> = buildList {
        add("-f" to FORMAT)
        add("--merge-output-format" to "mp4")
        add("-o" to File(outputDir, OUTPUT_TEMPLATE).absolutePath)
        // Plain ASCII names that work on every file system.
        add("--restrict-filenames" to null)
        // Use "now" as the file date so the video appears as recent in the gallery.
        add("--no-mtime" to null)
        // Keep going if a carousel item (e.g. a photo) fails; we check the
        // resulting MP4 files instead of trusting the exit code.
        add("--ignore-errors" to null)
        add("--socket-timeout" to "30")
        add("--retries" to "3")
        if (cookies != null) add("--cookies" to cookies.absolutePath)
    }
}
