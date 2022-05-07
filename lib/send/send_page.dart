import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lotus_pollen/providers.dart';

class SendPage extends HookConsumerWidget {
  const SendPage({Key? key}) : super(key: key);

  double? _processTotal(List<Recipient> recipients) {
    try {
      final total = recipients.fold<double>(0, (acc, r) {
        final amount = double.tryParse(r.amount);
        if (amount == null) {
          throw Exception();
        }
        return acc + amount;
      });
      return total;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, ref) {
    final rpcClient = ref.watch(rpcClientProvider);
    final sharedPreferences = ref.watch(sharedPreferencesProvider);
    final balance = ref.watch(balanceProvider);
    final recipients = ref.watch(recipientProvider);
    final addressCtrl = useTextEditingController();
    final amountCtrl = useTextEditingController();
    final newAddress = useState('');
    final newAmount = useState('');
    final loading = useState(false);

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        try {
          final response = await rpcClient.call('getbalance', []);
          ref.read(balanceProvider.notifier).setBalance(response.toString());
        } catch (e) {
          print(e);
        }
      });

      return () => timer.cancel();
    }, [rpcClient]);

    useEffect(() {
      Future.microtask(() {
        try {
          final storedRecipients = sharedPreferences.getString('recipients');
          if (storedRecipients != null) {
            final parsedRecipients =
                jsonDecode(storedRecipients) as Map<String, dynamic>;
            final recipients = parsedRecipients.entries
                .map((e) => Recipient(address: e.key, amount: e.value))
                .toList();
            ref.read(recipientProvider.notifier).setRecipients(recipients);
          }
        } catch (e) {
          print(e);
        }
      });

      return null;
    }, [sharedPreferences]);

    useEffect(() {
      addressCtrl.addListener(() {
        newAddress.value = addressCtrl.text;
      });
      amountCtrl.addListener(() {
        newAmount.value = amountCtrl.text;
      });
      return null;
    }, [addressCtrl, amountCtrl]);

    final total = _processTotal(recipients);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Balance: $balance'),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Address',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: TextField(
                        controller: amountCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Amount',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: addressCtrl.text.isNotEmpty &&
                              amountCtrl.text.isNotEmpty
                          ? () async {
                              try {
                                final address = addressCtrl.text;
                                final amount = amountCtrl.text;

                                try {
                                  final response = await rpcClient
                                      .call('validateaddress', [address]);
                                  if (!response['isvalid']) {
                                    throw Exception();
                                  }
                                } catch (e) {
                                  throw Exception('Invalid address');
                                }

                                if (double.tryParse(amount) == null) {
                                  throw Exception('Invalid amount');
                                }

                                ref
                                    .read(recipientProvider.notifier)
                                    .addRecipient(Recipient(
                                        address: address, amount: amount));
                                addressCtrl.clear();
                                amountCtrl.clear();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: const Icon(Icons.add),
                      style: TextButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: recipients.length,
                  itemBuilder: (context, index) {
                    final recipient = recipients[index];
                    return ListTile(
                      title: Text(recipient.address),
                      subtitle: Text('${recipient.amount} XPI'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          ref.read(recipientProvider.notifier).setRecipients(
                              recipients.where((e) => e != recipient).toList());
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                    total == null ? 'Invalid Amount' : 'Total: $total XPI'),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: recipients.isNotEmpty && !loading.value
                      ? () async {
                          try {
                            if (total != null &&
                                total >= (double.tryParse(balance) ?? 0)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Insufficient Funds')),
                              );
                              return;
                            }

                            loading.value = true;
                            final recipientsJson = {
                              for (var e in recipients) e.address: e.amount
                            };
                            print(recipientsJson);

                            if (rpcClient.walletPassphrase.isNotEmpty) {
                              await rpcClient.call(
                                'walletpassphrase',
                                [rpcClient.walletPassphrase, 30],
                              );
                            }

                            final result = await rpcClient.call(
                              'sendmany',
                              [
                                '',
                                recipientsJson,
                              ],
                            );
                            print(result);
                            sharedPreferences.setString(
                              'recipients',
                              jsonEncode(recipientsJson),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Successfully sent! $result'),
                              action: SnackBarAction(
                                label: 'Copy',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: '$result',
                                    ),
                                  );
                                },
                              ),
                            ));
                          } catch (e) {
                            print(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to send'),
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
                        const Text('Send'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
