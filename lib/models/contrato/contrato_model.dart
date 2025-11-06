class ContratoServicios {
  String ciudad;
  String fecha;
  String empresaNombre;
  String empresaRepresentante;
  String empresaCi;
  String empresaDomicilio;
  String clienteNombre;
  String clienteCi;
  String clienteEstadoCivil;
  String clienteProfesion;
  String clienteDomicilio;
  String agenteNombre;
  String agenteCi;
  String agenteEstadoCivil;
  String agenteDomicilio;
  String inmuebleDireccion;
  String inmuebleSuperficie;
  String inmuebleDistrito;
  String inmuebleManzana;
  String inmuebleLote;
  String inmuebleZona;
  String inmuebleMatricula;
  String precioInmueble;
  String comision;
  String vigenciaDias;
  String direccionOficina;
  String telefonoOficina;
  String emailOficina;
  int agenteId;
  int inmuebleId;

  ContratoServicios({
    required this.ciudad,
    required this.fecha,
    required this.empresaNombre,
    required this.empresaRepresentante,
    required this.empresaCi,
    required this.empresaDomicilio,
    required this.clienteNombre,
    required this.clienteCi,
    required this.clienteEstadoCivil,
    required this.clienteProfesion,
    required this.clienteDomicilio,
    required this.agenteNombre,
    required this.agenteCi,
    required this.agenteEstadoCivil,
    required this.agenteDomicilio,
    required this.inmuebleDireccion,
    required this.inmuebleSuperficie,
    required this.inmuebleDistrito,
    required this.inmuebleManzana,
    required this.inmuebleLote,
    required this.inmuebleZona,
    required this.inmuebleMatricula,
    required this.precioInmueble,
    required this.comision,
    required this.vigenciaDias,
    required this.direccionOficina,
    required this.telefonoOficina,
    required this.emailOficina,
    required this.agenteId,
    required this.inmuebleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'ciudad': ciudad,
      'fecha': fecha,
      'empresa_nombre': empresaNombre,
      'empresa_representante': empresaRepresentante,
      'empresa_ci': empresaCi,
      'empresa_domicilio': empresaDomicilio,
      'cliente_nombre': clienteNombre,
      'cliente_ci': clienteCi,
      'cliente_estado_civil': clienteEstadoCivil,
      'cliente_profesion': clienteProfesion,
      'cliente_domicilio': clienteDomicilio,
      'agente_nombre': agenteNombre,
      'agente_ci': agenteCi,
      'agente_estado_civil': agenteEstadoCivil,
      'agente_domicilio': agenteDomicilio,
      'inmueble_direccion': inmuebleDireccion,
      'inmueble_superficie': inmuebleSuperficie,
      'inmueble_distrito': inmuebleDistrito,
      'inmueble_manzana': inmuebleManzana,
      'inmueble_lote': inmuebleLote,
      'inmueble_zona': inmuebleZona,
      'inmueble_matricula': inmuebleMatricula,
      'precio_inmueble': precioInmueble,
      'comision': comision,
      'vigencia_dias': vigenciaDias,
      'direccion_oficina': direccionOficina,
      'telefono_oficina': telefonoOficina,
      'email_oficina': emailOficina,
      'agente_id': agenteId,
      'inmueble_id': inmuebleId,
    };
  }

  // Método fromJson si lo necesitas
  factory ContratoServicios.fromJson(Map<String, dynamic> json) {
    return ContratoServicios(
      ciudad: json['ciudad'] ?? '',
      fecha: json['fecha'] ?? '',
      empresaNombre: json['empresa_nombre'] ?? '',
      empresaRepresentante: json['empresa_representante'] ?? '',
      empresaCi: json['empresa_ci'] ?? '',
      empresaDomicilio: json['empresa_domicilio'] ?? '',
      clienteNombre: json['cliente_nombre'] ?? '',
      clienteCi: json['cliente_ci'] ?? '',
      clienteEstadoCivil: json['cliente_estado_civil'] ?? '',
      clienteProfesion: json['cliente_profesion'] ?? '',
      clienteDomicilio: json['cliente_domicilio'] ?? '',
      agenteNombre: json['agente_nombre'] ?? '',
      agenteCi: json['agente_ci'] ?? '',
      agenteEstadoCivil: json['agente_estado_civil'] ?? '',
      agenteDomicilio: json['agente_domicilio'] ?? '',
      inmuebleDireccion: json['inmueble_direccion'] ?? '',
      inmuebleSuperficie: json['inmueble_superficie'] ?? '',
      inmuebleDistrito: json['inmueble_distrito'] ?? '',
      inmuebleManzana: json['inmueble_manzana'] ?? '',
      inmuebleLote: json['inmueble_lote'] ?? '',
      inmuebleZona: json['inmueble_zona'] ?? '',
      inmuebleMatricula: json['inmueble_matricula'] ?? '',
      precioInmueble: json['precio_inmueble'] ?? '',
      comision: json['comision'] ?? '',
      vigenciaDias: json['vigencia_dias'] ?? '',
      direccionOficina: json['direccion_oficina'] ?? '',
      telefonoOficina: json['telefono_oficina'] ?? '',
      emailOficina: json['email_oficina'] ?? '',
      agenteId: json['agente_id'] ?? 0,
      inmuebleId: json['inmueble_id'] ?? 0,
    );
  }
}
