package io.github.djandrex.viddownloader

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.github.djandrex.viddownloader.bridge.DownloaderChannel

/**
 * Single activity (launchMode="singleTask"): sharing from Instagram while the
 * app is open arrives in [onNewIntent] instead of creating a second copy.
 */
class MainActivity : FlutterActivity() {
    private var channel: DownloaderChannel? = null

    /** Shared text read in onCreate, handed to the channel once it exists. */
    private var initialSharedText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        initialSharedText = consumeSharedText(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = DownloaderChannel(this, flutterEngine.dartExecutor.binaryMessenger).also {
            it.setInitialSharedText(initialSharedText)
        }
        initialSharedText = null
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel?.dispose()
        channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        consumeSharedText(intent)?.let { channel?.deliverSharedText(it) }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (channel?.onPermissionsResult(requestCode, permissions, grantResults) != true) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    @Deprecated("Deprecated in Java")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (channel?.onActivityResult(requestCode, resultCode) != true) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    /**
     * Returns the text shared by another app and clears it from the intent, so
     * it is handled only once (not again if the activity is recreated or
     * reopened from the recent apps list).
     */
    private fun consumeSharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND || intent.type?.startsWith("text/") != true) return null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
        intent.action = Intent.ACTION_MAIN
        intent.removeExtra(Intent.EXTRA_TEXT)
        setIntent(intent)
        return text?.takeIf { it.isNotBlank() }
    }
}
