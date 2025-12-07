// lib/main.dart (snippet)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service/auth_service.dart';
import 'providers/task_provider.dart';
import 'pages/login_page.dart';
import 'pages/todo_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logged = await AuthService.isLoggedIn();

  runApp(
    ChangeNotifierProvider(
      create: (_) => TasksProvider(),
      child: MyApp(isLogged: logged),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLogged;
  const MyApp({required this.isLogged, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do + Login Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: isLogged ? const TodoListScreen() : const LoginPage(),
    );
  }
}
