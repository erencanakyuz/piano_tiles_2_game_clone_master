import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:piano_tiles/provider/game_state.dart';
import 'package:piano_tiles/provider/mission_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../model/node_model.dart';
import 'widgets/line.dart';
import 'widgets/line_divider.dart';
import 'package:http/http.dart' as http;
import 'package:social_share/social_share.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Note> notes = mission();
  late AnimationController animationController;
  int currentNoteIndex = 0;
  int points = 0;
  bool hasStarted = false;
  bool isPlaying = true;
  NoteState state = NoteState.ready;
  int time = 5000;
  int highScore = 0;

  final List<AudioPlayer> _audioPlayers = List.generate(7, (index) => AudioPlayer());

  @override
  void initState() {
    super.initState();
    getHighScore().then((value) {
      setState(() {
        highScore = value;
      });
    });

    animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1000));
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && isPlaying) {
        if (notes[currentNoteIndex].state != NoteState.tapped) {
          setState(() {
            isPlaying = false;
            notes[currentNoteIndex].state = NoteState.missed;
          });
          animationController.reverse().then((_) => _showFinishDialog());
        } else if (currentNoteIndex == notes.length - 5) {
          _showFinishDialog();
        } else {
          setState(() => ++currentNoteIndex);
          animationController.forward(from: 0);
        }
      }
    });
    animationController.forward(from: -1);
  }

  Future<void> updateHighScore() async {
    if (points > highScore) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', points);
      setState(() {
        highScore = points;
      });
    }
  }

  void _onTap(Note note) {
    bool areAllPreviousTapped = notes
        .sublist(0, note.orderNumber)
        .every((n) => n.state == NoteState.tapped);

    if (areAllPreviousTapped) {
      if (areAllPreviousTapped && !hasStarted) {
        setState(() => hasStarted = true);
        animationController.forward();
      }
      _playNote(note);
      setState(() {
        note.state = NoteState.tapped;
        ++points;
        if (points == 15) {
          animationController.duration = Duration(milliseconds: 700);
        } else if (points == 20) {
          animationController.duration = Duration(milliseconds: 500);
        } else if (points == 30) {
          animationController.duration = Duration(milliseconds: 400);
        }
        updateHighScore();
        getHighScore().then((value) {
          setState(() {
            highScore = value;
          });
        });
      });
    }
  }

  _drawPoints() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Text(
          "$points",
          style: TextStyle(color: Colors.greenAccent, fontSize: 120),
        ),
      ),
    );
  }

  _drawLine(int lineNumber) {
    return Expanded(
      child: Line(
        lineNumber: lineNumber,
        currentNotes: notes.sublist(currentNoteIndex, currentNoteIndex + 5),
        animation: animationController,
        onTileTap: _onTap,
      ),
    );
  }

  Future<void> _shareScoreOnFacebook(BuildContext context, int score) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final graphResponse = await http.post(
          Uri.parse('https://graph.facebook.com/me/feed?message=My score is $score'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer ${accessToken.token}',
          },
        );

        if (graphResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Score shared on Facebook.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share score on Facebook.'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error sharing score on Facebook: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing score on Facebook.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
    _audioPlayers.forEach((player) => player.dispose());
  }

  void _restart() {
    setState(() {
      hasStarted = false;
      isPlaying = true;
      notes = mission();
      points = 0;
      currentNoteIndex = 0;
      animationController.duration = Duration(milliseconds: 1000);
    });
    animationController.reset();
  }

  Future<int> getHighScore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('highScore') ?? 0;
  }

  Future<void> setHighScore(int score) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', score);
  }

  void _showFinishDialog() {
    updateHighScore();

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<int>(
          future: getHighScore(),
          builder: (context, snapshot) {
            int highScore = snapshot.data ?? 0;
            return AlertDialog(
              backgroundColor: Colors.transparent,
              content: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.all(Radius.circular(150)),
                      ),
                      child: Icon(Icons.play_arrow, size: 50),
                    ),
                    SizedBox(height: 10),
                    Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.all(Radius.circular(150)),
                      ),
                      child: Text(
                        "Score: $points",
                        style: TextStyle(fontSize: 18, color: Colors.yellow),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "High Score: $highScore",
                      style: TextStyle(fontSize: 18, color: Colors.yellow),
                    ),
                    SizedBox(height: 10),
                    _startWidget(),
                    ElevatedButton(
                      child: Icon(Icons.add_alert_outlined),
                      onPressed: () async {
                        SocialShare.shareTwitter(
                            "Look at my high score on Sliding Notes High Score: $highScore"
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => _restart());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            child: Image.asset(
              "assets/background.gif",
              fit: BoxFit.cover,
            ),
          ),
          Row(
            children: <Widget>[
              _drawLine(0),
              LineDivider(),
              _drawLine(1),
              LineDivider(),
              _drawLine(2),
              LineDivider(),
              _drawLine(3),
              LineDivider(),
              _drawLine(4),
              LineDivider(),
              _drawLine(5),
              LineDivider(),
              _drawLine(6),
            ],
          ),
          _drawPoints(),
        ],
      ),
    );
  }

  _playNote(Note note) {
    switch (note.line) {
      case 0:
        _playSound('a.ogg', 0);
        return;
      case 1:
        _playSound('b.ogg', 1);
        return;
      case 2:
        _playSound('c.ogg', 2);
        return;
      case 3:
        _playSound('d.ogg', 3);
        return;
      case 4:
        _playSound('e.ogg', 4);
        return;
      case 5:
        _playSound('f.ogg', 5);
        return;
      case 6:
        _playSound('g.ogg', 6);
        return;
    }
  }

  void _playSound(String sound, int playerIndex) async {
    await _audioPlayers[playerIndex].play(AssetSource(sound));
  }

  _tileWidget(IconData icon, {required Color color}) {
    return Container(
      child: Icon(
        icon,
        color: color,
      ),
    );
  }

  _tileHorizontalLine(Color color) {
    return Container(
      width: 80,
      height: 4,
      color: color,
    );
  }

  Widget _startWidget() {
    if (points >= 5 && points < 10)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            color: Colors.yellowAccent,
          ),
          Icon(
            Icons.star,
            color: Colors.blueGrey[200],
          ),
          Icon(
            Icons.star,
            color: Colors.blueGrey[200],
          ),
        ],
      );
    else if (points >= 11 && points < 17)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            color: Colors.yellowAccent,
          ),
          Icon(
            Icons.star,
            color: Colors.yellowAccent,
          ),
          Icon(
            Icons.star,
            color: Colors.green[200],
          ),
        ],
      );
    else if (points >= 17)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            color: Colors.yellowAccent,
          ),
          Icon(
            Icons.star,
            color: Colors.yellowAccent,
          ),
          Icon(
            Icons.star,
            color: Colors.yellowAccent,
          ),
        ],
      );
    else
      return Container();
  }
}
