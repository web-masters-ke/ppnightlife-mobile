import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/gradient_button.dart';

// ── Providers ──────────────────────────────────────────────────────────────────
final _walletProvider = FutureProvider.autoDispose((ref) async {
  final res = await ApiService().getWalletBalance();
  return res.data['data'] as Map<String, dynamic>;
});

final _txProvider = FutureProvider.autoDispose.family<List<dynamic>, String?>((ref, type) async {
  final res = await ApiService().getTransactionHistory(type: type);
  return (res.data['data']['items'] as List?) ?? [];
});

final _tippersProvider = FutureProvider.autoDispose((ref) async {
  final res = await ApiService().getTopTippers(limit: 5);
  return (res.data['data']['items'] as List?) ?? [];
});

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String? _txFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletAsync = ref.watch(_walletProvider);
    final txAsync = ref.watch(_txProvider(_txFilter));

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Wallet',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 20,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onPressed: () {
              ref.invalidate(_walletProvider);
              ref.invalidate(_txProvider(_txFilter));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: () async {
          ref.invalidate(_walletProvider);
          ref.invalidate(_txProvider(_txFilter));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance card
              walletAsync.when(
                loading: () => _BalanceCard(balance: null, isDark: isDark),
                error: (_, __) => _BalanceCard(balance: null, isDark: isDark),
                data: (wallet) => _BalanceCard(
                  balance: (wallet['balance'] as num?)?.toDouble(),
                  isDark: isDark,
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      label: 'Top Up',
                      height: 46,
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.white, size: 18),
                      onTap: () => _showTopUpSheet(context, isDark),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OutlineButton(
                      label: 'Send',
                      icon: HugeIcons.strokeRoundedSendToMobile02,
                      isDark: isDark,
                      onTap: () => _showSendSheet(context, isDark),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OutlineButton(
                      label: 'Withdraw',
                      icon: HugeIcons.strokeRoundedSent,
                      isDark: isDark,
                      onTap: () => _showWithdrawSheet(context, isDark),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Quick actions
              Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Row(
                children: [
                  _QuickAction(icon: HugeIcons.strokeRoundedMusicNote01, label: 'Tip DJ', gradient: AppColors.warmGradient, onTap: () {}),
                  const SizedBox(width: 10),
                  _QuickAction(icon: HugeIcons.strokeRoundedParty, label: 'Buy Ticket', gradient: AppColors.cyanGradient, onTap: () {}),
                  const SizedBox(width: 10),
                  _QuickAction(icon: HugeIcons.strokeRoundedDrink, label: 'Order', gradient: AppColors.primaryGradient, onTap: () {}),
                  const SizedBox(width: 10),
                  _QuickAction(
                    icon: HugeIcons.strokeRoundedGift,
                    label: 'Vouchers',
                    gradient: const LinearGradient(colors: [AppColors.pink, AppColors.purple]),
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Transaction stats summary
              walletAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (wallet) {
                  final tipsReceived = (wallet['tipsReceived'] as num?)?.toDouble() ?? 0;
                  final tipsSent = (wallet['tipsSent'] as num?)?.toDouble() ?? 0;
                  final totalTopups = (wallet['totalTopups'] as num?)?.toDouble() ?? 0;
                  final txCount = (wallet['transactionCount'] as num?)?.toInt() ?? 0;
                  if (tipsReceived == 0 && tipsSent == 0 && totalTopups == 0 && txCount == 0) return const SizedBox.shrink();
                  return Column(
                    children: [
                      Row(children: [
                        _StatCard(label: 'Tips Sent', value: 'KES ${tipsSent.toStringAsFixed(0)}', color: AppColors.orange, isDark: isDark),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Tips Received', value: 'KES ${tipsReceived.toStringAsFixed(0)}', color: AppColors.cyan, isDark: isDark),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        _StatCard(label: 'Total Top-ups', value: 'KES ${totalTopups.toStringAsFixed(0)}', color: AppColors.green, isDark: isDark),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Transactions', value: '$txCount', color: AppColors.purple, isDark: isDark),
                      ]),
                      const SizedBox(height: 28),
                    ],
                  );
                },
              ),

              // Transaction filter — all 7 types
              Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'All', selected: _txFilter == null, isDark: isDark, onTap: () => setState(() => _txFilter = null)),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Top-ups', selected: _txFilter == 'topup', isDark: isDark, onTap: () => setState(() => _txFilter = 'topup')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Tips Sent', selected: _txFilter == 'dj_tip', isDark: isDark, onTap: () => setState(() => _txFilter = 'dj_tip')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Tips Received', selected: _txFilter == 'tip_received', isDark: isDark, onTap: () => setState(() => _txFilter = 'tip_received')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Offers', selected: _txFilter == 'ticket_purchase', isDark: isDark, onTap: () => setState(() => _txFilter = 'ticket_purchase')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Sent', selected: _txFilter == 'transfer_out', isDark: isDark, onTap: () => setState(() => _txFilter = 'transfer_out')),
                    const SizedBox(width: 6),
                    _FilterChip(label: 'Withdrawals', selected: _txFilter == 'withdrawal', isDark: isDark, onTap: () => setState(() => _txFilter = 'withdrawal')),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              txAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.purple),
                )),
                error: (e, _) => _ErrorState(message: 'Failed to load transactions', isDark: isDark),
                data: (txList) {
                  if (txList.isEmpty) {
                    return _EmptyState(message: 'No transactions yet', emoji: '💳', isDark: isDark);
                  }
                  return Column(
                    children: txList.map((tx) => _TransactionTile(tx: tx as Map<String, dynamic>, isDark: isDark)).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopUpSheet(BuildContext context, bool isDark) {
    final amountCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String method = 'kcb_buni';
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgElevatedDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Top Up Wallet',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 17, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                const SizedBox(height: 16),

                // Payment method selector
                Text('Payment Method',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                const SizedBox(height: 8),
                ...[
                  ('kcb_buni', '📱 M-Pesa via KCB BUNI', 'Instant · STK Push'),
                  ('stripe_card', '💳 Credit/Debit Card', 'Instant'),
                  ('airtel_money', '📶 Airtel Money', 'Instant'),
                ].map((m) {
                  final selected = method == m.$1;
                  return GestureDetector(
                    onTap: () => setS(() => method = m.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.purple.withOpacity(0.08) : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.purple.withOpacity(0.5) : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                      ),
                      child: Row(children: [
                        Text(m.$1 == 'kcb_buni' ? '📱' : m.$1 == 'stripe_card' ? '💳' : '📶', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.$2.split(' ').skip(1).join(' '),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                            Text(m.$3, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                          ]),
                        ),
                        if (selected) Container(
                          width: 18, height: 18,
                          decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 11, color: Colors.white),
                        ),
                      ]),
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Quick amounts
                Text('Amount (KES)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['100','250','500','1000','2000','5000'].map((a) {
                    final sel = amountCtrl.text == a;
                    return GestureDetector(
                      onTap: () => setS(() => amountCtrl.text = a),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: sel ? AppColors.primaryGradient : null,
                          color: sel ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                        ),
                        child: Text('KES $a', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setS(() {}),
                  style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Or enter custom amount',
                    prefixText: 'KES ',
                    hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    filled: true, fillColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.purple)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),

                // Phone number for KCB BUNI / Airtel
                if (method == 'kcb_buni' || method == 'airtel_money') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: method == 'kcb_buni' ? 'M-Pesa number e.g. 0712345678' : 'Airtel number',
                      prefixIcon: const Icon(Icons.phone, size: 18, color: AppColors.purple),
                      hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      filled: true, fillColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: AppColors.purple)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                GradientButton(
                  label: loading ? 'Processing...' : 'Pay KES ${amountCtrl.text.isEmpty ? "—" : amountCtrl.text}',
                  onTap: loading ? null : () async {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) return;
                    if ((method == 'kcb_buni' || method == 'airtel_money') && phoneCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Please enter your phone number'),
                        backgroundColor: AppColors.red,
                      ));
                      return;
                    }
                    setS(() => loading = true);
                    try {
                      final res = await ApiService().topUpWallet({
                        'amount': amount,
                        'paymentMethod': method,
                        if (phoneCtrl.text.trim().isNotEmpty) 'phoneNumber': phoneCtrl.text.trim(),
                      });
                      final data = res.data['data'] as Map<String, dynamic>? ?? {};
                      final status = data['status'] as String? ?? 'completed';
                      final txId = data['transactionId'] as String?;
                      final checkoutRequestId = data['checkoutRequestId'] as String?;

                      if (ctx.mounted) Navigator.pop(ctx);

                      if (method == 'kcb_buni' && status == 'pending' && txId != null) {
                        // Show STK push waiting dialog
                        if (mounted) _showKcbWaitingDialog(context, isDark, txId, checkoutRequestId, amount);
                      } else {
                        // Immediately completed
                        ref.invalidate(_walletProvider);
                        ref.invalidate(_txProvider(_txFilter));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('✅ KES ${amount.toStringAsFixed(0)} added to wallet'),
                            backgroundColor: AppColors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ));
                        }
                      }
                    } catch (e) {
                      setS(() => loading = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text('Top up failed: $e'),
                          backgroundColor: AppColors.red,
                        ));
                      }
                    }
                  },
                ),

                if (method == 'kcb_buni') ...[
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_outline, size: 12, color: AppColors.textMutedDark),
                    const SizedBox(width: 4),
                    Text('Secured by KCB BUNI · STK Push',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showKcbWaitingDialog(BuildContext context, bool isDark, String txId, String? checkoutRequestId, double amount) {
    // State: 'waiting' | 'success' | 'timeout'
    String dialogState = 'waiting';
    int secondsLeft = 180; // 3 minutes

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        return StatefulBuilder(builder: (dCtx, setD) {
          // Start countdown + polling when dialog is first built
          Future.delayed(Duration.zero, () async {
            if (!dCtx.mounted) return;

            // Poll every 3 seconds for up to 3 minutes
            for (int i = 0; i < 60; i++) {
              await Future.delayed(const Duration(seconds: 3));
              if (!dCtx.mounted || dialogState != 'waiting') return;

              // Decrement timer
              if (mounted) setD(() { secondsLeft = (180 - (i + 1) * 3).clamp(0, 180); });

              // Poll transaction history for completion
              try {
                final histRes = await ApiService().getTransactionHistory(type: 'topup', limit: 5);
                final items = (histRes.data['data']['items'] as List?) ?? [];
                final tx = items.cast<Map<String, dynamic>>().firstWhere(
                  (t) => t['transactionId'] == txId || t['transaction_id'] == txId,
                  orElse: () => {},
                );
                if (tx.isNotEmpty && tx['status'] == 'completed') {
                  if (dCtx.mounted) setD(() => dialogState = 'success');
                  ref.invalidate(_walletProvider);
                  ref.invalidate(_txProvider(_txFilter));
                  await Future.delayed(const Duration(seconds: 2));
                  if (dCtx.mounted) Navigator.of(dCtx).pop();
                  return;
                }
              } catch (_) {}

              // Timeout after 3 minutes
              if (secondsLeft <= 0) {
                if (dCtx.mounted) setD(() => dialogState = 'timeout');
                return;
              }
            }
            if (dCtx.mounted && dialogState == 'waiting') setD(() => dialogState = 'timeout');
          });

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgElevatedDark : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: dialogState == 'success'
                  ? _KcbSuccessContent(amount: amount, isDark: isDark)
                  : dialogState == 'timeout'
                      ? _KcbTimeoutContent(
                          isDark: isDark,
                          onRetry: () { Navigator.of(dCtx).pop(); _showTopUpSheet(context, isDark); },
                          onCancel: () => Navigator.of(dCtx).pop(),
                        )
                      : _KcbWaitingContent(
                          amount: amount, secondsLeft: secondsLeft, isDark: isDark,
                          onCancel: () {
                            setD(() => dialogState = 'timeout');
                          },
                        ),
            ),
          );
        });
      },
    );
  }

  void _showSendSheet(BuildContext context, bool isDark) {
    final recipientCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          bool sending = false;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgElevatedDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 36, height: 4,
                      decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                        child: HugeIcon(icon: HugeIcons.strokeRoundedSendToMobile02, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Send Money', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 17, fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InputField(ctrl: recipientCtrl, label: 'Recipient (User ID or phone)', hint: 'e.g. user123 or +254...', isDark: isDark),
                  const SizedBox(height: 12),
                  _InputField(ctrl: amountCtrl, label: 'Amount (KES)', hint: '100', isDark: isDark, keyboardType: TextInputType.number, prefix: 'KES '),
                  const SizedBox(height: 12),
                  _InputField(ctrl: noteCtrl, label: 'Note (optional)', hint: 'e.g. For the night out', isDark: isDark),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: sending ? 'Sending...' : 'Send Money',
                    onTap: sending ? null : () async {
                      final recipient = recipientCtrl.text.trim();
                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (recipient.isEmpty || amount == null || amount <= 0) return;
                      setS(() => sending = true);
                      try {
                        await ApiService().sendMoney({
                          'recipientId': recipient,
                          'amount': amount,
                          if (noteCtrl.text.trim().isNotEmpty) 'note': noteCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        ref.invalidate(_walletProvider);
                        ref.invalidate(_txProvider(_txFilter));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('✅ KES ${amount.toStringAsFixed(0)} sent to $recipient'),
                            backgroundColor: AppColors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ));
                        }
                      } catch (e) {
                        setS(() => sending = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Send failed: $e'),
                            backgroundColor: AppColors.red,
                          ));
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, bool isDark) {
    final amountCtrl = TextEditingController();
    String method = 'm_pesa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgElevatedDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text('Withdraw', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 17, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (KES)',
                    prefixText: 'KES ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: InputDecoration(
                    labelText: 'Withdraw To',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'm_pesa', child: Text('M-Pesa')),
                    DropdownMenuItem(value: 'airtel_money', child: Text('Airtel Money')),
                    DropdownMenuItem(value: 'stripe_card', child: Text('Bank Card')),
                  ],
                  onChanged: (v) => setS(() => method = v!),
                ),
                const SizedBox(height: 16),
                _OutlineButton(
                  label: 'Withdraw',
                  icon: HugeIcons.strokeRoundedSent,
                  isDark: isDark,
                  onTap: () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) return;
                    try {
                      await ApiService().withdraw({'amount': amount, 'method': method});
                      if (ctx.mounted) Navigator.pop(ctx);
                      ref.invalidate(_walletProvider);
                      ref.invalidate(_txProvider(_txFilter));
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text('Withdrawal failed: $e'),
                          backgroundColor: AppColors.red,
                        ));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Balance Card ──────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double? balance;
  final bool isDark;
  const _BalanceCard({required this.balance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Positioned(top: -30, right: -30,
            child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
          Positioned(bottom: -40, left: -20,
            child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PP Balance', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        balance == null
                            ? Container(width: 120, height: 28, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)))
                            : Text(
                                'KES ${_fmt(balance!)}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                              ),
                      ],
                    ),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: const HugeIcon(icon: HugeIcons.strokeRoundedWallet01, color: Colors.white, size: 22),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _WalletChip(label: 'KCB BUNI', icon: HugeIcons.strokeRoundedSmartPhone01),
                    const SizedBox(width: 10),
                    _WalletChip(label: 'Card', icon: HugeIcons.strokeRoundedCreditCard),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) {
      final parts = v.toStringAsFixed(2).split('.');
      final whole = parts[0];
      final dec = parts[1];
      final formatted = whole.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
      return '$formatted.$dec';
    }
    return v.toStringAsFixed(2);
  }
}

// ── KCB BUNI Dialog Content ───────────────────────────────────────────────────
class _KcbWaitingContent extends StatelessWidget {
  final double amount;
  final int secondsLeft;
  final bool isDark;
  final VoidCallback onCancel;
  const _KcbWaitingContent({required this.amount, required this.secondsLeft, required this.isDark, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final mins = secondsLeft ~/ 60;
    final secs = secondsLeft % 60;
    final timerStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70, height: 70,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
          child: const Center(child: Text('📱', style: TextStyle(fontSize: 32))),
        ),
        const SizedBox(height: 16),
        Text('Check Your Phone',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        const SizedBox(height: 6),
        Text('Enter your M-Pesa PIN to complete\nKES ${amount.toStringAsFixed(0)} payment',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        const SizedBox(height: 20),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: secondsLeft / 180,
            backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Waiting for payment...', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          Text(timerStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.purple)),
        ]),
        const SizedBox(height: 16),
        const SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.purple),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.purple.withOpacity(0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.lock_outline, size: 14, color: AppColors.purple),
            SizedBox(width: 6),
            Expanded(child: Text('Powered by KCB BUNI · STK Push', style: TextStyle(fontSize: 12, color: AppColors.purple))),
          ]),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onCancel,
          child: Text('Cancel', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ),
      ],
    );
  }
}

class _KcbSuccessContent extends StatelessWidget {
  final double amount;
  final bool isDark;
  const _KcbSuccessContent({required this.amount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(color: AppColors.green.withOpacity(0.15), shape: BoxShape.circle,
              border: Border.all(color: AppColors.green.withOpacity(0.4), width: 2)),
          child: const Center(child: Icon(Icons.check_circle_rounded, size: 40, color: AppColors.green)),
        ),
        const SizedBox(height: 16),
        const Text('Payment Successful!',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.green)),
        const SizedBox(height: 6),
        Text('KES ${amount.toStringAsFixed(0)} has been added\nto your PP wallet',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMutedDark)),
      ],
    );
  }
}

class _KcbTimeoutContent extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  const _KcbTimeoutContent({required this.isDark, required this.onRetry, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(color: AppColors.red.withOpacity(0.12), shape: BoxShape.circle,
              border: Border.all(color: AppColors.red.withOpacity(0.3), width: 2)),
          child: const Center(child: Icon(Icons.timer_off_rounded, size: 38, color: AppColors.red)),
        ),
        const SizedBox(height: 16),
        Text('Payment Timed Out',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 17, fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        const SizedBox(height: 8),
        Text('The payment request expired.\nPlease try again.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: onCancel,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Center(child: Text('Close',
                  style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                height: 44,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String label;
  final List<List<dynamic>> icon;
  const _WalletChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Quick Action ──────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: (gradient as LinearGradient).colors.first.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Center(child: HugeIcon(icon: icon, color: Colors.white, size: 22)),
            ),
            const SizedBox(height: 6),
            Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Outline Button ────────────────────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final String label;
  final List<List<dynamic>> icon;
  final bool isDark;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 18, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
      ),
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final bool isDark;
  const _TransactionTile({required this.tx, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final type = tx['type'] as String? ?? '';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final isDebit = ['dj_tip', 'withdrawal', 'ticket_purchase', 'transfer_out'].contains(type);
    final status = tx['status'] as String? ?? 'completed';
    final ts = tx['timestamp'] as String? ?? '';
    final time = ts.isNotEmpty ? _fmtTime(ts) : '';

    final (label, icon) = _txMeta(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: isDebit ? AppColors.warmGradient : AppColors.cyanGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: HugeIcon(icon: icon, color: Colors.white, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                Text(status == 'pending' ? '⏳ Pending' : status,
                    style: TextStyle(fontSize: 12, color: status == 'completed' ? AppColors.green : status == 'pending' ? AppColors.orange : AppColors.red)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isDebit ? '-KES ${amount.toStringAsFixed(0)}' : '+KES ${amount.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                    color: status == 'pending' ? AppColors.orange : (isDebit ? AppColors.red : AppColors.green)),
              ),
              Text(time, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
            ],
          ),
        ],
      ),
    );
  }

  (String, List<List<dynamic>>) _txMeta(String type) {
    switch (type) {
      case 'dj_tip': return ('DJ Tip', HugeIcons.strokeRoundedMusicNote01);
      case 'topup': return ('Wallet Top Up', HugeIcons.strokeRoundedAdd01);
      case 'withdrawal': return ('Withdrawal', HugeIcons.strokeRoundedSent);
      case 'ticket_purchase': return ('Event Ticket', HugeIcons.strokeRoundedParty);
      default: return ('Transaction', HugeIcons.strokeRoundedWallet01);
    }
  }

  String _fmtTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return ts;
    }
  }
}

// ── Empty / Error States ──────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message, emoji;
  final bool isDark;
  const _EmptyState({required this.message, required this.emoji, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorState({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _StatCard({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ],
      ),
    );
  }
}

// ── Input Field ───────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool isDark;
  final TextInputType? keyboardType;
  final String? prefix;
  const _InputField({required this.ctrl, required this.label, required this.hint, required this.isDark, this.keyboardType, this.prefix});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType ?? TextInputType.text,
          style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            prefixStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            filled: true,
            fillColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.purple)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
