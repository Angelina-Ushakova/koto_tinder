import 'dart:async';
import 'package:flutter/material.dart';
import 'package:koto_tinder/data/datasources/connectivity_service.dart';
import 'package:koto_tinder/di/service_locator.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivityService = serviceLocator<ConnectivityService>();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      bool isConnected,
    ) {
      if (mounted) {
        if (!isConnected) {
          _wasOffline = true;
          _showConnectivitySnackBar(
            'Нет подключения к интернету',
            isConnected: false,
          );
        } else if (_wasOffline) {
          // Показываем сообщение о восстановлении только если был оффлайн
          _showConnectivitySnackBar(
            'Подключение к интернету восстановлено',
            isConnected: true,
          );
          _wasOffline = false;
        }
      }
    });
  }

  void _showConnectivitySnackBar(String message, {required bool isConnected}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    // Закрываем предыдущий SnackBar
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isConnected ? Colors.green : Colors.orange,
        duration: Duration(seconds: isConnected ? 2 : 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
