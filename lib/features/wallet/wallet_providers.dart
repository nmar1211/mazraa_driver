import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/constants/build_flags.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';

final walletSummaryProvider = FutureProvider<WalletSummary>((ref) async {
  if (BuildFlags.ciSmokeHome) {
    return const WalletSummary(
      balance: 286,
      currency: 'SAR',
      accountNumber: 'DRV-SMOKE-77',
      monthlyCredits: 286,
      monthlyDebits: 0,
      pendingTopUpBalance: 0,
      canTransfer: true,
    );
  }
  return ref.watch(driverApiProvider).getWallet();
});

final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((
  ref,
) async {
  return ref.watch(driverApiProvider).getWalletTransactions();
});
