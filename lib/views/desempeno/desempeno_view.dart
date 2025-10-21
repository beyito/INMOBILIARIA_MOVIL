// lib/views/desempeno/desempeno_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

// PDF
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

// Asegúrate de que las rutas a tus modelos y servicios sean correctas.
import '../../models/desempeno/desempeno_model.dart';
import '../../services/desempeno/desempeno_service.dart';

// ====================================================================================
// 🎩 --- CONFIGURACIÓN DE LA SIMULACIÓN --- 🎩
// ====================================================================================
final DateTime FECHA_INICIO_HISTORICA = DateTime(2025, 10, 1);
// ====================================================================================

const List<Color> _chartColors = [
  Color(0xFF0ea5e9),
  Color(0xFF22c55e),
  Color(0xFFf97316),
  Color(0xFFa78bfa),
  Color(0xFFef4444),
  Color(0xFF14b8a6)
];

class DesempenoView extends StatefulWidget {
  const DesempenoView({super.key});

  @override
  State<DesempenoView> createState() => _DesempenoViewState();
}

class _DesempenoViewState extends State<DesempenoView> {
  final DesempenoService _desempenoService = DesempenoService();

  bool _isLoading = true;
  String? _error;
  int? _agenteId;

  DesempenoModel? _datosHistoricos;
  DesempenoModel? _datosMostrados;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  bool _isIaLoading = false;
  String? _iaError;
  String? _iaText;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final agenteId = prefs.getInt('id');
      if (agenteId == null || agenteId == 0) {
        throw Exception("Sin ID de agente en la sesión.");
      }

      final res = await _desempenoService.getDesempenoAgente(agenteId);
      setState(() {
        _agenteId = agenteId;
        _datosHistoricos = res;
        _datosMostrados = _simularDatosPorPeriodo(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error al procesar los datos: $e";
        _isLoading = false;
      });
    }
  }

  DesempenoModel? _simularDatosPorPeriodo(DesempenoModel? datosTotales) {
    if (datosTotales == null) return null;

    final hoy = DateTime.now();
    final inicioHistorico = FECHA_INICIO_HISTORICA;

    final duracionTotalMs = hoy.difference(inicioHistorico).inMilliseconds;
    if (duracionTotalMs <= 0) return datosTotales;

    final fechaInicioFiltro = _fechaInicio ?? inicioHistorico;
    DateTime fechaFinFiltro = _fechaFin ?? hoy;
    if (_fechaFin != null) {
      fechaFinFiltro = DateTime(
          fechaFinFiltro.year, fechaFinFiltro.month, fechaFinFiltro.day, 23, 59, 59);
    }

    final duracionSeleccionadaMs =
        fechaFinFiltro.difference(fechaInicioFiltro).inMilliseconds.clamp(0, double.infinity).toInt();
    final proporcion = (duracionSeleccionadaMs / duracionTotalMs).clamp(0.0, 1.0);

    int estimar(int valor) => (valor * proporcion).round();

    final totalesSimulados = TotalesModel(
      publicaciones: estimar(datosTotales.totales.publicaciones),
      publicacionesConAnuncio: estimar(datosTotales.totales.publicacionesConAnuncio),
      anuncios: estimar(datosTotales.totales.anuncios),
    );

    final Map<String, EstadoDetalleModel> estadosMap =
        datosTotales.estados.toJson().map((key, value) {
      final count = estimar(value['count']);
      return MapEntry(key, EstadoDetalleModel(count: count, pct: 0.0));
    });

    final totalAnunciosSimulados = totalesSimulados.anuncios;
    estadosMap.forEach((key, value) {
      final pct = totalAnunciosSimulados > 0
          ? (value.count * 100) / totalAnunciosSimulados
          : 0.0;
      estadosMap[key] = EstadoDetalleModel(count: value.count, pct: pct);
    });

    final estadosSimulados = EstadosModel.fromJson(
        estadosMap.map((k, v) => MapEntry(k, v.toJson())));

    final cerradosSimulados = (estadosSimulados.vendido.count) +
        (estadosSimulados.anticretico.count) +
        (estadosSimulados.alquilado.count);

    final desempenoSimulado = totalAnunciosSimulados > 0
        ? (cerradosSimulados * 100) / totalAnunciosSimulados
        : 0.0;

    final tasaPublicacionSimulada = totalesSimulados.publicaciones > 0
        ? (totalesSimulados.publicacionesConAnuncio * 100) /
            totalesSimulados.publicaciones
        : 0.0;

    String etiquetaDesempeno(double p) =>
        p >= 75 ? "Excelente" : p >= 50 ? "Bueno" : p >= 25 ? "Regular" : "Bajo";

    final kpisSimulados = KpisModel(
      desempeno: desempenoSimulado,
      tasaPublicacion: tasaPublicacionSimulada,
      nota: etiquetaDesempeno(desempenoSimulado),
    );

    return DesempenoModel(
      agenteId: datosTotales.agenteId,
      totales: totalesSimulados,
      estados: estadosSimulados,
      kpis: kpisSimulados,
    );
  }

  void _aplicarFiltros() {
    setState(() {
      _datosMostrados = _simularDatosPorPeriodo(_datosHistoricos);
      _iaText = null;
      _iaError = null;
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _datosMostrados = _simularDatosPorPeriodo(_datosHistoricos);
      _iaText = null;
      _iaError = null;
    });
  }

  Future<void> _pedirReporteIA() async {
    if (_datosMostrados == null) return;
    setState(() {
      _isIaLoading = true;
      _iaError = null;
      _iaText = null;
    });

    try {
      final reporte = await _desempenoService.getReporteIA(_datosMostrados!);
      setState(() {
        _iaText = reporte;
      });
    } catch (e) {
      setState(() {
        _iaError = e.toString();
      });
    } finally {
      setState(() {
        _isIaLoading = false;
      });
    }
  }

  // ----- Exportar a PDF -----
  Future<void> _exportarPdf() async {
    if (_datosMostrados == null) return;

    final d = _datosMostrados!;
    final estadosMap = d.estados.toJson().map((k, v) =>
        MapEntry(k[0].toUpperCase() + k.substring(1), EstadoDetalleModel.fromJson(v)));

    final format = DateFormat('dd/MM/yyyy', 'es_ES');
    final String rango = _fechaInicio == null && _fechaFin == null
        ? "Histórico total"
        : "Del ${_fechaInicio != null ? format.format(_fechaInicio!) : 'inicio'} "
          "al ${_fechaFin != null ? format.format(_fechaFin!) : 'hoy'}";

    final pdf = pw.Document();

    pw.Widget _kv(String k, String v) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(k, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        pw.Text(v, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text("Reporte de Desempeño",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text("Agente #$_agenteId • $rango",
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 16),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(children: [
                _kv("Tasa de Cierre", "${d.kpis.desempeno.toStringAsFixed(1)}%"),
                _kv("Tasa de Publicación", "${d.kpis.tasaPublicacion.toStringAsFixed(1)}%"),
                _kv("Total Publicaciones", d.totales.publicaciones.toString()),
                _kv("Total Anuncios", d.totales.anuncios.toString()),
                _kv("Nota", d.kpis.nota),
              ]),
            ),

            pw.SizedBox(height: 16),
            pw.Text("Desglose por Estado",
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              headers: ["Estado", "Cantidad", "% del Total"],
              data: estadosMap.entries.map((e) => [
                e.key,
                e.value.count,
                "${e.value.pct.toStringAsFixed(2)}%"
              ]).toList(),
              cellStyle: const pw.TextStyle(fontSize: 11),
              headerStyle: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),

            if (_iaText != null) ...[
              pw.SizedBox(height: 16),
              pw.Text("Análisis IA",
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(_iaText!, style: const pw.TextStyle(fontSize: 11)),
            ],
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: "desempeno_agente_$_agenteId.pdf",
    );
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esFechaInicio) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'), // ← fuerza español
      initialDate: (esFechaInicio ? _fechaInicio : _fechaFin) ?? DateTime.now(),
      firstDate: FECHA_INICIO_HISTORICA,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esFechaInicio) {
          _fechaInicio = fechaSeleccionada;
        } else {
          _fechaFin = fechaSeleccionada;
        }
      });
      _aplicarFiltros();
    }
  }

  String _formatearRangoFechas() {
    if (_fechaInicio == null && _fechaFin == null) return "histórico total";
    final format = DateFormat('dd/MM/yyyy', 'es_ES');
    final inicio = _fechaInicio != null ? format.format(_fechaInicio!) : "principio";
    final fin = _fechaFin != null ? format.format(_fechaFin!) : "hoy";
    return "del $inicio al $fin";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildContenido()),
    );
  }

  Widget _buildContenido() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.alertCircle, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(child: Text(_error!)),
            ]),
          ),
        ),
      );
    }
    if (_datosMostrados == null) {
      return const Center(child: Text("No hay datos de desempeño para mostrar."));
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFiltros(),
          const SizedBox(height: 16),
          _buildKpiGrid(_datosMostrados!),
          const SizedBox(height: 16),
          _buildCharts(_datosMostrados!),
          const SizedBox(height: 16),
          _buildCardReporteIA(),
          const SizedBox(height: 16),
          _buildTablaDesglose(_datosMostrados!),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Desempeño del Agente #$_agenteId",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          "Mostrando resultados para el período ${_formatearRangoFechas()}.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            OutlinedButton.icon(
              icon: Icon(LucideIcons.refreshCw, size: 16),
              label: const Text("Actualizar"),
              onPressed: _cargarDatos,
            ),
            // → Reemplazo por PDF
            ElevatedButton.icon(
              icon: Icon(LucideIcons.download, size: 16, color: Colors.white),
              label: const Text("PDF", style: TextStyle(color: Colors.white)),
              onPressed: _exportarPdf,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600),
            ),
            // Botón IA
            ElevatedButton.icon(
              icon: Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
              label: Text(_isIaLoading ? "Generando..." : "Análisis IA",
                  style: const TextStyle(color: Colors.white)),
              onPressed: _isIaLoading ? null : _pedirReporteIA,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildFiltros() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade100,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _buildDatePicker("Filtrar desde", _fechaInicio, (ctx) => _seleccionarFecha(ctx, true)),
            _buildDatePicker("Filtrar hasta", _fechaFin, (ctx) => _seleccionarFecha(ctx, false)),
            OutlinedButton.icon(
              icon: Icon(LucideIcons.xCircle, size: 16),
              label: const Text("Limpiar"),
              onPressed: _limpiarFiltros,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(BuildContext) onTap) {
    final format = DateFormat('dd/MM/yyyy', 'es_ES');
    return GestureDetector(
      onTap: () => onTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.calendar, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(date != null ? format.format(date) : "Seleccionar..."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(DesempenoModel d) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        // Más alto en pantallas angostas para evitar overflow
        final ratio = constraints.maxWidth > 800
            ? 1.8
            : (constraints.maxWidth > 600 ? 1.5 : (isNarrow ? 1.0 : 1.25));

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
          children: [
            _KpiCard(
              title: 'Tasa de Cierre (Desempeño)',
              value: '${d.kpis.desempeno.toStringAsFixed(1)}%',
              subtitle: d.kpis.nota,
            ),
            _KpiCard(
              title: 'Tasa de Publicación',
              value: '${d.kpis.tasaPublicacion.toStringAsFixed(1)}%',
              subtitle: 'Publicaciones con anuncio',
            ),
            _KpiCard(
              title: 'Total Publicaciones',
              value: d.totales.publicaciones.toString(),
              subtitle: 'en período seleccionado',
            ),
            _KpiCard(
              title: 'Total Anuncios',
              value: d.totales.anuncios.toString(),
              subtitle: 'en período seleccionado',
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharts(DesempenoModel d) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 800;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPieChart(d.estados)),
              const SizedBox(width: 16),
              Expanded(child: _buildBarChart(d.totales)),
            ],
          );
        }
        return Column(
          children: [
            _buildPieChart(d.estados),
            const SizedBox(height: 16),
            _buildBarChart(d.totales),
          ],
        );
      },
    );
  }

  Widget _buildPieChart(EstadosModel estados) {
    final Map<String, EstadoDetalleModel> estadosMap = estados.toJson().map(
      (key, value) => MapEntry(
        key.substring(0, 1).toUpperCase() + key.substring(1),
        EstadoDetalleModel.fromJson(value),
      ),
    );
    final filtered = estadosMap.entries.where((e) => e.value.count > 0).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Distribución por Estado",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: List.generate(filtered.length, (i) {
                    final entry = filtered[i];
                    return PieChartSectionData(
                      color: _chartColors[i % _chartColors.length],
                      value: entry.value.count.toDouble(),
                      title: '${entry.value.count}',
                      radius: 80,
                      titleStyle: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    );
                  }),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: List.generate(filtered.length, (i) {
                final entry = filtered[i];
                return Chip(
                  avatar: CircleAvatar(
                      backgroundColor: _chartColors[i % _chartColors.length], radius: 6),
                  label: Text(entry.key, style: const TextStyle(fontSize: 12)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(TotalesModel totales) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Resumen de Totales",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    _buildBarGroupData(0, totales.publicaciones.toDouble(), _chartColors[0]),
                    _buildBarGroupData(1, totales.publicacionesConAnuncio.toDouble(), _chartColors[2]),
                    _buildBarGroupData(2, totales.anuncios.toDouble(), _chartColors[1]),
                  ],
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
                          String text;
                          switch (value.toInt()) {
                            case 0:
                              text = 'Publicaciones';
                              break;
                            case 1:
                              text = 'Con Anuncio';
                              break;
                            case 2:
                              text = 'Anuncios';
                              break;
                            default:
                              text = '';
                              break;
                          }
                          return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(text, style: style));
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: color, width: 25, borderRadius: BorderRadius.circular(4))],
    );
  }

  Widget _buildCardReporteIA() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Análisis con IA",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (_iaText != null && !_isIaLoading)
                OutlinedButton.icon(
                  icon: Icon(LucideIcons.copy, size: 14),
                  label: const Text("Copiar"),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _iaText!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Reporte copiado al portapapeles.")),
                    );
                  },
                )
            ]),
            const SizedBox(height: 16),
            if (_iaError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(LucideIcons.alertCircle, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Flexible(child: Text(_iaError!, style: TextStyle(color: Colors.red.shade800))),
                ]),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minHeight: 100),
              child: _isIaLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      _iaText ??
                          "Haz clic en \"Análisis IA\" para obtener un resumen y recomendaciones automáticas sobre el desempeño en el período seleccionado.",
                      style: TextStyle(
                          color: _iaText != null ? Colors.black87 : Colors.grey.shade600, height: 1.5),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaDesglose(DesempenoModel d) {
    final Map<String, EstadoDetalleModel> estadosMap = d.estados.toJson().map(
      (key, value) => MapEntry(
        key.substring(0, 1).toUpperCase() + key.substring(1),
        EstadoDetalleModel.fromJson(value),
      ),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // ← evita RIGHT OVERFLOWED
        child: DataTable(
          columns: const [
            DataColumn(
                label: Text('Estado del Anuncio', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold)),
                numeric: true),
            DataColumn(
                label: Text('% del Total', style: TextStyle(fontWeight: FontWeight.bold)),
                numeric: true),
          ],
          rows: estadosMap.entries.map((entry) {
            final index = estadosMap.keys.toList().indexOf(entry.key);
            return DataRow(cells: [
              DataCell(Row(children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _chartColors[index % _chartColors.length],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(entry.key),
              ])),
              DataCell(Text(entry.value.count.toString())),
              DataCell(Text('${entry.value.pct.toStringAsFixed(2)}%')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _KpiCard({required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
