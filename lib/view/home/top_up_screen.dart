// ignore_for_file: deprecated_member_use

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
    _reservas = _mockReservas();
    _controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: 380));
    _animation = CurvedAnimation(parent: _controller!, curve: Curves.easeInOut);
  }

  List<ReservaMock> _mockReservas() {
    return [
      ReservaMock(
        codigoReserva: "RES1001",
        chapaAuto: "ABC123",
        piso: "P1",
        codigoLugar: "P1L002",
        horarioInicio: "2025-06-05 09:00",
        horarioSalida: "2025-06-05 11:00",
        monto: 60000,
      ),
      ReservaMock(
        codigoReserva: "RES1002",
        chapaAuto: "GHI789",
        piso: "P2",
        codigoLugar: "P2L001",
        horarioInicio: "2025-06-06 14:30",
        horarioSalida: "2025-06-06 16:00",
        monto: 45000,
      ),
      ReservaMock(
        codigoReserva: "RES1003",
        chapaAuto: "DEF456",
        piso: "P3",
        codigoLugar: "P3L004",
        horarioInicio: "2025-06-07 08:00",
        horarioSalida: "2025-06-07 09:00",
        monto: 35000,
      ),
    ];
  }

  void _pagarReserva(int idx) {
    setState(() {
      _reservas[idx].estado = "PAGADO";
      _selectedIndex = idx;
      _showDialog = false;
      _showSwipe = false;
    });
    _controller?.reverse();
    Future.delayed(Duration(milliseconds: 600), () {
      setState(() => _selectedIndex = -1);
    });
  }

  void _eliminarReserva(int idx) {
    setState(() {
      _reservas.removeAt(idx);
      _showDialog = false;
      _showSwipe = false;
    });
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