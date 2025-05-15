// ignore_for_file: deprecated_member_use

import 'package:finpay/config/textstyle.dart';
import 'package:finpay/controller/profile_controller.dart';
import 'package:finpay/view/profile/widget/notification_view.dart';
import 'package:finpay/widgets/custom_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final profileController = Get.put(ProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.isLightTheme == false
            ? HexColor('#15141f')
            : Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.titleLarge!.color,
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: Get.height,
            width: Get.width,
            color: AppTheme.isLightTheme == false
                ? HexColor('#15141f')
                : Theme.of(context).appBarTheme.backgroundColor,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notificaciones",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 32),
                    notificationView(
                      context,
                      "Alerta de tarifas",
                      CupertinoSwitch(
                        value: profileController.alert.value,
                        activeColor: HexColor(AppTheme.primaryColorString!),
                        onChanged: (v) {
                          setState(() {
                            profileController.alert.value = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    notificationView(
                      context,
                      "Alerta de gasto expensivo",
                      CupertinoSwitch(
                        value: profileController.expense.value,
                        activeColor: HexColor(AppTheme.primaryColorString!),
                        onChanged: (v) {
                          setState(() {
                            profileController.expense.value = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    notificationView(
                      context,
                      "Alerta de utilización de crédito",
                      CupertinoSwitch(
                        value: profileController.utilize.value,
                        activeColor: HexColor(AppTheme.primaryColorString!),
                        onChanged: (v) {
                          setState(() {
                            profileController.alert.value = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    notificationView(
                      context,
                      "Alerta de saldo bajo",
                      CupertinoSwitch(
                        value: profileController.balance.value,
                        activeColor: HexColor(AppTheme.primaryColorString!),
                        onChanged: (v) {
                          setState(() {
                            profileController.balance.value = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    notificationView(
                      context,
                      "Alerta de pago recurrente",
                      CupertinoSwitch(
                        value: profileController.paid.value,
                        activeColor: HexColor(AppTheme.primaryColorString!),
                        onChanged: (v) {
                          setState(() {
                            profileController.paid.value = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    notificationView(
                      context,
                      "Actualización de gastos",
                      CupertinoSwitch(
                        value: profileController.spending.value,
                        activeColor: HexColor(AppTheme.primaryColorString!),
                        onChanged: (v) {
                          setState(() {
                            profileController.spending.value = v;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
            child: CustomButton(
              title: "Guardar cambios",
              onTap: () {
                Navigator.pop(context);
              },
            ),
          )
        ],
      ),
    );
  }
}
