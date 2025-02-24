import '../model/node_model.dart';
import 'dart:math';

List<Note> mission() {
  List<Note> notes = [
    Note(0, 0),
    Note(1, 2),
    Note(2, 3),
    Note(3, 1),
    Note(4, 5),
  ];

  List<int> channels = [0, 1, 2, 3 ,4 ,5,6];
  Random random = Random();

  // Create remaining notes and assign random channels
  for (int i = 5; i < 100; i++) {
    int channel = channels[random.nextInt(channels.length)];
    notes.add(Note(i, channel));
  }

  return notes;
}
