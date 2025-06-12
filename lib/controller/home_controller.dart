// ignore_for_file: deprecated_member_use

import 'package:finpay/alumno/controller/reserva_controller_alumno.dart';
import 'package:finpay/api/local.db.service.dart';
import 'package:finpay/config/images.dart';
import 'package:finpay/config/textstyle.dart';
import 'package:finpay/model/sitema_reservas.dart';
import 'package:finpay/model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  var pagosPrevios = <Pago>[].obs; // Cambia a observable
  List<TransactionModel> transactionList = List<TransactionModel>.empty().obs;
  RxBool isWeek = true.obs;
  RxBool isMonth = false.obs;
  RxBool isYear = false.obs;
  RxBool isAdd = false.obs;

  customInit() async {
    cargarPagosPrevios();
    isWeek.value = true;
    isMonth.value = false;
    isYear.value = false;
    transactionList = [
      TransactionModel(
        Theme.of(Get.context!).textTheme.titleLarge!.color,
        DefaultImages.transaction4,
        "Apple Store",
        "iPhone 12 Case",
        "- \$120,90",
        "09:39 AM",
      ),
      TransactionModel(
        HexColor(AppTheme.primaryColorString!).withOpacity(0.10),
        DefaultImages.transaction3,
        "Ilya Vasil",
        "Wise • 5318",
        "- \$50,90",
        "05:39 AM",
      ),
      TransactionModel(
        Theme.of(Get.context!).textTheme.titleLarge!.color,
        "",
        "Burger King",
        "Cheeseburger XL",
        "- \$5,90",
        "09:39 AM",
      ),
      TransactionModel(
        HexColor(AppTheme.primaryColorString!).withOpacity(0.10),
        DefaultImages.transaction1,
        "Claudia Sarah",
        "Finpay Card • 5318",
        "- \$50,90",
        "04:39 AM",
      ),
    ];
  }

  @override
  void onInit() {
    super.onInit();
    cargarPagosPrevios(); 
  }

  Future<void> cargarPagosPrevios() async {
    final db = LocalDBService();
    final data = await db.getAll("pagos.json");
    pagosPrevios.value = data.map((json) => Pago.fromJson(json)).toList();
  }

  int get pagosRealizadosEsteMes {
    final ahora = DateTime.now();
    return pagosPrevios.where((p) =>
      p.estadoPago == "COMPLETADO" &&
      p.fechaPago.month == ahora.month &&
      p.fechaPago.year == ahora.year
    ).length;
  }

  int get pagosPendientes {
    return pagosPrevios.where((p) => p.estadoPago == "PENDIENTE").length;
  }

  int get cantidadAutos {
    final reservaCtrl = Get.find<ReservaControllerAlumno>();
    return reservaCtrl.autosAlumno.length;
  }
}

// Después de reservar o pagar:
Future<void> actualizarDatosDespuesDeReservaOPago() async {
  await Get.find<HomeController>().cargarPagosPrevios();
  await Get.find<ReservaControllerAlumno>().cargarAutosDelAlumno();
}
