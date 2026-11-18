package io.github.djandrex.viddownloader.auth

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Build
import android.os.Bundle
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.LinearLayout
import android.widget.Toolbar
import android.window.OnBackInvokedDispatcher

/**
 * Optional Instagram login in a WebView. As soon as Instagram sets the
 * `sessionid` cookie, the cookies are saved for yt-dlp and the screen closes
 * with RESULT_OK. The password never touches our code: it is typed into
 * Instagram's own web page.
 */
class InstagramLoginActivity : Activity() {
    companion object {
        const val EXTRA_TITLE = "title"
        private const val LOGIN_URL = "https://www.instagram.com/accounts/login/"
    }

    private lateinit var webView: WebView
    private var saved = false

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val toolbar = Toolbar(this).apply {
            title = intent.getStringExtra(EXTRA_TITLE) ?: "Instagram"
            setNavigationIcon(android.R.drawable.ic_menu_close_clear_cancel)
            setNavigationOnClickListener { finish() }
        }

        val cookies = CookieManager.getInstance()
        cookies.setAcceptCookie(true)

        webView = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            cookies.setAcceptThirdPartyCookies(this, true)
            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView, url: String?) {
                    super.onPageFinished(view, url)
                    trySaveSession()
                }
            }
        }
        // fitsSystemWindows keeps the toolbar and page clear of the status and
        // navigation bars (apps are drawn edge-to-edge on Android 15+).
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            fitsSystemWindows = true
            addView(toolbar, LinearLayout.LayoutParams(MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
            addView(webView, LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f))
        }
        setContentView(root)
        if (savedInstanceState == null) {
            webView.loadUrl(LOGIN_URL)
        } else {
            webView.restoreState(savedInstanceState)
        }

        // Back goes back inside Instagram's pages before closing the screen.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT,
            ) { goBackOrFinish() }
        }
    }

    private fun goBackOrFinish() {
        if (webView.canGoBack()) webView.goBack() else finish()
    }

    private fun trySaveSession() {
        if (saved) return
        CookieManager.getInstance().flush()
        if (CookieStore.saveFromWebView(this)) {
            saved = true
            setResult(RESULT_OK)
            finish()
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        webView.saveState(outState)
    }

    @Deprecated("Used only before Android 13; newer versions use onBackInvokedDispatcher.")
    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        goBackOrFinish()
    }

    override fun onDestroy() {
        webView.destroy()
        super.onDestroy()
    }
}
