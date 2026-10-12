import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/expense_store.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseApp());
}

class ExpenseApp extends StatefulWidget {
  const ExpenseApp({super.key});
  @override
  State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  late Future<ExpenseStore> store;
  @override
  void initState() {
    super.initState();
    store = ExpenseStore.open();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sổ chi tiêu VKU',
    debugShowCheckedModeBanner: false,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xff26705d),
      scaffoldBackgroundColor: const Color(0xfff5f7f4),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: FutureBuilder<ExpenseStore>(
      future: store,
      builder: (context, snapshot) {
        if (snapshot.hasData) return HomeScreen(store: snapshot.data!);
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Không mở được dữ liệu: ${snapshot.error}'),
                  TextButton(
                    onPressed: () =>
                        setState(() => store = ExpenseStore.open()),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    ),
  );
}
