import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finpay/controller/alumno/reserva_controller_alumno.dart';
import 'package:finpay/model/sitema_reservas.dart';

class ReservaScreen extends StatelessWidget {
  final controller = Get.put(ReservaControllerAlumno());

  ReservaScreen({Key? key}) : super(key: key);

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
        return Column(
          children: [
            // BLOQUE 1: Auto y bienvenida
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.directions_car, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Auto>(
                      value: controller.autoSeleccionado.value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(),
                        hintText: "Seleccionar auto",
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                      ),
                      onChanged: (auto) => controller.autoSeleccionado.value = auto,
                      items: controller.autosAlumno.map((a) {
                        final nombre = "${a.chapa ?? ''} - ${a.marca ?? ''} ${a.modelo ?? ''}";
                        return DropdownMenuItem(value: a, child: Text(nombre));
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "¡Hola! Selecciona tu auto y reserva un espacio.",
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // BLOQUE 2: Selector de piso (Tabs)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                height: 40,
                child: Obx(() {
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.pisos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final piso = controller.pisos[i];
                      final seleccionado = piso == controller.pisoSeleccionado.value;
                      return GestureDetector(
                        onTap: () => controller.seleccionarPiso(piso),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: seleccionado ? theme.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: seleccionado ? theme.primaryColor : Colors.grey.shade300,
                              width: seleccionado ? 2 : 1
                            ),
                            boxShadow: seleccionado
                                ? [BoxShadow(color: theme.primaryColor.withOpacity(0.08), blurRadius: 8)]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              piso.descripcion ?? '',
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: seleccionado ? Colors.white : theme.primaryColor,
                                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
            // BLOQUE 3: Grid de lugares
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Obx(() {
                  final lugares = controller.lugaresDisponibles
                      .where((l) => l.codigoPiso == controller.pisoSeleccionado.value?.codigo)
                      .toList();
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: lugares.length,
                    itemBuilder: (context, idx) {
                      final lugar = lugares[idx];
                      final seleccionado = lugar == controller.lugarSeleccionado.value;
                      final reservado = (lugar.estado.toLowerCase() == "reservado");

                      Color bgColor;
                      Color borderColor;
                      Color textColor;
                      if (reservado) {
                        bgColor = Colors.grey[300]!;
                        borderColor = Colors.grey[400]!;
                        textColor = Colors.grey;
                      } else if (seleccionado) {
                        bgColor = theme.primaryColor;
                        borderColor = theme.primaryColorDark;
                        textColor = Colors.white;
                      } else {
                        bgColor = Colors.white;
                        borderColor = Colors.grey.shade300;
                        textColor = Colors.black87;
                      }

                      return GestureDetector(
                        onTap: reservado ? null : () => controller.lugarSeleccionado.value = lugar,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: borderColor,
                              width: seleccionado ? 2.5 : 1.3
                            ),
                            boxShadow: seleccionado
                                ? [BoxShadow(color: theme.primaryColor.withOpacity(0.13), blurRadius: 8)]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            lugar.codigoLugar ?? '',
                            style: theme.textTheme.titleMedium!.copyWith(
                              color: textColor,
                              fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
            // BLOQUE 4: Botón inferior
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 0,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: Obx(() {
                  final puedeReservar = controller.lugarSeleccionado.value != null
                      && controller.pisoSeleccionado.value != null
                      && controller.autoSeleccionado.value != null;
                  final lugarLabel = controller.lugarSeleccionado.value?.codigoLugar ?? "";
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: puedeReservar
                          ? theme.primaryColor
                          : Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: puedeReservar
                        ? () async {
                            final resultado = await controller.confirmarReserva();
                            if (resultado) {
                              Get.snackbar(
                                "Reserva exitosa",
                                "Tu espacio ha sido reservado",
                                backgroundColor: Colors.green[100],
                                colorText: Colors.black,
                                duration: const Duration(seconds: 2),
                              );
                            } else {
                              Get.snackbar(
                                "Error",
                                controller.mensajeEstado.value ?? "Error al reservar",
                                backgroundColor: Colors.red[100],
                                colorText: Colors.black,
                                duration: const Duration(seconds: 2),
                              );
                            }
                          }
                        : null,
                    child: Text(
                      lugarLabel.isNotEmpty
                        ? "Reservar espacio - $lugarLabel"
                        : "Selecciona un espacio",
                      style: theme.textTheme.titleLarge!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }
}
