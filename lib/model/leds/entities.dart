
import 'package:shadows/model/paging.dart';

class Led extends Entity {
  bool enabled;
  String name;

  Led(id, this.enabled, this.name) : super(id);
}