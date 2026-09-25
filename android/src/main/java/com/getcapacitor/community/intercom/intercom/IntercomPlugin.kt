package com.getcapacitor.community.intercom

import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.Logger
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission
import io.intercom.android.sdk.Intercom
import io.intercom.android.sdk.UserAttributes
import io.intercom.android.sdk.identity.Registration
import io.intercom.android.sdk.push.IntercomPushClient

@CapacitorPlugin(name = "Intercom", permissions = [Permission(strings = [], alias = "receive")])
public class IntercomPlugin : Plugin() {
    private val intercomPushClient = IntercomPushClient()

    override fun load() {
        // Set up Intercom
        setUpIntercom()

        // load parent
        super.load()
    }

    @PluginMethod
    public fun loadWithKeys(call: PluginCall) {
        val appId = call.getString("appId", "NO_APP_ID_PASSED")
        val apiKey = call.getString("apiKeyAndroid", "NO_API_KEY_PASSED")

        Intercom.initialize(activity.application, apiKey, appId)

        // load parent
        super.load()
        call.resolve()
    }

    override fun handleOnStart() {
        super.handleOnStart()
        bridge.activity.runOnUiThread {
            // We also initialize intercom here just in case it has died. If Intercom is already set up, this won't do anything.
            setUpIntercom()
            Intercom.client().handlePushMessage()
        }
    }

    override fun handleOnPause() {
        super.handleOnPause()
        notifyListeners(EVENT_WINDOW_DID_SHOW, null)
    }

    override fun handleOnResume() {
        super.handleOnResume()
        notifyListeners(EVENT_WINDOW_DID_HIDE, null)
    }

    @PluginMethod
    public fun registerIdentifiedUser(call: PluginCall) {
        val email = call.getString("email")
        val userId = call.data.getString("userId")

        var registration = Registration()

        if (!email.isNullOrEmpty()) {
            registration = registration.withEmail(email)
        }
        if (!userId.isNullOrEmpty()) {
            registration = registration.withUserId(userId)
        }
        Intercom.client().registerIdentifiedUser(registration)
        call.resolve()
    }

    @PluginMethod
    public fun registerUnidentifiedUser(call: PluginCall) {
        Intercom.client().registerUnidentifiedUser()
        call.resolve()
    }

    @PluginMethod
    public fun updateUser(call: PluginCall) {
        val builder = UserAttributes.Builder()
        val userId = call.getString("userId")
        if (!userId.isNullOrEmpty()) {
            builder.withUserId(userId)
        }
        val email = call.getString("email")
        if (!email.isNullOrEmpty()) {
            builder.withEmail(email)
        }
        val name = call.getString("name")
        if (!name.isNullOrEmpty()) {
            builder.withName(name)
        }
        val phone = call.getString("phone")
        if (!phone.isNullOrEmpty()) {
            builder.withPhone(phone)
        }
        val languageOverride = call.getString("languageOverride")
        if (!languageOverride.isNullOrEmpty()) {
            builder.withLanguageOverride(languageOverride)
        }
        val customAttributes = mapFromJSON(call.getObject("customAttributes"))
        // The SDK ignores a null map apart from logging a warning, and its parameter is declared non-null.
        if (customAttributes != null) {
            builder.withCustomAttributes(customAttributes)
        }
        Intercom.client().updateUser(builder.build())
        call.resolve()
    }

    @PluginMethod
    public fun logout(call: PluginCall) {
        Intercom.client().logout()
        call.resolve()
    }

    @PluginMethod
    public fun logEvent(call: PluginCall) {
        val eventName = call.getString("name")
        val metaData = mapFromJSON(call.getObject("data"))

        // The SDK does not accept null here, so a call without "name" has always failed with a NullPointerException.
        if (metaData == null) {
            Intercom.client().logEvent(eventName!!)
        } else {
            Intercom.client().logEvent(eventName!!, metaData)
        }

        call.resolve()
    }

    @PluginMethod
    public fun displayMessenger(call: PluginCall) {
        Intercom.client().displayMessenger()
        call.resolve()
    }

    @PluginMethod
    public fun displayMessageComposer(call: PluginCall) {
        val message = call.getString("message")
        Intercom.client().displayMessageComposer(message)
        call.resolve()
    }

    @PluginMethod
    public fun displayHelpCenter(call: PluginCall) {
        Intercom.client().displayHelpCenter()
        call.resolve()
    }

    @PluginMethod
    public fun hideMessenger(call: PluginCall) {
        Intercom.client().hideIntercom()
        call.resolve()
    }

    @PluginMethod
    public fun displayLauncher(call: PluginCall) {
        Intercom.client().setLauncherVisibility(Intercom.VISIBLE)
        call.resolve()
    }

    @PluginMethod
    public fun hideLauncher(call: PluginCall) {
        Intercom.client().setLauncherVisibility(Intercom.GONE)
        call.resolve()
    }

    @PluginMethod
    public fun displayInAppMessages(call: PluginCall) {
        Intercom.client().setInAppMessageVisibility(Intercom.VISIBLE)
        call.resolve()
    }

    @PluginMethod
    public fun hideInAppMessages(call: PluginCall) {
        Intercom.client().setLauncherVisibility(Intercom.GONE)
        call.resolve()
    }

    @PluginMethod
    public fun displayCarousel(call: PluginCall) {
        val carouselId = call.getString("carouselId")
        // The SDK does not accept null here, so a call without "carouselId" has always failed with a NullPointerException.
        Intercom.client().displayCarousel(carouselId!!)
        call.resolve()
    }

    @PluginMethod
    public fun setUserHash(call: PluginCall) {
        val hmac = call.getString("hmac")
        // The SDK does not accept null here, so a call without "hmac" has always failed with a NullPointerException.
        Intercom.client().setUserHash(hmac!!)
        call.resolve()
    }

    @PluginMethod
    public fun setUserJwt(call: PluginCall) {
        val jwt = call.getString("jwt")
        // The SDK does not accept null here, so a call without "jwt" has always failed with a NullPointerException.
        Intercom.client().setUserJwt(jwt!!)
        call.resolve()
    }

    @PluginMethod
    public fun setBottomPadding(call: PluginCall) {
        val stringValue = call.getString("value")
        val value = Integer.parseInt(stringValue)
        Intercom.client().setBottomPadding(value)
        call.resolve()
    }

    @PluginMethod
    public fun sendPushTokenToIntercom(call: PluginCall) {
        val token = call.getString("value")
        try {
            // The SDK does not accept null here. The NullPointerException for a missing "value" is rejected below, as before.
            intercomPushClient.sendTokenToIntercom(activity.application, token!!)
            call.resolve()
        } catch (e: Exception) {
            call.reject("Failed to send push token to Intercom", ex = e)
        }
    }

    @PluginMethod
    public fun receivePush(call: PluginCall) {
        try {
            // The values are handed over unchecked, as the raw Map in the Java version did.
            @Suppress("UNCHECKED_CAST")
            val message = mapFromJSON(call.data) as Map<String, String>
            if (intercomPushClient.isIntercomPush(message)) {
                intercomPushClient.handlePush(activity.application, message)
                call.resolve()
            } else {
                call.reject("Notification data was not a valid Intercom push message")
            }
        } catch (e: Exception) {
            call.reject("Failed to handle received Intercom push", ex = e)
        }
    }

    @PluginMethod
    public fun displayArticle(call: PluginCall) {
        val articleId = call.getString("articleId")
        // The SDK does not accept null here, so a call without "articleId" has always failed with a NullPointerException.
        Intercom.client().displayArticle(articleId!!)
        call.resolve()
    }

    private fun setUpIntercom() {
        try {
            // get config
            val config = bridge.config
            val apiKey = config.getPluginConfiguration("Intercom").getString("androidApiKey")
            val appId = config.getPluginConfiguration("Intercom").getString("androidAppId")

            // init intercom sdk
            Intercom.initialize(activity.application, apiKey, appId)
        } catch (e: Exception) {
            Logger.error("Intercom", "ERROR: Something went wrong when initializing Intercom. Check your configurations", e)
        }
    }

    private companion object {
        private const val EVENT_WINDOW_DID_SHOW = "windowDidShow"
        private const val EVENT_WINDOW_DID_HIDE = "windowDidHide"

        private fun mapFromJSON(jsonObject: JSObject?): Map<String, Any>? {
            if (jsonObject == null) {
                return null
            }
            val map = HashMap<String, Any>()
            for (key in jsonObject.keys()) {
                val value = getObject(jsonObject.opt(key))
                if (value != null) {
                    map[key] = value
                }
            }
            return map
        }

        private fun getObject(value: Any?): Any? = when (value) {
            is JSObject -> mapFromJSON(value)
            is JSArray -> listFromJSON(value)
            else -> value
        }

        private fun listFromJSON(jsonArray: JSArray): List<Any> {
            val list = ArrayList<Any>()
            for (i in 0 until jsonArray.length()) {
                val value = getObject(jsonArray.opt(i))
                if (value != null) {
                    list.add(value)
                }
            }
            return list
        }
    }
}
