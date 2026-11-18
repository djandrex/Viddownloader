package io.github.djandrex.viddownloader

import android.app.Application
import io.github.djandrex.viddownloader.engine.Engine

/** Starts preparing the download engine as soon as the app process starts. */
class ViddownloaderApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Engine.initInBackground(this)
    }
}
