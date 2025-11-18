import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'providers/project_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  final provider = ProjectProvider(storage: storage);
  await provider.load();

  runApp(MyApp(provider: provider));
}

class MyApp extends StatelessWidget {
  final ProjectProvider provider;
  const MyApp({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProjectProvider>.value(
      value: provider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FlashQuanta',
        themeMode: ThemeMode.dark,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            primary: Colors.orange,
            secondary: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          canvasColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            primary: Colors.orange,
            secondary: Colors.blue,
            brightness: Brightness.dark,
            background: Colors.black,
            surface: Colors.black,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}