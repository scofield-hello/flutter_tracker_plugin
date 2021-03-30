package com.chuangdun.flutter.plugin.tracker

import android.annotation.TargetApi
import android.app.*
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Build
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationCompat.BigTextStyle
import org.json.JSONObject
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.ThreadFactory
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit


class TrackerCommand {
    companion object {
        const val ON = 1
        const val OFF = 0
    }
}

class TrackerService : Service(), LocationTracker.LocationCallback {
    companion object {
        private const val TAG = "TrackerService"
        private const val NOTIFICATION_ID = 10024
        private const val DEFAULT_NOTIFICATION_CHANNEL_ID = "tracker_service"
        private const val DEFAULT_NOTIFICATION_CHANNEL_NAME = "位置服务"
        private const val DEFAULT_NOTIFICATION_DESCRIPTION = DEFAULT_NOTIFICATION_CHANNEL_NAME
        private const val DEFAULT_NOTIFICATION_TITLE = "后台服务正在运行中"
        private const val DEFAULT_NOTIFICATION_CONTENT = "后台服务正在运行中..."
    }

    private var minDistance = 0.0f
    private var minTimeInterval = 300
    private var isDestroy = false
    private lateinit var postUrl: String
    private lateinit var headers: JSONObject
    private lateinit var extraBody: JSONObject
    private lateinit var notificationTitle: String
    private lateinit var notificationContent: String
    private lateinit var mGpsTracker: LocationTracker
    private val threadPool = ThreadPoolExecutor(1,
            1,
            0L,
            TimeUnit.MINUTES,
            LinkedBlockingQueue(),
            ThreadFactory { r -> Thread(r, "tracker_upload_thread") })

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        mGpsTracker = LocationTracker(this, this)
        Log.i(TAG, "位置跟踪服务组件已创建.")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent!!.getIntExtra("command", TrackerCommand.OFF)) {
            TrackerCommand.ON -> {
                Log.i(TAG, "正在开启位置跟踪服务组件...")
                postUrl = intent.getStringExtra("postUrl")!!
                headers = JSONObject(intent.getStringExtra("headers")!!)
                extraBody = JSONObject(intent.getStringExtra("extraBody")!!)
                minDistance = intent.getFloatExtra("minDistance", 0.0f)
                minTimeInterval = intent.getIntExtra("minTimeInterval", 300)
                notificationTitle = intent.getStringExtra("notificationTitle")!!
                notificationContent = intent.getStringExtra("notificationContent")!!
                Log.d(TAG, "postUrl:$postUrl")
                Log.d(TAG, "headers: $headers")
                Log.d(TAG, "extraBody: $extraBody")
                Log.d(TAG, "minTimeInterval: $minTimeInterval 秒")
                Log.d(TAG, "minDistance: $minDistance 米")
                Log.d(TAG, "notificationTitle: $notificationTitle")
                Log.d(TAG, "notificationContent: $notificationContent")
                mGpsTracker.minDistance = minDistance * 1000L
                mGpsTracker.minTimeIntervalInMillSecond = minTimeInterval * 1000L
                createNotification(this, notificationTitle, notificationContent)
                track(true)
                Log.i(TAG, "位置跟踪服务组件已开启.")
            }
            TrackerCommand.OFF -> {
                Log.i(TAG, "正在关闭位置跟踪服务组件...")
                createNotification(this,
                        DEFAULT_NOTIFICATION_TITLE,
                        DEFAULT_NOTIFICATION_CONTENT)
                track(false)
                stopForeground(true)
                stopSelf()
            }
        }
        return START_REDELIVER_INTENT
    }

    private fun createNotification(context: Service,
                                   notificationTitle: String,
                                   notificationContent: String) {
        if (VERSION.SDK_INT < VERSION_CODES.O) {
            createNotificationPreO(context, notificationTitle, notificationContent)
        } else {
            createNotificationO(context, notificationTitle, notificationContent)
        }
    }

    @TargetApi(26)
    fun createNotificationO(context: Service,
                            notificationTitle: String,
                            notificationContent: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val importance = NotificationManager.IMPORTANCE_DEFAULT
        val notificationChannel = NotificationChannel(DEFAULT_NOTIFICATION_CHANNEL_ID,
                DEFAULT_NOTIFICATION_CHANNEL_NAME, importance)
        notificationChannel.description = DEFAULT_NOTIFICATION_DESCRIPTION
        notificationManager.createNotificationChannel(notificationChannel)
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val piLaunchMainActivity = PendingIntent.getActivity(context,
                10001, intent, PendingIntent.FLAG_UPDATE_CURRENT)
        val notification = Notification.Builder(context, DEFAULT_NOTIFICATION_CHANNEL_ID)
                .setContentTitle(notificationTitle)
                .setContentText(notificationContent)
                .setContentIntent(piLaunchMainActivity)
                .setStyle(Notification.BigTextStyle())
                .build()
        context.startForeground(
                NOTIFICATION_ID, notification)
    }

    @TargetApi(25)
    fun createNotificationPreO(context: Service,
                               notificationTitle: String,
                               notificationContent: String) {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val piLaunchMainActivity = PendingIntent.getActivity(context,
                10001, intent, PendingIntent.FLAG_UPDATE_CURRENT)
        val mNotification: Notification = NotificationCompat.Builder(context)
                .setContentTitle(notificationTitle)
                .setContentText(notificationContent)
                .setContentIntent(piLaunchMainActivity)
                .setStyle(BigTextStyle())
                .build()
        context.startForeground(NOTIFICATION_ID, mNotification)
    }

    private fun track(start: Boolean) {
        if (start) {
            if (mGpsTracker.isStart()) {
                mGpsTracker.stop()
            }
            mGpsTracker.start()
        } else {
            if (mGpsTracker.isStart()) {
                mGpsTracker.stop()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        threadPool.shutdown()
        isDestroy = true
        Log.i(TAG, "位置跟踪服务组件已销毁.")
    }

    override fun onLocationChanged(location: Location) {
        Log.d(TAG, "onLocationChanged: 获取到位置信息:$location")
        val uploadTask = UploadTask(
                status = UploadTask.Status.LOCATION,
                postUrl = postUrl,
                latitude = location.latitude,
                longitude = location.longitude,
                timestamp = location.time,
                provider = location.provider,
                deviceBrand = Build.BRAND,
                deviceModel = Build.MODEL,
                systemVersion = VERSION.SDK_INT,
                headers = headers,
                extraBody = extraBody
        )
        if (!isDestroy){
            threadPool.submit(uploadTask)
        }
    }

    override fun onNotAvailable() {
        val uploadTask = UploadTask(
                status = UploadTask.Status.NOT_AVAILABLE,
                postUrl = postUrl,
                latitude = 0.0,
                longitude = 0.0,
                timestamp = System.currentTimeMillis(),
                provider = "gps",
                deviceBrand = Build.BRAND,
                deviceModel = Build.MODEL,
                systemVersion = VERSION.SDK_INT,
                headers = headers,
                extraBody = extraBody
        )
        threadPool.submit(uploadTask)
    }

    override fun onPermissionDenied() {
        val uploadTask = UploadTask(
                status = UploadTask.Status.PERMISSION_DENIED,
                postUrl = postUrl,
                latitude = 0.0,
                longitude = 0.0,
                timestamp = System.currentTimeMillis(),
                provider = "gps",
                deviceBrand = Build.BRAND,
                deviceModel = Build.MODEL,
                systemVersion = VERSION.SDK_INT,
                headers = headers,
                extraBody = extraBody
        )
        threadPool.submit(uploadTask)
    }
}