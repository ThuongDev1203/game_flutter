import 'package:flutter/material.dart';
import 'package:game_flutter/DatabaseHelper.dart';

class Ranking extends StatefulWidget {
  final String playerName; // Tên người chơi được truyền từ màn hình trước

  const Ranking({Key? key, required this.playerName}) : super(key: key);

  @override
  State<Ranking> createState() => _RankingState();
}

class _RankingState extends State<Ranking> {
  List<Map<String, dynamic>> players = [];
  int currentLevel = 0; // Giả sử bạn có cách để lấy currentLevel của người chơi

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  // Lấy danh sách người chơi từ cơ sở dữ liệu
  Future<void> _loadPlayers() async {
    final playerList = await DatabaseHelper().getPlayers();
    setState(() {
      players = playerList;
    });

    // Lấy level hiện tại của người chơi và kiểm tra xem có phải là level cao nhất không
    final currentPlayer = players.firstWhere(
        (player) => player['name'] == widget.playerName,
        orElse: () => {'level': 0});
    final currentPlayerLevel = currentPlayer['level'];

    // Kiểm tra nếu người chơi đã đạt level cao nhất
    _updatePlayerLevel(currentPlayerLevel);
  }

  // Cập nhật level cho người chơi nếu đạt được level cao nhất
  Future<void> _updatePlayerLevel(int currentPlayerLevel) async {
    // Lấy danh sách người chơi từ cơ sở dữ liệu
    final players = await DatabaseHelper().getPlayers();

    // Lấy level cao nhất hiện tại trong bảng xếp hạng
    final highestLevel = players.fold<int>(
        0, (prev, player) => player['level'] > prev ? player['level'] : prev);

    if (currentPlayerLevel > highestLevel) {
      // Nếu level mới cao nhất, cập nhật level cho người chơi
      final rowsAffected =
          await DatabaseHelper().updateHighestLevel(currentPlayerLevel);
      if (rowsAffected > 0) {
        // Nếu thành công, tải lại danh sách người chơi
        await _loadPlayers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Level mới đã được cập nhật!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BẢNG XẾP HẠNG',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: players.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];

                // Kiểm tra nếu người chơi có đạt level cao nhất
                bool isHighestLevel = player['level'] == currentLevel;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  color: // Màu nổi bật cho người chơi có level cao nhất
                      const Color.fromARGB(255, 82, 77, 77),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    leading: CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 243, 113, 26),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    title: Text(
                      player['name'],
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(221, 255, 255, 255),
                      ),
                    ),
                    trailing: Text(
                      'Level ${player['level']}',
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Color.fromARGB(255, 223, 179, 35),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
