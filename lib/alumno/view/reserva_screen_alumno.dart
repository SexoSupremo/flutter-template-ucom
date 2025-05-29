import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finpay/alumno/controller/reserva_controller_alumno.dart';
import 'package:finpay/model/sitema_reservas.dart';

class ReservaScreenAlumno extends StatefulWidget {
  ReservaScreenAlumno({Key? key}) : super(key: key);

  @override
  State<ReservaScreenAlumno> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreenAlumno> with TickerProviderStateMixin {
  final ReservaControllerAlumno controller = Get.put(ReservaControllerAlumno());

  final Map<String, dynamic> lugarDetalles = {
    "P1L001": {
      "name": "Piso 1 - Lugar 001",
      "address": "Piso 1, Entrada principal",
      "price": "40.000/hr",
      "available": 8,
      "minutes": 3,
      "km": 2.2,
      "facilities": [0, 1, 2]
    },
    "P1L002": {
      "name": "Piso 1 - Lugar 002",
      "address": "Piso 1, Entrada lateral",
      "price": "40.000/hr",
      "available": 7,
      "minutes": 4,
      "km": 2.7,
      "facilities": [1, 2]
    },
    "P1L003": {
      "name": "Piso 1 - Lugar 003",
      "address": "Piso 1, Cerca de ascensor",
      "price": "40.000/hr",
      "available": 5,
      "minutes": 6,
      "km": 3.1,
      "facilities": [0, 2]
    },
    "P2L001": {
      "name": "Piso 2 - Lugar 001",
      "address": "Piso 2, Frente a escaleras",
      "price": "40.000/hr",
      "available": 6,
      "minutes": 2,
      "km": 1.9,
      "facilities": [0, 1]
    },
    "P2L002": {
      "name": "Piso 2 - Lugar 002",
      "address": "Piso 2, Esquina",
      "price": "40.000/hr",
      "available": 4,
      "minutes": 5,
      "km": 2.6,
      "facilities": [2]
    },
  };

  final List<Map<String, dynamic>> facilitiesList = [
    {'icon': Icons.videocam_rounded, 'label': 'Cámaras'},
    {'icon': Icons.ev_station_rounded, 'label': 'Carga'},
    {'icon': Icons.wifi_rounded, 'label': 'WiFi'},
  ];

  int step = 0;
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.pisos.isNotEmpty && controller.pisoSeleccionado.value == null) {
        controller.seleccionarPiso(controller.pisos.first);
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  List<Lugar> _lugaresDelPisoActual() => controller.lugaresDisponibles;

  Map<String, dynamic> detallesLugar(Lugar? lugar) {
    if (lugar == null) {
      return {
        "name": "Espacio de estacionamiento",
        "address": "",
        "price": "₲ 40.000/hr",
        "available": 0,
        "minutes": 0,
        "km": 0.0,
        "facilities": [0]
      };
    }
    if (lugarDetalles.containsKey(lugar.codigoLugar)) {
      return lugarDetalles[lugar.codigoLugar]!;
    }
    return {
      "name": lugar.codigoLugar,
      "address": "Ubicación desconocida",
      "price": "₲ 40.000/hr",
      "available": 1,
      "minutes": 0,
      "km": 0.0,
      "facilities": [0]
    };
  }

  void goToPisoHorario() async {
    setState(() => step = 1);
    try {
      _animCtrl.forward(from: 0.0);
    } catch (_) {}
  }

  void volverAlInicio() {
    try {
      _animCtrl.reverse().then((_) {
        if (mounted) setState(() => step = 0);
      });
    } catch (_) {
      if (mounted) setState(() => step = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            _pantallaLugares(theme),
            if (step == 1) _pantallaPisoHorario(theme),
          ],
        ),
      ),
    );
  }

  Widget _pantallaLugares(ThemeData theme) {
    return AnimatedOpacity(
      opacity: step == 0 ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      child: Obx(() {
        final lugarSel = controller.lugarSeleccionado.value;
        final lugarInfo = detallesLugar(lugarSel);
        final lugaresDisponibles = _lugaresDelPisoActual();
        final tieneLugares = lugaresDisponibles.isNotEmpty;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de auto y lugar
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _autoSelector(theme),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _lugarDropdown(theme, lugaresDisponibles),
                    ),
                  ],
                ),
              ),
              // Card de información principal moderna
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                child: Card(
                  elevation: 1.5,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Precio destacado
                        Row(
                          children: [
                            Icon(Icons.attach_money_rounded, color: Colors.green[600], size: 28),
                            const SizedBox(width: 7),
                            Text(
                              lugarInfo["price"] ?? "",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Dirección
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: Colors.red[400], size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                lugarInfo["address"] ?? "",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatInfoModern(
                              icon: Icons.directions_car_filled_rounded,
                              label: "${lugarInfo["available"]} libres",
                              color: Colors.green,
                            ),
                            _StatInfoModern(
                              icon: Icons.timer_rounded,
                              label: "${lugarInfo["minutes"]} min",
                              color: Colors.blue,
                            ),
                            _StatInfoModern(
                              icon: Icons.map_rounded,
                              label: "${lugarInfo["km"]} km",
                              color: Colors.deepPurple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Facilidades (más abajo, con separación)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 30, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Facilidades",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedFacilities(
                      key: ValueKey(lugarSel?.codigoLugar ?? 'none'),
                      facilities: lugarInfo["facilities"],
                      facilitiesList: facilitiesList,
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 42),
              // Botón
              SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                      left: 24, right: 24, bottom: 16, top: 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      backgroundColor: tieneLugares ? Colors.black : Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 19),
                    ),
                    onPressed: tieneLugares ? () => goToPisoHorario() : null,
                    child: Text(
                      "Seleccionar horario",
                      style: theme.textTheme.titleLarge!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _lugarDropdown(ThemeData theme, List<Lugar> lugaresDisponibles) {
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonFormField<Lugar>(
          value: lugaresDisponibles.contains(controller.lugarSeleccionado.value)
              ? controller.lugarSeleccionado.value
              : (lugaresDisponibles.isNotEmpty ? lugaresDisponibles.first : null),
          isExpanded: true,
          decoration: InputDecoration(
            icon: Icon(Icons.location_on, color: theme.primaryColor),
            border: InputBorder.none,
            filled: false,
            hintText: lugaresDisponibles.isEmpty
                ? "No hay lugares"
                : "Lugar",
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          ),
          dropdownColor: Colors.white,
          onChanged: lugaresDisponibles.isEmpty
              ? null
              : (lugar) {
                  controller.lugarSeleccionado.value = lugar;
                },
          items: lugaresDisponibles.isEmpty
              ? []
              : lugaresDisponibles.map((lugar) {
                  return DropdownMenuItem(
                      value: lugar,
                      child: Text(lugar.codigoLugar,
                          style: theme.textTheme.bodyMedium));
                }).toList(),
        ),
      );
    });
  }

  Widget _pantallaPisoHorario(ThemeData theme) {
    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnim,
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: volverAlInicio,
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 26),
                      ),
                      Text(
                        "Seleccionar piso y horario",
                        style: theme.textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                  child: Obx(() {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: controller.pisos.map((piso) {
                        final seleccionado =
                            piso == controller.pisoSeleccionado.value;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 7),
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? theme.primaryColor
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: seleccionado
                                ? [
                                    BoxShadow(
                                      color:
                                          theme.primaryColor.withOpacity(0.18),
                                      blurRadius: 18,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              controller.seleccionarPiso(piso);
                              final lugares = _lugaresDelPisoActual();
                              if (lugares.isNotEmpty) {
                                controller.lugarSeleccionado.value = lugares.first;
                              } else {
                                controller.lugarSeleccionado.value = null;
                              }
                              setState(() {});
                            },
                            child: Text(
                              piso.descripcion,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    seleccionado ? Colors.white : Colors.black87,
                                fontSize: seleccionado ? 17 : 15,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 2),
                  child: _horarioSelector(theme),
                ),
                const SizedBox(height: 32),
                SafeArea(
                  top: false,
                  child: Obx(() {
                    final puedeReservar =
                        controller.lugarSeleccionado.value != null &&
                            controller.pisoSeleccionado.value != null &&
                            controller.autoSeleccionado.value != null &&
                            controller.horarioInicio.value != null &&
                            controller.horarioSalida.value != null;
                    final lugarLabel =
                        controller.lugarSeleccionado.value?.codigoLugar ?? "";
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, bottom: 16, top: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 2,
                          backgroundColor:
                              puedeReservar ? Colors.black : Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 19),
                        ),
                        onPressed: puedeReservar
                            ? () async {
                                final resultado =
                                    await controller.confirmarReserva();
                                if (resultado) {
                                  Get.snackbar(
                                    "Reserva exitosa",
                                    "Tu espacio ha sido reservado",
                                    backgroundColor: Colors.green[100],
                                    colorText: Colors.black,
                                    duration: const Duration(seconds: 2),
                                  );
                                  volverAlInicio();
                                } else {
                                  Get.snackbar(
                                    "Error",
                                    controller.mensajeEstado.value ??
                                        "Error al reservar",
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
                              : "Selecciona un lugar",
                          style: theme.textTheme.titleLarge!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _autoSelector(ThemeData theme) {
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonFormField<Auto>(
          value: controller.autoSeleccionado.value,
          isExpanded: true,
          decoration: InputDecoration(
            icon: Icon(Icons.directions_car, color: theme.primaryColor),
            border: InputBorder.none,
            filled: false,
            hintText: controller.autosAlumno.isEmpty
                ? "No hay autos"
                : "Auto",
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          ),
          dropdownColor: Colors.white,
          onChanged: controller.autosAlumno.isEmpty
              ? null
              : (auto) => controller.autoSeleccionado.value = auto,
          items: controller.autosAlumno.isEmpty
              ? []
              : controller.autosAlumno.map((a) {
                  final nombre = "${a.chapa} - ${a.marca} ${a.modelo}";
                  return DropdownMenuItem(
                      value: a,
                      child: Text(nombre, style: theme.textTheme.bodyMedium));
                }).toList(),
        ),
      );
    });
  }

  Widget _horarioSelector(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Obx(() => InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: controller.horarioInicio.value != null
                        ? TimeOfDay(
                            hour: controller.horarioInicio.value!.hour,
                            minute: controller.horarioInicio.value!.minute)
                        : TimeOfDay.now(),
                  );
                  if (picked != null) {
                    final now = DateTime.now();
                    controller.horarioInicio.value = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      picked.hour,
                      picked.minute,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.grey[200]!, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 17, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        controller.horarioInicio.value == null
                            ? "--:--"
                            : "${controller.horarioInicio.value!.hour.toString().padLeft(2, '0')}:${controller.horarioInicio.value!.minute.toString().padLeft(2, '0')}",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Obx(() => InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: controller.horarioSalida.value != null
                        ? TimeOfDay(
                            hour: controller.horarioSalida.value!.hour,
                            minute: controller.horarioSalida.value!.minute)
                        : TimeOfDay.now(),
                  );
                  if (picked != null) {
                    final now = DateTime.now();
                    controller.horarioSalida.value = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      picked.hour,
                      picked.minute,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.grey[200]!, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 17, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        controller.horarioSalida.value == null
                            ? "--:--"
                            : "${controller.horarioSalida.value!.hour.toString().padLeft(2, '0')}:${controller.horarioSalida.value!.minute.toString().padLeft(2, '0')}",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )),
        ),
      ],
    );
  }
}

// Modern stat info widget for main card
class _StatInfoModern extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatInfoModern({
    required this.icon,
    required this.label,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 5),
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                )),
      ],
    );
  }
}

// AnimatedFacilities y _StatCardAnim 


class AnimatedFacilities extends StatefulWidget {
  final List facilities;
  final List<Map<String, dynamic>> facilitiesList;
  final ThemeData theme;

  const AnimatedFacilities({
    Key? key,
    required this.facilities,
    required this.facilitiesList,
    required this.theme,
  }) : super(key: key);

  @override
  State<AnimatedFacilities> createState() => _AnimatedFacilitiesState();
}

class _AnimatedFacilitiesState extends State<AnimatedFacilities> with SingleTickerProviderStateMixin {
  late AnimationController _facAnimCtrl;
  late Animation<double> _facFadeAnim;
  late Animation<double> _facScaleAnim;

  @override
  void initState() {
    super.initState();
    _facAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _facFadeAnim = CurvedAnimation(parent: _facAnimCtrl, curve: Curves.easeInOutCubicEmphasized);
    _facScaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _facAnimCtrl, curve: Curves.elasticOut));
    _facAnimCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _facAnimCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedFacilities oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.facilities != oldWidget.facilities) {
      _facAnimCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _facAnimCtrl,
      builder: (context, child) {
        return Row(
          children: (widget.facilities as List)
              .asMap()
              .entries
              .map<Widget>((entry) {
            int idx = entry.key;
            int i = entry.value;
            return FadeTransition(
              opacity: _facFadeAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.4 + idx * 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: _facAnimCtrl,
                    curve: Interval(0, 0.4 + idx * 0.17, curve: Curves.easeOut))),
                child: Transform.scale(
                  scale: _facScaleAnim.value + idx * 0.03,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Chip(
                      avatar: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Icon(
                          widget.facilitiesList[i]['icon'],
                          size: (20 + 2 * idx).toDouble(),
                          key: ValueKey<int>(i),
                          color: Colors.black87,
                        ),
                      ),
                      label: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          widget.facilitiesList[i]['label'],
                          key: ValueKey(i.toString() + "label"),
                          style: widget.theme.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: idx % 2 == 0
                                ? Colors.black
                                : Colors.blueGrey[700],
                          ),
                        ),
                      ),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      labelPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 0),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCardAnim extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String keyText;

  const _StatCardAnim({
    required this.icon,
    required this.label,
    required this.color,
    required this.keyText,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(keyText),
        width: 110,
        height: 74,
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withOpacity(0.20), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 5),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    )),
          ],
        ),
      ),
    );
  }
}