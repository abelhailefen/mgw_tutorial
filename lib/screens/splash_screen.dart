import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/widgets/custom_loading_widget.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Wait for AuthProvider to finish initializing (loading from DB)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    while (authProvider.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await Future.delayed(const Duration(seconds: 1)); 

    if (authProvider.currentUser != null && authProvider.currentUser!.id != null) {
      Navigator.of(context).pushReplacementNamed('/main'); 
    } else {
      Navigator.of(context).pushReplacementNamed('/intro'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const CustomLoadingWidget(),
    );
  }
}