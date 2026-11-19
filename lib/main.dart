import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:toktok/app.dart';
import 'package:toktok/firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Startup());
}

class _Startup extends StatefulWidget {
  const _Startup();
  @override
  State<_Startup> createState() => _StartupState();
}

class _StartupState extends State<_Startup> {
  late Future<void> _ready = _initialize();
  Future<void> _initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return const TawselaApp();
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child:
                  snapshot.hasError
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'تعذر تشغيل توصيلة. تحقق من الإنترنت وحاول تاني',
                          ),
                          TextButton(
                            onPressed:
                                () => setState(() => _ready = _initialize()),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      )
                      : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}
