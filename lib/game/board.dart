import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:game_flutter/game/level.dart';
import 'package:game_flutter/game/block.dart';
import 'package:game_flutter/game/rotation.dart';
import 'package:game_flutter/game/touch.dart';
import 'package:game_flutter/game/vector.dart';
import 'package:flutter/widgets.dart';

class Board extends ChangeNotifier {
  static const Duration lockDelayTime = Duration(seconds: 1);
  static const Duration animationTime = Duration(milliseconds: 600);
  static const int x = 10;
  static const int y = 2 * x;
  static const bool isAnimationEnabled = true;

  Ticker? _ticker;
  int lastMovedTime = 0;

  final List<Vector> _blocked;

  Block currentBlock;

  Block? holdBlock;

  final List<Block> _nextBlocks = [];

  List<Block> get nextBlocks => _nextBlocks;

  Vector _cursor;

  Vector get cursor => _cursor;

  int _clearedLines = 0;

  int get clearedLines => _clearedLines;

  List<AnimationController> animationController;

  Board(TickerProvider tickerProvider)
      : currentBlock = Block.empty(),
        _blocked = [],
        _cursor = Vector.zero,
        animationController = isAnimationEnabled
            ? List.generate(
                x * y,
                (index) => AnimationController(
                    duration: animationTime, vsync: tickerProvider),
              )
            : [] {
    _ticker = tickerProvider.createTicker(onTick);
    _ticker?.start();
    startGame();
  }

  int ticks = 0;

  void onTick(Duration elapsed) {
    if (ticks % getLevel(clearedLines).speed == 0) {
      move(const Vector(0, -1));
    }
    if (isBlockOut()) {
      startGame();
    } else if (!canMove(const Vector(0, -1)) && isLockDelayExpired()) {
      merge();
      clearRows();
      spawn();
    }
    ticks++;
  }

  @override
  void dispose() {
    _ticker?.stop(canceled: true);
    super.dispose();
  }

  bool isLockDelayExpired() =>
      lastMovedTime <
      DateTime.now().millisecondsSinceEpoch - lockDelayTime.inMilliseconds;

  void hardDrop() {
    while (move(const Vector(0, -1))) {}
    lastMovedTime = 0;
  }

  void startGame() {
    reset();
  }

  bool isBlocked(Vector v) => _blocked.contains(v);

  bool isCurrentBlockTile(Vector v) => currentBlock.tiles.contains(v - _cursor);

  bool isFree({Vector offset = Vector.zero}) => currentBlock.tiles
      .where((v) => _blocked.contains(v + _cursor + offset))
      .isEmpty;

  bool inBounds({Vector offset = Vector.zero}) =>
      currentBlock.tiles
          .where((v) => v + _cursor + offset >= const Vector(x, y))
          .isEmpty &&
      currentBlock.tiles
          .where((v) => v + _cursor + offset < Vector.zero)
          .isEmpty;

  bool move(Vector offset) {
    if (canMove(offset)) {
      _cursor += offset;
      _notify();
      return true;
    }
    return false;
  }

  bool canMove(Vector offset) =>
      inBounds(offset: offset) && isFree(offset: offset);

  bool rotate({bool clockwise = true}) {
    final from = currentBlock.rotation;
    currentBlock.rotate(clockwise: clockwise);
    if (inBounds() && isFree()) {
      final kick =
          currentBlock.getKicks(from: from, clockwise: clockwise).first;
      if (canMove(kick)) {
        _cursor += kick;
      }
      debugPrint('$from${currentBlock.rotation} rotated with first kick $kick');
      _notify();
      return true;
    } else {
      final kicks = currentBlock.getKicks(from: from, clockwise: clockwise);
      for (final kick in kicks) {
        if (inBounds(offset: kick) && isFree(offset: kick)) {
          _cursor += kick;
          debugPrint('$from${currentBlock.rotation} rotated with kick $kick');
          _notify();
          return true;
        }
      }
    }
    debugPrint('Rotation reverted');
    currentBlock.rotate(clockwise: !clockwise);
    return false;
  }

  void spawn() {
    if (_nextBlocks.length <= 3) {
      _nextBlocks.addAll(nextBlockBag);
    }
    currentBlock = _nextBlocks[0];
    _nextBlocks.removeAt(0);
    _cursor = currentBlock.spawnOffset(x, y);
    _notify();
  }

  void merge() {
    for (final element in currentBlock.tiles) {
      _blocked.add(element + _cursor);
    }
  }

  void clearRows() {
    var clearedRows = 0;
    var blocked = List.of(_blocked);
    for (var yp = y - 1; yp >= 0; yp--) {
      final result = _blocked.where((element) => element.y == yp);
      if (result.length == x) {
        clearedRows++;
        final belowVectors = blocked.where((element) => element.y < yp);
        final aboveVectors = blocked
            .where((element) => element.y > yp)
            .map((e) => e + const Vector(0, -1));
        blocked = [...belowVectors, ...aboveVectors];
        debugPrint('Cleared row $yp');
        if (isAnimationEnabled) {
          for (var x = 0; x < Board.x; x++) {
            final index = (Board.y - yp - 1) * Board.x + x;
            animationController[index]
              ..forward()
              ..addStatusListener((status) {
                if (status == AnimationStatus.dismissed ||
                    status == AnimationStatus.completed) {
                  _blocked
                    ..clear()
                    ..addAll(blocked);
                  _notify();
                  animationController[index].reset();
                }
              });
          }
        }
      }
    }
    if (!isAnimationEnabled) {
      _blocked
        ..clear()
        ..addAll(blocked);
    }
    _clearedLines += clearedRows;
  }

  void hold() {
    final tmp = currentBlock;
    while (tmp.rotation != Rotation.zero) {
      tmp.rotate();
    }
    if (holdBlock == null) {
      holdBlock = tmp;
      spawn();
    } else {
      currentBlock = holdBlock!;
      holdBlock = tmp;
    }
    _cursor = currentBlock.spawnOffset(x, y);
    _notify();
  }

  void reset() {
    spawn();
    _blocked
      ..clear()
      ..addAll(getPredefinedBlockedTiles());
    _clearedLines = 0;
    holdBlock = null;
  }

  bool isBlockOut() => _blocked.where((e) => e.y == y - 1).isNotEmpty;

  Vector _tileVectorFromIndex(int index) {
    final xp = index % x;
    final yp = y - ((index - index % x) / x).round() - 1;
    return Vector(xp, yp);
  }

  void _notify() {
    lastMovedTime = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  bool isGhostTile(Vector v) {
    var offset = const Vector(0, -1);
    while (canMove(offset)) {
      offset += const Vector(0, -1);
    }
    return currentBlock.tiles
        .contains(v - _cursor - offset - const Vector(0, 1));
  }

  Tile _getTile(Vector vector) {
    if (isBlocked(vector)) {
      return Tile.blocked;
    } else if (isCurrentBlockTile(vector)) {
      return Tile.block;
    } else if (isGhostTile(vector)) {
      return Tile.ghost;
    }
    return Tile.blank;
  }

  List<Tile> getTiles() => List.generate(
      Board.x * Board.y, (index) => _getTile(_tileVectorFromIndex(index)));

  static List<Vector> getPredefinedBlockedTiles() {
    final board = [
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],

      // empty
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ].reversed.toList();
    final blocked = <Vector>[];
    for (var yp = 0; yp < board.length; yp++) {
      for (var xp = 0; xp < board.first.length; xp++) {
        if (board[yp][xp] == 1) {
          blocked.add(Vector(xp, yp));
        }
      }
    }
    return blocked;
  }

  KeyEventResult onKey(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        move(const Vector(-1, 0));
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        move(const Vector(1, 0));
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        hold();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        move(const Vector(0, -1));
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        rotate(clockwise: false);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        rotate();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        hardDrop();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _nextBlocks.clear();
        startGame();
      }
    }
    return KeyEventResult.handled;
  }

  void onTapUp(BuildContext context, TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final localOffset = box.globalToLocal(details.globalPosition);
    final x = localOffset.dx;
    final clockwise = x >= box.size.width / 2;
    rotate(clockwise: clockwise);
  }

  void onTouch(TouchAction action) {
    switch (action) {
      case TouchAction.right:
        move(const Vector(1, 0));
        break;
      case TouchAction.left:
        move(const Vector(-1, 0));
        break;
      case TouchAction.up:
        break;
      case TouchAction.down:
        move(const Vector(0, -1));
        break;
      case TouchAction.upEnd:
        hold();
        break;
      case TouchAction.downEnd:
        hardDrop();
        break;
    }
  }
}

enum Tile { blank, blocked, block, ghost }
