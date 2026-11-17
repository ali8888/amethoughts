import 'package:uuid/uuid.dart';

class Thought {
  String thought;
  final String uuid;
  final DateTime? date;

  Thought(this.thought) : uuid = Uuid().v4(), date = DateTime.now();
  Thought.edit(Thought oldThought, this.thought) : uuid = oldThought.uuid, date = oldThought.date;
  Thought.recreate(this.thought, this.uuid, this.date);

  bool sameDay(Thought otherThought) {
    if(date == null) {
      if(otherThought.date == null) {
        return true;
      } else {
        return false;
      }
    }
    return date!.toIso8601String().split('T')[0] == otherThought.date!.toIso8601String().split('T')[0];
  }

  String formattedDate() {
    if(date==null) {
      return "Unknown Date";
    } else {
      return date!.toIso8601String().split('T')[0];
    }
  }

}