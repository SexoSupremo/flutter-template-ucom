import 'package:finpay/model/sitema_reservas.dart';
import 'package:get/get.dart';
import 'package:finpay/api/local.db.service.dart';
import 'package:flutter/material.dart';

class ReservaControllerAlumno extends GetxController {
  // Observables para datos de las reservas
  RxList<Piso> pisos = <Piso>[].obs;
  Rx<Piso?> pisoSeleccionado = Rx<Piso?>(null);
  RxList<Lugar> lugaresDisponibles = <Lugar>[].obs;
  Rx<Lugar?> lugarSeleccionado = Rx<Lugar?>(null);
  
  // Observables para horarios
  Rx<DateTime?> horarioInicio = Rx<DateTime?>(null);
  Rx<DateTime?> horarioSalida = Rx<DateTime?>(null);
  RxInt duracionSeleccionada = 0.obs;
  
  // Observables para datos del alumno
  RxList<Auto> autosAlumno = <Auto>[].obs;
  Rx<Auto?> autoSeleccionado = Rx<Auto?>(null);
  
  // ID del alumno actual 
  String codigoAlumnoActual = 'alumno_1';
  
  // Historial de reservas del alumno
  RxList<Reserva> historialReservas = <Reserva>[].obs;
  
  // Servicio de base de datos local
  final LocalDBService db = LocalDBService();
  
  // Estado de carga
  RxBool isLoading = false.obs;
  
  // Mensajes de error o éxito
  Rx<String?> mensajeEstado = Rx<String?>(null);
  
  @override
  void onInit() {
    super.onInit();
    resetearCampos();
    cargarAutosDelAlumno();
    cargarPisosYLugares();
    cargarHistorialReservas();
  }
  
  // Método para resetear todos los campos de selección
  void resetearCampos() {
    pisoSeleccionado.value = null;
    lugarSeleccionado.value = null;
    horarioInicio.value = null;
    horarioSalida.value = null;
    autoSeleccionado.value = null;
    duracionSeleccionada.value = 0;
  }
  
  // Cargar los autos registrados del usuario actual
  Future<void> cargarAutosDelAlumno() async {
    isLoading.value = true;
    try {
      // Obtener todos los autos de la base de datos
      final rawAutos = await db.getAll("autos.json");
      
      // Filtrar solo los autos del usuario actual
      autosAlumno.value = rawAutos
        .map((e) => Auto.fromJson(e))
        .where((auto) => auto.clienteId == codigoAlumnoActual)
        .toList();
    } catch (e) {
      mensajeEstado.value = "Error al cargar los autos: $e";
    } finally {
      isLoading.value = false;
    }
  }
  
  // Cargar los pisos y lugares disponibles
  Future<void> cargarPisosYLugares() async {
    isLoading.value = true;
    try {
      final rawPisos = await db.getAll("pisos.json");
      final rawLugares = await db.getAll("lugares.json");
      final rawReservas = await db.getAll("reservas.json");
      
      final reservas = rawReservas.map((e) => Reserva.fromJson(e)).toList();
      
      // Obtener los códigos de lugares que están reservados actualmente
      final lugaresReservados = reservas
        .where((r) => r.estadoReserva != "cancelada" && 
                     r.estadoReserva != "completada")
        .map((r) => r.codigoReserva)
        .toSet();
      
      final todosLugares = rawLugares.map((e) => Lugar.fromJson(e)).toList();
      
      // Unir pisos con sus lugares correspondientes
      pisos.value = rawPisos.map((pJson) {
        final codigoPiso = pJson['codigo'];
        final lugaresDelPiso = todosLugares
          .where((l) => l.codigoPiso == codigoPiso)
          .toList();
        
        return Piso(
          codigo: codigoPiso,
          descripcion: pJson['descripcion'],
          lugares: lugaresDelPiso,
        );
      }).toList();
      
      // Inicializar lugares disponibles (solo los no reservados)
      actualizarLugaresDisponibles();
    } catch (e) {
      mensajeEstado.value = "Error al cargar pisos y lugares: $e";
    } finally {
      isLoading.value = false;
    }
  }
  
  // Actualizar lugares disponibles basados en el piso seleccionado
  void actualizarLugaresDisponibles() {
    if (pisoSeleccionado.value == null) {
      lugaresDisponibles.clear();
      return;
    }
    
    lugaresDisponibles.value = pisoSeleccionado.value!.lugares
      .where((lugar) => lugar.estado == "disponible")
      .toList();
  }
  
  // Seleccionar un piso y actualizar lugares disponibles
  Future<void> seleccionarPiso(Piso piso) async {
    pisoSeleccionado.value = piso;
    lugarSeleccionado.value = null;
    actualizarLugaresDisponibles();
    return Future.value();
  }
  
  // Seleccionar un lugar específico
  void seleccionarLugar(Lugar lugar) {
    lugarSeleccionado.value = lugar;
  }
  
  // Seleccionar un auto
  void seleccionarAuto(Auto auto) {
    autoSeleccionado.value = auto;
  }
  
  // Establecer horario de inicio
  void establecerHorarioInicio(DateTime hora) {
    horarioInicio.value = hora;
    actualizarDuracion();
  }
  
  // Establecer horario de salida
  void establecerHorarioSalida(DateTime hora) {
    horarioSalida.value = hora;
    actualizarDuracion();
  }
  
  // Actualizar la duración de la reserva
  void actualizarDuracion() {
    if (horarioInicio.value != null && horarioSalida.value != null) {
      final minutos = horarioSalida.value!.difference(horarioInicio.value!).inMinutes;
      duracionSeleccionada.value = minutos ~/ 60;
    }
  }
  
  // Calcular el monto de la reserva basado en la duración
  double calcularMonto() {
    if (horarioInicio.value == null || horarioSalida.value == null) return 0.0;
    
    final duracionEnHoras = 
        horarioSalida.value!.difference(horarioInicio.value!).inMinutes / 60;
        
    if (duracionEnHoras <= 0) return 0.0;
    
    // 10,000 Gs por hora (definir precio por hora según necesidad)
    final montoCalculado = (duracionEnHoras * 10000).roundToDouble();
    return montoCalculado;
  }
  
  // Cargar el historial de reservas del alumno actual
  Future<void> cargarHistorialReservas() async {
    isLoading.value = true;
    try {
      final rawReservas = await db.getAll("reservas.json");
      final rawAutos = await db.getAll("autos.json");
      
      // Obtener las chapas de los autos del alumno
      final autosDelAlumno = rawAutos
        .map((e) => Auto.fromJson(e))
        .where((auto) => auto.clienteId == codigoAlumnoActual)
        .map((auto) => auto.chapa)
        .toSet();
      
      // Filtrar reservas que corresponden a los autos del alumno
      historialReservas.value = rawReservas
        .map((e) => Reserva.fromJson(e))
        .where((reserva) => autosDelAlumno.contains(reserva.chapaAuto))
        .toList();
      
      // Ordenar por fecha más reciente primero
      historialReservas.sort((a, b) => b.horarioInicio.compareTo(a.horarioInicio));
    } catch (e) {
      mensajeEstado.value = "Error al cargar historial de reservas: $e";
    } finally {
      isLoading.value = false;
    }
  }
  
  // Confirmar una nueva reserva
  Future<bool> confirmarReserva() async {
    // Validar que todos los campos necesarios estén completos
    if (pisoSeleccionado.value == null ||
        lugarSeleccionado.value == null ||
        horarioInicio.value == null ||
        horarioSalida.value == null ||
        autoSeleccionado.value == null) {
      mensajeEstado.value = "Todos los campos son obligatorios";
      return false;
    }
    
    // Verificar que la duración sea válida
    final duracionEnHoras = 
        horarioSalida.value!.difference(horarioInicio.value!).inMinutes / 60;
    
    if (duracionEnHoras <= 0) {
      mensajeEstado.value = "La hora de salida debe ser posterior a la hora de inicio";
      return false;
    }
    
    // Calcular el monto
    final montoCalculado = calcularMonto();
    
    isLoading.value = true;
    try {
      // Crear nueva reserva
      final nuevaReserva = Reserva(
        codigoReserva: "RES-A-${DateTime.now().millisecondsSinceEpoch}",
        horarioInicio: horarioInicio.value!,
        horarioSalida: horarioSalida.value!,
        monto: montoCalculado,
        estadoReserva: "pendiente", // pendiente, confirmada, cancelada, completada
        chapaAuto: autoSeleccionado.value!.chapa,
      );
      
      // Guardar la reserva en la base de datos
      final reservas = await db.getAll("reservas.json");
      reservas.add(nuevaReserva.toJson());
      await db.saveAll("reservas.json", reservas);
      
      // Actualizar el estado del lugar a reservado
      final lugares = await db.getAll("lugares.json");
      final lugarIndex = lugares.indexWhere((l) => 
        l['codigoLugar'] == lugarSeleccionado.value!.codigoLugar);
      
      if (lugarIndex >= 0) {
        lugares[lugarIndex]['estado'] = 'reservado';
        await db.saveAll("lugares.json", lugares);
      }
      
      // Actualizar listas locales
      await cargarPisosYLugares();
      await cargarHistorialReservas();
      
      // Limpiar selección
      resetearCampos();
      
      mensajeEstado.value = "Reserva creada exitosamente";
      return true;
    } catch (e) {
      mensajeEstado.value = "Error al crear la reserva: $e";
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Cancelar una reserva existente
  Future<bool> cancelarReserva(String codigoReserva) async {
    isLoading.value = true;
    try {
      final reservas = await db.getAll("reservas.json");
      final reservaIndex = reservas.indexWhere((r) => r['codigoReserva'] == codigoReserva);
      
      if (reservaIndex < 0) {
        mensajeEstado.value = "Reserva no encontrada";
        return false;
      }
      
      // Actualizar el estado de la reserva a cancelada
      reservas[reservaIndex]['estadoReserva'] = 'cancelada';
      await db.saveAll("reservas.json", reservas);
      
      // Liberar el lugar asociado
      final reservaCancelada = Reserva.fromJson(reservas[reservaIndex]);
      final lugares = await db.getAll("lugares.json");
      
      // Encontrar y actualizar el lugar
      for (final lugar in lugares) {
        if (lugar['codigoLugar'] == reservaCancelada.codigoReserva) {
          lugar['estado'] = 'disponible';
          break;
        }
      }
      
      await db.saveAll("lugares.json", lugares);
      
      // Actualizar datos locales
      await cargarPisosYLugares();
      await cargarHistorialReservas();
      
      mensajeEstado.value = "Reserva cancelada exitosamente";
      return true;
    } catch (e) {
      mensajeEstado.value = "Error al cancelar la reserva: $e";
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Registrar un nuevo auto para el alumno
  Future<bool> registrarNuevoAuto(String marca, String modelo, String chapa, String chasis) async {
    if (marca.isEmpty || modelo.isEmpty || chapa.isEmpty || chasis.isEmpty) {
      mensajeEstado.value = "Todos los campos son obligatorios";
      return false;
    }
    
    isLoading.value = true;
    try {
      final nuevoAuto = Auto(
        marca: marca,
        modelo: modelo,
        chapa: chapa,
        chasis: chasis,
        clienteId: codigoAlumnoActual,
      );
      
      final autos = await db.getAll("autos.json");
      
      // Verificar si la chapa ya existe
      final autoExistente = autos.any((a) => a['chapa'] == chapa);
      if (autoExistente) {
        mensajeEstado.value = "Ya existe un auto con esa chapa";
        return false;
      }
      
      // Agregar el nuevo auto
      autos.add(nuevoAuto.toJson());
      await db.saveAll("autos.json", autos);
      
      // Actualizar la lista local
      await cargarAutosDelAlumno();
      
      mensajeEstado.value = "Auto registrado exitosamente";
      return true;
    } catch (e) {
      mensajeEstado.value = "Error al registrar el auto: $e";
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Obtener reservas activas (pendientes o confirmadas)
  List<Reserva> obtenerReservasActivas() {
    return historialReservas
      .where((r) => r.estadoReserva == "pendiente" || r.estadoReserva == "confirmada")
      .toList();
  }
  
  // Obtener reservas pasadas (completadas o canceladas)
  List<Reserva> obtenerReservasPasadas() {
    return historialReservas
      .where((r) => r.estadoReserva == "completada" || r.estadoReserva == "cancelada")
      .toList();
  }
  
  // Formatear fecha y hora para mostrar
  String formatearFechaHora(DateTime fechaHora) {
    return "${fechaHora.day}/${fechaHora.month}/${fechaHora.year} ${fechaHora.hour}:${fechaHora.minute.toString().padLeft(2, '0')}";
  }
  
  // Método para obtener la descripción del lugar de una reserva
  Future<String> obtenerDescripcionLugar(String codigoLugar) async {
    try {
      final lugares = await db.getAll("lugares.json");
      final lugarEncontrado = lugares.firstWhere(
        (l) => l['codigoLugar'] == codigoLugar,
        orElse: () => {'descripcionLugar': 'Desconocido'}
      );
      return lugarEncontrado['descripcionLugar'];
    } catch (e) {
      return "Lugar no encontrado";
    }
  }
}