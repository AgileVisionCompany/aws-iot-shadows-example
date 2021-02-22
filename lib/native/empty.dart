
class Empty {

}

Map<String, dynamic> emptySerializer(Empty empty) {
  return {};
}

Empty emptyDeserializer(Map<String, dynamic> map) {
  return Empty();
}