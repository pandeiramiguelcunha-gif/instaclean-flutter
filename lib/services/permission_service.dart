import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestAllPermissions(BuildContext context) async {
    try {
      int sdkVersion = 30;
      
      if (Platform.isAndroid) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          sdkVersion = androidInfo.version.sdkInt;
        } catch (e) {
          debugPrint('Erro ao obter versão Android: $e');
        }
      }

      debugPrint('Android SDK Version: $sdkVersion');

      if (sdkVersion >= 33) {
        // Android 13+ - Permissões granulares
        final photosStatus = await Permission.photos.request();
        final videosStatus = await Permission.videos.request();
        final audioStatus = await Permission.audio.request();
        
        debugPrint('Photos: $photosStatus, Videos: $videosStatus, Audio: $audioStatus');
        
        return photosStatus.isGranted || videosStatus.isGranted || audioStatus.isGranted;
        
      } else if (sdkVersion >= 30) {
        // Android 11-12 - MANAGE_EXTERNAL_STORAGE
        final storageStatus = await Permission.storage.request();
        
        if (!storageStatus.isGranted) {
          final manageStatus = await Permission.manageExternalStorage.status;
          
          if (!manageStatus.isGranted) {
            // Mostrar diálogo para abrir configurações
            if (context.mounted) {
              final shouldOpen = await _showSettingsDialog(context);
              if (shouldOpen) {
                await openAppSettings();
                // Aguardar utilizador voltar
                await Future.delayed(const Duration(seconds: 2));
                return await Permission.manageExternalStorage.isGranted;
              }
            }
            return false;
          }
          return true;
        }
        return storageStatus.isGranted;
        
      } else {
        // Android 10 e inferior
        final status = await Permission.storage.request();
        debugPrint('Storage permission: $status');
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Erro ao pedir permissões: $e');
      // Em caso de erro, tentar permissão básica
      try {
        final status = await Permission.storage.request();
        return status.isGranted;
      } catch (e2) {
        debugPrint('Erro fatal nas permissões: $e2');
        return false;
      }
    }
  }

  Future<bool> _showSettingsDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Permissão Necessária',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Para limpar ficheiros, o InstaClean PMC precisa de acesso total aos ficheiros.\n\nVai ser redirecionado para as definições. Por favor, ative a permissão "Permitir acesso a todos os ficheiros".',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
            ),
            child: const Text('Abrir Definições', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> checkPermissions() async {
    try {
      int sdkVersion = 30;
      
      if (Platform.isAndroid) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          sdkVersion = androidInfo.version.sdkInt;
        } catch (e) {
          debugPrint('Erro ao verificar versão: $e');
        }
      }

      if (sdkVersion >= 33) {
        final photos = await Permission.photos.isGranted;
        final videos = await Permission.videos.isGranted;
        final audio = await Permission.audio.isGranted;
        return photos || videos || audio;
      } else if (sdkVersion >= 30) {
        final manage = await Permission.manageExternalStorage.isGranted;
        final storage = await Permission.storage.isGranted;
        return manage || storage;
      } else {
        return await Permission.storage.isGranted;
      }
    } catch (e) {
      debugPrint('Erro ao verificar permissões: $e');
      return false;
    }
  }
}
