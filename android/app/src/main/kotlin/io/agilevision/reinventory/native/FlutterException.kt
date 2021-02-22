package io.agilevision.reinventory.native

class FlutterException(
    val code: String,
    val msg: String
) : Exception(msg) {
}