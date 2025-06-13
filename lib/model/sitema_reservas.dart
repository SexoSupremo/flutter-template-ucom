class Cliente {
  String id;
  String nombre;
  String apellido;
  String telefono;
  List<Auto> autos;

  Cliente({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.autos,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'],
        nombre: json['nombre'],
        apellido: json['apellido'],
        telefono: json['telefono'],
        autos: List.empty(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
        'autos': autos.map((a) => a.toJson()).toList(),
      };
}

class Auto {
  String chapa;
  String marca;
  String modelo;
  String chasis;
  String clienteId;

  Auto(
      {required this.chapa,
      required this.marca,
      required this.modelo,
      required this.chasis,
      required this.clienteId});

  factory Auto.fromJson(Map<String, dynamic> json) => Auto(
        chapa: json['chapa'],
        marca: json['marca'],
        modelo: json['modelo'],
        chasis: json['chasis'],
        clienteId: json['clienteId'],
      );

  Map<String, dynamic> toJson() => {
        'chapa': chapa,
        'marca': marca,
        'modelo': modelo,
        'chasis': chasis,
        'clienteId': clienteId
      };
}

class Piso {
  String codigo;
  String descripcion;
  List<Lugar> lugares;

  Piso({
    required this.codigo,
    required this.descripcion,
    required this.lugares,
  });

  factory Piso.fromJson(Map<String, dynamic> json) => Piso(
        codigo: json['codigo'],
        descripcion: json['descripcion'],
        lugares:
            (json['lugares'] as List).map((l) => Lugar.fromJson(l)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'descripcion': descripcion,
        'lugares': lugares.map((l) => l.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piso &&
          runtimeType == other.runtimeType &&
          codigo == other.codigo;

  @override
  int get hashCode => codigo.hashCode;
}

class Lugar {
  String codigoPiso;
  String codigoLugar;
  String descripcionLugar;
  String estado; // disponible, reservado, ocupado

  Lugar({
    required this.codigoPiso,
    required this.codigoLugar,
    required this.descripcionLugar,
    this.estado = "disponible",
  });

  factory Lugar.fromJson(Map<String, dynamic> json) => Lugar(
        codigoPiso: json['codigoPiso'],
        codigoLugar: json['codigoLugar'],
        descripcionLugar: json['descripcionLugar'],
        estado: json['estado'] ?? "disponible",
      );

  Map<String, dynamic> toJson() => {
        'codigoPiso': codigoPiso,
        'codigoLugar': codigoLugar,
        'descripcionLugar': descripcionLugar,
        'estado': estado,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lugar &&
          runtimeType == other.runtimeType &&
          codigoLugar == other.codigoLugar &&
          codigoPiso == other.codigoPiso;

  @override
  int get hashCode => Object.hash(codigoPiso, codigoLugar);
}

class Reserva {
  String codigoReserva;
  DateTime horarioInicio;
  DateTime horarioSalida;
  double monto;
  String estadoReserva;
  String chapaAuto; // solo la chapa

  Reserva({
    required this.codigoReserva,
    required this.horarioInicio,
    required this.horarioSalida,
    required this.monto,
    required this.estadoReserva,
    required this.chapaAuto,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
        codigoReserva: json['codigoReserva'],
        horarioInicio: DateTime.parse(json['horarioInicio']),
        horarioSalida: DateTime.parse(json['horarioSalida']),
        monto: json['monto'].toDouble(),
        estadoReserva: json['estadoReserva'],
        chapaAuto: json['chapaAuto'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'codigoReserva': codigoReserva,
        'horarioInicio': horarioInicio.toIso8601String(),
        'horarioSalida': horarioSalida.toIso8601String(),
        'monto': monto,
        'estadoReserva': estadoReserva,
        'chapaAuto': chapaAuto,
      };
}

class Pago {
  final String codigoPago;
  final String codigoReservaAsociada;
  final double montoPagado;
  final DateTime fechaPago;
  final String estadoPago;

  Pago({
    required this.codigoPago,
    required this.codigoReservaAsociada,
    required this.montoPagado,
    required this.fechaPago,
    required this.estadoPago,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      codigoPago: json['codigoPago'],
      codigoReservaAsociada: json['codigoReservaAsociada'],
      montoPagado: (json['montoPagado'] as num).toDouble(),
      fechaPago: DateTime.parse(json['fechaPago']),
      estadoPago: json['estadoPago'],
    );
  }

  Map<String, dynamic> toJson() => {
        'codigoPago': codigoPago,
        'codigoReservaAsociada': codigoReservaAsociada,
        'montoPagado': montoPagado,
        'fechaPago': fechaPago.toIso8601String(),
      };
}
