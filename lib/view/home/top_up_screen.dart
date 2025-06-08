// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:finpay/config/images.dart';
import 'package:finpay/config/textstyle.dart';
import 'package:finpay/view/home/topup_dialog.dart';
import 'package:finpay/view/home/widget/amount_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:swipe/swipe.dart';

/// Fictitious reservation model for mock/testing UI
class ReservaMock {
  String codigoReserva;
  String chapaAuto;
  String piso;
  String codigoLugar;
  String horarioInicio;
  String horarioSalida;
  int monto;
  String estado; // 'PENDIENTE' or 'PAGADO'
  ReservaMock({
    required this.codigoReserva,
    required this.chapaAuto,
    required this.piso,
    required this.codigoLugar,
    required this.horarioInicio,
    required this.horarioSalida,
    required this.monto,
    this.estado = 'PENDIENTE',
  });

  // Nuevo: Factory para crear desde cualquier json de reserva
  factory ReservaMock.fromJson(Map<String, dynamic> e) {
    return ReservaMock(
      codigoReserva: e['codigoReserva'] ?? e['codigo'] ?? '',
      chapaAuto: e['chapaAuto'] ?? '',
      piso: e['piso'] ?? e['codigoPiso'] ?? '',
      codigoLugar: e['codigoLugar'] ?? '',
      horarioInicio: e['horarioInicio'] is DateTime
          ? (e['horarioInicio'] as DateTime).toIso8601String()
          : (e['horarioInicio'] ?? ''),
      horarioSalida: e['horarioSalida'] is DateTime
          ? (e['horarioSalida'] as DateTime).toIso8601String()
          : (e['horarioSalida'] ?? ''),
      monto: e['monto'] is int
          ? e['monto']
          : (e['monto'] is double
              ? (e['monto'] as double).toInt()
              : int.tryParse(e['monto'].toString()) ?? 0),
      estado: e['estado'] ?? e['estadoReserva'] ?? 'PENDIENTE',
    );
  }
}

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen>
    with SingleTickerProviderStateMixin {
  List<ReservaMock> _reservas = [];
  bool _isLoading = false;
  int _selectedIndex = -1;
  AnimationController? _controller;
  Animation<double>? _animation;
  bool _showSwipe = false;
  bool _showDialog = false;
  double _topUpAmount = 0;
  String? _errorText;
  TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarReservas();
    _controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: 380));
    _animation = CurvedAnimation(parent: _controller!, curve: Curves.easeInOut);
  }

  Future<File> _getLocalFile(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    if (!await file.exists()) {
      // Copia desde assets si no existe
      final assetData = await rootBundle.loadString('assets/data/$filename');
      await file.writeAsString(assetData);
    }
    return file;
  }

  Future<List<dynamic>> _readJsonList(String filename) async {
    final file = await _getLocalFile(filename);
    final data = await file.readAsString();
    return jsonDecode(data) as List;
  }

  Future<void> _writeJsonList(String filename, List<dynamic> list) async {
    final file = await _getLocalFile(filename);
    await file.writeAsString(jsonEncode(list));
  }

  Future<void> _liberarLugar(String codigoPiso, String codigoLugar) async {
    final lugares = await _readJsonList('lugares.json');
    for (var lugar in lugares) {
      if (lugar['codigoPiso'] == codigoPiso && lugar['codigoLugar'] == codigoLugar) {
        lugar['estado'] = 'DISPONIBLE';
        break;
      }
    }
    await _writeJsonList('lugares.json', lugares);
  }

  Future<void> _registrarPago(ReservaMock reserva) async {
    final pagos = await _readJsonList('pagos.json');
    final nuevoPago = {
      "codigoPago": "PAG${DateTime.now().millisecondsSinceEpoch}",
      "codigoReservaAsociada": reserva.codigoReserva,
      "montoPagado": reserva.monto,
      "fechaPago": DateTime.now().toIso8601String(),
      "estadoPago": "COMPLETADO"
    };
    pagos.add(nuevoPago);
    await _writeJsonList('pagos.json', pagos);
  }

  Future<void> _actualizarReservaComoPagada(ReservaMock reserva) async {
    final reservas = await _readJsonList('reservas.json');
    for (var r in reservas) {
      if (r['codigoReserva'] == reserva.codigoReserva) {
        r['estado'] = 'PAGADO';
        break;
      }
    }
    await _writeJsonList('reservas.json', reservas);
  }

  Future<void> _eliminarReservaJson(ReservaMock reserva) async {
    final reservas = await _readJsonList('reservas.json');
    reservas.removeWhere((r) => r['codigoReserva'] == reserva.codigoReserva);
    await _writeJsonList('reservas.json', reservas);
  }

  Future<void> _cargarReservas() async {
    final reservasList = await _readJsonList('reservas.json');
    setState(() {
      _reservas = reservasList
          .map((e) => ReservaMock.fromJson(e))
          .where((r) => r.estado == "PENDIENTE")
          .toList();
    });
  }

  void _pagarReserva(int idx) async {
    final reserva = _reservas[idx];
    setState(() {
      _reservas[idx].estado = "PAGADO";
      _selectedIndex = idx;
      _showDialog = false;
      _showSwipe = false;
    });
    await _actualizarReservaComoPagada(reserva);
    await _registrarPago(reserva);
    await _liberarLugar(reserva.piso, reserva.codigoLugar);
    _controller?.reverse();
    Future.delayed(Duration(milliseconds: 600), () {
      setState(() => _selectedIndex = -1);
    });
  }

  void _eliminarReserva(int idx) async {
    final reserva = _reservas[idx];
    setState(() {
      _reservas.removeAt(idx);
      _showDialog = false;
      _showSwipe = false;
    });
    await _eliminarReservaJson(reserva);
    await _liberarLugar(reserva.piso, reserva.codigoLugar);
    _controller?.reverse();
  }

  void _openPagoDialog(int idx) {
    setState(() {
      _selectedIndex = idx;
      _showDialog = true;
      _showSwipe = false;
    });
    _controller?.forward(from: 0.0);
  }

  void _closePagoDialog() {
    _controller?.reverse().then((_) {
      setState(() {
        _showDialog = false;
        _selectedIndex = -1;
      });
    });
  }

  void _onSwipeTopUp() {
    if (_selectedIndex < 0) return;
    _pagarReserva(_selectedIndex);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Reserva pagada correctamente",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  void _onTopUpAmountDialog(int idx) {
    setState(() {
      _selectedIndex = idx;
      _showSwipe = true;
      _amountController.text = _reservas[idx].monto.toString();
      _topUpAmount = _reservas[idx].monto.toDouble();
      _errorText = null;
    });
    _controller?.forward(from: 0.0);
  }

  void _onConfirmTopUp() {
    if (_topUpAmount >= 1000) {
      _pagarReserva(_selectedIndex);
      _showSwipe = false;
      _amountController.clear();
      _topUpAmount = 0;
    } else {
      setState(() {
        _errorText = "El monto mínimo es 1.000 Gs";
      });
    }
  }

  Widget _buildPagoDialog(BuildContext context) {
    if (_selectedIndex < 0) return SizedBox.shrink();
    ReservaMock r = _reservas[_selectedIndex];
    return FadeTransition(
      opacity: _animation!,
      child: Container(
        color: Colors.black38,
        child: Center(
          child: ScaleTransition(
            scale: _animation!,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 32),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 30,
                    color: Colors.black12,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payment, size: 48, color: Colors.deepPurple),
                  SizedBox(height: 10),
                  Text(
                    "Confirmar Pago",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "¿Deseas marcar esta reserva como pagada?",
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Costo: ${r.monto} Gs",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.deepPurple),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _closePagoDialog,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.deepPurple),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            "Cancelar",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _onSwipeTopUp();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Confirmar",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopUpAmountDialog(BuildContext context) {
    if (_selectedIndex < 0) return SizedBox.shrink();
    ReservaMock r = _reservas[_selectedIndex];
    return FadeTransition(
      opacity: _animation!,
      child: Container(
        color: Colors.black38,
        child: Center(
          child: ScaleTransition(
            scale: _animation!,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 32),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 30,
                    color: Colors.black12,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      size: 48, color: Colors.deepPurple),
                  SizedBox(height: 10),
                  Text(
                    "Editar Monto",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Monto de la reserva:",
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Monto (Gs)",
                      border: OutlineInputBorder(),
                      errorText: _errorText,
                    ),
                    onChanged: (v) {
                      setState(() {
                        _topUpAmount = double.tryParse(v) ?? 0;
                        _errorText = null;
                      });
                    },
                  ),
                  SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showSwipe = false;
                              _errorText = null;
                              _topUpAmount = r.monto.toDouble();
                            });
                            _controller?.reverse();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.deepPurple),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text("Cancelar"),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onConfirmTopUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text("Confirmar"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardReserva(ReservaMock r, int idx) {
    return Card(
      margin: EdgeInsets.only(bottom: 18),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  "${r.chapaAuto} — ${r.piso}/${r.codigoLugar}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: r.estado == "PAGADO"
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    r.estado,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: r.estado == "PAGADO"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "Horario: ${r.horarioInicio} - ${r.horarioSalida}",
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 4),
            Text("Monto: ${r.monto} Gs", style: TextStyle(fontSize: 15)),
            SizedBox(height: 16),
            if (r.estado == "PENDIENTE")
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.payment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _openPagoDialog(idx),
                      label: Text("Pagar"),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.edit, color: Colors.orange),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orangeAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _onTopUpAmountDialog(idx),
                      label: Text("Editar", style: TextStyle(color: Colors.orange)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.delete_forever, color: Colors.red),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _eliminarReserva(idx),
                      label: Text("Eliminar", style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            if (r.estado == "PAGADO")
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.check_circle, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: null,
                      label: Text("PAGADO"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.isLightTheme == false
          ? HexColor('#15141f')
          : HexColor(AppTheme.primaryColorString!),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Top Up (Reservas Mock)"),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.deepPurple),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: _reservas.isEmpty
            ? Center(
                child: Text(
                  'No hay reservas pendientes.',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.grey[700]),
                ),
              )
            : ListView.builder(
                itemCount: _reservas.length,
                itemBuilder: (context, idx) {
                  return _buildCardReserva(_reservas[idx], idx);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _reservas.add(
              ReservaMock(
                codigoReserva: "RES${_reservas.length + 1000}",
                chapaAuto: "ZZZ999",
                piso: "P4",
                codigoLugar: "P4L005",
                horarioInicio: "2025-06-08 10:00",
                horarioSalida: "2025-06-08 12:00",
                monto: 70000,
              ),
            );
          });
        },
        backgroundColor: Colors.deepPurple,
        tooltip: "Agregar reserva ficticia",
        child: Icon(Icons.add),
      ),
      // Dialogs
      persistentFooterButtons: [
        if (_showDialog) _buildPagoDialog(context),
        if (_showSwipe) _buildTopUpAmountDialog(context),
      ],
    );
  }
}