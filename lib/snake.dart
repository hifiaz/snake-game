import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:signals/signals_flutter.dart';
import 'package:ular_berbisa/utils/env.dart';

final backgroundMusic = signal(true);
final hightScore = signal(0);

class Snake extends StatefulWidget {
  const Snake({super.key});

  @override
  SnakeState createState() => SnakeState();
}

class SnakeState extends State<Snake> {
  InterstitialAd? _interstitialAd;
  final playerBackground = AudioPlayer();
  final player = AudioPlayer();
  final int squaresPerRow = 20;
  final int squaresPerCol = 40;
  final textStyle = const TextStyle(color: Colors.black, fontSize: 20);
  final randomGen = Random();

  late List<int> snakePosition;
  late int snakeDirection;
  late int foodPosition;
  late Timer timer;
  late bool isGameOver;

  @override
  void initState() {
    super.initState();
    setupGame();
    loadAd();
  }

  void playBackgroundMusic() async {
    await playerBackground.play(AssetSource('audio/background.mp3'));
    await playerBackground.setReleaseMode(ReleaseMode.loop);
  }

  void stopBackgroundMusic() async {
    await playerBackground.stop();
  }

  void setupGame() {
    if (backgroundMusic.value) {
      playBackgroundMusic();
    }
    loadAd();
    snakePosition = [45, 65, 85, 105, 125];
    snakeDirection = 20; // up
    isGameOver = false;
    generateNewFood();
    timer = Timer.periodic(const Duration(milliseconds: 250), (Timer timer) {
      updateGame();
    });
  }

  void updateGame() {
    setState(() {
      if (snakePosition.last == foodPosition) {
        // If the snake eats the food, grow the snake & generate new food.
        eatFood();
      }
      // Move the snake
      moveSnake();
      // Check collision after moving the snake.
      if (collisionDetected()) {
        endGame();
      }
    });
  }

  bool collisionDetected() {
    if (snakeDirection == -1 && snakePosition.last % squaresPerRow == 0) {
      return true; // left
    } else if (snakeDirection == 1 &&
        snakePosition.last % squaresPerRow == squaresPerRow - 1) {
      return true; // right
    } else if (snakeDirection == -squaresPerRow &&
        snakePosition.last < squaresPerRow) {
      return true; // up
    } else if (snakeDirection == squaresPerRow &&
        snakePosition.last > squaresPerRow * (squaresPerCol - 1)) {
      return true; // down
    } else if (snakePosition
        .sublist(0, snakePosition.length - 1)
        .contains(snakePosition.last)) {
      return true; // collision with itself
    }

    return false;
  }

  void generateNewFood() {
    foodPosition = randomGen.nextInt(squaresPerRow * squaresPerCol);

    while (snakePosition.contains(foodPosition)) {
      foodPosition = randomGen.nextInt(squaresPerRow * squaresPerCol);
    }
  }

  void endGame() async {
    isGameOver = true;
    timer.cancel();
    stopBackgroundMusic();
    await player.play(AssetSource('audio/gameover.mp3'));
    if (snakePosition.length >= hightScore.value) {
      hightScore.value = snakePosition.length;
    }
    _interstitialAd?.show();
  }

  void eatFood() async {
    await player.play(AssetSource('audio/eat.mp3'));
    // Add new head based on current direction but do not remove the tail.
    snakePosition.add(snakePosition.last + snakeDirection);
    generateNewFood();
  }

  void moveSnake() {
    // Add a new head and remove the tail.
    snakePosition.add(snakePosition.last + snakeDirection);
    snakePosition.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    final music = backgroundMusic.watch(context);
    return Stack(
      children: [
        Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {
                  backgroundMusic.value = !music;
                  if (backgroundMusic.watch(context)) {
                    playBackgroundMusic();
                  } else {
                    stopBackgroundMusic();
                  }
                },
                icon: Icon(
                  music ? Icons.music_note_sharp : Icons.music_off_outlined,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (snakeDirection != -20 && details.delta.dy > 0) {
                    snakeDirection = squaresPerRow;
                  } else if (snakeDirection != 20 && details.delta.dy < 0) {
                    snakeDirection = -squaresPerRow;
                  }
                },
                onHorizontalDragUpdate: (details) {
                  if (snakeDirection != 1 && details.delta.dx < 0) {
                    snakeDirection = -1;
                  } else if (snakeDirection != -1 && details.delta.dx > 0) {
                    snakeDirection = 1;
                  }
                },
                child: AspectRatio(
                  aspectRatio: squaresPerRow / (squaresPerCol + 5),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: squaresPerRow * squaresPerCol,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: squaresPerRow,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      if (snakePosition.contains(index)) {
                        return Container(
                          padding: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Container(
                              color: const Color(0xee352b42),
                            ),
                          ),
                        );
                      } else if (index == foodPosition) {
                        return Container(
                          padding: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.asset('assets/food.png'),
                            // child: Container(
                            //   color: Colors.green,
                            // ),
                          ),
                        );
                      } else {
                        return Container(
                          padding: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Container(
                              color: const Color(0xffffffd1),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isGameOver)
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Game Over',
                  style: textStyle,
                ),
                Text('Hight Score: ${hightScore.watch(context)}',
                    style: textStyle),
              ],
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Score: ${snakePosition.length}', style: textStyle),
                ElevatedButton(
                  onPressed: isGameOver ? () => setupGame() : null,
                  child: const Text(
                    'New Game',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  void loadAd() {
    InterstitialAd.load(
        adUnitId: Environment.unit,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            debugPrint('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }
}
