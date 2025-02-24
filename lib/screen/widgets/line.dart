import 'package:flutter/material.dart';
import 'package:piano_tiles/model/node_model.dart';
import 'package:piano_tiles/screen/widgets/tile_widget.dart';

import '../../model/node_model.dart';


class Line extends AnimatedWidget {
  final int lineNumber;
  final List<Note> currentNotes;
  final Function(Note) onTileTap;

  const Line({
    Key? key, // Use Key? for nullable type
    required this.lineNumber,
    required this.currentNotes,
    required Animation<double> animation,
    required this.onTileTap,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    Animation<double> animation = super.listenable as Animation<double>;

    // Get heights
    double height = MediaQuery.of(context).size.height;
    double tileHeight = height / 5;

    // Get only notes for that line
    List<Note> thisLineNotes =
    currentNotes.where((note) => note.line == lineNumber).toList();

    // Map notes to widgets
    List<Widget> tiles = thisLineNotes.map((note) {
      // Specify note distance from top
      int index = currentNotes.indexOf(note);
      double offset = (3 - index + animation.value) * tileHeight;

      return Transform.translate(
        offset: Offset(0, offset),
        child: Tile(
          height: tileHeight,
          state: note.state,
          onTapDown: () => onTileTap(note),
          index: note.orderNumber,
        ),
      );
    }).toList();

    return SizedBox.expand(
      child: Stack(
        children: tiles,
      ),
    );
  }
}
