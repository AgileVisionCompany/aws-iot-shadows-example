
import 'dart:async';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class Entity {

  /// internal id, filled automatically by the repositories
  final int id;

  Entity(this.id);

}

class PagedData<T extends Entity> {
  List<T> list;
  int totalCount;

  PagedData(this.list, this.totalCount);

  bool get isEmpty => list.isEmpty;
}

/// Represents the information abou the page size and index, which are used
/// for loading a chunk of some large data set.
class ListPage {
  final int index;
  final int size;

  static final defaultSize = 20;
  static final int maxSize = 0x7FFFFFFF;

  static ListPage first() {
    return ListPage(0, defaultSize);
  }

  static ListPage firstItem() {
    return ListPage(0, 1);
  }

  static ListPage all() {
    return ListPage(0, maxSize);
  }

  ListPage(this.index, this.size);

  ListPage next() {
    return ListPage(index + 1, size);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListPage &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          size == other.size;

  @override
  int get hashCode => index.hashCode ^ size.hashCode;

  @override
  String toString() {
    return 'ListPage{index: $index, size: $size}';
  }
}

/// Base class for all paging event
class PagingEvent {}

/// Notifies that the specified item has been deleted from the list
class ItemDeletedEvent extends PagingEvent {
  /// Item that has been deleted
  Entity deletedItem;

  ItemDeletedEvent(this.deletedItem);
}

/// Notifies that the specified item has been updated
class ItemUpdatedEvent extends PagingEvent {
  /// Item with a new updated data
  Entity updatedItem;

  ItemUpdatedEvent(this.updatedItem);
}

/// Notifies that the new item has been created
class ItemInsertedEvent extends PagingEvent {
  Entity insertedItem;

  ItemInsertedEvent(this.insertedItem);
}

/// Notifies that the entire list should be reloaded
class ListUpdated extends PagingEvent {
  List<Entity> items;
  ListUpdated(this.items);
}

/// Helper class which handles [PagingController] state
class PagingListUpdater<T, I extends Entity> {
  PagingController<T, I> controller;

  StreamSubscription<PagingEvent> _subscription;

  PagingListUpdater(this.controller);

  void startListening(Stream<PagingEvent> stream) {
    _subscription = stream.listen((event) {
      if (event is ListUpdated) {
        final updatedList = event.items;
        controller.value = withNewList(updatedList);
      } else if (event is ItemDeletedEvent) {
        final item = event.deletedItem;
        int indexToDelete = findIndex(item);
        if (indexToDelete != -1) {
          final updatedList = List.of(controller.itemList);
          updatedList.removeAt(indexToDelete);
          controller.value = withNewList(updatedList);
        }
      } else if (event is ItemUpdatedEvent) {
        final item = event.updatedItem;
        int indexToUpdate = findIndex(item);
        if (indexToUpdate != -1) {
          final updatedList = List.of(controller.itemList);
          updatedList[indexToUpdate] = item;
          controller.value = withNewList(updatedList);
        }
      } else if (event is ItemInsertedEvent) {
        // todo: maybe optimize this:
        controller.refresh();
      }
    });
  }

  void dispose() {
    _subscription.cancel();
  }

  int findIndex(Entity entity) {
    return controller.itemList.indexWhere((element) => element.id == entity.id);
  }

  PagingState<T, I> withNewList(List<I> newList) {
    final oldState = controller.value;
    return PagingState(
      nextPageKey: oldState.nextPageKey,
      error: oldState.error,
      itemList: newList
    );
  }
}