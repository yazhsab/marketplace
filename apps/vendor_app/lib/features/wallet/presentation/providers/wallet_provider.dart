import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../data/models/wallet_model.dart';

class WalletState {
  final bool isLoading;
  final String? error;
  final WalletModel? wallet;
  final List<WalletTransactionModel> transactions;
  final bool isTransactionsLoading;

  const WalletState({
    this.isLoading = false,
    this.error,
    this.wallet,
    this.transactions = const [],
    this.isTransactionsLoading = false,
  });

  WalletState copyWith({
    bool? isLoading,
    String? error,
    WalletModel? wallet,
    List<WalletTransactionModel>? transactions,
    bool? isTransactionsLoading,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      isTransactionsLoading:
          isTransactionsLoading ?? this.isTransactionsLoading,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final Ref _ref;

  WalletNotifier(this._ref) : super(const WalletState()) {
    loadWallet();
    loadTransactions();
  }

  Future<void> loadWallet() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(ApiEndpoints.vendorWallet);
      final wallet = WalletModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
      state = state.copyWith(isLoading: false, wallet: wallet);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isTransactionsLoading: true);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response =
          await apiClient.get(ApiEndpoints.vendorWalletTransactions);

      final data = response.data['data'];
      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List;
      }

      state = state.copyWith(
        isTransactionsLoading: false,
        transactions: items
            .map((e) => WalletTransactionModel.fromJson(
                e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isTransactionsLoading: false);
    }
  }

  Future<bool> requestPayout(double amount) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(
        ApiEndpoints.vendorWalletPayout,
        data: {'amount': amount},
      );
      await loadWallet();
      await loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref);
});
