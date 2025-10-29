import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:packman/ghost.dart';
import 'package:packman/ghost3.dart';
import 'package:packman/ghost2.dart';
import 'package:packman/path.dart';
import 'package:packman/pixel.dart';
import 'package:packman/player.dart';
import 'package:audioplayers/audioplayers.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int numberInRow = 11;
  static const int _minSpawnDistance = 4;
  static const Map<String, int> _directionOffsets = {
    "left": -1,
    "right": 1,
    "up": -numberInRow,
    "down": numberInRow,
  };
  static const Map<String, String> _oppositeDirections = {
    "left": "right",
    "right": "left",
    "up": "down",
    "down": "up",
  };
  final int numberOfSquares = numberInRow * 16;
  final Random _random = Random();
  int player = numberInRow * 14 + 1;
  int ghost = numberInRow * 2 - 2;
  int ghost2 = numberInRow * 9 - 1;
  int ghost3 = numberInRow * 11 - 2;
  bool preGame = true;
  bool mouthClosed = false;
  Timer? _gameLoop;
  Timer? _ghostTimer;
  Timer? _mouthTimer;
  int score = 0;
  bool paused = false;
  final AudioPlayer backgroundPlayer = AudioPlayer();
  final AudioPlayer pausePlayer = AudioPlayer();
  final AudioPlayer munchPlayer = AudioPlayer();
  final AudioPlayer deathPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    barriers = _generateRandomBarriers();
    getFood();
  }

  void _loopAudio(AudioPlayer player, String asset) async {
    await player.stop();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource(asset));
  }

  void _playAudio(AudioPlayer player, String asset) async {
    await player.stop();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.play(AssetSource(asset));
  }

  void _stopAudio(AudioPlayer player) {
    player.stop();
  }

  void _pauseGame() {
    if (paused) {
      return;
    }
    setState(() {
      paused = true;
    });
    backgroundPlayer.pause();
    pausePlayer.pause();
  }

  void _resumeGame() {
    if (!paused) {
      return;
    }
    setState(() {
      paused = false;
    });
    pausePlayer.pause();
    backgroundPlayer.resume();
  }

  Set<int> barriers = <int>{};

  List<int> food = [];
  String direction = "right";
  String ghostLast = "left";
  String ghostLast2 = "left";
  String ghostLast3 = "down";

  void startGame() {
    if (preGame) {
      _loopAudio(backgroundPlayer, 'pacman_beginning.wav');
      _stopAudio(pausePlayer);
      _setupRandomEntities(resetScore: true);

      _gameLoop?.cancel();
      _gameLoop = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        if (!paused) {
          backgroundPlayer.resume();
        }
        if (player == ghost || player == ghost2 || player == ghost3) {
          backgroundPlayer.stop();
          _playAudio(deathPlayer, 'pacman_death.wav');
          setState(() {
            player = -1;
          });
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Center(child: Text("Game Over!")),
                  content: Text("Your Score : " + (score).toString()),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        _loopAudio(backgroundPlayer, 'pacman_beginning.wav');
                        _stopAudio(pausePlayer);
                        _setupRandomEntities(resetScore: true);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0xFF0D47A1),
                              Color(0xFF1976D2),
                              Color(0xFF42A5F5),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        child: const Text('Restart'),
                      ),
                    )
                  ],
                );
              });
        }
      });
      _ghostTimer?.cancel();
      _ghostTimer = Timer.periodic(const Duration(milliseconds: 190), (timer) {
        if (!paused) {
          moveGhost();
          moveGhost2();
          moveGhost3();
        }
      });
      _mouthTimer?.cancel();
      _mouthTimer = Timer.periodic(const Duration(milliseconds: 170), (timer) {
        setState(() {
          mouthClosed = !mouthClosed;
        });
        if (food.contains(player)) {
          _playAudio(munchPlayer, 'pacman_chomp.wav');
          setState(() {
            food.remove(player);
          });
          score++;
        }

        // if (player == ghost || player == ghost2 || player == ghost3) {
        //   setState(() {
        //     player = -1;
        //   });
        //   showDialog(
        //       context: context,
        //       builder: (BuildContext context) {
        //         return AlertDialog(
        //           title: Center(child: Text("Game Over!")),
        //           content: Text("Your Score : " + (score).toString()),
        //           actions: [
        //             RaisedButton(
        //               onPressed: () {
        //                 setState(() {
        //                   player = numberInRow * 14 + 1;
        //                   ghost = numberInRow * 2 - 2;
        //                   ghost2 = numberInRow * 9 - 1;
        //                   ghost3 = numberInRow * 11 - 2;
        //                   preGame = false;
        //                   mouthClosed = false;
        //                   direction = "right";
        //                   food.clear();
        //                   getFood();
        //                   score = 0;
        //                   Navigator.pop(context);
        //                 });
        //               },
        //               textColor: Colors.white,
        //               padding: const EdgeInsets.all(0.0),
        //               child: Container(
        //                 decoration: const BoxDecoration(
        //                   gradient: LinearGradient(
        //                     colors: <Color>[
        //                       Color(0xFF0D47A1),
        //                       Color(0xFF1976D2),
        //                       Color(0xFF42A5F5),
        //                     ],
        //                   ),
        //                 ),
        //                 padding: const EdgeInsets.all(10.0),
        //                 child: const Text('Restart'),
        //               ),
        //             )
        //           ],
        //         );
        //       });
        // }
        switch (direction) {
          case "left":
            if (!paused) moveLeft();
            break;
          case "right":
            if (!paused) moveRight();
            break;
          case "up":
            if (!paused) moveUp();
            break;
          case "down":
            if (!paused) moveDown();
            break;
        }
      });
    }
  }

  void restart() {
    startGame();
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _ghostTimer?.cancel();
    _mouthTimer?.cancel();
    backgroundPlayer.dispose();
    pausePlayer.dispose();
    munchPlayer.dispose();
    deathPlayer.dispose();
    super.dispose();
  }

  void getFood() {
    food.clear();
    for (int i = 0; i < numberOfSquares; i++) {
      if (!barriers.contains(i)) {
        food.add(i);
      }
    }
  }

  void _setupRandomEntities({bool resetScore = false}) {
    final Set<int> newBarriers = _generateRandomBarriers();
    final List<int> positions = _generateSpawnPositions(newBarriers);
    setState(() {
      barriers = newBarriers;
      player = positions[0];
      ghost = positions[1];
      ghost2 = positions[2];
      ghost3 = positions[3];
      direction = "right";
      ghostLast = "left";
      ghostLast2 = "left";
      ghostLast3 = "down";
      paused = false;
      mouthClosed = false;
      preGame = false;
      if (resetScore) {
        score = 0;
      }
      getFood();
    });
  }

  List<int> _generateSpawnPositions(Set<int> currentBarriers) {
    final List<int> walkable = [];
    for (int i = 0; i < numberOfSquares; i++) {
      if (!currentBarriers.contains(i)) {
        walkable.add(i);
      }
    }
    if (walkable.length < 4) {
      throw StateError('Not enough walkable squares to spawn entities.');
    }
    final Set<int> occupied = {};
    final int newPlayer = _drawPosition(walkable, occupied);
    final int newGhost =
        _drawPositionWithDistance(walkable, occupied, newPlayer);
    final int newGhost2 =
        _drawPositionWithDistance(walkable, occupied, newPlayer);
    final int newGhost3 =
        _drawPositionWithDistance(walkable, occupied, newPlayer);
    return [newPlayer, newGhost, newGhost2, newGhost3];
  }

  int _drawPosition(List<int> pool, Set<int> occupied) {
    final List<int> candidates =
        pool.where((index) => !occupied.contains(index)).toList();
    if (candidates.isEmpty) {
      throw StateError('No available positions for entity spawn.');
    }
    final int choice = candidates[_random.nextInt(candidates.length)];
    occupied.add(choice);
    pool.remove(choice);
    return choice;
  }

  int _drawPositionWithDistance(
      List<int> pool, Set<int> occupied, int reference) {
    int currentMinDistance = _minSpawnDistance;
    while (currentMinDistance > 0) {
      final List<int> candidates = pool.where((index) {
        if (occupied.contains(index)) {
          return false;
        }
        return _manhattanDistance(index, reference) >= currentMinDistance;
      }).toList();
      if (candidates.isNotEmpty) {
        final int choice = candidates[_random.nextInt(candidates.length)];
        occupied.add(choice);
        pool.remove(choice);
        return choice;
      }
      currentMinDistance--;
    }
    return _drawPosition(pool, occupied);
  }

  int _manhattanDistance(int a, int b) {
    final int rowA = a ~/ numberInRow;
    final int colA = a % numberInRow;
    final int rowB = b ~/ numberInRow;
    final int colB = b % numberInRow;
    return (rowA - rowB).abs() + (colA - colB).abs();
  }

  Set<int> _generateRandomBarriers() {
    final Set<int> barrierSet = <int>{};
    final int rows = numberOfSquares ~/ numberInRow;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < numberInRow; col++) {
        final int index = row * numberInRow + col;
        if (row == 0 ||
            row == rows - 1 ||
            col == 0 ||
            col == numberInRow - 1) {
          barrierSet.add(index);
        }
      }
    }

    final List<int> interior = [];
    for (int row = 1; row < rows - 1; row++) {
      for (int col = 1; col < numberInRow - 1; col++) {
        interior.add(row * numberInRow + col);
      }
    }
    interior.shuffle(_random);

    final int boundaryCount = barrierSet.length;
    final double density = 0.22 + _random.nextDouble() * 0.1;
    final int targetInteriorWalls =
        min(interior.length, (interior.length * density).round());

    for (final int candidate in interior) {
      if ((barrierSet.length - boundaryCount) >= targetInteriorWalls) {
        break;
      }
      barrierSet.add(candidate);
      if (!_isWalkableConnected(barrierSet)) {
        barrierSet.remove(candidate);
      }
    }

    if ((numberOfSquares - barrierSet.length) < 8) {
      return _generateRandomBarriers();
    }

    return barrierSet;
  }

  bool _isWalkableConnected(Set<int> barrierSet) {
    final int totalWalkable = numberOfSquares - barrierSet.length;
    if (totalWalkable <= 0) {
      return false;
    }

    int? start;
    for (int i = 0; i < numberOfSquares; i++) {
      if (!barrierSet.contains(i)) {
        start = i;
        break;
      }
    }
    if (start == null) {
      return false;
    }

    final Set<int> visited = <int>{start};
    final List<int> queue = [start];

    while (queue.isNotEmpty) {
      final int current = queue.removeAt(0);
      for (final MapEntry<String, int> entry in _directionOffsets.entries) {
        final String direction = entry.key;
        final int offset = entry.value;
        if (_wouldWrapRow(current, direction)) {
          continue;
        }
        final int next = current + offset;
        if (next < 0 || next >= numberOfSquares) {
          continue;
        }
        if (barrierSet.contains(next) || visited.contains(next)) {
          continue;
        }
        visited.add(next);
        queue.add(next);
      }
    }

    return visited.length == totalWalkable;
  }

  _GhostDecision _chooseRandomGhostMove(int position, String lastDirection) {
    final List<String> availableDirections =
        _availableGhostDirections(position);
    if (availableDirections.isEmpty) {
      return _GhostDecision(position, lastDirection);
    }

    List<String> candidates = availableDirections
        .where((direction) => !_isOppositeDirection(direction, lastDirection))
        .toList();
    if (candidates.isEmpty) {
      candidates = availableDirections;
    }

    final String chosenDirection =
        candidates[_random.nextInt(candidates.length)];
    final int offset = _directionOffsets[chosenDirection]!;
    return _GhostDecision(position + offset, chosenDirection);
  }

  List<String> _availableGhostDirections(int position) {
    final List<String> result = [];
    _directionOffsets.forEach((direction, offset) {
      if (_wouldWrapRow(position, direction)) {
        return;
      }
      final int next = position + offset;
      if (next < 0 || next >= numberOfSquares) {
        return;
      }
      if (!barriers.contains(next)) {
        result.add(direction);
      }
    });
    return result;
  }

  bool _isOppositeDirection(String direction, String lastDirection) {
    return _oppositeDirections[direction] == lastDirection;
  }

  bool _wouldWrapRow(int position, String direction) {
    if (direction == "left" && position % numberInRow == 0) {
      return true;
    }
    if (direction == "right" && position % numberInRow == numberInRow - 1) {
      return true;
    }
    return false;
  }

  void moveLeft() {
    if (!barriers.contains(player - 1)) {
      setState(() {
        player--;
      });
    }
  }

  void moveRight() {
    if (!barriers.contains(player + 1)) {
      setState(() {
        player++;
      });
    }
  }

  void moveUp() {
    if (!barriers.contains(player - numberInRow)) {
      setState(() {
        player -= numberInRow;
      });
    }
  }

  void moveDown() {
    if (!barriers.contains(player + numberInRow)) {
      setState(() {
        player += numberInRow;
      });
    }
  }

  void moveGhost() {
    setState(() {
      final _GhostDecision decision = _chooseRandomGhostMove(ghost, ghostLast);
      ghost = decision.position;
      ghostLast = decision.direction;
    });
  }

  void moveGhost2() {
    setState(() {
      final _GhostDecision decision =
          _chooseRandomGhostMove(ghost2, ghostLast2);
      ghost2 = decision.position;
      ghostLast2 = decision.direction;
    });
  }

  void moveGhost3() {
    setState(() {
      final _GhostDecision decision =
          _chooseRandomGhostMove(ghost3, ghostLast3);
      ghost3 = decision.position;
      ghostLast3 = decision.direction;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: (MediaQuery.of(context).size.height.toInt() * 0.0139).toInt(),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 0) {
                  direction = "down";
                } else if (details.delta.dy < 0) {
                  direction = "up";
                }
                // print(direction);
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 0) {
                  direction = "right";
                } else if (details.delta.dx < 0) {
                  direction = "left";
                }
                // print(direction);
              },
              child: Container(
                child: GridView.builder(
                  padding: (MediaQuery.of(context).size.height.toInt() * 0.0139)
                              .toInt() >
                          10
                      ? EdgeInsets.only(top: 80)
                      : EdgeInsets.only(top: 20),
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: numberOfSquares,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: numberInRow),
                  itemBuilder: (BuildContext context, int index) {
                    if (mouthClosed && player == index) {
                      return Padding(
                        padding: EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.yellow, shape: BoxShape.circle),
                        ),
                      );
                    } else if (player == index) {
                      switch (direction) {
                        case "left":
                          return Transform.rotate(
                            angle: pi,
                            child: MyPlayer(),
                          );
                          break;
                        case "right":
                          return MyPlayer();
                          break;
                        case "up":
                          return Transform.rotate(
                            angle: 3 * pi / 2,
                            child: MyPlayer(),
                          );
                          break;
                        case "down":
                          return Transform.rotate(
                            angle: pi / 2,
                            child: MyPlayer(),
                          );
                          break;
                        default:
                          return MyPlayer();
                      }
                    } else if (ghost == index) {
                      return MyGhost();
                    } else if (ghost2 == index) {
                      return MyGhost2();
                    } else if (ghost3 == index) {
                      return MyGhost3();
                    } else if (barriers.contains(index)) {
                      return MyPixel(
                        innerColor: Colors.blue[900],
                        outerColor: Colors.blue[800],
                        // child: Text(index.toString()),
                      );
                    } else if (preGame || food.contains(index)) {
                      return MyPath(
                        innerColor: Colors.yellow,
                        outerColor: Colors.black,
                        // child: Text(index.toString()),
                      );
                    } else {
                      return MyPath(
                        innerColor: Colors.black,
                        outerColor: Colors.black,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    " Score : " + (score).toString(),
                    // // (MediaQuery.of(context).size.height.toInt() * 0.0139)
                    //     .toInt()
                    //     .toString(),
                    style: TextStyle(color: Colors.white, fontSize: 23),
                  ),
                  GestureDetector(
                    onTap: startGame,
                    child: Text("P L A Y",
                        style: TextStyle(color: Colors.white, fontSize: 23)),
                  ),
                  if (!paused)
                    GestureDetector(
                      child: Icon(
                        Icons.pause,
                        color: Colors.white,
                      ),
                      onTap: _pauseGame,
                    ),
                  if (paused)
                    GestureDetector(
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onTap: _resumeGame,
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _GhostDecision {
  final int position;
  final String direction;

  const _GhostDecision(this.position, this.direction);
}
