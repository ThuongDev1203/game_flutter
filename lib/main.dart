import 'package:flutter/material.dart';
import 'package:game_flutter/game/tetris.dart';
import 'package:game_flutter/ui/user.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(brightness: Brightness.dark).copyWith(
          scaffoldBackgroundColor: const Color.fromARGB(255, 207, 145, 28),
          dividerColor: const Color(0xFF2F2F2F),
          dividerTheme: const DividerThemeData(thickness: 10),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        routes: {
          '/tetris': (context) => const Tetris(playerName: "Player1"),
          '/home': (context) => const UserUI(),
        },
        debugShowCheckedModeBanner: false,
        //home: const Tetris(),
        home: const UserUI(),
      );
}
