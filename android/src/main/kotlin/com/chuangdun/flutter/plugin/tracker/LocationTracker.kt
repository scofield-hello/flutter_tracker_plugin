package com.chuangdun.flutter.plugin.tracker

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Criteria
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.content.ContextCompat
import io.reactivex.processors.PublishProcessor
import java.util.concurrent.TimeUnit

class LocationTracker(private val context: Context, private val callback: LocationCallback) : LocationListener {

    var minDistance = 0.0f
    var minTimeIntervalInMillSecond = 300000L
    private var isStart = false
    private var mProvider: String? = null
    private var lastLocationTime = 0L
    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private val publisher = PublishProcessor.create<Location>()
    init {
        //2秒内如果多次上传位置，使用之后一次的位置
        publisher.throttleLast(5,TimeUnit.SECONDS)
                .subscribe {  it -> callback?.onLocationChanged(it)}
    }
    companion object {
        private const val TAG = "LocationTracker"
    }

    override fun onLocationChanged(location: Location?) {
        if (location == null) {
            return
        }
        if (outRangeOfChina(location.latitude, location.longitude)){
            Log.d(TAG, "位置超出中国范围,可能出现漂移，该位置信息被丢弃")
            return
        }
        val timeSpan = location.time - lastLocationTime
        if (timeSpan >= minTimeIntervalInMillSecond) {
            lastLocationTime = location.time
            publisher.onNext(location)
        } else {
            Log.d(TAG, "位置变化过于频繁,该位置信息被丢弃")
        }
    }

    override fun onStatusChanged(provider: String, status: Int, extras: Bundle) {
        restart()
    }

    override fun onProviderEnabled(provider: String?) {
        restart()
    }

    override fun onProviderDisabled(provider: String?) {
        restart()
    }

    private fun restart() {
        val newBestProvider = getBestProvider()
        if (newBestProvider == null) {
            if (isStart) {
                stop()
            }
            callback.onNotAvailable()
            return
        }
        if (newBestProvider != mProvider) {
            if (isStart) {
                stop()
                start()
            }
        }
    }

    fun start() {
        val permissions = mutableListOf(
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_FINE_LOCATION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            permissions.add(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        }
        val notGrantedPermissions = permissions.filterNot {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
        if (notGrantedPermissions.isNotEmpty()) {
            callback.onPermissionDenied()
            return
        }
        if (!isStart) {
            mProvider = getBestProvider()
            if (mProvider == null) {
                return
            }
            locationManager.requestLocationUpdates(mProvider,
                    minTimeIntervalInMillSecond, minDistance, this)
            isStart = true
            Log.i(TAG, "定位已开始: $mProvider")
        }
    }

    fun stop() {
        if (isStart) {
            locationManager.removeUpdates(this)
            lastLocationTime = 0L
            isStart = false
            Log.i(TAG, "定位已停止")
        }
    }

    fun isStart(): Boolean {
        return isStart
    }

    private fun getBestProvider(): String? {
        val criteria = Criteria().apply {
            isCostAllowed = true
            isSpeedRequired = false
            isBearingRequired = false
            isAltitudeRequired = false
            accuracy = Criteria.ACCURACY_MEDIUM
            powerRequirement = Criteria.POWER_MEDIUM
        }
        return locationManager.getBestProvider(criteria, true)
    }

    private fun outRangeOfChina(latitude:Double, longitude:Double): Boolean{
        if(longitude < 72.004 || longitude > 137.8347){
            return true
        }
        if(latitude < 0.8293 || latitude > 55.8271){
            return true
        }
        return false
    }

    interface LocationCallback {
        fun onLocationChanged(location: Location)
        fun onNotAvailable()
        fun onPermissionDenied()
    }
}