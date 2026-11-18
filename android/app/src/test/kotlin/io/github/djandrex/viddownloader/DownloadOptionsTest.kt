package io.github.djandrex.viddownloader

import io.github.djandrex.viddownloader.download.DownloadTexts
import io.github.djandrex.viddownloader.download.ShareLinkResolver
import io.github.djandrex.viddownloader.download.YtDlpOptions
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class DownloadOptionsTest {
    @Test
    fun ytDlpArgumentsIncludeTheAgreedOptions() {
        val args = YtDlpOptions.arguments(File("/tmp/out"), cookies = null).toMap()
        assertEquals("best[ext=mp4][height<=720]/bestvideo[height<=720]+bestaudio/best", args["-f"])
        assertEquals("mp4", args["--merge-output-format"])
        assertTrue(args.containsKey("--no-mtime"))
        assertTrue(args.containsKey("--ignore-errors"))
        assertTrue(args.containsKey("--restrict-filenames"))
        assertTrue(args["-o"]!!.startsWith("/tmp/out/instagram_%(channel,uploader_id|unknown)s_%(id)s"))
        assertFalse(args.containsKey("--cookies"))
    }

    @Test
    fun cookiesArePassedOnlyWhenLoggedIn() {
        val args = YtDlpOptions.arguments(File("/tmp/out"), File("/data/cookies.txt")).toMap()
        assertEquals("/data/cookies.txt", args["--cookies"])
    }

    @Test
    fun shareLinksAreDetected() {
        assertTrue(ShareLinkResolver.isShareLink("https://www.instagram.com/share/BAabc123/"))
        assertTrue(ShareLinkResolver.isShareLink("https://www.instagram.com/share/reel/BAabc123/"))
        assertFalse(ShareLinkResolver.isShareLink("https://www.instagram.com/reel/ABC123/"))
        assertFalse(ShareLinkResolver.isShareLink("not a url"))
    }

    @Test
    fun notificationTextsUseFlutterTranslations() {
        val texts = DownloadTexts.fromMap(
            mapOf(
                "itemPattern" to "Vídeo {current} de {total}",
                "successSingle" to "Vídeo guardado en tu galería",
                "successMultiplePattern" to "{count} vídeos guardados en tu galería",
                "downloading" to "",
            ),
        )
        assertEquals("Vídeo 2 de 3", texts.item(2, 3))
        assertEquals("Vídeo guardado en tu galería", texts.success(1))
        assertEquals("3 vídeos guardados en tu galería", texts.success(3))
        // Blank or missing values keep the English default.
        assertEquals("Downloading video…", texts.downloading)
        assertEquals("Cancel", DownloadTexts.fromMap(null).cancelAction)
    }

    @Test
    fun missingTextsMapGivesEnglishDefaults() {
        val texts = DownloadTexts.fromMap(null)
        assertEquals("Video 1 of 2", texts.item(1, 2))
    }
}
