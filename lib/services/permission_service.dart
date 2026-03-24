import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestAllPermissions(BuildContext context) async {
    // Verificar versão do Android
    int sdkVersion = 0;
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      sdkVersion = androidInfo.version.sdkInt;
    }

    List<Permission> permissionsToRequest = [];

    if (sdkVersion >= 33) {
      // Android 13+ usa permissões granulares
      permissionsToRequest = [
        Permission.photos,
        Permission.videos,
        Permission.audio,
        Permission.contacts,
      ];
    } else if (sdkVersion >= 30) {
      // Android 11-12 usa MANAGE_EXTERNAL_STORAGE
      permissionsToRequest = [
        Permission.manageExternalStorage,
        Permission.contacts,
      ];
    } else {
      // Android 10 e inferior
      permissionsToRequest = [
        Permission.storage,
        Permission.contacts,
      ];
    }

    // Pedir permissões
    Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();

    // Verificar se todas foram concedidas
    bool allGranted = true;
    for (var entry in statuses.entries) {
      if (!entry.value.isGranted) {
        allGranted = false;
        break;
      }
    }

    // Se MANAGE_EXTERNAL_STORAGE não foi concedido, abrir configurações
    if (sdkVersion >= 30 && sdkVersion < 33) {
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        await _showManageStorageDialog(context);
        manageStatus = await Permission.manageExternalStorage.status;
        allGranted = manageStatus.isGranted;
      }
    }

    return allGranted;
  }

  Future<void> _showManageStorageDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Permissão Necessária',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Para limpar ficheiros duplicados, o InstaClean PMC precisa de acesso total aos ficheiros.\n\nClique em "Permitir" e ative a permissão nas definições.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
            ),
            child: const Text('Permitir', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<bool> checkPermissions() async {
    int sdkVersion = 0;
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      sdkVersion = androidInfo.version.sdkInt;
    }

    if (sdkVersion >= 33) {
      return await Permission.photos.isGranted &&
          await Permission.videos.isGranted &&
          await Permission.audio.isGranted;
    } else if (sdkVersion >= 30) {
      return await Permission.manageExternalStorage.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }
}
