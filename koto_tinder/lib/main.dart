import 'package:flutter/material.dart';
import 'package:koto_tinder/di/service_locator.dart';
import 'package:koto_tinder/presentation/screens/home_screen.dart';

void main() {
  // Инициализируем сервис-локатор
  setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'КотоТиндер',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true, // Центрирование заголовка на всех платформах
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
