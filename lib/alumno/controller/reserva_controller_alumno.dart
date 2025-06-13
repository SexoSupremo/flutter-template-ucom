import 'package:get/get.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/api/local.db.service.dart';
import 'package:finpay/controller/home_controller.dart';

class ReservaControllerAlumno extends GetxController {
  RxList<Piso> pisos = <Piso>[].obs;
  Rx<Piso?> pisoSeleccionado = Rx<Piso?>(null);

  RxList<Lugar> lugaresDisponibles = <Lugar>[].obs;
  Rx<Lugar?> lugarSeleccionado = Rx<Lugar?>(null);

  Rx<DateTime?> horarioInicio = Rx<DateTime?>(null);
  Rx<DateTime?> horarioSalida = Rx<DateTime?>(null);
  RxInt duracionSeleccionada = 0.obs;

  var autosAlumno = <Auto>[].obs; 
  Rx<Auto?> autoSeleccionado = Rx<Auto?>(null);

  RxList<Reserva> historialReservas = <Reserva>[].obs;
  RxBool isLoading = false.obs;
  Rx<String?> mensajeEstado = Rx<String?>(null);

  // Simula el alumno logueado
  String codigoAlumnoActual = 'cliente_1';
  final LocalDBService db = LocalDBService();

  @override
  void onInit() {
    super.onInit();
    resetearCampos();
    cargarAutosDelAlumno(); 
    cargarPisosYLugares();
    cargarHistorialReservas();
  }

  Future<void> cargarPisosYLugares() async {
    isLoading.value = true;
    try {
      final rawPisos = await db.getAll("pisos.json");
      final rawLugares = await db.getAll("lugares.json");
      final todosLugares = rawLugares.map((e) => Lugar.fromJson(e)).toList();

      pisos.value = rawPisos.map<Piso>((pJson) {
        final codigoPiso = pJson['codigo'];
        final lugaresDelPiso = todosLugares.where((l) => l.codigoPiso == codigoPiso).toList();
        return Piso(
          codigo: codigoPiso,
          descripcion: pJson['descripcion'],
          lugares: lugaresDelPiso,
        );
      }).toList();

      lugaresDisponibles.value = todosLugares.where((l) => l.estado.toLowerCase() == "disponible").toList();
    } catch (e) {
      mensajeEstado.value = "Error al cargar pisos y lugares: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> seleccionarPiso(Piso piso) async {
    pisoSeleccionado.value = piso;
    lugarSeleccionado.value = null;
    lugaresDisponibles.value = piso.lugares.where((l) => l.estado.toLowerCase() == "disponible").toList();
  }

  bool get puedeReservar =>
      pisoSeleccionado.value != null &&
      lugarSeleccionado.value != null &&
      horarioInicio.value != null &&
      horarioSalida.value != null &&
      autoSeleccionado.value != null;

  Future<bool> confirmarReserva() async {
    if (!puedeReservar) {
      mensajeEstado.value = "Completa todos los campos antes de reservar";
      return false;
    }

    final duracionEnHoras = horarioSalida.value!.difference(horarioInicio.value!).inMinutes / 60;
    if (duracionEnHoras <= 0) {
      mensajeEstado.value = "La hora de salida debe ser posterior a la de inicio";
      return false;
    }

    final montoCalculado = calcularMonto(duracionEnHoras);

    final nuevaReserva = {
      "codigoReserva": "RES-${DateTime.now().millisecondsSinceEpoch}",
      "chapaAuto": autoSeleccionado.value!.chapa,
      "piso": pisoSeleccionado.value!.codigo,
      "codigoLugar": lugarSeleccionado.value!.codigoLugar,
      "horarioInicio": horarioInicio.value!.toIso8601String(),
      "horarioSalida": horarioSalida.value!.toIso8601String(),
      "monto": montoCalculado,
      "estado": "PENDIENTE"
    };

    try {
      // Guardar reserva
      final reservas = await db.getAll("reservas.json");
      reservas.add(nuevaReserva);
      await db.saveAll("reservas.json", reservas);

      // Marcar el lugar como reservado
      final lugares = await db.getAll("lugares.json");
      final index = lugares.indexWhere((l) => l['codigoLugar'] == lugarSeleccionado.value!.codigoLugar);
      if (index != -1) {
        lugares[index]['estado'] = "RESERVADO";
        await db.saveAll("lugares.json", lugares);
      }

      // Crear pago pendiente asociado a la reserva
      final pagos = await db.getAll("pagos.json");
      final nuevoPago = {
        "codigoPago": "PAG-${DateTime.now().millisecondsSinceEpoch}",
        "codigoReservaAsociada": nuevaReserva["codigoReserva"],
        "montoPagado": nuevaReserva["monto"],
        "fechaPago": DateTime.now().toIso8601String(),
        "estadoPago": "PENDIENTE"
      };
      pagos.add(nuevoPago);
      await db.saveAll("pagos.json", pagos);

      await cargarPisosYLugares();
      await cargarHistorialReservas();
      resetearCampos();
      mensajeEstado.value = "Reserva creada correctamente";

      // Después de reservar o pagar:
      await recargarTodoHome();
      return true;
    } catch (e) {
      mensajeEstado.value = "Error al guardar reserva: $e";
      return false;
    }
  }

  Future<void> cargarHistorialReservas() async {
    isLoading.value = true;
    try {
      final rawReservas = await db.getAll("reservas.json");
      final rawAutos = await db.getAll("autos.json");
      final autosDelAlumno = rawAutos
          .where((auto) => auto['clienteId'] == codigoAlumnoActual)
          .map((auto) => auto['chapa'])
          .toSet();

      historialReservas.value = rawReservas
          .map((e) => Reserva.fromJson(e))
          .where((reserva) => autosDelAlumno.contains(reserva.chapaAuto))
          .toList();
      historialReservas.sort((a, b) => b.horarioInicio.compareTo(a.horarioInicio));
    } catch (e) {
      mensajeEstado.value = "Error al cargar historial de reservas: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cargarAutosDelAlumno() async {
    final db = LocalDBService();
    final data = await db.getAll("autos.json");
    autosAlumno.value = data
        .map((json) => Auto.fromJson(json))
        .where((auto) => auto.clienteId == codigoAlumnoActual)
        .toList();
  }

  void resetearCampos() {
    pisoSeleccionado.value = null;
    lugarSeleccionado.value = null;
    horarioInicio.value = null;
    horarioSalida.value = null;
    duracionSeleccionada.value = 0;
    autoSeleccionado.value = null;
  }

  double calcularMonto(double duracionHoras) {
    return (duracionHoras * 10000).roundToDouble();
  }

void actualizarPrecio() {
  if (duracionSeleccionada.value > 0) {
    
  }
}

  Future<void> recargarTodoHome() async {
    await cargarAutosDelAlumno();
    await cargarHistorialReservas();
    await Get.find<HomeController>().cargarPagosPrevios();
  }

  void filtrarDisponibilidadPorDia(int weekday) {
  if (weekday == DateTime.monday) {
    pisos.value = pisos.where((p) => p.codigo != "P1").toList();
  } else if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
    for (var piso in pisos) {
      piso.lugares.removeWhere((l) => l.codigoLugar.hashCode % 2 == 0);
    }
  } else {
    cargarPisosYLugares();
  }

  if (pisoSeleccionado.value != null &&
      !pisos.any((p) => p.codigo == pisoSeleccionado.value!.codigo)) {
    pisoSeleccionado.value = null;
    lugarSeleccionado.value = null;
  }
}

  @override
  void onClose() {
    resetearCampos();
    super.onClose();
  }
}