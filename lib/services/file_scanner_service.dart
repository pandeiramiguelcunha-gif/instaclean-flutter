import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class FileItem {
  final String filePath;
  final String name;
  final int size;
  final DateTime modified;
  final String? hash;
  final FileType type;

  FileItem({
    required this.filePath,
    required this.name,
    required this.size,
    required this.modified,
    this.hash,
    required this.type,
  });
}

enum FileType { photo, screenshot, video, music, contact }

class FileScannerService {
  static final FileScannerService _instance = FileScannerService._internal();
  factory FileScannerService() => _instance;
  FileScannerService._internal();

  final List<String> photoExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif'];
  final List<String> videoExtensions = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.3gp'];
  final List<String> musicExtensions = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma'];
  final List<String> screenshotFolders = ['Screenshots', 'Screen captures', 'Capturas'];

  Future<Map<FileType, List<FileItem>>> scanAllFiles({
    Function(String status, double progress)? onProgress,
  }) async {
    Map<FileType, List<FileItem>> results = {
      FileType.photo: [],
      FileType.screenshot: [],
      FileType.video: [],
      FileType.music: [],
    };

    try {
      List<Directory> dirsToScan = [];

      if (Platform.isAndroid) {
        final baseDirs = [
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Pictures',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Movies',
          '/storage/emulated/0/Videos',
          '/storage/emulated/0/Screenshots',
        ];

        for (var dirPath in baseDirs) {
          final dir = Directory(dirPath);
          try {
            if (await dir.exists()) {
              dirsToScan.add(dir);
            }
          } catch (e) {
            debugPrint('Não foi possível aceder a $dirPath: $e');
          }
        }
      }

      if (dirsToScan.isEmpty) {
        onProgress?.call('Sem acesso a pastas. Use modo demo.', 1.0);
        return results;
      }

      int totalDirs = dirsToScan.length;
      int processedDirs = 0;

      for (var dir in dirsToScan) {
        onProgress?.call('A escanear: ${path.basename(dir.path)}', processedDirs / totalDirs);
        await _scanDirectory(dir, results);
        processedDirs++;
      }

      onProgress?.call('Análise concluída!', 1.0);
    } catch (e) {
      debugPrint('Erro ao escanear ficheiros: $e');
      onProgress?.call('Erro na análise: $e', 1.0);
    }

    return results;
  }

  Future<void> _scanDirectory(Directory dir, Map<FileType, List<FileItem>> results) async {
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final ext = path.extension(entity.path).toLowerCase();
            final fileName = path.basename(entity.path);

            FileType? type;

            if (photoExtensions.contains(ext)) {
              if (screenshotFolders.any((folder) => 
                  entity.path.toLowerCase().contains(folder.toLowerCase())) ||
                  fileName.toLowerCase().contains('screenshot')) {
                type = FileType.screenshot;
              } else {
                type = FileType.photo;
              }
            } else if (videoExtensions.contains(ext)) {
              type = FileType.video;
            } else if (musicExtensions.contains(ext)) {
              type = FileType.music;
            }

            if (type != null) {
              final stat = await entity.stat();
              results[type]!.add(FileItem(
                filePath: entity.path,
                name: fileName,
                size: stat.size,
                modified: stat.modified,
                type: type,
              ));
            }
          } catch (e) {
            // Ignorar ficheiros individuais com erro
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao escanear diretório ${dir.path}: $e');
    }
  }

  Future<List<List<FileItem>>> findDuplicates(List<FileItem> files, {
    Function(String status, double progress)? onProgress,
  }) async {
    List<List<FileItem>> duplicateGroups = [];
    
    if (files.isEmpty) return duplicateGroups;

    Map<int, List<FileItem>> sizeGroups = {};

    onProgress?.call('A agrupar por tamanho...', 0.1);

    for (var file in files) {
      sizeGroups.putIfAbsent(file.size, () => []).add(file);
    }

    var potentialDuplicates = sizeGroups.values.where((group) => group.length > 1).toList();

    if (potentialDuplicates.isEmpty) {
      onProgress?.call('Sem duplicados encontrados', 1.0);
      return duplicateGroups;
    }

    onProgress?.call('A verificar ${potentialDuplicates.length} grupos...', 0.3);

    int processed = 0;
    int total = potentialDuplicates.length;

    for (var group in potentialDuplicates) {
      Map<String, List<FileItem>> hashGroups = {};

      for (var file in group) {
        try {
          final hash = await _calculateFileHash(file.filePath);
          hashGroups.putIfAbsent(hash, () => []).add(FileItem(
            filePath: file.filePath,
            name: file.name,
            size: file.size,
            modified: file.modified,
            hash: hash,
            type: file.type,
          ));
        } catch (e) {
          // Ignorar ficheiros com erro
        }
      }

      for (var hashGroup in hashGroups.values) {
        if (hashGroup.length > 1) {
          duplicateGroups.add(hashGroup);
        }
      }

      processed++;
      onProgress?.call('A verificar duplicados...', 0.3 + (0.7 * processed / total));
    }

    return duplicateGroups;
  }

  Future<String> _calculateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    Uint8List bytesToHash;
    if (bytes.length > 1024 * 1024) {
      final first = bytes.sublist(0, 512 * 1024);
      final last = bytes.sublist(bytes.length - 512 * 1024);
      bytesToHash = Uint8List.fromList([...first, ...last]);
    } else {
      bytesToHash = bytes;
    }

    final digest = md5.convert(bytesToHash);
    return digest.toString();
  }

  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao eliminar ficheiro: $e');
      return false;
    }
  }

  Future<int> deleteFiles(List<String> filePaths) async {
    int deleted = 0;
    for (var path in filePaths) {
      if (await deleteFile(path)) {
        deleted++;
      }
    }
    return deleted;
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
