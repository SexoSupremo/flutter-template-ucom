import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finpay/controller/reserva_controller.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/utils/utiles.dart';

class ReservaScreen extends StatelessWidget {
  final controller = Get.put(ReservaController());

  ReservaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Reservar espacio"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:  Column(
            children: [
              _seccion(
                title: "Tu auto",
                child: DropdownButtonFormField<Auto>(
                  value: controller.autoSeleccionado.value,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(),
                    hintText: "Seleccionar auto",
                  ),
                  onChanged: (auto) =>
                      controller.autoSeleccionado.value = auto,
                  items: controller.autosCliente.map((a) {
                    final nombre = "${a.chapa} - ${a.marca} ${a.modelo}";
                    return DropdownMenuItem(value: a, child: Text(nombre));
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _seccion(
                title: "Seleccionar piso",
                child: DropdownButtonFormField<Piso>(
                  value: controller.pisoSeleccionado.value,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(),
                    hintText: "Seleccionar piso",
                  ),
                  onChanged: (p) => controller.seleccionarPiso(p!),
                  items: controller.pisos
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(p.descripcion)))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              _seccion(
                title: "Elegí un lugar",
                child: SizedBox(
                  height: 200,
                  child: GridView.count(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: controller.lugaresDisponibles
                        .where((l) =>
                            l.codigoPiso ==
                            controller.pisoSeleccionado.value?.codigo)
                        .map((lugar) {
                      final seleccionado =
                          lugar == controller.lugarSeleccionado.value;
                      final reservado = lugar.estado == "RESERVADO";

                      return GestureDetector(
                        onTap: reservado
                            ? null
                            : () => controller.lugarSeleccionado.value = lugar,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: reservado
                                ? Colors.grey[300]
                                : seleccionado
                                    ? theme.colorScheme.primary
                                    : Colors.white,
                            border: Border.all(
                              color: seleccionado
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: seleccionado
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            lugar.codigoLugar,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: reservado
                                  ? Colors.grey
                                  : seleccionado
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _seccion(
                title: "Horarios",
                child: Row(
                  children: [
                    Expanded(
                      child: _botonHorario(
                        context,
                        "Inicio",
                        Icons.access_time,
                        controller.horarioInicio.value,
                        (picked) => controller.horarioInicio.value = picked,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _botonHorario(
                        context,
                        "Salida",
                        Icons.timer_off,
                        controller.horarioSalida.value,
                        (picked) => controller.horarioSalida.value = picked,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _seccion(
                title: "Duración rápida",
                child: Wrap(
                  spacing: 8,
                  children: [1, 2, 4, 6, 8].map((horas) {
                    final seleccionada =
                        controller.duracionSeleccionada.value == horas;
                    return ChoiceChip(
                      label: Text("$horas h"),
                      selected: seleccionada,
                      selectedColor: theme.colorScheme.primary,
                      onSelected: (_) {
                        controller.duracionSeleccionada.value = horas;
                        final inicio =
                            controller.horarioInicio.value ?? DateTime.now();
                        controller.horarioInicio.value = inicio;
                        controller.horarioSalida.value =
                            inicio.add(Duration(hours: horas));
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final inicio = controller.horarioInicio.value;
                final salida = controller.horarioSalida.value;

                if (inicio == null || salida == null) return const SizedBox();

                final minutos = salida.difference(inicio).inMinutes;
                final horas = minutos / 60;
                final monto = (horas * 10000).round();

                return Text(
                  "Monto estimado: ₲${UtilesApp.formatearGuaranies(monto)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final confirmada = await controller.confirmarReserva();

                    if (confirmada) {
                      Get.snackbar(
                        "Reserva",
                        "Reserva realizada con éxito",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      await Future.delayed(
                          const Duration(milliseconds: 2000));
                      Get.back();
                    } else {
                      Get.snackbar(
                        "Error",
                        "Verificá que todos los campos estén completos",
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.red.shade900,
                      );
                    }
                  },
                  child: const Text("Confirmar Reserva"),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _seccion({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _botonHorario(BuildContext context, String label, IconData icon,
      DateTime? dateTime, Function(DateTime) onPicked) {
    return ElevatedButton.icon(
      onPressed: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date == null) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time == null) return;
        final picked = DateTime(
            date.year, date.month, date.day, time.hour, time.minute);
        onPicked(picked);
      },
      icon: Icon(icon),
      label: Text(
        dateTime == null
            ? label
            : "${UtilesApp.formatearFechaDdMMAaaa(dateTime)} ${TimeOfDay.fromDateTime(dateTime).format(context)}",
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.grey[200],
        elevation: 0,
      ),
    );
  }
}
