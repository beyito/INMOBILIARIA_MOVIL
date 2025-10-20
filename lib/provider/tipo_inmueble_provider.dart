// lib/providers/tipo_inmueble_provider.dart

import 'package:flutter/material.dart';

import '../models/tipoinmueble/tipo_inmueble_model.dart';
import '../services/inmueble/inmueble_service.dart';


class TipoInmuebleProvider with ChangeNotifier {
  final InmuebleService _inmuebleService = InmuebleService();

  List<TipoInmueble> _tipos = [];
  bool _isLoading = false;
  String? _error;
  String _busqueda = "";

  // Getters para acceder al estado desde la UI
  List<TipoInmueble> get tipos {
    if (_busqueda.isEmpty) {
      return _tipos;
    }
    final q = _busqueda.toLowerCase();
    return _tipos.where((t) {
      return t.nombre.toLowerCase().contains(q) ||
          (t.descripcion ?? "").toLowerCase().contains(q);
    }).toList();
  }
  
  int get totalCount => _tipos.length;
  int get activosCount => _tipos.where((t) => t.isActive).length;
  int get inactivosCount => totalCount - activosCount;

  bool get isLoading => _isLoading;
  String? get error => _error;

  TipoInmuebleProvider() {
    fetchData();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notifica a la UI que actualice

    try {
      _tipos = await _inmuebleService.listarTipos();
    } catch (e) {
      _error = "No se pudo cargar el listado";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void buscar(String query) {
    _busqueda = query;
    notifyListeners();
  }

  Future<void> crearOActualizar({TipoInmueble? tipo, required String nombre, required String descripcion}) async {
    final payload = {'nombre': nombre, 'descripcion': descripcion};
    
    try {
      if (tipo != null) { // Actualizando
        await _inmuebleService.actualizarTipo(tipo.id, payload);
      } else { // Creando
        await _inmuebleService.crearTipo(payload);
      }
      await fetchData(); // Recargar datos
    } catch (e) {
      // En una app real, manejarías este error de forma más elegante
      rethrow;
    }
  }

  Future<void> eliminar(int id) async {
    await _inmuebleService.eliminarTipo(id);
    await fetchData();
  }

  Future<void> activar(int id) async {
    await _inmuebleService.activarTipo(id);
    await fetchData();
  }
}