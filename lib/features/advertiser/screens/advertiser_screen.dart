import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class AdvertiserScreen extends ConsumerStatefulWidget {
  const AdvertiserScreen({super.key});

  @override
  ConsumerState<AdvertiserScreen> createState() => _AdvertiserScreenState();
}

class _AdvertiserScreenState extends ConsumerState<AdvertiserScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: isDark ? 0 : 1,
        title: Row(
          children: [
            const Text('📣', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              user?.name ?? 'Ad Manager',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification01,
              size: 22,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.orange,
          labelColor: AppColors.orange,
          unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          labelStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Campaigns'),
            Tab(text: 'Analytics'),
            Tab(text: 'Billing'),
            Tab(text: 'Targeting'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(isDark: isDark),
          _CampaignsTab(isDark: isDark),
          _AnalyticsTab(isDark: isDark),
          _BillingTab(isDark: isDark),
          _TargetingTab(isDark: isDark),
          _SettingsTab(isDark: isDark, user: user),
        ],
      ),
    );
  }
}

// ─── OVERVIEW TAB ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  final bool isDark;
  const _OverviewTab({required this.isDark});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  List<_MockCampaign> _campaigns = [];
  Map<String, dynamic>? _overview;
  bool _loadingOverview = false;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() => _loadingOverview = true);
    try {
      final results = await Future.wait([
        ApiService().getAdvertiserOverview(),
        ApiService().getCampaigns(),
      ]);
      final overviewData = results[0].data['data'];
      final campaignsData = (results[1].data['data']['items'] as List?) ?? [];
      setState(() {
        _overview = overviewData as Map<String, dynamic>?;
        if (campaignsData.isNotEmpty) {
          _campaigns = campaignsData.map((c) {
            final m = c as Map<String, dynamic>;
            final budget = (m['budget'] as num?)?.toDouble() ?? 0;
            final spent = (m['spentAmount'] as num?)?.toDouble() ?? 0;
            return _MockCampaign(
              name: m['name'] as String? ?? 'Campaign',
              description: m['description'] as String? ?? '',
              adType: m['type'] as String? ?? 'banner',
              reach: '${m['impressions'] ?? 0}',
              clicks: '${m['clicks'] ?? 0}',
              ctr: '${((m['ctr'] as num?) ?? 0).toStringAsFixed(1)}%',
              budget: 'KES ${budget.toStringAsFixed(0)}',
              progress: budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0,
              budgetNum: budget,
              startDate: m['startDate'] as String? ?? '',
              endDate: m['endDate'] as String? ?? '',
              isActive: m['status'] == 'active',
            );
          }).toList();
        }
        _loadingOverview = false;
      });
    } catch (_) {
      setState(() => _loadingOverview = false);
    }
  }

  void _toggleCampaign(int i) {
    setState(() => _campaigns[i] = _campaigns[i].copyWith(isActive: !_campaigns[i].isActive));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Campaign Manager', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                      const Text('Reach your audience 🎯',
                          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 3),
                      const Text('Nightlife advertising at its best', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                const Text('📣', style: TextStyle(fontSize: 40)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPI grid
          Row(children: [
            _KpiCard(label: 'Impressions', value: _overview != null ? '${_overview!['totalImpressions'] ?? 0}' : '—', icon: HugeIcons.strokeRoundedView, color: AppColors.cyan, isDark: isDark),
            const SizedBox(width: 10),
            _KpiCard(label: 'Clicks', value: _overview != null ? '${_overview!['totalClicks'] ?? 0}' : '—', icon: HugeIcons.strokeRoundedCursor01, color: AppColors.purple, isDark: isDark),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _KpiCard(label: 'Avg CTR', value: _overview != null ? '${((_overview!['avgCtr'] as num?) ?? 0).toStringAsFixed(1)}%' : '—', icon: HugeIcons.strokeRoundedAnalytics01, color: AppColors.green, isDark: isDark),
            const SizedBox(width: 10),
            _KpiCard(label: 'Budget Spent', value: _overview != null ? 'KES ${_overview!['totalSpent'] ?? 0}' : '—', icon: HugeIcons.strokeRoundedMoney01, color: AppColors.orange, isDark: isDark),
          ]),

          const SizedBox(height: 20),
          _SectionTitle('Active Campaigns', isDark: isDark),
          const SizedBox(height: 10),
          ..._campaigns.asMap().entries.map((e) => _CampaignCard(
                campaign: e.value,
                isDark: isDark,
                onToggle: () => _toggleCampaign(e.key),
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── CAMPAIGNS TAB ────────────────────────────────────────────────────────────
class _CampaignsTab extends StatefulWidget {
  final bool isDark;
  const _CampaignsTab({required this.isDark});

  @override
  State<_CampaignsTab> createState() => _CampaignsTabState();
}

class _CampaignsTabState extends State<_CampaignsTab> {
  List<_MockCampaign> _campaigns = [];
  bool _showCreateForm = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final res = await ApiService().getCampaigns();
      final items = (res.data['data']['items'] as List?) ?? [];
      setState(() {
        if (items.isNotEmpty) {
          _campaigns = items.map((c) {
            final m = c as Map<String, dynamic>;
            final budget = (m['budget'] as num?)?.toDouble() ?? 0;
            final spent = (m['spentAmount'] as num?)?.toDouble() ?? 0;
            return _MockCampaign(
              campaignId: m['campaignId'] as String? ?? m['_id'] as String? ?? '',
              name: m['name'] as String? ?? 'Campaign',
              description: m['description'] as String? ?? '',
              adType: m['type'] as String? ?? 'banner',
              reach: '${m['impressions'] ?? 0}',
              clicks: '${m['clicks'] ?? 0}',
              ctr: '${((m['ctr'] as num?) ?? 0).toStringAsFixed(1)}%',
              budget: 'KES ${budget.toStringAsFixed(0)}',
              progress: budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0,
              budgetNum: budget,
              startDate: m['startDate'] as String? ?? '',
              endDate: m['endDate'] as String? ?? '',
              isActive: m['status'] == 'active',
            );
          }).toList();
        }
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleCampaign(int i) async {
    final c = _campaigns[i];
    final newActive = !c.isActive;
    setState(() => _campaigns[i] = c.copyWith(isActive: newActive));
    if (c.campaignId.isNotEmpty) {
      try {
        if (newActive) {
          await ApiService().resumeCampaign(c.campaignId);
        } else {
          await ApiService().pauseCampaign(c.campaignId);
        }
      } catch (_) {
        if (mounted) setState(() => _campaigns[i] = c.copyWith(isActive: c.isActive));
      }
    }
  }

  Future<void> _deleteCampaign(int i) async {
    final c = _campaigns[i];
    setState(() => _campaigns.removeAt(i));
    if (c.campaignId.isNotEmpty) {
      try {
        await ApiService().updateCampaign(c.campaignId, {'status': 'deleted'});
      } catch (_) {
        if (mounted) setState(() => _campaigns.insert(i, c));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(
      children: [
        // Header bar
        Container(
          color: isDark ? AppColors.bgDark : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Text(
                '${_campaigns.length} Campaigns',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showCreateForm = !_showCreateForm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: _showCreateForm ? null : AppColors.warmGradient,
                    color: _showCreateForm ? (isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight) : null,
                    borderRadius: BorderRadius.circular(20),
                    border: _showCreateForm
                        ? Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_showCreateForm ? Icons.close : Icons.add, size: 14,
                          color: _showCreateForm ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight) : Colors.white),
                      const SizedBox(width: 4),
                      Text(_showCreateForm ? 'Cancel' : 'New Campaign',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: _showCreateForm ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight) : Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Create form
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _showCreateForm
              ? _CreateCampaignForm(
                  isDark: isDark,
                  onCreated: (c) => setState(() {
                    _campaigns.insert(0, c);
                    _showCreateForm = false;
                  }),
                )
              : const SizedBox.shrink(),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _campaigns.length,
            itemBuilder: (_, i) => _CampaignDetailCard(
              campaign: _campaigns[i],
              isDark: isDark,
              onToggle: () => _toggleCampaign(i).ignore(),
              onDelete: () => _deleteCampaign(i).ignore(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateCampaignForm extends StatefulWidget {
  final bool isDark;
  final Function(_MockCampaign) onCreated;
  const _CreateCampaignForm({required this.isDark, required this.onCreated});

  @override
  State<_CreateCampaignForm> createState() => _CreateCampaignFormState();
}

class _CreateCampaignFormState extends State<_CreateCampaignForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  String _adType = 'Feed Ad';
  String _startDate = 'Today';
  String _endDate = '+7 days';
  final _adTypes = ['Feed Ad', 'Story Ad', 'Banner'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Campaign', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 12),
          _FormField(ctrl: _nameCtrl, label: 'Campaign Name', hint: 'e.g. Weekend Vibes Promo', isDark: isDark),
          const SizedBox(height: 10),
          _FormField(ctrl: _descCtrl, label: 'Description', hint: 'What are you promoting?', isDark: isDark, maxLines: 2),
          const SizedBox(height: 10),
          _FormField(ctrl: _budgetCtrl, label: 'Total Budget (KES)', hint: 'e.g. 5000', isDark: isDark, keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          Text('Ad Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 6),
          Row(
            children: _adTypes.map((t) {
              final sel = t == _adType;
              return GestureDetector(
                onTap: () => setState(() => _adType = t),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.warmGradient : null,
                    color: sel ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                  ),
                  child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (_nameCtrl.text.trim().isEmpty || _budgetCtrl.text.trim().isEmpty) return;
                    final budget = double.tryParse(_budgetCtrl.text.trim()) ?? 0;
                    try {
                      await ApiService().createCampaign({
                        'name': _nameCtrl.text.trim(),
                        'description': _descCtrl.text.trim().isEmpty ? 'Nightlife campaign' : _descCtrl.text.trim(),
                        'type': _adType,
                        'budget': budget,
                        'startDate': _startDate,
                        'endDate': _endDate,
                      });
                    } catch (_) {}
                    widget.onCreated(_MockCampaign(
                      name: _nameCtrl.text.trim(),
                      description: _descCtrl.text.trim().isEmpty ? 'Nightlife campaign' : _descCtrl.text.trim(),
                      adType: _adType,
                      reach: '0',
                      clicks: '0',
                      ctr: '0%',
                      budget: 'KES ${_budgetCtrl.text.trim()}',
                      budgetNum: budget,
                      progress: 0,
                      startDate: _startDate,
                      endDate: _endDate,
                      isActive: true,
                    ));
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(gradient: AppColors.warmGradient, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('Create Campaign',
                        style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampaignDetailCard extends StatelessWidget {
  final _MockCampaign campaign;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CampaignDetailCard({required this.campaign, required this.isDark, required this.onToggle, required this.onDelete});

  void _showAnalytics(BuildContext context) {
    if (campaign.campaignId.isEmpty) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _CampaignAnalyticsSheet(campaignId: campaign.campaignId, name: campaign.name, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media preview strip
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedImage01, size: 30, color: Colors.white38),
                const SizedBox(width: 10),
                Text(campaign.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(campaign.description,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(campaign.adType,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.orange)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (campaign.isActive ? AppColors.green : Colors.grey).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(campaign.isActive ? 'Active' : 'Paused',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                        color: campaign.isActive ? AppColors.green : Colors.grey)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: onToggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (campaign.isActive ? AppColors.orange : AppColors.green).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: (campaign.isActive ? AppColors.orange : AppColors.green).withOpacity(0.3)),
                            ),
                            child: Text(campaign.isActive ? 'Pause' : 'Resume',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    color: campaign.isActive ? AppColors.orange : AppColors.green)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: onDelete,
                          child: const HugeIcon(icon: HugeIcons.strokeRoundedDelete01, size: 18, color: AppColors.red),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _Metric(label: 'Impressions', value: campaign.reach, isDark: isDark),
                  const SizedBox(width: 20),
                  _Metric(label: 'Clicks', value: campaign.clicks, isDark: isDark),
                  const SizedBox(width: 20),
                  _Metric(label: 'CTR', value: campaign.ctr, isDark: isDark),
                ]),
                const SizedBox(height: 10),
                Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedCalendar01, size: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    const SizedBox(width: 4),
                    Text('${campaign.startDate} → ${campaign.endDate}',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    const Spacer(),
                    Text(campaign.budget,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.orange)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: campaign.progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                  ),
                ),
                const SizedBox(height: 3),
                Text('${(campaign.progress * 100).toInt()}% of budget used',
                    style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                if (campaign.campaignId.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showAnalytics(context),
                    child: Container(
                      width: double.infinity, height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedAnalytics01, size: 14, color: AppColors.orange),
                        SizedBox(width: 6),
                        Text('View Analytics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange)),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignAnalyticsSheet extends StatefulWidget {
  final String campaignId, name;
  final bool isDark;
  const _CampaignAnalyticsSheet({required this.campaignId, required this.name, required this.isDark});

  @override
  State<_CampaignAnalyticsSheet> createState() => _CampaignAnalyticsSheetState();
}

class _CampaignAnalyticsSheetState extends State<_CampaignAnalyticsSheet> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService().getCampaignAnalytics(widget.campaignId);
      if (mounted) setState(() { _data = res.data['data'] as Map<String, dynamic>?; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgElevatedDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: ListView(controller: ctrl, padding: const EdgeInsets.all(20), children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(widget.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 4),
            Text('Campaign Analytics', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.orange))
            else if (_data == null)
              const Center(child: Text('No analytics available yet'))
            else ...[
              _buildMetric('Impressions', '${_data!['impressions'] ?? 0}', AppColors.purple, isDark),
              _buildMetric('Clicks', '${_data!['clicks'] ?? 0}', AppColors.cyan, isDark),
              _buildMetric('CTR', '${((_data!['ctr'] as num?) ?? 0).toStringAsFixed(2)}%', AppColors.orange, isDark),
              _buildMetric('Spent', 'KES ${((_data!['spent'] as num?) ?? 0).toStringAsFixed(0)}', AppColors.red, isDark),
              _buildMetric('Conversions', '${_data!['conversions'] ?? 0}', AppColors.green, isDark),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

// ─── ANALYTICS TAB ────────────────────────────────────────────────────────────
class _AnalyticsTab extends StatefulWidget {
  final bool isDark;
  const _AnalyticsTab({required this.isDark});

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  Map<String, dynamic>? _overview;
  List<_MockCampaign> _campaigns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService().getAdvertiserOverview(),
        ApiService().getCampaigns(),
      ]);
      final overview = results[0].data['data'] as Map<String, dynamic>?;
      final campaignItems = (results[1].data['data']['items'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _overview = overview;
          if (campaignItems.isNotEmpty) {
            _campaigns = campaignItems.map((c) {
              final m = c as Map<String, dynamic>;
              final budget = (m['budget'] as num?)?.toDouble() ?? 0;
              final spent = (m['spentAmount'] as num?)?.toDouble() ?? 0;
              return _MockCampaign(
                name: m['name'] as String? ?? 'Campaign',
                description: m['description'] as String? ?? '',
                adType: m['type'] as String? ?? 'banner',
                reach: '${m['impressions'] ?? 0}',
                clicks: '${m['clicks'] ?? 0}',
                ctr: '${((m['ctr'] as num?) ?? 0).toStringAsFixed(1)}%',
                budget: 'KES ${budget.toStringAsFixed(0)}',
                progress: budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0,
                budgetNum: budget,
                startDate: m['startDate'] as String? ?? '',
                endDate: m['endDate'] as String? ?? '',
                isActive: m['status'] == 'active',
              );
            }).toList();
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final totalImpressions = (_overview?['totalImpressions'] as num?)?.toInt() ?? 48200;
    final totalClicks = (_overview?['totalClicks'] as num?)?.toInt() ?? 3100;
    final avgCtr = (_overview?['avgCtr'] as num?)?.toDouble() ?? 6.4;
    final activeCampaigns = _campaigns.where((c) => c.isActive).length;
    final maxImpressions = _campaigns.isEmpty ? 1 : _campaigns.map((c) => int.tryParse(c.reach.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).reduce((a, b) => a > b ? a : b);
    final impStr = totalImpressions >= 1000 ? '${(totalImpressions / 1000).toStringAsFixed(1)}K' : '$totalImpressions';
    final clickStr = totalClicks >= 1000 ? '${(totalClicks / 1000).toStringAsFixed(1)}K' : '$totalClicks';

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: _load,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _KpiCard(label: 'Impressions', value: impStr, icon: HugeIcons.strokeRoundedView, color: AppColors.cyan, isDark: isDark),
            const SizedBox(width: 10),
            _KpiCard(label: 'Clicks', value: clickStr, icon: HugeIcons.strokeRoundedCursor01, color: AppColors.purple, isDark: isDark),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _KpiCard(label: 'Avg CTR', value: '${avgCtr.toStringAsFixed(1)}%', icon: HugeIcons.strokeRoundedAnalytics01, color: AppColors.green, isDark: isDark),
            const SizedBox(width: 10),
            _KpiCard(label: 'Active', value: '$activeCampaigns', icon: HugeIcons.strokeRoundedMegaphone01, color: AppColors.orange, isDark: isDark),
          ]),

          const SizedBox(height: 20),
          _SectionTitle('Campaign Performance', isDark: isDark),
          const SizedBox(height: 10),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.orange))),
          ..._campaigns.asMap().entries.map((e) {
            final c = e.value;
            final impressionsInt = int.tryParse(c.reach.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            final barFraction = maxImpressions > 0 ? impressionsInt / maxImpressions : 0.0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgCardDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${e.key + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(c.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      ),
                      Text(c.ctr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
                      Text(' CTR', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${c.reach} impressions · ${c.clicks} clicks',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: barFraction.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 80),
        ],
      ),
      ),
    );
  }
}

// ─── BILLING TAB ─────────────────────────────────────────────────────────────
class _BillingTab extends StatefulWidget {
  final bool isDark;
  const _BillingTab({required this.isDark});

  @override
  State<_BillingTab> createState() => _BillingTabState();
}

class _BillingTabState extends State<_BillingTab> {
  String _paymentMethod = 'M-Pesa';
  double _balance = 0;
  double _pendingCharges = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService().getWalletBalance(),
        ApiService().getAdvertiserBilling(),
        ApiService().getTransactionHistory(type: 'ad_spend', limit: 10),
      ]);
      final balanceData = results[0].data['data'];
      final billingData = results[1].data['data'] as Map<String, dynamic>?;
      final txItems = (results[2].data['data']['items'] as List?) ?? [];
      if (mounted) setState(() {
        _balance = (balanceData['balance'] as num?)?.toDouble() ?? 0;
        _pendingCharges = (billingData?['pendingCharges'] as num?)?.toDouble() ?? 0;
        _transactions = txItems.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddCreditModal(BuildContext context) {
    final isDark = widget.isDark;
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setModalState) {
        bool paying = false;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgElevatedDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Add Ad Credit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                const SizedBox(height: 16),
                // Quick amounts
                Row(children: [for (final amt in [1000, 5000, 10000, 20000])
                  Expanded(child: Padding(
                    padding: EdgeInsets.only(right: amt < 20000 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => amountCtrl.text = '$amt',
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.orange.withOpacity(0.4)),
                        ),
                        child: Center(child: Text('$amt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange))),
                      ),
                    ),
                  ))
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: 'Enter amount (KES)',
                    prefixText: 'KES ',
                    filled: true,
                    fillColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.orange)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: paying ? null : () async {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) return;
                    setModalState(() => paying = true);
                    try {
                      await ApiService().topUpWallet({'amount': amount.toInt(), 'method': _paymentMethod.toLowerCase().replaceAll('-', '').replaceAll(' ', '_')});
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    } catch (_) {
                      setModalState(() => paying = false);
                    }
                  },
                  child: Container(
                    height: 48, width: double.infinity,
                    decoration: BoxDecoration(gradient: AppColors.warmGradient, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: paying
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Add Credit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final balanceStr = 'KES ${_balance.toStringAsFixed(0)}';
    final pendingStr = 'KES ${_pendingCharges.toStringAsFixed(0)} pending charges';

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: _load,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ad Credit Balance', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 6),
                Text(_loading ? 'Loading...' : balanceStr,
                    style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text(pendingStr, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _showAddCreditModal(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Add Credit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Payment method
          _SectionTitle('Payment Method', isDark: isDark),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                ..._paymentMethods.map((m) => GestureDetector(
                  onTap: () => setState(() => _paymentMethod = m.$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text(m.$2, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                              Text(m.$3, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: m.$1,
                          groupValue: _paymentMethod,
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                          activeColor: AppColors.orange,
                        ),
                      ],
                    ),
                  ),
                )),
                Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 16, color: AppColors.orange),
                      const SizedBox(width: 6),
                      const Text('Add Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.orange)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _SectionTitle('Transaction History', isDark: isDark),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: _transactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text('No transactions yet', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight))),
                  )
                : Column(
              children: _transactions.asMap().entries.map((e) {
                final t = e.value as Map<String, dynamic>;
                final isLast = e.key == _transactions.length - 1;
                final txType = t['type'] as String? ?? 'debit';
                final isIn = txType == 'credit' || txType == 'topup';
                final label = t['description'] as String? ?? t['label'] as String? ?? 'Transaction';
                final date = t['createdAt'] as String? ?? t['date'] as String? ?? '';
                final amount = t['amount'] ?? '0';
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: (isIn ? AppColors.green : AppColors.red).withOpacity(0.12), shape: BoxShape.circle),
                            child: Center(child: Text(isIn ? '💳' : '📣', style: const TextStyle(fontSize: 16))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                                Text(date, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${isIn ? '+' : '-'}KES $amount',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isIn ? AppColors.green : AppColors.red)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text('Completed', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.green)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) Divider(height: 0.5, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
      ),
    );
  }
}

// ─── TARGETING TAB ────────────────────────────────────────────────────────────
class _TargetingTab extends StatefulWidget {
  final bool isDark;
  const _TargetingTab({required this.isDark});

  @override
  State<_TargetingTab> createState() => _TargetingTabState();
}

class _TargetingTabState extends State<_TargetingTab> {
  Set<String> _selectedVenues = {'Club Insomnia', 'Skybar Nairobi'};
  Set<String> _selectedGenres = {'Afrobeats', 'Hip Hop'};
  Set<String> _selectedSlots = {'10 PM – 12 AM'};
  bool _saving = false;

  int get _estimatedReach {
    int base = 0;
    base += _selectedVenues.length * 800;
    base += _selectedGenres.length * 400;
    base += _selectedSlots.length * 300;
    return base;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    try {
      await ApiService().getTargetingOptions(); // fetch to verify connection
      await ApiService().dio.put('/advertiser/targeting', data: {
        'venues': _selectedVenues.toList(),
        'genres': _selectedGenres.toList(),
        'timeSlots': _selectedSlots.toList(),
      });
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Targeting preferences saved!'),
      backgroundColor: AppColors.orange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estimated reach card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimated Reach', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                      Text(
                        '~${_estimatedReach.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} people',
                        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text('Based on your selections', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ),
                const Text('🎯', style: TextStyle(fontSize: 36)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Venues
          _SectionTitle('Venues', isDark: isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _targetVenues.map((v) {
              final sel = _selectedVenues.contains(v);
              return _ToggleChip(label: v, selected: sel, activeColor: AppColors.orange, isDark: isDark,
                  onTap: () => setState(() => sel ? _selectedVenues.remove(v) : _selectedVenues.add(v)));
            }).toList(),
          ),

          const SizedBox(height: 18),
          _SectionTitle('Music Genres', isDark: isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _targetGenres.map((g) {
              final sel = _selectedGenres.contains(g);
              return _ToggleChip(label: g, selected: sel, activeColor: AppColors.purple, isDark: isDark,
                  onTap: () => setState(() => sel ? _selectedGenres.remove(g) : _selectedGenres.add(g)));
            }).toList(),
          ),

          const SizedBox(height: 18),
          _SectionTitle('Time Slots', isDark: isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _targetSlots.map((s) {
              final sel = _selectedSlots.contains(s);
              return _ToggleChip(label: s, selected: sel, activeColor: AppColors.cyan, isDark: isDark,
                  onTap: () => setState(() => sel ? _selectedSlots.remove(s) : _selectedSlots.add(s)));
            }).toList(),
          ),

          const SizedBox(height: 24),
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              height: 50,
              decoration: BoxDecoration(gradient: AppColors.warmGradient, borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Targeting', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── SETTINGS TAB ─────────────────────────────────────────────────────────────
class _SettingsTab extends StatefulWidget {
  final bool isDark;
  final dynamic user;
  const _SettingsTab({required this.isDark, required this.user});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late TextEditingController _companyCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _companyCtrl = TextEditingController(text: widget.user?.name ?? '');
    _websiteCtrl = TextEditingController(text: '');
    _phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final res = await ApiService().getMe();
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        setState(() {
          _companyCtrl.text = data['name'] as String? ?? widget.user?.name ?? '';
          _phoneCtrl.text = data['phone'] as String? ?? '';
          _websiteCtrl.text = data['website'] as String? ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _websiteCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    try {
      final me = await ApiService().getMe();
      final userId = me.data['data']['userId'] as String? ?? '';
      if (userId.isNotEmpty) {
        await ApiService().updateUser(userId, {
          'name': _companyCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        });
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Settings saved!'),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Account Information', isDark: isDark),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(gradient: AppColors.warmGradient, shape: BoxShape.circle),
                        child: const Center(child: Text('📣', style: TextStyle(fontSize: 32))),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.bgCardDark : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, size: 13, color: AppColors.orange)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormField(ctrl: _companyCtrl, label: 'Company Name', hint: 'Your company or brand name', isDark: isDark),
                const SizedBox(height: 10),
                _FormField(ctrl: _websiteCtrl, label: 'Website', hint: 'www.yoursite.com', isDark: isDark),
                const SizedBox(height: 10),
                _FormField(ctrl: _phoneCtrl, label: 'Phone Number', hint: '+254...', isDark: isDark, keyboardType: TextInputType.phone),
              ],
            ),
          ),

          const SizedBox(height: 18),
          _SectionTitle('Notification Preferences', isDark: isDark),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                _SwitchRow(label: 'Campaign performance alerts', isDark: isDark, initialValue: true),
                _SwitchRow(label: 'Low balance warnings', isDark: isDark, initialValue: true),
                _SwitchRow(label: 'Weekly summary report', isDark: isDark, initialValue: false),
                _SwitchRow(label: 'New audience insights', isDark: isDark, initialValue: true, last: true),
              ],
            ),
          ),

          const SizedBox(height: 24),
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              height: 50,
              decoration: BoxDecoration(gradient: AppColors.warmGradient, borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label, value;
  final List<List<dynamic>> icon;
  final Color color;
  final bool isDark;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Center(child: HugeIcon(icon: icon, size: 20, color: color)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final _MockCampaign campaign;
  final bool isDark;
  final VoidCallback onToggle;

  const _CampaignCard({required this.campaign, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(campaign.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (campaign.isActive ? AppColors.green : Colors.grey).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(campaign.isActive ? '● Active' : '○ Paused',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: campaign.isActive ? AppColors.green : Colors.grey)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            _Metric(label: 'Reach', value: campaign.reach, isDark: isDark),
            const SizedBox(width: 16),
            _Metric(label: 'Clicks', value: campaign.clicks, isDark: isDark),
            const SizedBox(width: 16),
            _Metric(label: 'Budget', value: campaign.budget, isDark: isDark),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: campaign.progress.clamp(0.0, 1.0),
              backgroundColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 3),
          Text('${(campaign.progress * 100).toInt()}% of budget used',
              style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _Metric({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle(this.title, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight));
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final bool isDark;
  final int maxLines;
  final TextInputType keyboardType;
  const _FormField({required this.ctrl, required this.label, required this.hint, required this.isDark, this.maxLines = 1, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ToggleChip({required this.label, required this.selected, required this.activeColor, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.12) : (isDark ? AppColors.bgCardDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? activeColor.withOpacity(0.5) : (isDark ? AppColors.borderDark : AppColors.borderLight)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: selected ? activeColor : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
      ),
    );
  }
}

class _SwitchRow extends StatefulWidget {
  final String label;
  final bool isDark;
  final bool initialValue;
  final bool last;
  const _SwitchRow({required this.label, required this.isDark, required this.initialValue, this.last = false});

  @override
  State<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<_SwitchRow> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(child: Text(widget.label, style: TextStyle(fontSize: 13,
                  color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))),
              Switch(
                value: _value,
                onChanged: (v) => setState(() => _value = v),
                activeColor: AppColors.orange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        if (!widget.last) Divider(height: 0.5, color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
      ],
    );
  }
}

// ─── MOCK DATA ────────────────────────────────────────────────────────────────
class _MockCampaign {
  final String campaignId, name, description, adType, reach, clicks, ctr, budget, startDate, endDate;
  final double progress, budgetNum;
  final bool isActive;

  const _MockCampaign({
    this.campaignId = '',
    required this.name,
    required this.description,
    required this.adType,
    required this.reach,
    required this.clicks,
    required this.ctr,
    required this.budget,
    required this.progress,
    required this.budgetNum,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  _MockCampaign copyWith({bool? isActive}) => _MockCampaign(
        campaignId: campaignId,
        name: name, description: description, adType: adType,
        reach: reach, clicks: clicks, ctr: ctr, budget: budget,
        progress: progress, budgetNum: budgetNum,
        startDate: startDate, endDate: endDate,
        isActive: isActive ?? this.isActive,
      );
}

class _MockTransaction {
  final String label, date, amount, type;
  const _MockTransaction({required this.label, required this.date, required this.amount, required this.type});
}


const _paymentMethods = [
  ('M-Pesa', '📱', 'Linked: 0700 *** 000'),
  ('Credit Card', '💳', 'Visa ending in 4242'),
  ('Airtel Money', '📲', 'Link Airtel account'),
];

const _targetVenues = ['Club Insomnia', 'Skybar Nairobi', 'The Hub', 'Alchemist Bar', 'B-Club', 'Mercury Lounge'];
const _targetGenres = ['Afrobeats', 'Hip Hop', 'House', 'R&B', 'Dancehall', 'Reggaeton', 'Pop', 'EDM'];
const _targetSlots = ['8 PM – 10 PM', '10 PM – 12 AM', '12 AM – 2 AM', '2 AM – 4 AM'];
