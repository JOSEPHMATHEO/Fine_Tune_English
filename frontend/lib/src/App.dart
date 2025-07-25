import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../components/auth/LoginScreen.dart';
import '../components/layout/Layout.dart';
import '../components/common/LoadingSpinner.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: LoadingSpinner()),
          );
        } else if (state is AuthAuthenticated) {
          return const Layout();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}