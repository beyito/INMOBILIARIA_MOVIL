// models/comisiones/comisiones_model.dart
class ComisionesAgente {
  final StatsAgente statsAgente;
  final List<ComisionTipo> comisionesTipo;
  final List<ContratoDetalle> contratos;

  ComisionesAgente({
    required this.statsAgente,
    required this.comisionesTipo,
    required this.contratos,
  });

  factory ComisionesAgente.fromJson(Map<String, dynamic> json) {
    return ComisionesAgente(
      statsAgente: StatsAgente.fromJson(json['stats_agente']),
      comisionesTipo: (json['comisiones_tipo'] as List)
          .map((item) => ComisionTipo.fromJson(item))
          .toList(),
      contratos: (json['contratos'] as List)
          .map((item) => ContratoDetalle.fromJson(item))
          .toList(),
    );
  }
}

class StatsAgente {
  final int totalContratos;
  final double totalComision;
  final double comisionPromedio;
  final double montoTotalContratos;
  final String agenteNombre;
  final String agenteUsername;

  StatsAgente({
    required this.totalContratos,
    required this.totalComision,
    required this.comisionPromedio,
    required this.montoTotalContratos,
    required this.agenteNombre,
    required this.agenteUsername,
  });

  factory StatsAgente.fromJson(Map<String, dynamic> json) {
    return StatsAgente(
      totalContratos: json['total_contratos'] ?? 0,
      totalComision: (json['total_comision'] ?? 0).toDouble(),
      comisionPromedio: (json['comision_promedio'] ?? 0).toDouble(),
      montoTotalContratos: (json['monto_total_contratos'] ?? 0).toDouble(),
      agenteNombre: json['agente_nombre'] ?? '',
      agenteUsername: json['agente_username'] ?? '',
    );
  }
}

class ComisionTipo {
  final String tipoContrato;
  final double totalComision;
  final double montoTotal;

  ComisionTipo({
    required this.tipoContrato,
    required this.totalComision,
    required this.montoTotal,
  });

  factory ComisionTipo.fromJson(Map<String, dynamic> json) {
    return ComisionTipo(
      tipoContrato: json['tipo_contrato'] ?? '',
      totalComision: (json['total_comision'] ?? 0).toDouble(),
      montoTotal: (json['monto_total'] ?? 0).toDouble(),
    );
  }
}

class ContratoDetalle {
  final int id;
  final String cliente;
  final String inmueble;
  final String tipoContrato;
  final String fechaContrato;
  final double montoContrato;
  final double comisionMonto;
  final double comisionPorcentaje;
  final String estado;

  ContratoDetalle({
    required this.id,
    required this.cliente,
    required this.inmueble,
    required this.tipoContrato,
    required this.fechaContrato,
    required this.montoContrato,
    required this.comisionMonto,
    required this.comisionPorcentaje,
    required this.estado,
  });

  factory ContratoDetalle.fromJson(Map<String, dynamic> json) {
    return ContratoDetalle(
      id: json['id'] ?? 0,
      cliente: json['cliente'] ?? '',
      inmueble: json['inmueble'] ?? '',
      tipoContrato: json['tipo_contrato'] ?? '',
      fechaContrato: json['fecha_contrato'] ?? '',
      montoContrato: (json['monto_contrato'] ?? 0).toDouble(),
      comisionMonto: (json['comision_monto'] ?? 0).toDouble(),
      comisionPorcentaje: (json['comision_porcentaje'] ?? 0).toDouble(),
      estado: json['estado'] ?? '',
    );
  }
}
