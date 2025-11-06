// views/comisiones/dashboard_comisiones_agente.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/comisiones/comisiones_model.dart';
import '../../services/comisiones/comisiones_service.dart';

class DashboardComisionesAgente extends StatefulWidget {
  const DashboardComisionesAgente({super.key});

  @override
  State<DashboardComisionesAgente> createState() =>
      _DashboardComisionesAgenteState();
}

class _DashboardComisionesAgenteState extends State<DashboardComisionesAgente> {
  final ComisionesService _comisionesService = ComisionesService();

  ComisionesAgente? _datos;
  bool _loading = false;
  String _message = '';

  // Filtros
  String _fechaInicio = '';
  String _fechaFin = '';
  String _tipoContrato = 'todos';
  bool _incluirServicios = false;

  final List<Map<String, String>> _tiposContrato = [
    {'value': 'todos', 'label': 'Todos los contratos'},
    {'value': 'venta', 'label': 'Ventas'},
    {'value': 'alquiler', 'label': 'Alquileres'},
    {'value': 'anticretico', 'label': 'Anticréticos'},
  ];

  Map<String, dynamic>? _currentUser;
  bool _isAgente = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioActual();
  }

  Future<void> _cargarUsuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_profile');

    if (userString != null) {
      setState(() {
        _currentUser = json.decode(userString) as Map<String, dynamic>;
        _isAgente = _currentUser?['grupo_id'] == 2;
      });

      if (_isAgente) {
        _cargarDashboard();
      }
    }
  }

  Future<void> _cargarDashboard() async {
    if (_currentUser == null) return;

    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      final datos = await _comisionesService.getDetalleComisionesAgente(
        agenteId: _currentUser!['id'],
        fechaInicio: _fechaInicio.isNotEmpty ? _fechaInicio : null,
        fechaFin: _fechaFin.isNotEmpty ? _fechaFin : null,
        tipoContrato: _tipoContrato != 'todos' ? _tipoContrato : null,
        incluirServicios: _incluirServicios,
      );

      setState(() {
        _datos = datos;
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _aplicarFiltros() {
    _cargarDashboard();
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = '';
      _fechaFin = '';
      _tipoContrato = 'todos';
      _incluirServicios = false;
    });
    _cargarDashboard();
  }

  void _toggleIncluirServicios(bool value) {
    setState(() {
      _incluirServicios = value;
    });
    _cargarDashboard();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cargando tus comisiones...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSinDatos() {
    return Column(
      children: [
        // Header
        _buildHeader(),
        const SizedBox(height: 16),

        // Mensaje sin datos
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.attach_money, size: 48, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  'No hay datos disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No se encontraron comisiones en el período seleccionado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.amber[700]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _toggleIncluirServicios(true),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Incluir contratos de servicios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Título
        Text(
          'Mis Comisiones',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Resumen de tus contratos y comisiones generadas',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        // Toggle simple
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _incluirServicios ? Icons.visibility : Icons.visibility_off,
              color: _incluirServicios ? Colors.blue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Incluir servicios',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _incluirServicios,
              onChanged: _toggleIncluirServicios,
              activeThumbColor: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _limpiarFiltros,
                  icon: Icon(Icons.clear, size: 16),
                  label: Text('Limpiar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Campos de fecha
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha Inicio', style: TextStyle(fontSize: 12)),
                      TextField(
                        controller: TextEditingController(text: _fechaInicio),
                        decoration: InputDecoration(
                          hintText: 'YYYY-MM-DD',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _seleccionarFecha(true),
                          ),
                        ),
                        onChanged: (value) => _fechaInicio = value,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha Fin', style: TextStyle(fontSize: 12)),
                      TextField(
                        controller: TextEditingController(text: _fechaFin),
                        decoration: InputDecoration(
                          hintText: 'YYYY-MM-DD',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _seleccionarFecha(false),
                          ),
                        ),
                        onChanged: (value) => _fechaFin = value,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tipo de contrato
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo de Contrato', style: TextStyle(fontSize: 12)),
                DropdownButtonFormField<String>(
                  initialValue: _tipoContrato,
                  items: _tiposContrato.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo['value'],
                      child: Text(tipo['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoContrato = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Botón aplicar
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _aplicarFiltros,
                icon: Icon(Icons.filter_list),
                label: Text('Aplicar Filtros'),
              ),
            ),
            // Info sobre servicios
            if (!_incluirServicios)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contratos de servicios excluidos - son prospectos y no generan comisiones reales',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            if (_incluirServicios)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contratos de servicios incluidos - mostrando comisiones potenciales',
                        style:
                            TextStyle(fontSize: 12, color: Colors.amber[700]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticas() {
    final stats = _datos!.statsAgente;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildTarjetaEstadistica(
          titulo: 'Total Contratos',
          valor: stats.totalContratos.toString(),
          icono: Icons.description,
          color: Colors.blue,
          subtitulo: _incluirServicios ? 'Incl. servicios' : null,
        ),
        _buildTarjetaEstadistica(
          titulo: _incluirServicios
              ? 'Total Comisiones (pot.)'
              : 'Total Comisiones',
          valor: '\$${stats.totalComision.toInt()}',
          icono: Icons.attach_money,
          color: _incluirServicios ? Colors.amber : Colors.green,
        ),
        _buildTarjetaEstadistica(
          titulo: 'Comisión Promedio',
          valor: '${stats.comisionPromedio.toStringAsFixed(2)}%',
          icono: Icons.trending_up,
          color: Colors.purple,
        ),
        _buildTarjetaEstadistica(
          titulo: 'Valor Total Contratos',
          valor: '\$${stats.montoTotalContratos.toInt()}',
          icono: Icons.bar_chart,
          color: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildTarjetaEstadistica({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    String? subtitulo,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        valor,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (subtitulo != null)
                        Text(
                          subtitulo,
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: color, size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformacionAgente() {
    final stats = _datos!.statsAgente;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Mi Información',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildInfoItem('Nombre:', stats.agenteNombre),
                _buildInfoItem('Usuario:', '@${stats.agenteUsername}'),
                _buildInfoItem(
                    'Contratos activos:', stats.totalContratos.toString(),
                    esNumero: true),
                _buildInfoItem('Valor gestionado:',
                    '\$${stats.montoTotalContratos.toInt()}',
                    esNumero: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool esNumero = false}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: esNumero ? Colors.blue : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaContratos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Mis Contratos${_incluirServicios ? ' (incl. servicios)' : ''}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_datos!.contratos.isEmpty)
              Column(
                children: [
                  Icon(Icons.description, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes contratos en el período seleccionado',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _datos!.contratos.length,
                itemBuilder: (context, index) {
                  final contrato = _datos!.contratos[index];
                  final esServicio = contrato.tipoContrato == 'servicios';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: esServicio ? Colors.amber : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: esServicio ? Colors.amber[50] : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contrato.cliente,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    contrato.inmueble,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_capitalize(contrato.tipoContrato)} • ${_formatearFecha(contrato.fechaContrato)}',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                  if (esServicio)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '📋 Contrato de Servicios (Comisión Potencial)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.amber[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Monto del contrato
                                Text(
                                  '\$${contrato.montoContrato.toInt()}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  'Valor del contrato',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Comisión
                                Text(
                                  '\$${contrato.comisionMonto.toInt()}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: esServicio
                                        ? Colors.amber
                                        : Colors.green,
                                  ),
                                ),
                                Text(
                                  '${contrato.comisionPorcentaje}% de comisión',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contrato.estado,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final fecha = picked.toIso8601String().split('T')[0];
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAgente) {
      return Scaffold(
        appBar: AppBar(title: Text('Mis Comisiones')),
        body: Center(
          child: Text('Esta función solo está disponible para agentes'),
        ),
      );
    }

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Mis Comisiones')),
        body: _buildLoading(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Comisiones'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_datos == null)
              _buildSinDatos()
            else ...[
              _buildHeader(),
              const SizedBox(height: 16),
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_message),
                ),
              _buildFiltros(),
              const SizedBox(height: 16),
              _buildEstadisticas(),
              const SizedBox(height: 16),
              _buildInformacionAgente(),
              const SizedBox(height: 16),
              _buildListaContratos(),
            ],
          ],
        ),
      ),
    );
  }
}
