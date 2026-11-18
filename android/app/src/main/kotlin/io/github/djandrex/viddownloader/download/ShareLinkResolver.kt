package io.github.djandrex.viddownloader.download

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL

/**
 * Instagram sometimes shares short links like `instagram.com/share/AbC123/`
 * that redirect to the real `/reel/...` or `/p/...` URL. yt-dlp needs the
 * real one, so we follow the redirects ourselves (without downloading pages).
 */
object ShareLinkResolver {
    private const val MAX_REDIRECTS = 5
    private const val USER_AGENT =
        "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36"
    private val postPath = Regex("^/(?:[^/]+/)?(?:reels?|p|tv)/[A-Za-z0-9_-]+")

    fun isShareLink(url: String): Boolean =
        runCatching { URI(url).path.trimStart('/').startsWith("share/") }.getOrDefault(false)

    /** Returns the final post URL, or [url] unchanged if it cannot be resolved. */
    suspend fun resolve(url: String): String {
        if (!isShareLink(url)) return url
        return withContext(Dispatchers.IO) {
            runCatching { follow(url) }.getOrNull() ?: url
        }
    }

    private fun follow(start: String): String? {
        var current = start
        repeat(MAX_REDIRECTS) {
            val connection = (URL(current).openConnection() as HttpURLConnection).apply {
                instanceFollowRedirects = false
                requestMethod = "GET" // Only headers are read; the body is never downloaded.
                connectTimeout = 15_000
                readTimeout = 15_000
                setRequestProperty("User-Agent", USER_AGENT)
            }
            try {
                val location = connection.getHeaderField("Location") ?: return null
                val next = URL(URL(current), location).toString()
                val uri = URI(next)
                if (!isInstagramHost(uri.host)) return null
                if (postPath.containsMatchIn(uri.path ?: "")) {
                    return "https://www.instagram.com${uri.path}"
                }
                current = next
            } finally {
                connection.disconnect()
            }
        }
        return null
    }

    private fun isInstagramHost(host: String?): Boolean {
        val h = host?.lowercase() ?: return false
        return h == "instagram.com" || h.endsWith(".instagram.com")
    }
}
