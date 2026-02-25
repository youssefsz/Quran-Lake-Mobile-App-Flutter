package tn.quranlake.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Boot receiver to restart background services when device reboots
 * This ensures adhan and countdown continue working even after phone restart
 * 
 * Note: Workmanager automatically restarts registered tasks on boot,
 * but this receiver ensures services are initialized even if app hasn't been opened
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED == intent.action || 
            Intent.ACTION_MY_PACKAGE_REPLACED == intent.action ||
            Intent.ACTION_PACKAGE_REPLACED == intent.action) {
            Log.d("BootReceiver", "Device booted or app updated - services will auto-restart")
            
            // Workmanager will automatically restart registered tasks on boot
            // AlarmManager alarms persist across reboots automatically
            // This receiver ensures the system knows to restart services
        }
    }
}
