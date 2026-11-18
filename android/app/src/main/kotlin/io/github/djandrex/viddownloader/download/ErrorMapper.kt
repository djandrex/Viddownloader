package io.github.djandrex.viddownloader.download

/** Error codes shared with Flutter (see lib/core/download_state.dart). */
enum class ErrorCode {
    INVALID_URL,
    PRIVATE_OR_DELETED,
    LOGIN_REQUIRED,
    RATE_LIMITED,
    NETWORK,
    BUSY,
    STORAGE_PERMISSION,
    UNKNOWN,
}

/**
 * Turns yt-dlp's error output into one of the [ErrorCode]s that the app shows
 * translated. Pure function, covered by unit tests (ErrorMapperTest).
 */
object ErrorMapper {
    private val rateLimited = listOf(
        "http error 429",
        "too many requests",
        "rate-limit",
        "rate limit",
        "please wait a few minutes",
    )

    private val loginRequired = listOf(
        "login required",
        "log in",
        "logged-in",
        "logged in",
        "--cookies",
        "http error 401",
        "http error 403",
    )

    private val notFound = listOf("http error 404", "http error 410")

    private val network = listOf(
        "unable to resolve host",
        "temporary failure in name resolution",
        "failed to resolve",
        "name or service not known",
        "no address associated with hostname",
        "network is unreachable",
        "connection refused",
        "connection reset",
        "timed out",
        "remote end closed connection",
        "getaddrinfo failed",
        "ssl:",
    )

    private val privateOrDeleted = listOf(
        "private",
        "not available",
        "isn't available",
        "is unavailable",
        "video unavailable",
        "does not exist",
        "has been removed",
        "no video formats found",
        "no video in this post",
        "there is no video",
    )

    /**
     * Rules are checked in order; the first match wins.
     *
     * @param errorOutput yt-dlp's stderr (or the exception message).
     * @param loggedIn whether a cookies file was used. Instagram often answers
     *   "rate-limit reached or login required" in one message: without a
     *   session we suggest logging in; with a session it is a rate limit.
     */
    fun map(errorOutput: String?, loggedIn: Boolean): ErrorCode {
        val text = errorOutput?.lowercase().orEmpty()
        if (text.isBlank()) return ErrorCode.UNKNOWN
        if ("unsupported url" in text) return ErrorCode.INVALID_URL

        val mentionsRateLimit = rateLimited.any { it in text }
        val mentionsLogin = loginRequired.any { it in text }

        return when {
            mentionsRateLimit && mentionsLogin ->
                if (loggedIn) ErrorCode.RATE_LIMITED else ErrorCode.LOGIN_REQUIRED
            mentionsRateLimit -> ErrorCode.RATE_LIMITED
            notFound.any { it in text } -> ErrorCode.PRIVATE_OR_DELETED
            // Already logged in and still not allowed: the post is private.
            mentionsLogin ->
                if (loggedIn) ErrorCode.PRIVATE_OR_DELETED else ErrorCode.LOGIN_REQUIRED
            network.any { it in text } -> ErrorCode.NETWORK
            privateOrDeleted.any { it in text } -> ErrorCode.PRIVATE_OR_DELETED
            else -> ErrorCode.UNKNOWN
        }
    }
}
