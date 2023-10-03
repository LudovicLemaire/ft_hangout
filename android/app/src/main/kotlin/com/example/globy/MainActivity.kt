package com.example.globy

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.os.Bundle
import android.telephony.SmsManager
import android.app.Activity
import androidx.core.app.ActivityCompat
import android.Manifest
import android.net.Uri
import android.provider.ContactsContract
import android.content.pm.PackageManager

class MainActivity: FlutterActivity() {
  private val CHANNEL = "samples.flutter.dev/main_channel"

	private fun getBatteryLevel(): Int {
		val batteryLevel: Int
		if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
			val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
			batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
		} else {
			val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
			batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
		}

		return batteryLevel
	}

	private fun sendSMS(phoneNo: String?, msg: String?, result: MethodChannel.Result) {
		try {
			val smsManager:SmsManager
			if (VERSION.SDK_INT >= 31) {
				smsManager = getSystemService(SmsManager::class.java)
			} else{
				smsManager = SmsManager.getDefault()
			}
			val parts: ArrayList<String> = smsManager.divideMessage(msg)
			smsManager.sendMultipartTextMessage(phoneNo, null, parts, null, null)
			result.success("SMS Sent at " + phoneNo)
		} catch (ex: Exception) {
			ex.printStackTrace()
			result.error("Err","Sms Not Sent","")
		}
	}

	private fun getNamePhoneDetails(): MutableList<String>? {
		val names: MutableList<String> = arrayListOf()
		val cr = contentResolver
		val cur = cr.query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, null,
				null, null, null)
		if (cur!!.count > 0) {
				while (cur.moveToNext()) {
						val id = cur.getString(cur.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NAME_RAW_CONTACT_ID))
						val name = cur.getString(cur.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME))
						val number = cur.getString(cur.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER))
						names.add(id + "," + name + "," + number)
				}
		}
		return names
	}

	private fun checkWriteExternalPermission(permission: String): Boolean {
		val res: Int = getContext().checkCallingOrSelfPermission(permission)
		return (res == PackageManager.PERMISSION_GRANTED)            
	}

	private fun verifyPermission(permission: String): Boolean {
		if (checkWriteExternalPermission(permission)) {
			return true
		} else {
			if (ActivityCompat.shouldShowRequestPermissionRationale(this, permission)) {
				ActivityCompat.requestPermissions(this, arrayOf(permission), 2)
				if (checkWriteExternalPermission(permission)) {
					return true
				}
			} 
		}
		return false
	}

	private fun checkAllSms(): Boolean {
		val resSend: Int = getContext().checkCallingOrSelfPermission(Manifest.permission.SEND_SMS)
		if (resSend == PackageManager.PERMISSION_GRANTED) {
			val resRead: Int = getContext().checkCallingOrSelfPermission(Manifest.permission.READ_SMS)
			if (resRead == PackageManager.PERMISSION_GRANTED) {
				val resReceive: Int = getContext().checkCallingOrSelfPermission(Manifest.permission.RECEIVE_SMS)
				if (resReceive == PackageManager.PERMISSION_GRANTED) {
					return true
				}
			}
		}
		return false
	}

	private fun verifyPermissionAllSms(): Boolean {
		if (checkAllSms()) {
			return true
		} else {
			if (ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.SEND_SMS) &&
					ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.READ_SMS) &&
					ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.RECEIVE_SMS)) {
				ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.SEND_SMS, Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS), 2)
				if (checkAllSms()) {
					return true
				}
			} 
		}
		return false
	}

	override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
		
		// ??????
	}

	private fun verifyPermissions(type: String?, result: MethodChannel.Result) {
		if (type == "call_phone") {
			val permission = Manifest.permission.CALL_PHONE;
			result.success(verifyPermission(permission))
		} else if (type == "send_sms") {
			val permission = Manifest.permission.SEND_SMS;
			result.success(verifyPermission(permission))
		} else if (type == "read_sms") {
			val permission = Manifest.permission.READ_SMS;
			result.success(verifyPermission(permission))
		} else if (type == "receive_sms") {
			val permission = Manifest.permission.RECEIVE_SMS;
			result.success(verifyPermission(permission))
		} else if (type == "contact") {
			val permission = Manifest.permission.READ_CONTACTS;
			result.success(verifyPermission(permission))
		} else if (type == "all_sms") {
			result.success(verifyPermissionAllSms())
		} else {
			result.success(false)
		}
	}

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.SEND_SMS, Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS, Manifest.permission.CALL_PHONE, Manifest.permission.READ_CONTACTS), 2)

    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
			// This method is invoked on the main thread.
			call, result ->
			if (call.method == "get_battery_level") {
				val batteryLevel = getBatteryLevel()

				if (batteryLevel != -1) {
					result.success(batteryLevel)
				} else {
					result.error("UNAVAILABLE", "Battery level not available.", null)
				}
			} else if (call.method == "send_sms") {
				val phone: String? = call.argument("phone")
        val msg: String? = call.argument("msg")
        sendSMS(phone, msg, result)
			} else if (call.method == "call_phone") {
				val phone: String? = call.argument("phone")
				val intent: Intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:" + phone))
				startActivity(intent)
				result.success(0)
			} else if (call.method == "get_contacts") {
				result.success(getNamePhoneDetails())
			} else if (call.method == "check_permission") {
				val type: String? = call.argument("type")
				verifyPermissions(type, result)
			} else if (call.method == "can_start_receive_sms") {
				result.success(checkWriteExternalPermission(Manifest.permission.RECEIVE_SMS))
			} else {
				result.notImplemented()
			}
		}

  }
}
