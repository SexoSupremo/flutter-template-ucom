import 'package:get/get.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/api/local.db.service.dart';

class ReservaControllerAlumno extends GetxController {
  RxList<Piso> pisos = <Piso>[].obs;
  Rx<Piso?> pisoSeleccionado = Rx<Piso?>(null);

  RxList<Lugar> lugaresDisponibles = <Lugar>[].obs;
  Rx<Lugar?> lugarSeleccionado = Rx<Lugar?>(null);

  Rx<DateTime?> horarioInicio = Rx<DateTime?>(null);
  Rx<DateTime?> horarioSalida = Rx<DateTime?>(null);
  RxInt duracionSeleccionada = 0.obs;

  RxList<Auto> autosAlumno = <Auto>[].obs;
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

    final nuevaReserva = Reserva(
      codigoReserva: "RES-${DateTime.now().millisecondsSinceEpoch}",
      horarioInicio: horarioInicio.value!,
      horarioSalida: horarioSalida.value!,
      monto: montoCalculado,
      estadoReserva: "PENDIENTE",
      chapaAuto: autoSeleccionado.value!.chapa,
    );

    try {
      // Guardar reserva
      final reservas = await db.getAll("reservas.json");
      reservas.add(nuevaReserva.toJson());
      await db.saveAll("reservas.json", reservas);

      // Marcar el lugar como reservado
      final lugares = await db.getAll("lugares.json");
      final index = lugares.indexWhere((l) => l['codigoLugar'] == lugarSeleccionado.value!.codigoLugar);
      if (index != -1) {
        lugares[index]['estado'] = "RESERVADO";
        await db.saveAll("lugares.json", lugares);
      }

      await cargarPisosYLugares();
      await cargarHistorialReservas();
      resetearCampos();
      mensajeEstado.value = "Reserva creada correctamente";
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
    final rawAutos = await db.getAll("autos.json");
    final autos = rawAutos.map((e) => Auto.fromJson(e)).toList();
    autosAlumno.value = autos.where((a) => a.clienteId == codigoAlumnoActual).toList();
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

  @override
  void onClose() {
    resetearCampos();
    super.onClose();
  }
}