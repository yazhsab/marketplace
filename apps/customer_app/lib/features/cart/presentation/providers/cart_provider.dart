import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cart_item_model.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    final existingIndex =
        state.indexWhere((e) => e.productId == item.productId);

    if (existingIndex >= 0) {
      final existing = state[existingIndex];
      final updated =
          existing.copyWith(quantity: existing.quantity + item.quantity);
      state = [
        ...state.sublist(0, existingIndex),
        updated,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(String productId) {
    state = state.where((e) => e.productId != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = state.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      final updated = state[index].copyWith(quantity: quantity);
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
    }
  }

  void incrementQuantity(String productId) {
    final index = state.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      updateQuantity(productId, state[index].quantity + 1);
    }
  }

  void decrementQuantity(String productId) {
    final index = state.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      updateQuantity(productId, state[index].quantity - 1);
    }
  }

  void clearCart() {
    state = [];
  }

  double get subtotal {
    return state.fold(0, (sum, item) => sum + item.total);
  }

  double get deliveryFee {
    if (state.isEmpty) return 0;
    return subtotal >= 500 ? 0 : 40;
  }

  double get total => subtotal + deliveryFee;

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// Computed providers
final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider.notifier).subtotal;
});

final cartDeliveryFeeProvider = Provider<double>((ref) {
  return ref.watch(cartProvider.notifier).deliveryFee;
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider.notifier).total;
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.notifier).itemCount;
});
