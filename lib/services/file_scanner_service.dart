import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

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

  // Extensões suportadas
  final List<String> photoExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif'];
  final List<String> videoExtensions = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.3gp'];
  final List<String> musicExtensions = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma'];

  // Pastas comuns de screenshots
  final List<String> screenshotFolders = ['Screenshots', 'Screen captures', 'Capturas de tela'];

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
      // Diretórios para escanear
      List<Directory> dirsToScan = [];

      // Armazenamento externo
      if (Platform.isAndroid) {
        final externalDirs = [
          Directory('/storage/emulated/0'),
          Directory('/storage/emulated/0/DCIM'),
          Directory('/storage/emulated/0/Pictures'),
          Directory('/storage/emulated/0/Download'),
          Directory('/storage/emulated/0/Music'),
          Directory('/storage/emulated/0/Movies'),
          Directory('/storage/emulated/0/Videos'),
        ];

        for (var dir in externalDirs) {
          if (await dir.exists()) {
            dirsToScan.add(dir);
          }
        }
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
      print('Erro ao escanear ficheiros: $e');
    }

    return results;
  }

  Future<void> _scanDirectory(Directory dir, Map<FileType, List<FileItem>> results) async {
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          final fileName = path.basename(entity.path);
          final parentFolder = path.basename(path.dirname(entity.path));

          FileType? type;

          if (photoExtensions.contains(ext)) {
            // Verificar se é screenshot
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
            try {
              final stat = await entity.stat();
              results[type]!.add(FileItem(
                filePath: entity.path,
                name: fileName,
                size: stat.size,
                modified: stat.modified,
                type: type,
              ));
            } catch (e) {
              // Ignorar ficheiros que não podem ser acedidos
            }
          }
        }
      }
    } catch (e) {
      // Ignorar diretórios que não podem ser acedidos
    }
  }

  Future<List<List<FileItem>>> findDuplicates(List<FileItem> files, {
    Function(String status, double progress)? onProgress,
  }) async {
    List<List<FileItem>> duplicateGroups = [];
    Map<int, List<FileItem>> sizeGroups = {};

    onProgress?.call('A agrupar por tamanho...', 0.1);

    // Agrupar por tamanho
    for (var file in files) {
      sizeGroups.putIfAbsent(file.size, () => []).add(file);
    }

    // Filtrar grupos com mais de 1 ficheiro
    var potentialDuplicates = sizeGroups.values.where((group) => group.length > 1).toList();

    onProgress?.call('A calcular hashes...', 0.3);

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
          // Ignorar ficheiros que não podem ser lidos
        }
      }

      // Adicionar grupos com duplicados reais
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
    
    // Para ficheiros grandes, usar apenas os primeiros e últimos bytes
    Uint8List bytesToHash;
    if (bytes.length > 1024 * 1024) { // > 1MB
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
      print('Erro ao eliminar ficheiro: $e');
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
