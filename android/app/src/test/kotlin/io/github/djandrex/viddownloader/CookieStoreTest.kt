package io.github.djandrex.viddownloader

import io.github.djandrex.viddownloader.auth.CookieStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CookieStoreTest {
    @Test
    fun convertsCookieHeaderToNetscapeFormat() {
        val content = CookieStore.toNetscape(
            "csrftoken=abc; sessionid=123%3Axyz; ds_user_id=42; mid=Z-1=x",
            expiresAtEpochSeconds = 1_900_000_000,
        )
        val lines = content.trimEnd().lines()
        assertEquals("# Netscape HTTP Cookie File", lines[0])
        assertEquals(5, lines.size)
        assertEquals(".instagram.com\tTRUE\t/\tTRUE\t1900000000\tcsrftoken\tabc", lines[1])
        assertEquals(".instagram.com\tTRUE\t/\tTRUE\t1900000000\tsessionid\t123%3Axyz", lines[2])
        // Only the first '=' separates name and value.
        assertEquals(".instagram.com\tTRUE\t/\tTRUE\t1900000000\tmid\tZ-1=x", lines[4])
        assertTrue(CookieStore.hasSession(content))
    }

    @Test
    fun withoutSessionIdThereIsNoSession() {
        val content = CookieStore.toNetscape("csrftoken=abc; mid=xyz", 1_900_000_000)
        assertFalse(CookieStore.hasSession(content))
        assertFalse(CookieStore.hasSession(CookieStore.toNetscape("sessionid=", 1_900_000_000)))
    }

    @Test
    fun ignoresMalformedPairs() {
        val content = CookieStore.toNetscape(" ; =novalue; justtext; a=1 ", 1)
        val lines = content.trimEnd().lines()
        assertEquals(2, lines.size)
        assertEquals(".instagram.com\tTRUE\t/\tTRUE\t1\ta\t1", lines[1])
    }
}
