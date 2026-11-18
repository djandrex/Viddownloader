package io.github.djandrex.viddownloader.download

import androidx.work.Data

/**
 * Notification texts, already translated by Flutter into the app language.
 * They travel with the WorkManager job so the worker can use them even if the
 * UI is closed.
 */
data class DownloadTexts(
    val channelName: String = "Downloads",
    val downloading: String = "Downloading video…",
    val itemPattern: String = "Video {current} of {total}",
    val saving: String = "Saving to the gallery…",
    val successSingle: String = "Video saved to your gallery",
    val successMultiplePattern: String = "{count} videos saved to your gallery",
    val failed: String = "Download failed",
    val canceled: String = "Download canceled.",
    val cancelAction: String = "Cancel",
) {
    fun item(current: Int, total: Int): String =
        itemPattern.replace("{current}", current.toString()).replace("{total}", total.toString())

    fun success(count: Int): String =
        if (count <= 1) successSingle else successMultiplePattern.replace("{count}", count.toString())

    fun toData(builder: Data.Builder): Data.Builder = builder
        .putString(K_CHANNEL, channelName)
        .putString(K_DOWNLOADING, downloading)
        .putString(K_ITEM, itemPattern)
        .putString(K_SAVING, saving)
        .putString(K_SUCCESS_SINGLE, successSingle)
        .putString(K_SUCCESS_MULTI, successMultiplePattern)
        .putString(K_FAILED, failed)
        .putString(K_CANCELED, canceled)
        .putString(K_CANCEL_ACTION, cancelAction)

    companion object {
        private const val K_CHANNEL = "t_channel"
        private const val K_DOWNLOADING = "t_downloading"
        private const val K_ITEM = "t_item"
        private const val K_SAVING = "t_saving"
        private const val K_SUCCESS_SINGLE = "t_success_single"
        private const val K_SUCCESS_MULTI = "t_success_multi"
        private const val K_FAILED = "t_failed"
        private const val K_CANCELED = "t_canceled"
        private const val K_CANCEL_ACTION = "t_cancel_action"

        /** Builds texts from the map sent by Flutter; missing keys keep English defaults. */
        fun fromMap(map: Map<*, *>?): DownloadTexts {
            val d = DownloadTexts()
            fun get(key: String, fallback: String) = (map?.get(key) as? String)?.takeIf { it.isNotBlank() } ?: fallback
            return DownloadTexts(
                channelName = get("channelName", d.channelName),
                downloading = get("downloading", d.downloading),
                itemPattern = get("itemPattern", d.itemPattern),
                saving = get("saving", d.saving),
                successSingle = get("successSingle", d.successSingle),
                successMultiplePattern = get("successMultiplePattern", d.successMultiplePattern),
                failed = get("failed", d.failed),
                canceled = get("canceled", d.canceled),
                cancelAction = get("cancelAction", d.cancelAction),
            )
        }

        fun fromData(data: Data): DownloadTexts {
            val d = DownloadTexts()
            return DownloadTexts(
                channelName = data.getString(K_CHANNEL) ?: d.channelName,
                downloading = data.getString(K_DOWNLOADING) ?: d.downloading,
                itemPattern = data.getString(K_ITEM) ?: d.itemPattern,
                saving = data.getString(K_SAVING) ?: d.saving,
                successSingle = data.getString(K_SUCCESS_SINGLE) ?: d.successSingle,
                successMultiplePattern = data.getString(K_SUCCESS_MULTI) ?: d.successMultiplePattern,
                failed = data.getString(K_FAILED) ?: d.failed,
                canceled = data.getString(K_CANCELED) ?: d.canceled,
                cancelAction = data.getString(K_CANCEL_ACTION) ?: d.cancelAction,
            )
        }
    }
}
