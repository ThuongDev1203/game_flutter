class Level {
  final int id;
  final int speed;
  final int requiredRows; // Số dòng yêu cầu để lên level

  Level(this.id, this.speed, this.requiredRows);
}

Level getLevel(int rows) => _level[_getLevelIndex(rows)];

const _levelFrameRate = [
  53,
  49,
  45,
  41,
  37,
  33,
  28,
  22,
  17,
  11,
  10,
  9,
  8,
  7,
  6,
  6,
  5,
  5,
  4,
  4,
  3,
];

// Mặc định level 0 sẽ có tốc độ là 53
final _level = List.generate(
  _levelFrameRate.length + 1, // Tăng thêm 1 phần tử cho Level 0
  (index) => index == 0
      ? Level(0, 53, 0) // Level 0, tốc độ mặc định và không yêu cầu dòng nào
      : Level(
          index,
          _levelFrameRate[
              index - 1], // Cộng thêm -1 vì Level 0 là phần tử đầu tiên
          index * 3, // Mỗi level yêu cầu thêm 3 dòng để đạt được
        ),
);

int _getLevelIndex(int rows) {
  if (rows < 3) {
    return 0; // Nếu người chơi chưa đạt đủ 3 dòng, vẫn ở level 0
  }

  var level = (rows - 1) ~/ 3; // Số dòng đạt được chia cho 3
  if (level >= _level.length) {
    level =
        _level.length - 1; // Nếu vượt quá mức độ cuối cùng thì lấy mức độ cuối
  }
  return level;
}
