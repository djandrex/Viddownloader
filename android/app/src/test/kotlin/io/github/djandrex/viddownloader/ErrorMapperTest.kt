package io.github.djandrex.viddownloader

import io.github.djandrex.viddownloader.download.ErrorCode
import io.github.djandrex.viddownloader.download.ErrorMapper
import org.junit.Assert.assertEquals
import org.junit.Test

class ErrorMapperTest {
    private fun map(text: String?, loggedIn: Boolean = false) = ErrorMapper.map(text, loggedIn)

    @Test
    fun emptyOutputIsUnknown() {
        assertEquals(ErrorCode.UNKNOWN, map(null))
        assertEquals(ErrorCode.UNKNOWN, map("   "))
    }

    @Test
    fun instagramRateLimitOrLoginDependsOnSession() {
        val message = "ERROR: [Instagram] ABC123: Requested content is not available, rate-limit " +
            "reached or login required. Use --cookies, --cookies-from-browser, --username and " +
            "--password, --netrc-cmd, or --netrc (instagram) to provide account credentials"
        assertEquals(ErrorCode.LOGIN_REQUIRED, map(message, loggedIn = false))
        assertEquals(ErrorCode.RATE_LIMITED, map(message, loggedIn = true))
    }

    @Test
    fun emptyMediaResponseAsksToLogIn() {
        val message = "ERROR: [Instagram] ABC123: Instagram sent an empty media response. Check if " +
            "this post is accessible in your browser without being logged-in. If it is not, then " +
            "use --cookies-from-browser or --cookies for the authentication."
        assertEquals(ErrorCode.LOGIN_REQUIRED, map(message))
        // Logged in and still empty: the post is private or gone.
        assertEquals(ErrorCode.PRIVATE_OR_DELETED, map(message, loggedIn = true))
    }

    @Test
    fun http429IsRateLimited() {
        assertEquals(ErrorCode.RATE_LIMITED, map("ERROR: Unable to download webpage: HTTP Error 429: Too Many Requests"))
    }

    @Test
    fun http404IsPrivateOrDeleted() {
        assertEquals(ErrorCode.PRIVATE_OR_DELETED, map("ERROR: Unable to download webpage: HTTP Error 404: Not Found"))
    }

    @Test
    fun postWithoutVideos() {
        assertEquals(ErrorCode.PRIVATE_OR_DELETED, map("ERROR: [Instagram] ABC123: There is no video in this post"))
        assertEquals(ErrorCode.PRIVATE_OR_DELETED, map("ERROR: [Instagram] ABC123: No video formats found!"))
    }

    @Test
    fun networkErrors() {
        assertEquals(
            ErrorCode.NETWORK,
            map("ERROR: Unable to download webpage: <urlopen error [Errno 7] No address associated with hostname>"),
        )
        assertEquals(ErrorCode.NETWORK, map("ERROR: Unable to download webpage: The read operation timed out"))
        assertEquals(ErrorCode.NETWORK, map("ERROR: Connection reset by peer"))
    }

    @Test
    fun unsupportedUrlIsInvalid() {
        assertEquals(ErrorCode.INVALID_URL, map("ERROR: Unsupported URL: https://www.instagram.com/someone/"))
    }

    @Test
    fun anythingElseIsUnknown() {
        assertEquals(ErrorCode.UNKNOWN, map("ERROR: something unexpected happened"))
    }
}
