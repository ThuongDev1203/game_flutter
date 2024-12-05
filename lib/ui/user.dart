import 'package:flutter/material.dart';
import 'package:game_flutter/DatabaseHelper.dart';
import 'package:game_flutter/game/tetris.dart'; // Đảm bảo import lớp Tetris của bạn

class UserUI extends StatefulWidget {
  const UserUI({super.key});

  @override
  State<UserUI> createState() => _UserUIState();
}

class _UserUIState extends State<UserUI> {
  final TextEditingController _nameController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VUI LÒNG NHẬP TÊN.')),
      );
      return;
    }

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Kiểm tra tài khoản
      final accountExists = await _dbHelper.checkAccountExists(name);

      Navigator.pop(context); // Tắt loading

      if (accountExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CHÀO MỪNG TRỞ LẠI, $name!')),
        );
      } else {
        final result = await _dbHelper.createAccount(name);
        if (result != -1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('TÀI KHOẢN $name ĐÃ ĐƯỢC TẠO!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('LỖI KHI TẠO TÀI KHOẢN, THỬ LẠI.')),
          );
          return;
        }
      }

      // Chuyển đến game và truyền tên người chơi vào Tetris
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Tetris(playerName: name), // Truyền tên
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Tắt loading nếu xảy ra lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ĐÃ XẢY RA LỖI, VUI LÒNG THỬ LẠI.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 0, 0, 0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/images/logo.png'),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  label: Center(child: Text("NHẬP TÊN ĐỂ VÀO GAME")),
                  labelStyle: TextStyle(fontSize: 20),
                  filled: true,
                  fillColor: Color.fromARGB(255, 37, 32, 32),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    backgroundColor: Colors.amber[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'CHƠI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
