package io.github.djandrex.viddownloader.download

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import kotlin.coroutines.resume

/** Copies a finished MP4 from the temporary folder into the gallery. */
object MediaSaver {
    const val FOLDER = "Viddownloader"

    /** @return the `content://` URI of the saved video (for Open/Share). */
    suspend fun save(context: Context, file: File): Uri = withContext(Dispatchers.IO) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveWithMediaStore(context, file)
        } else {
            saveLegacy(context, file)
        }
    }

    /** Android 10+: no storage permission needed. */
    private fun saveWithMediaStore(context: Context, file: File): Uri {
        val resolver = context.contentResolver
        val now = System.currentTimeMillis()
        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, file.name)
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            put(MediaStore.Video.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MOVIES}/$FOLDER")
            put(MediaStore.Video.Media.DATE_TAKEN, now)
            // Hidden from other apps until the copy is complete.
            put(MediaStore.Video.Media.IS_PENDING, 1)
        }
        val collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = resolver.insert(collection, values) ?: throw IOException("MediaStore insert failed")
        try {
            resolver.openOutputStream(uri)?.use { out ->
                file.inputStream().use { it.copyTo(out) }
            } ?: throw IOException("Cannot open output stream")
            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
    }

    /** Android 8–9: needs WRITE_EXTERNAL_STORAGE (requested at runtime). */
    @Suppress("DEPRECATION")
    private suspend fun saveLegacy(context: Context, file: File): Uri {
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), FOLDER)
        if (!dir.isDirectory && !dir.mkdirs()) throw IOException("Cannot create $dir")
        val target = uniqueFile(dir, file.name)
        file.copyTo(target)
        target.setLastModified(System.currentTimeMillis())
        // The scanner adds the file to the gallery and gives us a content:// URI.
        return suspendCancellableCoroutine { cont ->
            MediaScannerConnection.scanFile(context, arrayOf(target.absolutePath), arrayOf("video/mp4")) { _, uri ->
                if (uri != null) {
                    cont.resume(uri)
                } else {
                    cont.resumeWith(Result.failure(IOException("Media scan failed for $target")))
                }
            }
        }
    }

    /** Adds " (1)", " (2)"... if a file with the same name already exists. */
    private fun uniqueFile(dir: File, name: String): File {
        var candidate = File(dir, name)
        var index = 1
        while (candidate.exists()) {
            candidate = File(dir, "${name.substringBeforeLast('.')} ($index).${name.substringAfterLast('.')}")
            index++
        }
        return candidate
    }
}
