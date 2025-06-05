import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectivityController;

  Stream<bool> get connectivityStream {
    _connectivityController ??= StreamController<bool>.broadcast();
    return _connectivityController!.stream;
  }

  Future<void> initialize() async {
    // Проверяем начальное состояние
    final initialResult = await _connectivity.checkConnectivity();
    final isConnected = initialResult != ConnectivityResult.none;

    // Добавляем небольшую задержку для инициализации UI
    Future.delayed(Duration(milliseconds: 1000), () {
      _connectivityController?.add(isConnected);
    });

    // Слушаем изменения
    _connectivity.onConnectivityChanged.listen((result) {
      final bool isConnected = result != ConnectivityResult.none;
      _connectivityController?.add(isConnected);
    });
  }

  Future<bool> get isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void dispose() {
    _connectivityController?.close();
    _connectivityController = null;
  }
}
