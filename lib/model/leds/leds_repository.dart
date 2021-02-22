

import 'package:shadows/locator.dart';
import 'package:shadows/model/leds/entities.dart';
import 'package:shadows/native/empty.dart';
import 'package:shadows/native/native_bridge.dart';
import 'package:shadows/utils/logger/log_holder.dart';

abstract class LedsRepository {

  Future<void> toggle(Led led);

  Future<List<Led>> getLeds();

  Stream<List<Led>> listenLeds();

}

class LedsRepositoryImpl extends LogHolder implements LedsRepository {

  var nativeBridge = locator<NativeBridge>();

  Future<void> toggle(Led led) async {
    await nativeBridge.invokeNativeMethod("toggle", {
      "id": led.id
    });

  }

  Future<List<Led>> getLeds() async {
    final res = await nativeBridge.invokeNativeMethod("getLeds", emptySerializer(Empty()));
    return _eventToList(res);
  }

  Stream<List<Led>> listenLeds() {
    return nativeBridge.invokeNativeStream("listen", emptySerializer(Empty()))
        .map((event) {
          return _eventToList(event);
        });
  }

  List<Led> _eventToList(Map<String, dynamic> event) {
    List<dynamic> ledsList = event['leds'];
    return ledsList.map((e) => Led(e['id'], e['enabled'], e['name'])).toList();
  }

}
