import 'package:finpay/model/sitema_reservas.dart';
import 'package:get/get.dart';
import 'package:finpay/api/local.db.service.dart';

class ReservaController extends GetxController {
  RxList<Piso> pisos = <Piso>[].obs;
  Rx<Piso?> pisoSeleccionado = Rx<Piso?>(null);
  RxList<Lugar> lugaresDisponibles = <Lugar>[].obs;
  Rx<Lugar?> lugarSeleccionado = Rx<Lugar?>(null);
  Rx<DateTime?> horarioInicio = Rx<DateTime?>(null);
  Rx<DateTime?> horarioSalida = Rx<DateTime?>(null);
  RxInt duracionSeleccionada = 0.obs;
  final db = LocalDBService();
  RxList<Auto> autosCliente = <Auto>[].obs;
  Rx<Auto?> autoSeleccionado = Rx<Auto?>(null);
  String codigoClienteActual =
      'cliente_1'; // ← este puede venir de login o contexto
  @override
  void onInit() {
    super.onInit();
    resetearCampos();
    cargarAutosDelCliente();
    cargarPisosYLugares();
  }

  Future<void> cargarPisosYLugares() async {
    final rawPisos = await db.getAll("pisos.json");
    final rawLugares = await db.getAll("lugares.json");
    final rawReservas = await db.getAll("reservas.json");

    final reservas = rawReservas.map((e) => Reserva.fromJson(e)).toList();
    final lugaresReservados = reservas.map((r) => r.codigoReserva).toSet();

    final todosLugares = rawLugares.map((e) => Lugar.fromJson(e)).toList();

    // Unir pisos con sus lugares correspondientes
    pisos.value = rawPisos.map((pJson) {
      final codigoPiso = pJson['codigo'];
      final lugaresDelPiso =
          todosLugares.where((l) => l.codigoPiso == codigoPiso).toList();

      return Piso(
        codigo: codigoPiso,
        descripcion: pJson['descripcion'],
        lugares: lugaresDelPiso,
      );
    }).toList();

    // Inicializar lugares disponibles (solo los no reservados)
    lugaresDisponibles.value = todosLugares.where((l) {
      return !lugaresReservados.contains(l.codigoLugar);
    }).toList();
  }

  Future<void> seleccionarPiso(Piso piso) {
    pisoSeleccionado.value = piso;
    lugarSeleccionado.value = null;

    // filtrar lugares de este piso
    lugaresDisponibles.refresh();
    return Future.value();
  }

  Future<bool> confirmarReserva() async {
    if (pisoSeleccionado.value == null ||
        lugarSeleccionado.value == null ||
        horarioInicio.value == null ||
        horarioSalida.value == null) {
      return false;
    }

    final duracionEnHoras =
        horarioSalida.value!.difference(horarioInicio.value!).inMinutes / 60;

    if (duracionEnHoras <= 0) return false;

    final montoCalculado = (duracionEnHoras * 10000).roundToDouble();

    if (autoSeleccionado.value == null) return false;

    final nuevaReserva = Reserva(
      codigoReserva: "RES-${DateTime.now().millisecondsSinceEpoch}",
      horarioInicio: horarioInicio.value!,
      horarioSalida: horarioSalida.value!,
      monto: montoCalculado,
      estadoReserva: "PENDIENTE",
      chapaAuto: autoSeleccionado.value!.chapa,
    );

    try {
      // Guardar la reserva
      final reservas = await db.getAll("reservas.json");
      reservas.add(nuevaReserva.toJson());
      await db.saveAll("reservas.json", reservas);

      // Marcar el lugar como reservado
      final lugares = await db.getAll("lugares.json");
      final index = lugares.indexWhere(
        (l) => l['codigoLugar'] == lugarSeleccionado.value!.codigoLugar,
      );
      if (index != -1) {
        lugares[index]['estado'] = "RESERVADO";
        await db.saveAll("lugares.json", lugares);
      }

      return true;
    } catch (e) {
      print("Error al guardar reserva: $e");
      return false;
    }
  }

  void resetearCampos() {
    pisoSeleccionado.value = null;
    lugarSeleccionado.value = null;
    horarioInicio.value = null;
    horarioSalida.value = null;
    duracionSeleccionada.value = 0;
  }

  Future<void> cargarAutosDelCliente() async {
    final rawAutos = await db.getAll("autos.json");
    final autos = rawAutos.map((e) => Auto.fromJson(e)).toList();

    autosCliente.value =
        autos.where((a) => a.clienteId == codigoClienteActual).toList();
  }

  @override
  void onClose() {
    resetearCampos();
    super.onClose();
  }
}
