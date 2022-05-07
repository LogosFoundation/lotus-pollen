import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lotus_pollen/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  String _getFromPreferences(
      SharedPreferences prefs, String key, String fallback) {
    return prefs.getString(key) ?? fallback;
  }

  @override
  Widget build(BuildContext context, ref) {
    final rpcClient = ref.watch(rpcClientProvider);
    final sharedPreferences = ref.watch(sharedPreferencesProvider);
    final urlCtrl = useTextEditingController(
      text: _getFromPreferences(sharedPreferences, 'url', rpcClient.url),
    );
    final usernameCtrl = useTextEditingController(
      text: _getFromPreferences(
          sharedPreferences, 'username', rpcClient.username),
    );
    final passwordCtrl = useTextEditingController(
      text: _getFromPreferences(
          sharedPreferences, 'password', rpcClient.password),
    );
    final walletPassphraseCtrl =
        useTextEditingController(text: rpcClient.walletPassphrase);
    final loading = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pollen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                  ),
                  onChanged: (value) =>
                      ref.read(rpcClientProvider.notifier).setUrl(value),
                ),
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                  onChanged: (value) =>
                      ref.read(rpcClientProvider.notifier).setUsername(value),
                ),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  onChanged: (value) =>
                      ref.read(rpcClientProvider.notifier).setPassword(value),
                ),
                TextField(
                  controller: walletPassphraseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Wallet Passphrase',
                    hintText: 'Leave empty if no passphrase',
                  ),
                  onChanged: (value) => ref
                      .read(rpcClientProvider.notifier)
                      .setWalletPassphrase(value),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: !loading.value
                      ? () async {
                          try {
                            loading.value = true;
                            if (rpcClient.walletPassphrase.isNotEmpty) {
                              await rpcClient.call(
                                'walletpassphrase',
                                [walletPassphraseCtrl.text, 1],
                              );
                            }
                            final response =
                                await rpcClient.call('getbalance', []);
                            ref
                                .read(balanceProvider.notifier)
                                .setBalance(response.toString());
                            Navigator.pushNamed(context, '/send');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Failed to connect. Make sure your node is running'),
                              ),
                            );
                          }
                          loading.value = false;
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loading.value) ...[
                          const SizedBox(
                            height: 12,
                            width: 12,
                            child: CircularProgressIndicator(
                              color: Colors.pink,
                              strokeWidth: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        const Text('Connect'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
