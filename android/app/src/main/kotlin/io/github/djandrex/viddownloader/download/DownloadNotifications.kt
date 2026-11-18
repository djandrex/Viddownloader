package io.github.djandrex.viddownloader.download

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.ForegroundInfo
import androidx.work.WorkManager
import io.github.djandrex.viddownloader.MainActivity
import io.github.djandrex.viddownloader.R
import java.util.UUID

/** Builds the progress notification (foreground) and the final one. */
class DownloadNotifications(private val context: Context, private val texts: DownloadTexts) {
    companion object {
        const val CHANNEL_ID = "downloads"
        const val PROGRESS_ID = 1001
        const val RESULT_ID = 1002
    }

    private val manager = NotificationManagerCompat.from(context)

    init {
        // Creating the channel again with a new name renames it (language change).
        val channel = NotificationChannel(CHANNEL_ID, texts.channelName, NotificationManager.IMPORTANCE_LOW)
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    /** Ongoing notification shown while the worker runs in the foreground. */
    fun foregroundInfo(workId: UUID, title: String, detail: String?, percent: Int?): ForegroundInfo {
        val cancelIntent = WorkManager.getInstance(context).createCancelPendingIntent(workId)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_download)
            .setContentTitle(title)
            .setContentText(detail)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setContentIntent(openAppIntent())
            .setProgress(100, percent ?: 0, percent == null)
            .addAction(0, texts.cancelAction, cancelIntent)
            .build()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(PROGRESS_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(PROGRESS_ID, notification)
        }
    }

    /** Updates the ongoing notification (progress changes). */
    fun updateProgress(workId: UUID, title: String, detail: String?, percent: Int?) {
        if (!canNotify()) return
        @Suppress("MissingPermission")
        manager.notify(PROGRESS_ID, foregroundInfo(workId, title, detail, percent).notification)
    }

    /** Final notification: tapping it opens the first saved video. */
    fun showSuccess(uris: List<Uri>) {
        val open = uris.firstOrNull()?.let { uri ->
            val view = Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "video/*")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            PendingIntent.getActivity(context, 1, view, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        } ?: openAppIntent()
        showResult(texts.success(uris.size), open)
    }

    fun showFailure() = showResult(texts.failed, openAppIntent())

    fun showCanceled() = showResult(texts.canceled, openAppIntent())

    private fun showResult(title: String, contentIntent: PendingIntent) {
        if (!canNotify()) return
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_download)
            .setContentTitle(title)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .build()
        @Suppress("MissingPermission")
        manager.notify(RESULT_ID, notification)
    }

    private fun openAppIntent(): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    private fun canNotify(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
}
