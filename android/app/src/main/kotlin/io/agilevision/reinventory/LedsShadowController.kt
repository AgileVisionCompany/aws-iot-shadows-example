package io.agilevision.reinventory

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.amazonaws.mobile.client.AWSMobileClient
import com.amazonaws.mobile.client.Callback
import com.amazonaws.mobile.client.UserStateDetails
import com.amazonaws.mobileconnectors.iot.*
import com.amazonaws.mobileconnectors.iot.AWSIotMqttClientStatusCallback.AWSIotMqttClientStatus
import com.amazonaws.regions.Region
import com.amazonaws.services.iot.AWSIotClient
import com.amazonaws.services.iot.model.AttachPolicyRequest
import com.amplifyframework.core.Amplify
import io.agilevision.reinventory.native.Empty
import io.agilevision.reinventory.native.FlutterBridge
import io.agilevision.reinventory.native.gson
import io.reactivex.Completable
import io.reactivex.Observable
import io.reactivex.Single
import io.reactivex.SingleEmitter
import io.reactivex.schedulers.Schedulers
import io.reactivex.subjects.BehaviorSubject
import java.util.*

val deviceId = PLACE_DEVICE_ID_HERE (String, see README for details)
val topicGet = "\$aws/things/$deviceId/shadow/get"
val topicGetAccepted = "\$aws/things/$deviceId/shadow/get/accepted"
val topicUpdate = "\$aws/things/$deviceId/shadow/update"
val topicUpdateAccepted = "\$aws/things/$deviceId/shadow/update/accepted"
val mqttEndpoint = PLACE_PUB_SUB_ENDPOINT_HERE (String, see README for details)
val policyName = PLACE_POLICY_NAME_HERE (String, see README for details)

class LedsShadowController {

    private val TAG = LedsShadowController::class.java.simpleName

    private lateinit var context: Context
    private val subject = BehaviorSubject.create<List<Led>>()

    enum class State {
        No,
        Pending,
        Success
    }

    private var listeningGet = State.No
    private var listeningUpdates = State.No

    private val preparedServices = lazy<Single<PreparedServices>> {
        return@lazy Single.create<PreparedServices> {
                val mobileClient: AWSMobileClient = Amplify.Auth.getPlugin("awsCognitoAuthPlugin").getEscapeHatch() as AWSMobileClient
                val iotClient = AWSIotClient(mobileClient)
                mobileClient.initialize(context, object : Callback<UserStateDetails> {
                    override fun onResult(result: UserStateDetails?) {
                        attachPolicy(it, mobileClient, iotClient)
                    }

                    override fun onError(e: Exception?) {
                        it.onError(RuntimeException("Failed!"))
                    }
                })
            }
            .subscribeOn(Schedulers.io())
            .cache()
    }

    private lateinit var preferences: SharedPreferences
    private lateinit var clientUuid: String

    init {
        subject.onNext(emptyList())
    }

    fun setup(context: Context, bridge: FlutterBridge) {
        this.context = context
        preferences = context.getSharedPreferences("settings", Context.MODE_PRIVATE)
        val androidClientIdKey = "clientId"
        if (!preferences.contains(androidClientIdKey)) {
            preferences.edit()
                    .putString(androidClientIdKey, "leds-test-" + UUID.randomUUID().toString())
                    .apply()
        }
        clientUuid = preferences.getString(androidClientIdKey, null)!!

        bridge.registerStreamHandler("listen", Empty::class.java) {
            return@registerStreamHandler listenState()
        }
        bridge.registerCompletableInvocationHandler("toggle", LedId::class.java) {
            return@registerCompletableInvocationHandler toggle(it)
        }
        bridge.registerSingleInvocationHandler("getLeds", Empty::class.java) {
            return@registerSingleInvocationHandler getLeds();
        }
    }

    fun listenState(): Observable<Leds> {
        return preparedServices.value
            .flatMapObservable { services ->
                return@flatMapObservable subject.map { Leds(it) }
            }
    }

    fun toggle(id: LedId): Completable {
        return  preparedServices.value
                .flatMapCompletable {
                    return@flatMapCompletable doToggle(it.mqttManager, id)
                }
    }

    fun getLeds(): Single<Leds> {
        return Single.just(Leds(subject.value!!))
    }

    private fun doToggle(mqttManager: AWSIotMqttManager, id: LedId): Completable {
        return Completable.create { emitter ->
            val leds = subject.value ?: kotlin.run {
                Log.e(TAG, "Error", RuntimeException("No items"))
                emitter.tryOnError(RuntimeException("No items"))
                return@create
            }
            val updatedLeds = leds.map {
                if (it.id == id.id) return@map Led(it.id, it.name, !it.enabled)
                else return@map it
            }
            val event = RemoteState(RemoteStateBody(Leds(updatedLeds)))
            val serializedEvent = gson.toJson(event)

            mqttManager.publishString(serializedEvent, topicUpdate, AWSIotMqttQos.QOS0, object : AWSIotMqttMessageDeliveryCallback {
                override fun statusChanged(status: AWSIotMqttMessageDeliveryCallback.MessageDeliveryStatus?, userData: Any?) {
                    if (status == AWSIotMqttMessageDeliveryCallback.MessageDeliveryStatus.Success) {
                        if (!emitter.isDisposed) emitter.onComplete()
                    } else {
                        Log.e(TAG, "Error", RuntimeException("Failed to toggle"))
                        emitter.tryOnError(RuntimeException("Failed to toggle"))
                    }
                }
            }, null)
        }
    }

    private fun attachPolicy(emitter: SingleEmitter<PreparedServices>, mobileClient: AWSMobileClient, iotClient: AWSIotClient) {
        iotClient.setRegion(Region.getRegion("us-east-1"))
        mobileClient.initialize(context, object : Callback<UserStateDetails> {
            override fun onResult(result: UserStateDetails) {
                doAttachPolicy(mobileClient, iotClient)
                connectToMqtt(emitter, mobileClient, iotClient)
            }

            override fun onError(e: Exception) {
                Log.e(TAG, "Error", e)
                emitter.tryOnError(e)
            }
        })
    }

    private fun doAttachPolicy(mobileClient: AWSMobileClient, iotClient: AWSIotClient) {
        val request = AttachPolicyRequest()
                .withTarget(mobileClient.identityId)
                .withPolicyName(policyName)
        iotClient.attachPolicy(request)
    }

    private fun connectToMqtt(emitter: SingleEmitter<PreparedServices>, mobileClient: AWSMobileClient, iotClient: AWSIotClient) {
        val mqttManager = AWSIotMqttManager(clientUuid, mqttEndpoint)

        mqttManager.connect(mobileClient) { status: AWSIotMqttClientStatus, throwable: Throwable? ->
            if (throwable != null) {
                Log.e(TAG, "Error", throwable)
                emitter.tryOnError(throwable)
                return@connect
            }
            if (AWSIotMqttClientStatus.Connected == status) {
                subscribeToTopic(emitter, mobileClient, iotClient, mqttManager)
            }
        }

    }

    private fun subscribeToTopic(emitter: SingleEmitter<PreparedServices>, mobileClient: AWSMobileClient,
                                 iotClient: AWSIotClient, mqttManager: AWSIotMqttManager) {
        if (listeningGet != State.No) return
        listeningGet = State.Pending
        // getting the current data
        mqttManager.subscribeToTopic(
                topicGetAccepted,
                AWSIotMqttQos.QOS0,
                object : AWSIotMqttSubscriptionStatusCallback {
                    override fun onSuccess() {
                        listeningGet = State.Success
                        mqttManager.publishString("", topicGet, AWSIotMqttQos.QOS0, object : AWSIotMqttMessageDeliveryCallback {
                            override fun statusChanged(status: AWSIotMqttMessageDeliveryCallback.MessageDeliveryStatus?, userData: Any?) {
                                Log.d(TAG, "Status: $status")
                            }
                        }, null)
                    }

                    override fun onFailure(exception: Throwable?) {
                        Log.e(TAG, "Error", exception)
                        listeningGet = State.No
                        emitter.tryOnError(exception!!)
                    }
                },
                object : AWSIotMqttNewMessageCallback {
                    override fun onMessageArrived(topic: String?, data: ByteArray?) {
                        val leds = parseEvent(data)
                        listenForUpdates(
                                emitter,
                                PreparedServices(mobileClient, iotClient, mqttManager),
                                leds
                        )
                    }
                }
        )

    }

    private fun listenForUpdates(emitter: SingleEmitter<PreparedServices>, services: PreparedServices, leds: List<Led>) {
        if (listeningUpdates != State.No) return
        listeningUpdates = State.Pending

        // listening for updates
        services.mqttManager.subscribeToTopic(
                topicUpdateAccepted,
                AWSIotMqttQos.QOS0,
                object : AWSIotMqttSubscriptionStatusCallback {
                    override fun onSuccess() {
                        emitter.onSuccess(services)
                        subject.onNext(leds)
                        listeningUpdates = State.Success
                    }

                    override fun onFailure(exception: Throwable?) {
                        Log.e(TAG, "onFailure", exception)
                        emitter.tryOnError(exception!!)
                        listeningUpdates = State.No
                    }
                },
                object : AWSIotMqttNewMessageCallback {
                    override fun onMessageArrived(topic: String?, data: ByteArray?) {
                        subject.onNext(parseEvent(data!!))
                    }
                }
        )
    }

    private fun parseEvent(array: ByteArray?): List<Led> {
        if (array == null) return emptyList()
        val message = String(array)
        val state = gson.fromJson<RemoteState>(message, RemoteState::class.java)
        return state?.state?.reported?.leds ?: emptyList()
    }

}

class PreparedServices(
        val mobileClient: AWSMobileClient,
        val iotClient: AWSIotClient,
        val mqttManager: AWSIotMqttManager
)

class Led(
        val id: Int,
        val name: String,
        var enabled: Boolean
)

class LedId(
        val id: Int
)

class Leds(
        val leds: List<Led>
)

class RemoteState(
        val state: RemoteStateBody
)

class RemoteStateBody(
        val reported: Leds
)