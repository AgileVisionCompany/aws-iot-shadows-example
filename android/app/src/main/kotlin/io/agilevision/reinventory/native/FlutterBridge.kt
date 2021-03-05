package io.agilevision.reinventory.native


import android.annotation.SuppressLint
import android.util.Log
import com.google.gson.Gson
import io.flutter.plugin.common.MethodChannel
import io.reactivex.*
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.Disposable
import io.reactivex.subjects.CompletableSubject

const val DEFAULT_CHANNEL = "testapp/method-channel/default"

val gson: Gson = Gson()

typealias MethodHandler<A, R> = (A, Result<R>) -> Unit

typealias Function<A, R> = (A) -> R

fun convertToFlutterError(err: Throwable): FlutterException {
    if (err is FlutterException) return err
    return FlutterException(err.javaClass.simpleName, err.message ?: "Error")
}

interface Result<T> {

    fun success(result: T)

    fun error(code: String, message: String)

    fun error(err: Throwable) {
        val flutterError = convertToFlutterError(err)
        error(flutterError.code, flutterError.msg)
    }
}

class FlutterBridge {

    private val methodRecords: MutableMap<String, MethodHandlerRecord<*, *>> = mutableMapOf()

    private val nativeStreamHandlerRecords: MutableMap<String, NativeStreamHandlerRecord<*, *>> = mutableMapOf()
    private val nativeStreamRecords: MutableMap<Long, NativeStreamRecord> = mutableMapOf()

    private val flutterStreamRecords: MutableMap<Long, FlutterStreamRecord<*>> = mutableMapOf()

    private var flutterStreamIdSequence = 0L

    private val initSubject = CompletableSubject.create();

    private lateinit var methodChannel: MethodChannel

    /**
     * Called by [FlutterBridgePlugin] upon attaching to the engine.
     */
    fun initialize(methodChannel: MethodChannel) {
        this.methodChannel = methodChannel
        methodChannel.setMethodCallHandler { call, result ->
            val methodName = call.method
            val arg = call.arguments as String?

            val record = methodRecords[methodName]
            if (record == null) {
                result.notImplemented()
                return@setMethodCallHandler
            }
            Log.d(FlutterBridge::class.java.simpleName, "Got call from Flutter: '$methodName' with args: $arg")
            record.invoke(methodName, arg, result)
        }

        registerInvocationHandler<NativeStreamStartArgs, Empty>("stream:start", NativeStreamStartArgs::class.java) { args, result ->
            createNativeStream(args, result)
        }

        registerInvocationHandler<NativeStreamStopArgs, Empty>("stream:stop", NativeStreamStopArgs::class.java) { args, result ->
            stopNativeStream(args)
            result.success(Empty())
        }

        registerInvocationHandler<FlutterStreamOnEventArgs, Empty>("flutterStream:onEvent", FlutterStreamOnEventArgs::class.java) { args, result ->
            onFlutterStreamEvent(args.id, args.data)
            result.success(Empty())
        }

        registerInvocationHandler<FlutterStreamOnErrorArgs, Empty>("flutterStream:onError", FlutterStreamOnErrorArgs::class.java) { args, result ->
            onFlutterStreamError(args.id, args.code, args.message)
            result.success(Empty())
        }

        registerInvocationHandler<FlutterStreamOnCompleteArgs, Empty>("flutterStream:onComplete", FlutterStreamOnCompleteArgs::class.java) { args, result ->
            onFlutterStreamComplete(args.id)
            result.success(Empty())
        }

        registerInvocationHandler<Empty, Id>("stream:createId", Empty::class.java) { args, result ->
            result.success(Id(++flutterStreamIdSequence))
        }

        registerInvocationHandler<Empty, Empty>("onFlutterInitialized", Empty::class.java) { _, result ->
            initSubject.onComplete()
            result.success(Empty())
        }

    }

    /**
     * Called by [FlutterBridgePlugin] upon detaching to the engine.
     * ToDo: dispose all subscriptions here too
     */
    fun dispose() {
        methodChannel.setMethodCallHandler(null)
        methodRecords.clear()
        nativeStreamHandlerRecords.clear()
        nativeStreamRecords.clear()
        flutterStreamRecords.clear()
    }

    /**
     * Register native method invocation handler
     * @param name unique method name (this name is specified on the Flutter side upon calling)
     * @param argumentClass java-class of the argument which reflects the argument passed by Flutter
     * @param handler method handler which performs native code invocation
     */
    fun <A, R : Any> registerInvocationHandler(name: String, argumentClass: Class<A>, handler: MethodHandler<A, R>) {
        val record = MethodHandlerRecord(argumentClass, handler)
        methodRecords[name] = record
    }

    /**
     * Register native stream handler. Used for creating native observable streams. A new stream is created
     * by the passed [streamCreator] when the 'createNativeStream' method is called on the Flutter side.
     * @param name unique stream creator name which is also must be the same on the Flutter side
     * @param argumentClass java-class of the argument which reflects the argument passed by Flutter
     * @param streamCreator factory function used for creating streams
     */
    fun <A, R> registerStreamHandler(name: String, argumentClass: Class<A>, streamCreator: Function<A, Observable<R>>) {
        val record = NativeStreamHandlerRecord(argumentClass, streamCreator)
        nativeStreamHandlerRecords[name] = record
    }

    /**
     * Invoke Flutter method from native code
     * @param name Flutter method name identifier, must be the same on the Flutter side
     * @param argument argument that is serialized to JSON and passed to the Flutter
     * @param resultClass java-class for object which will mirror the response sent back by the Flutter
     */
    fun <A, R> invokeFlutterMethod(name: String, argument: A, resultClass: Class<R>): Single<R> {
        return initSubject
                .andThen(Single.create {
                    val serializedFlutterCall = gson.toJson(argument)
                    val callback = FlutterCallback(resultClass, it)
                    Log.d(FlutterBridge::class.java.simpleName, "Calling Flutter method '$name' with arguments: $serializedFlutterCall")
                    methodChannel.invokeMethod(name, serializedFlutterCall, callback)
                })
    }

    /**
     * Create a Flutter stream and map it to the native RxJava Observable stream
     */
    fun <A, R> invokeFlutterStream(name: String, argument: A, resultClass: Class<R>): Observable<R> {
        return initSubject.andThen(Single.fromCallable {
            val id = ++flutterStreamIdSequence
            return@fromCallable FlutterCreateStreamArgs(id, name, argument)
        }
                .flatMap { args ->
                    return@flatMap invokeFlutterMethod("flutterStream:start", args, Empty::class.java).map { args.id }
                }
                .flatMapObservable { id -> Observable.create<R> { emitter ->
                    flutterStreamRecords[id] = FlutterStreamRecord(emitter, resultClass)
                    emitter.setCancellable {
                        val stopArgs = FlutterStopStreamArgs(id)
                        invokeFlutterMethod("flutterStream:stop", stopArgs)
                        onFlutterStreamFinished(id)
                    }
                } })
    }

    /**
     * Convenient method for invoking native RxJava Single streams from Flutter
     */
    fun <A, R : Any> registerSingleInvocationHandler(name: String, argumentClass: Class<A>, singleCreator: Function<A, Single<R>>) {
        registerInvocationHandler<A, R>(name, argumentClass) { arg, result ->
            singleCreator.invoke(arg)
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribe(object : SingleObserver<R> {
                        override fun onSuccess(t: R) {
                            result.success(t)
                        }

                        override fun onSubscribe(d: Disposable) {
                        }

                        override fun onError(e: Throwable) {
                            result.error(e)
                        }
                    })
        }
    }

    /**
     * Convenient method for invoking native RxJava Completable streams from Flutter
     */
    fun <A> registerCompletableInvocationHandler(name: String, argumentClass: Class<A>, completableCreator: Function<A, Completable>) {
        registerInvocationHandler<A, Empty>(name, argumentClass) { arg, result ->
            completableCreator.invoke(arg)
                    .observeOn(AndroidSchedulers.mainThread())
                    .subscribe(object : CompletableObserver {
                        override fun onComplete() {
                            result.success(Empty())
                        }

                        override fun onSubscribe(d: Disposable) {
                        }

                        override fun onError(e: Throwable) {
                            result.error(e)
                        }
                    })
        }
    }

    private fun createNativeStream(args: NativeStreamStartArgs, result: Result<Empty>) {
        val streamHandlerRecord = nativeStreamHandlerRecords[args.name]
        if (streamHandlerRecord == null) {
            result.error(FlutterException("NativeException", "Stream handler is not implemented"))
            return
        }
        val streamRecord = streamHandlerRecord.invoke(args.id, args.args, this)
        nativeStreamRecords[args.id] = streamRecord

        result.success(Empty())
    }

    private fun stopNativeStream(args: NativeStreamStopArgs) {
        val record = nativeStreamRecords[args.id]
        if (record != null) {
            Log.d(FlutterBridge::class.java.simpleName, "Native stream #${args.id} subscription disposed");
            record.dispose()
            onNativeStreamFinished(args.id)
        }
    }

    private fun onFlutterStreamEvent(id: Long, event: Any) {
        val record = flutterStreamRecords[id] ?: return
        record.publishEvent(event)
    }

    private fun onFlutterStreamError(id: Long, code: String, message: String) {
        val record = flutterStreamRecords[id] ?: return
        record.emitter.onError(FlutterException(code, message))
        onFlutterStreamFinished(id)
    }

    private fun onFlutterStreamComplete(id: Long) {
        val record = flutterStreamRecords[id] ?: return
        record.emitter.onComplete()
        onFlutterStreamFinished(id)
    }

    private fun onFlutterStreamFinished(id: Long) {
        flutterStreamRecords.remove(id)
    }

    internal fun onNativeStreamFinished(id: Long) {
        nativeStreamRecords.remove(id)
    }

    @SuppressLint("CheckResult")
    internal fun <A> invokeFlutterMethod(name: String, argument: A) {
        invokeFlutterMethod(name, argument, Empty::class.java)
                .subscribe({}, {
                    Log.e(FlutterBridge::class.java.simpleName, "Error invoking Flutter method '$name'", it)
                })
    }

}

class MethodHandlerRecord<A, R : Any>(
        private val argumentClass: Class<A>,
        private val handler: MethodHandler<A, R>
) {

    fun invoke(methodName: String, arg: String?, result: MethodChannel.Result) {
        val argument = gson.fromJson<A>(arg, argumentClass)
        handler.invoke(argument, ResultImpl(methodName, result))
    }

}

class NativeStreamHandlerRecord<A, R>(
        private val argumentClass: Class<A>,
        private val creator: Function<A, Observable<R>>
) {

    fun invoke(id: Long, arg: Any, bridge: FlutterBridge): NativeStreamRecord {
        val preparedArg = gson.toJson(arg)
        val parsedArg = gson.fromJson(preparedArg, argumentClass)
        val stream = creator.invoke(parsedArg)

        val record = NativeStreamRecord()

        stream
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(object : Observer<R> {
                    override fun onComplete() {
                        Log.d(FlutterBridge::class.java.simpleName, "Native stream #$id completed")
                        record.disposable = null
                        bridge.onNativeStreamFinished(id)
                        bridge.invokeFlutterMethod("stream:onComplete", NativeStreamOnCompleteArgs(id))
                    }

                    override fun onSubscribe(d: Disposable) {
                        Log.d(FlutterBridge::class.java.simpleName, "Native stream #$id subscribed")
                        record.disposable = d
                    }

                    override fun onNext(t: R) {
                        Log.d(FlutterBridge::class.java.simpleName, "Native stream #$id fired event: ${gson.toJson(t)}")
                        bridge.invokeFlutterMethod("stream:onEvent", NativeStreamOnEventArgs(id, t))
                    }

                    override fun onError(e: Throwable) {
                        Log.e(FlutterBridge::class.java.simpleName, "Native stream #$id failed with error", e)
                        record.disposable = null
                        bridge.onNativeStreamFinished(id)
                        val flutterError = convertToFlutterError(e)
                        bridge.invokeFlutterMethod("stream:onError", NativeStreamOnErrorArgs(id, flutterError.code, flutterError.msg))
                    }
                })

        return record
    }

}

class NativeStreamRecord {
    var disposable: Disposable? = null

    fun dispose() {
        if (disposable != null) {
            disposable?.dispose()
            disposable = null
        }
    }
}

class ResultImpl<R : Any>(
        private val methodName: String,
        private val channelResult: MethodChannel.Result
) : Result<R> {

    override fun success(result: R) {
        val serializedResult = gson.toJson(result)
        if (result.javaClass != Empty::class.java) {
            Log.d(FlutterBridge::class.java.simpleName, "Sending response from native method '$methodName' to Flutter: $serializedResult")
        }
        channelResult.success(serializedResult)
    }

    override fun error(code: String, message: String) {
        Log.d(FlutterBridge::class.java.simpleName, "Sending error from native method '$methodName' to Flutter. Code: $code, message: $message")
        channelResult.error(code, message, null);
    }
}

class FlutterCallback<T>(
        private val resultClass: Class<T>,
        private val emitter: SingleEmitter<T>
) : MethodChannel.Result {
    override fun notImplemented() {
        if (emitter.isDisposed) return
        emitter.onError(FlutterException("FlutterException", "Method is not implemented on the Flutter side"))
    }

    override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
        if (emitter.isDisposed) return
        emitter.onError(FlutterException(errorCode ?: "FlutterException", errorMessage ?: ""))
    }

    override fun success(result: Any?) {
        if (emitter.isDisposed) return
        val deserializedResult: T = gson.fromJson<T>(result as String, resultClass)
        emitter.onSuccess(deserializedResult)
    }
}

class NativeStreamStartArgs(
        val name: String,
        val args: Any,
        val id: Long
)

class NativeStreamStopArgs(
        val id: Long
)

class NativeStreamOnCompleteArgs(
        val id: Long
)

class NativeStreamOnEventArgs<T>(
        val id: Long,
        val data: T
)

class NativeStreamOnErrorArgs(
        val id: Long,
        val code: String,
        val message: String
)

class FlutterCreateStreamArgs<T>(
        val id: Long,
        val name: String,
        val args: T
)

class FlutterStopStreamArgs(
        val id: Long
)

class FlutterStreamOnEventArgs(
        val id: Long,
        val data: Any
)

class FlutterStreamOnErrorArgs(
        val id: Long,
        val code: String,
        val message: String
)

class FlutterStreamOnCompleteArgs(
        val id: Long
)

class FlutterStreamRecord<R>(
        val emitter: ObservableEmitter<R>,
        val resultClass: Class<R>
) {

    fun publishEvent(arg: Any) {
        val json = gson.toJson(arg)
        val event = gson.fromJson<R>(json, resultClass)
        if (!emitter.isDisposed) emitter.onNext(event)
    }

}

class Id(
        val id: Long
)