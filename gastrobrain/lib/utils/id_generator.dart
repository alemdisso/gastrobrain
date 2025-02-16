import 'package:uuid/uuid.dart';

class IdGenerator {
  static final _uuid = Uuid();

  static String generateId() {
    return _uuid.v4(); // Generates a random UUID v4
  }
}
