import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

const navy = Color(0xFF111827);
const orange = Color(0xFFF97316);
const bg = Color(0xFFF8FAFC);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MAHER | العميل',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: orange,
          scaffoldBackgroundColor: bg,
          fontFamily: 'Arial',
        ),
        home: AppConfig.isConfigured ? const CustomerAuthGate() : const SetupPage(),
      );
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.cloud_off_rounded, size: 64),
                SizedBox(height: 18),
                Text('MAHER جاهز للبناء', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                SizedBox(height: 10),
                Text('نسخة الإنتاج تحتاج قيم SUPABASE_URL و SUPABASE_PUBLISHABLE_KEY أثناء البناء.', textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      );
}

class CustomerAuthGate extends StatefulWidget {
  const CustomerAuthGate({super.key});
  @override
  State<CustomerAuthGate> createState() => _CustomerAuthGateState();
}

class _CustomerAuthGateState extends State<CustomerAuthGate> {
  bool loading = true;
  bool valid = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final row = await client.from('profiles').select('role, full_name').eq('id', session.user.id).maybeSingle();
      valid = row?['role'] == 'customer';
      if (!valid) await client.auth.signOut();
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (valid) return const CustomerHome();
    return CustomerLogin(onLoggedIn: _check, error: error);
  }
}

class CustomerLogin extends StatefulWidget {
  const CustomerLogin({super.key, required this.onLoggedIn, this.error});
  final Future<void> Function() onLoggedIn;
  final String? error;
  @override
  State<CustomerLogin> createState() => _CustomerLoginState();
}

class _CustomerLoginState extends State<CustomerLogin> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  bool sent = false;
  bool busy = false;
  String? message;

  String _phone() {
    var value = phone.text.trim().replaceAll(' ', '');
    if (value.startsWith('00')) value = '+${value.substring(2)}';
    if (value.startsWith('07')) value = '+962${value.substring(1)}';
    if (!value.startsWith('+')) value = '+$value';
    return value;
  }

  Future<void> sendOtp() async {
    setState(() { busy = true; message = null; });
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: _phone());
      if (mounted) setState(() { sent = true; busy = false; });
    } catch (e) {
      if (mounted) setState(() { busy = false; message = e.toString(); });
    }
  }

  Future<void> verify() async {
    setState(() { busy = true; message = null; });
    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.sms,
        token: otp.text.trim(),
        phone: _phone(),
      );
      if (res.session == null) throw Exception('لم يتم تسجيل الدخول.');
      await widget.onLoggedIn();
      if (mounted) setState(() => busy = false);
    } catch (e) {
      if (mounted) setState(() { busy = false; message = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('MAHER', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('كل خدمة. الشخص المناسب.', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 34),
                    TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الموبايل', hintText: '07xxxxxxxx', border: OutlineInputBorder())),
                    if (sent) ...[
                      const SizedBox(height: 14),
                      TextField(controller: otp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رمز التحقق', border: OutlineInputBorder())),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: busy ? null : (sent ? verify : sendOtp),
                      child: Text(busy ? 'جاري...' : sent ? 'تأكيد الدخول' : 'إرسال رمز التحقق'),
                    ),
                    if (sent)
                      TextButton(onPressed: busy ? null : sendOtp, child: const Text('إعادة إرسال الرمز')),
                    if (message != null || widget.error != null) ...[
                      const SizedBox(height: 12),
                      Text(message ?? widget.error!, style: const TextStyle(fontSize: 12)),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int tab = 0;
  String service = 'سباكة';
  String type = 'بالساعة';
  String status = 'لا يوجد طلب';
  String? requestId;
  final desc = TextEditingController();
  List<Map<String, dynamic>> categories = [];
  RealtimeChannel? requestChannel;

  final fallbackServices = const [
    'سباكة', 'كهرباء', 'تكييف وتبريد', 'دهان', 'نجارة', 'تنظيف',
    'نقل وتركيب', 'تقنية', 'صيانة عامة', 'ألمنيوم وزجاج', 'خدمات سيارات', 'تصميم وتصوير',
  ];

  final modeMap = const {'بالساعة': 'hourly', 'يومي': 'daily', 'مقاولة': 'contract'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = Supabase.instance.client;
    try {
      categories = List<Map<String, dynamic>>.from(await client.from('service_categories').select('id,name_ar').eq('is_active', true).order('sort_order'));
      final rows = await client.from('requests').select('id,title,pricing_mode,status,category_id').order('created_at', ascending: false).limit(1);
      if (rows.isNotEmpty) {
        final r = Map<String, dynamic>.from(rows.first);
        requestId = r['id'];
        final cat = categories.where((c) => c['id'] == r['category_id']).toList();
        service = cat.isEmpty ? (r['title'] as String? ?? service) : cat.first['name_ar'] as String;
        type = {'hourly': 'بالساعة', 'daily': 'يومي', 'contract': 'مقاولة'}[r['pricing_mode']] ?? type;
        status = _statusText(r['status']);
        _subscribe(requestId!);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  String _statusText(String? value) => {
        'published': 'بانتظار عروض الصنايعية',
        'offers_received': 'وصلت عروض جديدة',
        'professional_selected': 'تم اختيار الصنايعي — بانتظار الوصول',
        'scheduled': 'تم تحديد الموعد',
        'en_route': 'الصنايعي بالطريق',
        'arrived': 'الصنايعي وصل',
        'in_progress': 'العمل قيد التنفيذ',
        'completed': 'تم إنهاء العمل',
        'paid': 'تم الدفع',
        'reviewed': 'تم التقييم',
        'cancelled': 'تم إلغاء الطلب',
      }[value] ?? 'لا يوجد طلب';

  void _subscribe(String id) {
    requestChannel?.unsubscribe();
    final client = Supabase.instance.client;
    requestChannel = client
        .channel('customer-request-$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'requests',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: id),
          callback: (_) => _load(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'offers',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'request_id', value: id),
          callback: (_) => _load(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  Future<void> createRequest() async {
    String draftService = service;
    String draftType = type;
    desc.clear();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('طلب خدمة جديد', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: draftService,
                  decoration: const InputDecoration(labelText: 'نوع الخدمة', border: OutlineInputBorder()),
                  items: fallbackServices.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) { if (v != null) setSheet(() => draftService = v); },
                ),
                const SizedBox(height: 14),
                const Text('طريقة التسعير', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: ['بالساعة', 'يومي', 'مقاولة'].map((v) => ChoiceChip(label: Text(v), selected: draftType == v, onSelected: (_) => setSheet(() => draftType = v))).toList()),
                const SizedBox(height: 14),
                TextField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText: 'وصف الطلب', hintText: 'مثلاً: بدي تصليح تسريب تحت المغسلة...', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.location_on_outlined), title: Text('الموقع'), subtitle: Text('سيتم ربط الخريطة في مرحلة الخرائط')),
                const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.schedule_outlined), title: Text('الموعد'), subtitle: Text('سيتم ربط اختيار الموعد في المرحلة التالية')),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
                  service = draftService; type = draftType;
                  final selected = categories.where((c) => c['name_ar'] == service).toList();
                  if (selected.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الخدمة غير متاحة حالياً'))); return; }
                  try {
                    final result = await Supabase.instance.client.rpc('create_request', params: {
                      'p_category_id': selected.first['id'],
                      'p_pricing_mode': modeMap[type],
                      'p_title': service,
                      'p_description': desc.text.trim().isEmpty ? null : desc.text.trim(),
                    });
                    requestId = result as String;
                    status = 'بانتظار عروض الصنايعية';
                    _subscribe(requestId!);
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }, child: const Text('نشر الطلب'))),
              ]),
            ),
          ),
        ),
      ),
    );
    if (ok == true && mounted) setState(() {});
  }

  Future<void> showOffers() async {
    if (requestId == null) return;
    final client = Supabase.instance.client;
    final rawOffers = await client.from('offers').select('id,professional_id,price,estimated_duration_minutes,note,status').eq('request_id', requestId!).order('created_at');
    final offers = List<Map<String, dynamic>>.from(rawOffers);
    final proIds = offers.map((o) => o['professional_id']).whereType<String>().toSet().toList();
    final profiles = proIds.isEmpty ? <Map<String, dynamic>>[] : List<Map<String, dynamic>>.from(await client.from('professional_directory').select('id,full_name,rating,completed_jobs,verification_status').inFilter('id', proIds));
    final byId = {for (final p in profiles) p['id']: p};

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(18), children: [
            const Text('العروض المستلمة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('قارن السعر والتقييم والخبرة قبل الاختيار.'),
            const SizedBox(height: 12),
            if (offers.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('لسه ما وصل أي عرض.'))),
            ...offers.map((o) {
              final p = byId[o['professional_id']];
              final name = (p?['full_name'] as String?)?.isNotEmpty == true ? p!['full_name'] as String : 'صنايعي موثّق';
              return Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
                ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('★ ${(p?['rating'] ?? 0)}  •  ${p?['completed_jobs'] ?? 0} طلب مكتمل\n${p?['verification_status'] == 'verified' ? 'محترف موثّق' : 'قيد التحقق'}')),
                Row(children: [Expanded(child: Text('${o['price']} د.أ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                  FilledButton(onPressed: o['status'] == 'pending' ? () async {
                    try {
                      final jobId = await client.rpc('accept_offer', params: {'p_offer_id': o['id']});
                      requestId = requestId;
                      status = 'تم اختيار $name — بانتظار الوصول';
                      if (context.mounted) Navigator.pop(context);
                      if (mounted) setState(() {});
                      _subscribe(requestId!);
                      debugPrint('Created job $jobId');
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  } : null, child: const Text('اختيار')),
                ])
              ])));
            }),
          ]),
        ),
      ),
    );
  }

  Widget home() => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(24)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('شو بدك يتصلّح؟', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('اطلب صنايعي قريب منك، قارن العروض واختار الشخص المناسب.', style: TextStyle(color: Colors.white70, height: 1.5))])),
    const SizedBox(height: 22),
    const Text('الخدمات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    const SizedBox(height: 12),
    GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: fallbackServices.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.05), itemBuilder: (_, i) => Card(child: InkWell(onTap: () { setState(() => service = fallbackServices[i]); createRequest(); }, borderRadius: BorderRadius.circular(14), child: Center(child: Padding(padding: const EdgeInsets.all(6), child: Text(fallbackServices[i], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))))))),
    const SizedBox(height: 18),
    if (status != 'لا يوجد طلب') Card(child: ListTile(title: const Text('طلبك الحالي', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('$service • $type\n$status'), isThreeLine: true, trailing: status.contains('عروض') || status.contains('بانتظار') ? TextButton(onPressed: showOffers, child: const Text('العروض')) : const Icon(Icons.chevron_left))),
    const SizedBox(height: 24),
    const Text('ليش MAHER؟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    const Card(child: ListTile(leading: Icon(Icons.verified_user_outlined), title: Text('صنايعية موثوقين'), subtitle: Text('تقييمات وأعمال سابقة وملف مهني واضح'))),
    const Card(child: ListTile(leading: Icon(Icons.compare_arrows_outlined), title: Text('قارن قبل ما تختار'), subtitle: Text('السعر + التقييم + الخبرة + معرض الأعمال'))),
    const Card(child: ListTile(leading: Icon(Icons.support_agent_outlined), title: Text('دعم ومتابعة'), subtitle: Text('الطلب له حالة وسجل واضح من البداية للنهاية'))),
  ]);

  Widget requests() => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('طلباتي', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
    const SizedBox(height: 14),
    Card(child: ListTile(leading: const Icon(Icons.receipt_long), title: Text(status == 'لا يوجد طلب' ? 'لا توجد طلبات' : '$service — $type'), subtitle: Text(status), onTap: requestId != null ? showOffers : null)),
  ]);

  Widget profile() => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('حسابي', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
    const SizedBox(height: 14),
    Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(Supabase.instance.client.auth.currentUser?.phone ?? 'حساب العميل'), subtitle: const Text('رقم الهاتف موثّق'))),
    const SizedBox(height: 8),
    Card(child: Column(children: [
      ListTile(leading: const Icon(Icons.payment_outlined), title: const Text('طرق الدفع'), onTap: () {}),
      ListTile(leading: const Icon(Icons.support_agent_outlined), title: const Text('الدعم والمساعدة'), onTap: () {}),
      ListTile(leading: const Icon(Icons.report_problem_outlined), title: const Text('بلاغ أو شكوى'), onTap: () {}),
      ListTile(leading: const Icon(Icons.logout), title: const Text('تسجيل الخروج'), onTap: () async { await Supabase.instance.client.auth.signOut(); if (mounted) setState(() {}); }),
    ])),
  ]);

  @override
  void dispose() {
    desc.dispose();
    requestChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('MAHER', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))]),
    body: tab == 0 ? home() : tab == 1 ? requests() : profile(),
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
      NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'طلباتي'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
    ]),
    floatingActionButton: tab == 0 ? FloatingActionButton.extended(backgroundColor: orange, foregroundColor: Colors.white, onPressed: createRequest, icon: const Icon(Icons.add), label: const Text('اطلب خدمة')) : null,
  ));
}
