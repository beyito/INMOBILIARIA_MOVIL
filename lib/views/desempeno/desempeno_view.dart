// lib/pages/desempeno_view.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/desempeno/desempeno_model.dart'; // Ajusta la ruta si es necesario
import '../../services/desempeno/desempeno_service.dart'; // Ajusta la ruta si es necesario

class DesempenoView extends StatefulWidget {
  const DesempenoView({super.key});

  @override
  State<DesempenoView> createState() => _DesempenoViewState();
}

class _DesempenoViewState extends State<DesempenoView> {
  Future<DesempenoModel>? _futureDesempeno;
  final DesempenoService _desempenoService = DesempenoService();

  String? _iaReporte;
  bool _isIaLoading = false;
  String? _iaError;

  final List<Color> _chartColors = const [
    Color(0xFF0ea5e9), Color(0xFF22c55e), Color(0xFFf97316),
    Color(0xFFa78bfa), Color(0xFFef4444), Color(0xFF14b8a6)
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final agenteId = prefs.getInt('id') ?? 0;

    if (agenteId != 0) {
      setState(() {
        _futureDesempeno = _desempenoService.getDesempenoAgente(agenteId);
      });
    } else {
      setState(() {
         _futureDesempeno = Future.error("No se encontró el ID del agente.");
      });
    }
  }

  Future<void> _pedirReporteIA(DesempenoModel data) async {
    setState(() {
      _isIaLoading = true;
      _iaError = null;
    });
    try {
      final reporte = await _desempenoService.getReporteIA(data);
      setState(() {
        _iaReporte = reporte;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Desempeño'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _futureDesempeno == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<DesempenoModel>(
              future: _futureDesempeno!,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.hasData) {
                  final desempeno = snapshot.data!;
                  return _buildDashboard(desempeno);
                }
                return const Center(child: Text('No hay datos.'));
              },
            ),
    );
  }

  Widget _buildDashboard(DesempenoModel desempeno) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildKpiGrid(desempeno),
          const SizedBox(height: 24),
          Text(
            "Gráficos de Desempeño",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPieChart(desempeno.estados),
          const SizedBox(height: 24),
          _buildBarChart(desempeno.totales),
          const SizedBox(height: 24),
          _buildCardReporteIA(desempeno),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(DesempenoModel desempeno) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, // Reducido el espaciado
      mainAxisSpacing: 12, // Reducido el espaciado
      childAspectRatio: 1.6, // Ajustado el aspecto para más espacio vertical
      children: [
        _KpiCard(
          title: 'Desempeño',
          value: '${desempeno.kpis.desempeno.toStringAsFixed(1)}%',
          subtitle: desempeno.kpis.nota,
          color: Colors.blue.shade700,
        ),
        _KpiCard(
          title: 'Tasa Publicación',
          value: '${desempeno.kpis.tasaPublicacion.toStringAsFixed(1)}%',
          subtitle: 'Con anuncio',
          color: Colors.green.shade700,
        ),
        _KpiCard(
          title: 'Publicaciones',
          value: desempeno.totales.publicaciones.toString(),
          subtitle: 'Total creadas',
          color: Colors.orange.shade700,
        ),
        _KpiCard(
          title: 'Anuncios',
          value: desempeno.totales.anuncios.toString(),
          subtitle: 'Activos',
          color: Colors.purple.shade700,
        ),
      ],
    );
  }

  Widget _buildPieChart(EstadosModel estados) {
    final List<MapEntry<String, EstadoDetalleModel>> entries = [
      MapEntry('Vendido', estados.vendido),
      MapEntry('Anticrético', estados.anticretico),
      MapEntry('Alquilado', estados.alquilado),
      MapEntry('Otros', estados.otros),
    ];

    // Filtramos los que tienen count > 0 para la leyenda y el gráfico
    final filteredEntries = entries.where((e) => e.value.count > 0).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8), // Margen para separar
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Distribución por Estado",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200, // Altura fija para el gráfico
              child: PieChart(
                PieChartData(
                  sections: List.generate(filteredEntries.length, (i) {
                    final entry = filteredEntries[i];
                    return PieChartSectionData(
                      color: _chartColors[i % _chartColors.length],
                      value: entry.value.count.toDouble(),
                      title: '${entry.value.count}',
                      radius: 60, // Radio reducido para más espacio
                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    );
                  }),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  // Aquí podemos añadir un título central si queremos
                  // Puedes usar un Stack y un Align para poner un Text en el centro
                  // Por simplicidad, lo dejo sin título central por ahora.
                ),
              ),
            ),
            const SizedBox(height: 16),
             Wrap( // Leyenda
              spacing: 8.0,
              runSpacing: 8.0, // Más espacio entre filas de chips
              alignment: WrapAlignment.center,
              children: List.generate(filteredEntries.length, (i) {
                final entry = filteredEntries[i];
                return Chip(
                  avatar: CircleAvatar(backgroundColor: _chartColors[i % _chartColors.length], radius: 6),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Text(
               "Resumen de Totales",
               style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: totales.publicaciones.toDouble(), color: _chartColors[0], width: 28, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: totales.publicacionesConAnuncio.toDouble(), color: _chartColors[2], width: 28, borderRadius: BorderRadius.circular(4))]), // Usado COLORS[2] para que coincida con la web
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: totales.anuncios.toDouble(), color: _chartColors[1], width: 28, borderRadius: BorderRadius.circular(4))]), // Usado COLORS[1] para que coincida con la web
                  ],
                  borderData: FlBorderData(show: false), // Ocultar bordes para un look más limpio
                  gridData: const FlGridData(show: true, drawVerticalLine: false), // Solo líneas horizontales
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(fontSize: 12, color: Colors.black87); // Mejor color y tamaño
                          String text;
                          switch (value.toInt()) {
                            case 0: text = 'Publicaciones'; break;
                            case 1: text = 'Con Anuncio'; break;
                            case 2: text = 'Anuncios'; break;
                            default: text = ''; break;
                          }
                          return Padding( // Espacio para que no toque las barras
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(text, style: style, textAlign: TextAlign.center),
                          );
                        },
                        reservedSize: 40, // Más espacio para los títulos del eje X
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32, // Espacio para los números del eje Y
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.black54));
                        },
                      ),
                    ),
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

  Widget _buildCardReporteIA(DesempenoModel desempeno) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Reporte con IA (Gemini)",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isIaLoading ? "Generando…" : "Generar"),
                  onPressed: _isIaLoading ? null : () => _pedirReporteIA(desempeno),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isIaLoading) const Center(child: CircularProgressIndicator()),
            if (_iaError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Error: $_iaError", style: const TextStyle(color: Colors.red)),
              ),
            if (_iaReporte != null && !_isIaLoading)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MarkdownBody(data: _iaReporte!),
              )
            else if (_iaReporte == null && !_isIaLoading && _iaError == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Aún no hay reporte. Haz clic en “Generar”.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Padding ajustado
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espacio entre elementos
          children: [
            FittedBox( // Asegura que el título quepa
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            FittedBox( // Asegura que el valor quepa
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), // Tamaño de fuente ajustado
            ),
            FittedBox( // Asegura que el subtítulo quepa
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)), // Tamaño de fuente más pequeño
            ),
          ],
        ),
      ),
    );
  }
}