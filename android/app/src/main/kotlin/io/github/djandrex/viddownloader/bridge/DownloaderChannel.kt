package io.github.djandrex.viddownloader.bridge

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import androidx.lifecycle.Observer
import androidx.work.ExistingWorkPolicy
import androidx.work.WorkInfo
import androidx.work.WorkManager
import com.yausername.youtubedl_android.YoutubeDL
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.github.djandrex.viddownloader.auth.CookieStore
import io.github.djandrex.viddownloader.auth.InstagramLoginActivity
import io.github.djandrex.viddownloader.download.DownloadTexts
import io.github.djandrex.viddownloader.download.DownloadWorker
import io.github.djandrex.viddownloader.download.ErrorCode
import io.github.djandrex.viddownloader.engine.Engine
import io.github.djandrex.viddownloader.engine.EngineBusyException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.UUID

/**
 * Connects Flutter with the native code:
 * - MethodChannel `.../downloader`: commands (see lib/services/downloader_bridge.dart).
 * - EventChannel `.../progress`: download status, read from WorkManager.
 */
class DownloaderChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "io.github.djandrex.viddownloader/downloader"
        const val EVENT_CHANNEL = "io.github.djandrex.viddownloader/progress"
        const val REQUEST_PERMISSIONS = 4101
        const val REQUEST_LOGIN = 4102
        private const val PREFS = "viddownloader_native"
        private const val PREF_ASKED_NOTIFICATIONS = "asked_notifications"

        /**
         * Work IDs whose final state should be shown. Old finished jobs that
         * WorkManager still remembers are ignored, so a past result does not
         * pop up when the app is opened.
         */
        private val trackedWork = mutableSetOf<UUID>()
    }

    private val context: Context = activity.applicationContext
    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val workManager = WorkManager.getInstance(context)
    private val workInfos = workManager.getWorkInfosForUniqueWorkLiveData(DownloadWorker.UNIQUE_NAME)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var events: EventChannel.EventSink? = null
    private var pendingSharedText: String? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var permissionsIncludeStorage = false
    private var pendingLoginResult: MethodChannel.Result? = null

    private val workObserver = Observer<List<WorkInfo>> { infos ->
        latestInfo(infos)?.let { info -> toEvent(info)?.let { events?.success(it) } }
    }

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        workInfos.removeObserver(workObserver)
        scope.cancel()
    }

    // ---------------------------------------------------------------- Sharing

    /** Text shared from Instagram when the app was launched (cold start). */
    fun setInitialSharedText(text: String?) {
        pendingSharedText = text
    }

    /** Text shared while the app was already open. */
    fun deliverSharedText(text: String) {
        methodChannel.invokeMethod("onSharedText", text)
    }

    // --------------------------------------------------------- Method channel

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInitialSharedText" -> {
                result.success(pendingSharedText)
                pendingSharedText = null
            }
            "startDownload" -> startDownload(call, result)
            "cancelDownload" -> cancelDownload(result)
            "getCurrentStatus" -> getCurrentStatus(result)
            "requestPermissions" -> requestPermissions(result)
            "openVideo" -> openVideo(call.argument<String>("uri"), result)
            "shareVideos" -> shareVideos(call.argument<List<String>>("uris").orEmpty(), result)
            "getEngineVersion" -> scope.launch {
                result.success(runCatching { Engine.version(context) }.getOrNull())
            }
            "updateEngine" -> updateEngine(result)
            "getAppVersion" -> result.success(appVersion())
            "isLoggedIn" -> result.success(CookieStore.isLoggedIn(context))
            "login" -> login(call.argument<String>("title"), result)
            "logout" -> {
                CookieStore.clear(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun startDownload(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url")
        if (url.isNullOrBlank()) {
            result.error(ErrorCode.INVALID_URL.name, "Missing url", null)
            return
        }
        val texts = DownloadTexts.fromMap(call.argument<Map<String, Any?>>("texts"))
        scope.launch {
            val running = currentWork().any { !it.state.isFinished }
            if (running) {
                result.error(ErrorCode.BUSY.name, "A download is already running", null)
                return@launch
            }
            val request = DownloadWorker.request(url, texts)
            trackedWork += request.id
            workManager.enqueueUniqueWork(DownloadWorker.UNIQUE_NAME, ExistingWorkPolicy.REPLACE, request)
            result.success(null)
        }
    }

    private fun cancelDownload(result: MethodChannel.Result) {
        // The worker kills the yt-dlp process when its job is cancelled.
        workManager.cancelUniqueWork(DownloadWorker.UNIQUE_NAME)
        result.success(null)
    }

    private fun getCurrentStatus(result: MethodChannel.Result) {
        scope.launch {
            val info = latestInfo(currentWork())
            // Only report a running download (to re-attach after reopening).
            result.success(info?.takeIf { !it.state.isFinished }?.let { toEvent(it) })
        }
    }

    private fun updateEngine(result: MethodChannel.Result) {
        scope.launch {
            try {
                val updated = Engine.update(context)
                result.success(
                    mapOf(
                        "status" to if (updated) "DONE" else "ALREADY_UP_TO_DATE",
                        "version" to Engine.version(context),
                    ),
                )
            } catch (e: EngineBusyException) {
                result.error("BUSY", e.message, null)
            } catch (e: Exception) {
                result.error("UPDATE_FAILED", e.message, null)
            }
        }
    }

    // ------------------------------------------------------------ Permissions

    /**
     * Android 13+: notifications (asked only once; downloads work without it).
     * Android 8–9: storage, required to save to the gallery.
     */
    private fun requestPermissions(result: MethodChannel.Result) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val needed = mutableListOf<String>()
        permissionsIncludeStorage = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !granted(Manifest.permission.POST_NOTIFICATIONS) &&
            !prefs.getBoolean(PREF_ASKED_NOTIFICATIONS, false)
        ) {
            needed += Manifest.permission.POST_NOTIFICATIONS
            prefs.edit().putBoolean(PREF_ASKED_NOTIFICATIONS, true).apply()
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            !granted(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        ) {
            needed += Manifest.permission.WRITE_EXTERNAL_STORAGE
            permissionsIncludeStorage = true
        }

        if (needed.isEmpty() || pendingPermissionResult != null) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        activity.requestPermissions(needed.toTypedArray(), REQUEST_PERMISSIONS)
    }

    /** Forwarded from MainActivity.onRequestPermissionsResult. */
    fun onPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_PERMISSIONS) return false
        val result = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        val storageOk = !permissionsIncludeStorage ||
            permissions.indices.any {
                permissions[it] == Manifest.permission.WRITE_EXTERNAL_STORAGE &&
                    grantResults.getOrNull(it) == PackageManager.PERMISSION_GRANTED
            }
        result.success(storageOk)
        return true
    }

    private fun granted(permission: String) =
        ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED

    // ------------------------------------------------------------ Open/Share

    private fun openVideo(uri: String?, result: MethodChannel.Result) {
        if (uri == null) {
            result.success(false)
            return
        }
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(Uri.parse(uri), "video/*")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        try {
            activity.startActivity(intent)
            result.success(true)
        } catch (e: ActivityNotFoundException) {
            result.success(false)
        }
    }

    private fun shareVideos(uris: List<String>, result: MethodChannel.Result) {
        if (uris.isEmpty()) {
            result.success(null)
            return
        }
        val parsed = ArrayList(uris.map(Uri::parse))
        val send = if (parsed.size == 1) {
            Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_STREAM, parsed.first())
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).putParcelableArrayListExtra(Intent.EXTRA_STREAM, parsed)
        }
        send.setType("video/mp4").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        activity.startActivity(Intent.createChooser(send, null))
        result.success(null)
    }

    // ------------------------------------------------------------------ Login

    private fun login(title: String?, result: MethodChannel.Result) {
        if (pendingLoginResult != null) {
            result.success(false)
            return
        }
        pendingLoginResult = result
        val intent = Intent(activity, InstagramLoginActivity::class.java)
            .putExtra(InstagramLoginActivity.EXTRA_TITLE, title)
        @Suppress("DEPRECATION")
        activity.startActivityForResult(intent, REQUEST_LOGIN)
    }

    /** Forwarded from MainActivity.onActivityResult. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_LOGIN) return false
        pendingLoginResult?.success(resultCode == Activity.RESULT_OK && CookieStore.isLoggedIn(context))
        pendingLoginResult = null
        return true
    }

    // ---------------------------------------------------------- Event channel

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        events = sink
        mainHandler.post { workInfos.observeForever(workObserver) }
    }

    override fun onCancel(arguments: Any?) {
        events = null
        mainHandler.post { workInfos.removeObserver(workObserver) }
    }

    /** Reads the jobs of the unique download queue off the main thread. */
    private suspend fun currentWork(): List<WorkInfo> = withContext(Dispatchers.IO) {
        runCatching {
            workManager.getWorkInfosForUniqueWork(DownloadWorker.UNIQUE_NAME).get()
        }.getOrDefault(emptyList())
    }

    /** The current (most relevant) job: the running one, else the newest. */
    private fun latestInfo(infos: List<WorkInfo>): WorkInfo? =
        infos.firstOrNull { !it.state.isFinished } ?: infos.lastOrNull()

    /** Converts a WorkInfo into the map Flutter expects (DownloadStatus.fromMap). */
    private fun toEvent(info: WorkInfo): Map<String, Any?>? {
        if (!info.state.isFinished) {
            trackedWork += info.id // Seen running: show its final result later.
        } else if (info.id !in trackedWork) {
            return null // Old result from a previous session.
        }
        return when (info.state) {
            WorkInfo.State.ENQUEUED, WorkInfo.State.BLOCKED ->
                mapOf("phase" to DownloadWorker.PHASE_PREPARING)
            WorkInfo.State.RUNNING -> {
                val p = info.progress
                mapOf(
                    "phase" to (p.getString(DownloadWorker.P_PHASE) ?: DownloadWorker.PHASE_PREPARING),
                    "progress" to p.getDouble(DownloadWorker.P_PROGRESS, -1.0),
                    "item" to p.getInt(DownloadWorker.P_ITEM, 0).takeIf { it > 0 },
                    "itemCount" to p.getInt(DownloadWorker.P_ITEM_COUNT, 0).takeIf { it > 0 },
                )
            }
            WorkInfo.State.SUCCEEDED -> mapOf(
                "phase" to "success",
                "uris" to info.outputData.getStringArray(DownloadWorker.O_URIS)?.toList().orEmpty(),
            )
            WorkInfo.State.FAILED -> mapOf(
                "phase" to "error",
                "errorCode" to (info.outputData.getString(DownloadWorker.O_ERROR) ?: ErrorCode.UNKNOWN.name),
            )
            WorkInfo.State.CANCELLED -> mapOf("phase" to "canceled")
        }
    }

    private fun appVersion(): String {
        val info = context.packageManager.getPackageInfo(context.packageName, 0)
        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        return "${info.versionName} ($code)"
    }
}
