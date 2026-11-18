package io.github.djandrex.viddownloader.download

import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.ForegroundInfo
import androidx.work.OneTimeWorkRequest
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.github.djandrex.viddownloader.auth.CookieStore
import io.github.djandrex.viddownloader.engine.Engine
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.sync.withLock
import java.io.File
import java.io.IOException

/**
 * Downloads one Instagram post with yt-dlp, then copies the MP4 files to the
 * gallery. Runs in WorkManager so it keeps going if the user leaves the app,
 * with a progress notification (foreground service of type dataSync).
 */
class DownloadWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG = "DownloadWorker"

        /** Only one download at a time. */
        const val UNIQUE_NAME = "instagram-download"

        const val KEY_URL = "url"

        // Progress keys (WorkInfo.progress).
        const val P_PHASE = "phase"
        const val P_PROGRESS = "progress"
        const val P_ITEM = "item"
        const val P_ITEM_COUNT = "itemCount"

        // Output keys (WorkInfo.outputData).
        const val O_URIS = "uris"
        const val O_ERROR = "errorCode"

        const val PHASE_PREPARING = "preparing"
        const val PHASE_DOWNLOADING = "downloading"
        const val PHASE_SAVING = "saving"

        /** yt-dlp prints this line for every item of a carousel. */
        private val ITEM_LINE = Regex("""Downloading (?:item|video) (\d+) of (\d+)""")

        private const val MIN_UPDATE_INTERVAL_MS = 400L

        fun request(url: String, texts: DownloadTexts): OneTimeWorkRequest {
            val input = texts.toData(Data.Builder().putString(KEY_URL, url)).build()
            return OneTimeWorkRequestBuilder<DownloadWorker>()
                .setInputData(input)
                .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                .build()
        }
    }

    private val texts = DownloadTexts.fromData(inputData)
    private val notifications by lazy { DownloadNotifications(applicationContext, texts) }

    // Progress state, updated from yt-dlp's output thread.
    @Volatile private var item: Int? = null
    @Volatile private var itemCount: Int? = null
    @Volatile private var lastPercent = -1
    @Volatile private var lastUpdateAt = 0L

    /** Needed for expedited work on Android 11 and older. */
    override suspend fun getForegroundInfo(): ForegroundInfo =
        notifications.foregroundInfo(id, texts.downloading, null, null)

    override suspend fun doWork(): Result {
        val url = inputData.getString(KEY_URL) ?: return failure(ErrorCode.INVALID_URL)
        val tempDir = File(applicationContext.cacheDir, "downloads/$id")
        tempDir.deleteRecursively()
        tempDir.mkdirs()

        try {
            setProgress(workDataOf(P_PHASE to PHASE_PREPARING))
            // Can fail if Android does not allow a foreground service right
            // now; the download still runs, just without the ongoing notification.
            runCatching { setForeground(getForegroundInfo()) }
                .onFailure { Log.w(TAG, "Could not start foreground", it) }

            Engine.ensureInitialized(applicationContext)
            val target = ShareLinkResolver.resolve(url)
            val cookies = CookieStore.fileIfLoggedIn(applicationContext)

            // Wait if yt-dlp is being updated right now.
            val errorOutput = Engine.workLock.withLock { runYtDlp(target, tempDir, cookies) }

            // With --ignore-errors yt-dlp may report an error even though some
            // videos were downloaded (e.g. photos in a carousel), so the files
            // decide whether it worked, not the exit code.
            val videos = tempDir.walkTopDown()
                .filter { it.isFile && it.extension.equals("mp4", ignoreCase = true) }
                .sortedBy { it.name }
                .toList()
            if (videos.isEmpty()) {
                Log.w(TAG, "No videos downloaded. yt-dlp said: $errorOutput")
                return failure(ErrorMapper.map(errorOutput, loggedIn = cookies != null))
            }

            setProgress(workDataOf(P_PHASE to PHASE_SAVING))
            notifications.updateProgress(id, texts.saving, null, null)
            val uris: List<Uri> = videos.map { MediaSaver.save(applicationContext, it) }

            notifications.showSuccess(uris)
            return Result.success(workDataOf(O_URIS to uris.map { it.toString() }.toTypedArray()))
        } catch (e: CancellationException) {
            // Cancelled by the user (or stopped by the system).
            notifications.showCanceled()
            throw e
        } catch (e: IOException) {
            Log.e(TAG, "Saving failed", e)
            val code = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) ErrorCode.STORAGE_PERMISSION else ErrorCode.UNKNOWN
            return failure(code)
        } catch (e: SecurityException) {
            Log.e(TAG, "Saving not allowed", e)
            return failure(ErrorCode.STORAGE_PERMISSION)
        } catch (e: Exception) {
            Log.e(TAG, "Download failed", e)
            return failure(ErrorCode.UNKNOWN)
        } finally {
            tempDir.deleteRecursively()
        }
    }

    /**
     * Runs yt-dlp. Returns its error output (null if it finished cleanly).
     * If the work is cancelled, the yt-dlp process tree is killed.
     */
    private suspend fun runYtDlp(url: String, outputDir: File, cookies: File?): String? {
        val processId = id.toString()
        val request = YoutubeDLRequest(url).apply {
            YtDlpOptions.arguments(outputDir, cookies).forEach { (option, value) ->
                if (value == null) addOption(option) else addOption(option, value)
            }
        }
        return coroutineScope {
            val run = async(Dispatchers.IO) {
                try {
                    YoutubeDL.getInstance().execute(request, processId) { progress, _, line ->
                        onOutput(progress, line)
                    }
                    null
                } catch (e: YoutubeDL.CanceledException) {
                    null // Killed because the work was cancelled.
                } catch (e: YoutubeDLException) {
                    e.message.orEmpty()
                }
            }
            try {
                run.await()
            } catch (e: CancellationException) {
                YoutubeDL.getInstance().destroyProcessById(processId)
                throw e
            }
        }
    }

    /** Called by yt-dlp for every output line (on a background thread). */
    private fun onOutput(progress: Float, line: String) {
        var itemChanged = false
        ITEM_LINE.find(line)?.let { match ->
            item = match.groupValues[1].toIntOrNull()
            itemCount = match.groupValues[2].toIntOrNull()
            lastPercent = -1
            itemChanged = true
        }
        val percent = if (progress >= 0) progress.toInt().coerceIn(0, 100) else lastPercent
        val now = SystemClock.elapsedRealtime()
        val changed = itemChanged || (percent != lastPercent && percent >= 0)
        if (!changed || (!itemChanged && now - lastUpdateAt < MIN_UPDATE_INTERVAL_MS && percent < 100)) return
        lastPercent = percent
        lastUpdateAt = now

        val data = Data.Builder().putString(P_PHASE, PHASE_DOWNLOADING)
        if (percent >= 0) data.putDouble(P_PROGRESS, progress.toDouble().coerceIn(0.0, 100.0))
        item?.let { data.putInt(P_ITEM, it) }
        itemCount?.let { data.putInt(P_ITEM_COUNT, it) }
        setProgressAsync(data.build())

        val detail = if ((itemCount ?: 0) > 1 && item != null) texts.item(item!!, itemCount!!) else null
        notifications.updateProgress(id, texts.downloading, detail, percent.takeIf { it >= 0 })
    }

    private fun failure(code: ErrorCode): Result {
        notifications.showFailure()
        return Result.failure(workDataOf(O_ERROR to code.name))
    }
}
