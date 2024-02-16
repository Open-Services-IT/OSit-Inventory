import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:osit_inventory/controllers/main_wrapper_controller.dart';
import 'package:osit_inventory/controllers/nfc_controller.dart';
import 'controllers/qr_controller.dart';

import 'controllers/app_controller.dart';
import 'services/app_storage.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();

  Get
    ..put(QrController(), permanent: true)
    ..put(AppController(), permanent: true)
    ..put(MainWrapperController(), permanent: true)
    ..put(NfcController(), permanent: true);

  runApp(const OSitInventoryApp());
}

class OSitInventoryApp extends StatelessWidget {
  const OSitInventoryApp({super.key});
  @override
  Widget build(BuildContext context) => GetBuilder<AppController>(
        builder: (_) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _.theme,
          home: HomePage(),
        ),
      );
}
