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

  MediaItem({
    required this.asset,
    required this.id,
    this.title,
    required this.size,
    required this.createDate,
    required this.type,
    this.hash,
  });
}

enum MediaCategory { photos, screenshots, videos, music }

class CleanerService {
  static final CleanerService _instance = CleanerService._internal();
  factory CleanerService() => _instance;
  CleanerService._internal();

  // Resultados do scan
  Map<MediaCategory, List<MediaItem>> allMedia = {};
  Map<MediaCategory, List<List<MediaItem>>> duplicates = {};
  
  int get totalDuplicatesCount {
    int count = 0;
    duplicates.forEach((key, groups) {
      for (var group in groups) {
        count += group.length - 1; // -1 para manter o original
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

  // Pedir permissões via photo_manager
  Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  // Verificar permissões
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

  // Scan de todos os media
  Future<void> scanAllMedia({
    Function(String status, double progress)? onProgress,
  }) async {
    allMedia = {
      MediaCategory.photos: [],
      MediaCategory.screenshots: [],
      MediaCategory.videos: [],
      MediaCategory.music: [],
    };

    duplicates = {
      MediaCategory.photos: [],
      MediaCategory.screenshots: [],
      MediaCategory.videos: [],
      MediaCategory.music: [],
    };

    try {
      onProgress?.call('A obter álbuns...', 0.1);

      // Obter todos os álbuns
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );

      if (albums.isEmpty) {
        onProgress?.call('Nenhum álbum encontrado', 1.0);
        return;
      }

      onProgress?.call('A analisar ${albums.length} álbuns...', 0.2);

      int totalAssets = 0;
      int processedAssets = 0;

      // Contar total de assets
      for (var album in albums) {
        totalAssets += await album.assetCountAsync;
      }

      // Processar cada álbum
      for (var album in albums) {
        final String albumName = album.name.toLowerCase();
        final int count = await album.assetCountAsync;
        
        if (count == 0) continue;

        final List<AssetEntity> assets = await album.getAssetListRange(
          start: 0,
          end: count,
        );

        for (var asset in assets) {
          processedAssets++;
          
          if (processedAssets % 50 == 0) {
            onProgress?.call(
              'A processar: $processedAssets de $totalAssets',
              0.2 + (0.5 * processedAssets / totalAssets),
            );
          }

          final title = await asset.titleAsync ?? '';
          final size = (asset.size.width * asset.size.height).toInt(); // Aproximação

          final mediaItem = MediaItem(
            asset: asset,
            id: asset.id,
            title: title,
            size: size,
            createDate: asset.createDateTime,
            type: asset.type,
          );

          // Categorizar
          if (asset.type == AssetType.video) {
            allMedia[MediaCategory.videos]!.add(mediaItem);
          } else if (asset.type == AssetType.audio) {
            allMedia[MediaCategory.music]!.add(mediaItem);
          } else if (asset.type == AssetType.image) {
            // Verificar se é screenshot
            if (albumName.contains('screenshot') ||
                albumName.contains('captura') ||
                title.toLowerCase().contains('screenshot')) {
              allMedia[MediaCategory.screenshots]!.add(mediaItem);
            } else {
              allMedia[MediaCategory.photos]!.add(mediaItem);
            }
          }
        }
      }

      onProgress?.call('A procurar duplicados...', 0.7);

      // Encontrar duplicados em cada categoria
      for (var category in MediaCategory.values) {
        if (allMedia[category]!.isNotEmpty) {
          duplicates[category] = await _findDuplicatesInCategory(
            allMedia[category]!,
            onProgress: (status, progress) {
              onProgress?.call(
                'Duplicados em ${_getCategoryName(category)}: $status',
                0.7 + (0.3 * progress / MediaCategory.values.length),
              );
            },
          );
        }
      }

      onProgress?.call('Análise concluída!', 1.0);
    } catch (e) {
      debugPrint('Erro no scan: $e');
      onProgress?.call('Erro: $e', 1.0);
    }
  }

  Future<List<List<MediaItem>>> _findDuplicatesInCategory(
    List<MediaItem> items, {
    Function(String status, double progress)? onProgress,
  }) async {
    List<List<MediaItem>> duplicateGroups = [];

    if (items.length < 2) return duplicateGroups;

    // Agrupar por tamanho (aproximação inicial)
    Map<int, List<MediaItem>> sizeGroups = {};
    for (var item in items) {
      sizeGroups.putIfAbsent(item.size, () => []).add(item);
    }

    // Filtrar grupos com potenciais duplicados
    var potentialDuplicates = sizeGroups.values
        .where((group) => group.length > 1)
        .toList();

    int processed = 0;
    int total = potentialDuplicates.length;

    for (var group in potentialDuplicates) {
      Map<String, List<MediaItem>> hashGroups = {};

      for (var item in group) {
        try {
          // Calcular hash do thumbnail para performance
          final thumb = await item.asset.thumbnailDataWithSize(
            const ThumbnailSize(100, 100),
            quality: 50,
          );
          
          if (thumb != null) {
            final hash = md5.convert(thumb).toString();
            item.hash = hash;
            hashGroups.putIfAbsent(hash, () => []).add(item);
          }
        } catch (e) {
          // Ignorar erros individuais
        }
      }

      // Adicionar grupos com duplicados reais
      for (var hashGroup in hashGroups.values) {
        if (hashGroup.length > 1) {
          duplicateGroups.add(hashGroup);
        }
      }

      processed++;
      onProgress?.call('$processed/$total grupos', processed / total);
    }

    return duplicateGroups;
  }

  // Eliminar ficheiros
  Future<int> deleteItems(List<MediaItem> items) async {
    if (items.isEmpty) return 0;

    try {
      final List<String> ids = items.map((e) => e.id).toList();
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

    for (var group in groups) {
      if (group.length > 1) {
        // Manter o primeiro (original), eliminar os restantes
        final toDelete = group.sublist(1);
        deleted += await deleteItems(toDelete);
      }
    }

    // Atualizar listas
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

  String _getCategoryName(MediaCategory category) {
    switch (category) {
      case MediaCategory.photos: return 'Fotos';
      case MediaCategory.screenshots: return 'Screenshots';
      case MediaCategory.videos: return 'Vídeos';
      case MediaCategory.music: return 'Músicas';
    }
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
