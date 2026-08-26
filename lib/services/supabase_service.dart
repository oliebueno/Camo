import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/mock_products.dart';
import '../models/product.dart';

/// Servicio central para gestionar la base de datos Supabase con soporte Offline-First
class SupabaseService {
  static const String supabaseUrl = 'https://tbuphfnkglpcgozpqzrp.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRidXBoZm5rZ2xwY2dvenBxenJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc3NTQ0MzQsImV4cCI6MjEwMzMzMDQzNH0.wQiAaJTx8lTy5h1DWR7cjLe1K7RvX-w3HsHpbq0yRpk';

  static const String _localProductsKey = 'camo_local_products_cache';

  static SupabaseClient get client => Supabase.instance.client;

  /// Inicializa la conexión de Supabase al arrancar la app
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Obtiene todos los productos: primero intenta Supabase; si no hay internet, lee del caché local
  static Future<List<Product>> getProducts() async {
    try {
      final response = await client
          .from('products')
          .select()
          .order('name', ascending: true);

      final List<dynamic> data = response;
      final products = data.map((json) => Product.fromJson(json)).toList();

      // Guardamos una copia fresca en el almacenamiento local para cuando no haya internet
      await _cacheProductsLocally(products);

      return products;
    } catch (e) {
      // Si falla la conexión (offline), cargamos del almacenamiento local
      return await getLocalCachedProducts();
    }
  }

  /// Crea un nuevo producto en Supabase y actualiza la copia local
  static Future<Product> createProduct(Product product) async {
    final response = await client
        .from('products')
        .insert(product.toJson(includeId: false))
        .select()
        .single();

    final created = Product.fromJson(response);
    await _addProductToLocalCache(created);
    return created;
  }

  /// Actualiza un producto existente en Supabase y en local
  static Future<void> updateProduct(Product product) async {
    await client
        .from('products')
        .update(product.toJson(includeId: false))
        .eq('id', product.id);

    await _updateProductInLocalCache(product);
  }

  /// Elimina un producto en Supabase y en local
  static Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
    await _deleteProductFromLocalCache(id);
  }

  // ==========================================
  // MÉTODOS DE ALMACENAMIENTO LOCAL (OFFLINE)
  // ==========================================

  static Future<void> _cacheProductsLocally(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = products.map((p) => p.toJson()).toList();
    await prefs.setString(_localProductsKey, json.encode(jsonList));
  }

  static Future<List<Product>> getLocalCachedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_localProductsKey);

    if (cachedString != null && cachedString.isNotEmpty) {
      final List<dynamic> decoded = json.decode(cachedString);
      return decoded.map((j) => Product.fromJson(j)).toList();
    }

    // Si nunca se ha guardado nada, usamos los iniciales de prueba
    return initialMockProducts;
  }

  static Future<void> _addProductToLocalCache(Product product) async {
    final products = await getLocalCachedProducts();
    products.add(product);
    await _cacheProductsLocally(products);
  }

  static Future<void> _updateProductInLocalCache(Product product) async {
    final products = await getLocalCachedProducts();
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      await _cacheProductsLocally(products);
    }
  }

  static Future<void> _deleteProductFromLocalCache(String id) async {
    final products = await getLocalCachedProducts();
    products.removeWhere((p) => p.id == id);
    await _cacheProductsLocally(products);
  }
}
