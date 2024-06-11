import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:osit_inventory/firebase_options.dart';
import 'package:osit_inventory/helpers/utils.dart';

import 'controllers/app_controller.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppUtils.initServices();
  runApp(const OSitInventoryApp());
}

class OSitInventoryApp extends StatelessWidget {
  const OSitInventoryApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(392, 744),
      builder: (context, child) => GetBuilder<AppController>(
        builder: (_) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _.theme,
          home: HomePage(),
        ),
      ),
    );
  }
}
