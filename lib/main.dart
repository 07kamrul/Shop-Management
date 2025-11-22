// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shop_management/blocs/category/category_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart'; // ← Add this
import 'features/dashboard/pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider<CategoryBloc>(
          create: (context) => CategoryBloc()..add(const LoadCategories()),
        ),
      ],
      child: MaterialApp(
        title: 'Shop Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),

        // Define all your named routes here
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => const DashboardPage(),
        },

        // Initial route
        initialRoute: '/login',

        // Optional: Fallback if route not found
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) =>
                const Scaffold(body: Center(child: Text('Page Not Found'))),
          );
        },
      ),
    );
  }
}
