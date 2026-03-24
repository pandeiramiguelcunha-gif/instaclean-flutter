import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Evento: Scan iniciado
  Future<void> logScanIniciado() async {
    await _analytics.logEvent(
      name: 'scan_iniciado',
    );
  }

  // Evento: Scan concluído
  Future<void> logScanConcluido({
    required int totalFicheiros,
    required int duplicadosEncontrados,
  }) async {
    await _analytics.logEvent(
      name: 'scan_concluido',
      parameters: {
        'total_ficheiros': totalFicheiros,
        'duplicados_encontrados': duplicadosEncontrados,
      },
    );
  }

  // Evento: Limpeza concluída
  Future<void> logLimpezaConcluida({
    required int ficheirosEliminados,
    required String categoria,
    required int tamanhoLibertado,
  }) async {
    await _analytics.logEvent(
      name: 'limpeza_concluida',
      parameters: {
        'ficheiros_eliminados': ficheirosEliminados,
        'categoria': categoria,
        'tamanho_libertado_bytes': tamanhoLibertado,
      },
    );
  }

  // Evento: Limpeza total de duplicados
  Future<void> logLimpezaTotal({
    required int ficheirosEliminados,
  }) async {
    await _analytics.logEvent(
      name: 'limpeza_concluida',
      parameters: {
        'ficheiros_eliminados': ficheirosEliminados,
        'categoria': 'todos_duplicados',
      },
    );
  }

  // Evento: Permissão concedida
  Future<void> logPermissaoConcedida() async {
    await _analytics.logEvent(
      name: 'permissao_concedida',
    );
  }
}
