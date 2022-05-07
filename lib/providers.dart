import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lotus_pollen/rpc_client/rpcclient.dart';
import 'package:shared_preferences/shared_preferences.dart';

final rpcClientProvider = StateNotifierProvider<RPCClientNotifier, RPCClient>(
  (ref) => RPCClientNotifier(),
);

class RPCClientNotifier extends StateNotifier<RPCClient> {
  RPCClientNotifier() : super(RPCClient());

  void setUrl(String url) => state.url = url;
  void setUsername(String username) => state.username = username;
  void setPassword(String password) => state.password = password;
  void setWalletPassphrase(String passphrase) =>
      state.walletPassphrase = passphrase;
}

class Recipient {
  final String address;
  final String amount;

  const Recipient({required this.address, required this.amount});

  dynamic toJson() {
    final json = <String, String>{};
    json['address'] = address;
    json['amount'] = amount;
    return json;
  }

  Recipient.fromJson(dynamic json)
      : address = json.keys.first,
        amount = json.values.first;
}

final recipientProvider =
    StateNotifierProvider<RecipientNotifier, List<Recipient>>(
  (ref) => RecipientNotifier(),
);

class RecipientNotifier extends StateNotifier<List<Recipient>> {
  RecipientNotifier() : super([]);

  void setRecipients(List<Recipient> recipients) => state = recipients;
  void addRecipient(Recipient recipient) =>
      state = List.from(state)..add(recipient);
}

late Provider<SharedPreferences> sharedPreferencesProvider;

final balanceProvider = StateNotifierProvider<BalanceNotifier, String>(
  (ref) => BalanceNotifier(),
);

class BalanceNotifier extends StateNotifier<String> {
  BalanceNotifier() : super('0');

  void setBalance(String balance) => state = balance;
}
