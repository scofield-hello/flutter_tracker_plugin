package com.chuangdun.flutter.plugin.tracker

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.*
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class TrackerManager {
    companion object{
        private const val TAG = "TrackerManager"
        private const val UNIQUE_WORK_NAME = "TrackerServiceLauncher"
        @JvmStatic
        fun start(context: Context, postUrl:String, headers:Map<String, String>,
                  extraBody:Map<String, String>, minTimeInterval: Int, minDistance: Float,
                  notificationTitle:String, notificationContent:String){
            val params = Data.Builder()
                    .putString("postUrl", postUrl)
                    .putString("headers", JSONObject(headers).toString(4))
                    .putString("extraBody", JSONObject(extraBody).toString(4))
                    .putString("notificationTitle", notificationTitle)
                    .putString("notificationContent", notificationContent)
                    .putInt("minTimeInterval", minTimeInterval)
                    .putFloat("minDistance", minDistance)
                    .build()
            val constraints = Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            val workRequest = PeriodicWorkRequest.Builder(
                    ServiceLauncher::class.java, 15, TimeUnit.MINUTES)
                    .setInputData(params)
                    .setConstraints(constraints)
                    .build()
            WorkManager.getInstance(context)
                    .enqueueUniquePeriodicWork(UNIQUE_WORK_NAME,
                            ExistingPeriodicWorkPolicy.REPLACE, workRequest)
            Log.i(TAG, "位置跟踪定时任务已开启.")
        }

        @JvmStatic
        fun shutdown(context: Context){
            val intent = Intent(context, TrackerService::class.java)
            intent.putExtra("command", TrackerCommand.OFF)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                context.startService(intent)
            } else {
                context.startForegroundService(intent)
            }
            WorkManager.getInstance(context).cancelUniqueWork(UNIQUE_WORK_NAME)
            Log.i(TAG, "位置跟踪定时任务已取消.")
        }
    }
}