import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/product_repository.dart';
import 'data/services/product_service.dart';
import 'providers/product_provider.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProductProvider(
        repository: ProductRepository(productService: ProductService()),
      ),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Catalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315C4C)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
