
import 'dart:async';

import 'package:shadows/locator.dart';
import 'package:shadows/model/base_bloc.dart';
import 'package:shadows/model/leds/entities.dart';
import 'package:shadows/model/leds/leds_repository.dart';
import 'package:shadows/model/paging.dart';
import 'package:rxdart/rxdart.dart';

class LedsBloc extends BaseBloc {

  LedsRepository _ledsRepository;
  List<Led> _leds = [];

  @override
  void setup() {
    _ledsRepository = locator<LedsRepository>();
  }

  @override
  void dispose() {
  }

  Future<void> toggle(Led led) {
    return _ledsRepository.toggle(led);
  }
  
  Stream<PagingEvent> listenLedsChanges() {
    return _ledsRepository.listenLeds()
      .map((value) {
        return ListUpdated(value);
      });
  }

  Future<PagedData<Led>> getLeds(ListPage page) async {
    final results = await _ledsRepository.getLeds();
    if (page.index == 0) {
      return PagedData(results, results.length);
    } else {
      return PagedData([], results.length);
    }
  }


}