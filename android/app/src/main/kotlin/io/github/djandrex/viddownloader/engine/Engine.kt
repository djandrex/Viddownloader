package io.github.djandrex.viddownloader.engine

import android.content.Context
import android.util.Log
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/**
 * Owns the yt-dlp engine (youtubedl-android: yt-dlp + Python + FFmpeg).
 *
 * - [ensureInitialized] is idempotent and safe to call from anywhere: the
 *   Application starts it in the background, and the download worker calls it
 *   again because WorkManager can run the worker while the app UI is closed.
 * - [workLock] makes downloads and yt-dlp updates mutually exclusive, because
 *   an update replaces the yt-dlp files that a running download is using.
 */
object Engine {
    private const val TAG = "Engine"

    private val initMutex = Mutex()

    @Volatile
    private var initialized = false

    /** Held while yt-dlp runs a download or an update. */
    val workLock = Mutex()

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /** Starts unpacking the engine at app start so the first download is fast. */
    fun initInBackground(context: Context) {
        val appContext = context.applicationContext
        scope.launch {
            runCatching { ensureInitialized(appContext) }
                .onFailure { Log.e(TAG, "Engine initialization failed", it) }
        }
    }

    suspend fun ensureInitialized(context: Context) {
        if (initialized) return
        initMutex.withLock {
            if (initialized) return
            val appContext = context.applicationContext
            withContext(Dispatchers.IO) {
                YoutubeDL.getInstance().init(appContext)
                FFmpeg.getInstance().init(appContext)
            }
            initialized = true
        }
    }

    /** Installed yt-dlp version, e.g. "2026.11.01". */
    suspend fun version(context: Context): String? {
        ensureInitialized(context)
        return withContext(Dispatchers.IO) {
            YoutubeDL.getInstance().version(context.applicationContext)
        }
    }

    /**
     * Updates yt-dlp from its stable channel.
     *
     * @throws EngineBusyException if a download is running.
     * @return `true` if a new version was installed, `false` if it was already
     *   up to date.
     */
    suspend fun update(context: Context): Boolean {
        ensureInitialized(context)
        if (!workLock.tryLock()) throw EngineBusyException()
        try {
            val status = withContext(Dispatchers.IO) {
                YoutubeDL.getInstance().updateYoutubeDL(
                    context.applicationContext,
                    YoutubeDL.UpdateChannel.STABLE,
                )
            }
            return status == YoutubeDL.UpdateStatus.DONE
        } finally {
            workLock.unlock()
        }
    }
}

/** Thrown when the engine is busy with a download. */
class EngineBusyException : Exception("A download is in progress")
