package io.github.djandrex.viddownloader.auth

import android.content.Context
import android.webkit.CookieManager
import android.webkit.WebStorage
import java.io.File

/**
 * Stores the optional Instagram session as a `cookies.txt` file that yt-dlp
 * reads with `--cookies`. The file lives in the app's private storage.
 */
object CookieStore {
    const val INSTAGRAM_URL = "https://www.instagram.com"
    private const val FILE_NAME = "cookies.txt"
    private const val ONE_YEAR_SECONDS = 365L * 24 * 60 * 60

    fun file(context: Context): File = File(context.filesDir, FILE_NAME)

    /** `true` if a saved session exists. */
    fun isLoggedIn(context: Context): Boolean {
        val file = file(context)
        return file.isFile && hasSession(file.readText())
    }

    /** Cookies file to pass to yt-dlp, or `null` if there is no session. */
    fun fileIfLoggedIn(context: Context): File? =
        if (isLoggedIn(context)) file(context) else null

    /**
     * Saves the WebView cookies for instagram.com.
     * @return `true` if a `sessionid` cookie was found and saved.
     */
    fun saveFromWebView(context: Context): Boolean {
        val header = CookieManager.getInstance().getCookie(INSTAGRAM_URL) ?: return false
        val content = toNetscape(header, System.currentTimeMillis() / 1000 + ONE_YEAR_SECONDS)
        if (!hasSession(content)) return false
        file(context).writeText(content)
        return true
    }

    /** Removes the saved session and the WebView cookies. */
    fun clear(context: Context) {
        file(context).delete()
        CookieManager.getInstance().removeAllCookies(null)
        CookieManager.getInstance().flush()
        WebStorage.getInstance().deleteAllData()
    }

    /**
     * Android's CookieManager only returns `name=value; name2=value2`, so we
     * build the Netscape cookie file format that yt-dlp expects ourselves:
     * a header line and one TAB-separated line per cookie:
     * `domain  includeSubdomains  path  secure  expiry  name  value`.
     */
    fun toNetscape(cookieHeader: String, expiresAtEpochSeconds: Long): String {
        val lines = cookieHeader.split(';')
            .map { it.trim() }
            .filter { '=' in it }
            .mapNotNull { pair ->
                val name = pair.substringBefore('=').trim()
                val value = pair.substringAfter('=').trim()
                if (name.isEmpty()) {
                    null
                } else {
                    listOf(
                        ".instagram.com",
                        "TRUE",
                        "/",
                        "TRUE",
                        expiresAtEpochSeconds.toString(),
                        name,
                        value,
                    ).joinToString("\t")
                }
            }
        return buildString {
            append("# Netscape HTTP Cookie File\n")
            lines.forEach { append(it).append('\n') }
        }
    }

    /** `true` if the Netscape file content contains a non-empty sessionid. */
    fun hasSession(netscapeContent: String): Boolean =
        netscapeContent.lineSequence().any { line ->
            val fields = line.split('\t')
            fields.size >= 7 && fields[5] == "sessionid" && fields[6].isNotBlank()
        }
}
