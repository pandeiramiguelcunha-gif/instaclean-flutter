import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/foundation.dart';

class MediaItem {
  final AssetEntity asset;
  final String id;
  final String? title;
  final int size;
  final DateTime createDate;
  final AssetType type;
  String? hash;
  bool isSelected;

  MediaItem({
    required this.asset,
    required this.id,
    this.title,
    required this.size,
    required this.createDate,
    required this.type,
    this.hash,
    this.isSelected = false,
  });
}

enum MediaCategory { photos, screenshots, videos }

class CleanerService {
  static final CleanerService _instance = CleanerService._internal();
  factory CleanerService() => _instance;
  CleanerService._internal();

  Map<MediaCategory, List<MediaItem>> allMedia = {};
  Map<MediaCategory, List<List<MediaItem>>> duplicates = {};
  
  int get totalDuplicatesCount {
    int count = 0;
    duplicates.forEach((key, groups) {
      for (var group in groups) {
        count += group.length - 1;
      }
    });
    return count;
  }

  int get totalDuplicatesSize {
    int size = 0;
    duplicates.forEach((key, groups) {
      for (var group in groups) {
        for (int i = 1; i < group.length; i++) {
          size += group[i].size;
        }
      }
    });
    return size;
  }

  Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: false,
        ),
      ),
    );
    return ps.isAuth || ps.hasAccess;
  }

  Future<bool> checkPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: false,
        ),
      ),
    );
    return ps.isAuth || ps.hasAccess;
  }

  // SCAN OPTIMIZADO - Mais rápido
  Future<void> scanAllMedia({
    Function(String status, double progress)? onProgress,
  }) async {
    allMedia = {
      MediaCategory.photos: [],
      MediaCategory.screenshots: [],
      MediaCategory.videos: [],
    };

    duplicates = {
      MediaCategory.photos: [],
      MediaCategory.screenshots: [],
      MediaCategory.videos: [],
    };

    try {
      onProgress?.call('A obter media...', 0.05);

      // Obter TODOS os assets de uma vez (mais rápido)
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );

      if (albums.isEmpty) {
        onProgress?.call('Nenhum álbum encontrado', 1.0);
        return;
      }

      // Encontrar o álbum "All" ou "Recentes"
      AssetPathEntity? allAlbum;
      for (var album in albums) {
        if (album.isAll) {
          allAlbum = album;
          break;
        }
      }
      allAlbum ??= albums.first;

      final int totalCount = await allAlbum.assetCountAsync;
      onProgress?.call('A processar $totalCount ficheiros...', 0.1);

      // Processar em lotes para melhor performance
      const int batchSize = 100;
      int processed = 0;

      for (int start = 0; start < totalCount; start += batchSize) {
        final end = (start + batchSize > totalCount) ? totalCount : start + batchSize;
        
        final List<AssetEntity> assets = await allAlbum.getAssetListRange(
          start: start,
          end: end,
        );

        for (var asset in assets) {
          final title = await asset.titleAsync ?? '';
          final relativePath = await asset.relativePath ?? '';
          
          // Obter tamanho real do ficheiro
          int fileSize = 0;
          try {
            final file = await asset.file;
            if (file != null) {
              fileSize = await file.length();
            }
          } catch (e) {
            fileSize = (asset.width * asset.height * 3).toInt(); // Estimativa
          }

          final mediaItem = MediaItem(
            asset: asset,
            id: asset.id,
            title: title,
            size: fileSize,
            createDate: asset.createDateTime,
            type: asset.type,
          );

          // Categorizar
          if (asset.type == AssetType.video) {
            allMedia[MediaCategory.videos]!.add(mediaItem);
          } else if (asset.type == AssetType.image) {
            // Filtro ESTRITO para screenshots:
            // 1. Caminho DEVE conter "Screenshots" (ex: /Pictures/Screenshots/)
            // 2. APENAS imagens .png ou .jpg (bloquear vídeos)
            final pathLower = relativePath.toLowerCase();
            final titleLower = title.toLowerCase();
            
            final isScreenshotPath = pathLower.contains('screenshot');
            final isImageFile = titleLower.endsWith('.png') ||
                titleLower.endsWith('.jpg') ||
                titleLower.endsWith('.jpeg');
            
            if (isScreenshotPath && isImageFile) {
              allMedia[MediaCategory.screenshots]!.add(mediaItem);
            } else if (!isScreenshotPath) {
              // Só adicionar a fotos se NÃO estiver na pasta Screenshots
              allMedia[MediaCategory.photos]!.add(mediaItem);
            }
            // Imagens na pasta Screenshots que não são .png/.jpg são ignoradas
          }

          processed++;
        }

        final progress = 0.1 + (0.5 * processed / totalCount);
        onProgress?.call('Processados: $processed de $totalCount', progress);
      }

      onProgress?.call('A procurar duplicados...', 0.7);

      // Encontrar duplicados (optimizado)
      for (var category in MediaCategory.values) {
        final items = allMedia[category] ?? [];
        if (items.length > 1) {
          duplicates[category] = await _findDuplicatesOptimized(items);
        }
      }

      onProgress?.call('Análise concluída!', 1.0);
    } catch (e) {
      debugPrint('Erro no scan: $e');
      onProgress?.call('Erro: $e', 1.0);
    }
  }

  // Encontrar duplicados - usa HASH DO FICHEIRO REAL (não thumbnails)
  Future<List<List<MediaItem>>> _findDuplicatesOptimized(List<MediaItem> items) async {
    List<List<MediaItem>> duplicateGroups = [];

    if (items.length < 2) return duplicateGroups;

    // Passo 1: Agrupar por tamanho exato (filtro rápido)
    Map<int, List<MediaItem>> sizeGroups = {};
    for (var item in items) {
      if (item.size > 0) {
        sizeGroups.putIfAbsent(item.size, () => []).add(item);
      }
    }

    // Passo 2: Só processar grupos com 2+ ficheiros do mesmo tamanho
    var potentialDuplicates = sizeGroups.values
        .where((group) => group.length > 1)
        .toList();

    for (var group in potentialDuplicates) {
      // Passo 3: Comparar hash MD5 do CONTEÚDO REAL do ficheiro
      Map<String, List<MediaItem>> hashGroups = {};

      for (var item in group) {
        try {
          final file = await item.asset.file;
          if (file != null && await file.exists()) {
            final bytes = await file.readAsBytes();
            final hash = md5.convert(bytes).toString();
            item.hash = hash;
            hashGroups.putIfAbsent(hash, () => []).add(item);
          }
        } catch (e) {
          // Se não conseguir ler o ficheiro, ignorar (NÃO agrupar como duplicado)
          debugPrint('Erro ao ler ficheiro para hash: $e');
        }
      }

      for (var hashGroup in hashGroups.values) {
        if (hashGroup.length > 1) {
          duplicateGroups.add(hashGroup);
        }
      }
    }

    return duplicateGroups;
  }

  // Obter thumbnail
  Future<Uint8List?> getThumbnail(MediaItem item) async {
    try {
      return await item.asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
        quality: 80,
      );
    } catch (e) {
      return null;
    }
  }

  // Eliminar items selecionados
  Future<int> deleteSelectedItems(List<MediaItem> items) async {
    final selectedItems = items.where((i) => i.isSelected).toList();
    if (selectedItems.isEmpty) return 0;

    try {
      final List<String> ids = selectedItems.map((e) => e.id).toList();
      final List<String> result = await PhotoManager.editor.deleteWithIds(ids);
      return result.length;
    } catch (e) {
      debugPrint('Erro ao eliminar: $e');
      return 0;
    }
  }

  // Eliminar duplicados de uma categoria
  Future<int> deleteDuplicatesInCategory(MediaCategory category) async {
    int deleted = 0;
    final groups = duplicates[category] ?? [];

    List<String> idsToDelete = [];
    for (var group in groups) {
      if (group.length > 1) {
        for (int i = 1; i < group.length; i++) {
          idsToDelete.add(group[i].id);
        }
      }
    }

    if (idsToDelete.isNotEmpty) {
      try {
        final result = await PhotoManager.editor.deleteWithIds(idsToDelete);
        deleted = result.length;
      } catch (e) {
        debugPrint('Erro ao eliminar: $e');
      }
    }

    duplicates[category] = [];
    return deleted;
  }

  // Eliminar todos os duplicados
  Future<int> deleteAllDuplicates() async {
    int totalDeleted = 0;
    for (var category in MediaCategory.values) {
      totalDeleted += await deleteDuplicatesInCategory(category);
    }
    return totalDeleted;
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
