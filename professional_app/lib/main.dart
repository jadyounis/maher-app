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
  runApp(const ProApp());
}

class ProApp extends StatelessWidget {
  const ProApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MAHER | الصنايعي',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: orange, scaffoldBackgroundColor: bg, fontFamily: 'Arial'),
        home: AppConfig.isConfigured ? const ProAuthGate() : const SetupPage(),
      );
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.cloud_off_rounded, size: 64),
            SizedBox(height: 18),
            Text('MAHER | الصنايعي', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            SizedBox(height: 10),
            Text('نسخة الإنتاج تحتاج قيم Supabase أثناء البناء.', textAlign: TextAlign.center),
          ]))),
        ),
      );
}

class ProAuthGate extends StatefulWidget {
  const ProAuthGate({super.key});
  @override
  State<ProAuthGate> createState() => _ProAuthGateState();
}

class _ProAuthGateState extends State<ProAuthGate> {
  bool loading = true;
  bool valid = false;
  String? error;

  @override
  void initState() { super.initState(); _check(); }

  Future<void> _check() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) { if (mounted) setState(() => loading = false); return; }
    try {
      final row = await client.from('profiles').select('role,full_name').eq('id', session.user.id).maybeSingle();
      valid = row?['role'] == 'professional';
      if (!valid) await client.auth.signOut();
    } catch (e) { error = e.toString(); }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (valid) return const ProHome();
    return ProLogin(onLoggedIn: _check, error: error);
  }
}

class ProLogin extends StatefulWidget {
  const ProLogin({super.key, required this.onLoggedIn, this.error});
  final Future<void> Function() onLoggedIn;
  final String? error;
  @override
  State<ProLogin> createState() => _ProLoginState();
}

class _ProLoginState extends State<ProLogin> {
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
    } catch (e) { if (mounted) setState(() { busy = false; message = e.toString(); }); }
  }

  Future<void> verify() async {
    setState(() { busy = true; message = null; });
    try {
      final res = await Supabase.instance.client.auth.verifyOTP(type: OtpType.sms, token: otp.text.trim(), phone: _phone());
      if (res.session == null) throw Exception('لم يتم تسجيل الدخول.');
      await widget.onLoggedIn();
      if (mounted) setState(() => busy = false);
    } catch (e) { if (mounted) setState(() { busy = false; message = e.toString(); }); }
  }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('MAHER', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('دخول الصنايعي', style: TextStyle(fontSize: 18)),
      const SizedBox(height: 34),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الموبايل', hintText: '07xxxxxxxx', border: OutlineInputBorder())),
      if (sent) ...[const SizedBox(height: 14), TextField(controller: otp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رمز التحقق', border: OutlineInputBorder()))],
      const SizedBox(height: 18),
      FilledButton(onPressed: busy ? null : (sent ? verify : sendOtp), child: Text(busy ? 'جاري...' : sent ? 'تأكيد الدخول' : 'إرسال رمز التحقق')),
      if (sent) TextButton(onPressed: busy ? null : sendOtp, child: const Text('إعادة إرسال الرمز')),
      const SizedBox(height: 10),
      const Text('حساب الصنايعي يجب أن يكون مفعّلاً من الإدارة قبل استقبال الطلبات.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
      if (message != null || widget.error != null) ...[const SizedBox(height: 12), Text(message ?? widget.error!, style: const TextStyle(fontSize: 12))],
    ]))))),
  ));
}

class ProHome extends StatefulWidget {
  const ProHome({super.key});
  @override
  State<ProHome> createState() => _ProHomeState();
}

class _ProHomeState extends State<ProHome> {
  int tab = 0;
  String jobMessage = 'لا يوجد عمل نشط';
  List<Map<String, dynamic>> requests = [];
  Map<String, dynamic>? activeJob;
  RealtimeChannel? channel;

  String modeLabel(String value) => {'hourly': 'بالساعة', 'daily': 'يومي', 'contract': 'مقاولة'}[value] ?? value;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final client = Supabase.instance.client;
    try {
      final rows = await client.from('requests').select('id,title,description,address_text,pricing_mode,status,scheduled_at').inFilter('status', ['published', 'offers_received']).order('created_at', ascending: false);
      final jobs = await client.from('jobs').select('id,request_id,customer_id,agreed_amount,pricing_mode,arrived_at,started_at,completed_at,requests(title,address_text,status)').eq('professional_id', client.auth.currentUser!.id).order('created_at', ascending: false).limit(1);
      requests = List<Map<String, dynamic>>.from(rows);
      activeJob = jobs.isEmpty ? null : Map<String, dynamic>.from(jobs.first);
      jobMessage = activeJob == null ? 'لا يوجد عمل نشط' : 'عمل فعلي مرتبط بطلب ${activeJob!['request_id']}';
    } catch (e) { jobMessage = e.toString(); }
    _subscribe();
    if (mounted) setState(() {});
  }

  void _subscribe() {
    channel?.unsubscribe();
    channel = Supabase.instance.client.channel('professional-feed')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'requests', callback: (_) => _load())
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'jobs', callback: (_) => _load())
      .subscribe();
  }

  Future<void> requestDetails(Map<String, dynamic> r) async {
    final price = TextEditingController();
    final note = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Directionality(textDirection: TextDirection.rtl, child: Padding(padding: EdgeInsets.fromLTRB(20,20,20,20+MediaQuery.of(context).viewInsets.bottom), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(r['title'] ?? 'طلب خدمة', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('${modeLabel(r['pricing_mode'] ?? '')} • ${r['address_text'] ?? 'الموقع يحدد لاحقاً'}'),
        const SizedBox(height: 14),
        Text(r['description'] ?? 'بدون وصف إضافي.'),
        const SizedBox(height: 18),
        TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعرك بالدينار', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظة للعميل (اختياري)', border: OutlineInputBorder())),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
          final value = double.tryParse(price.text.trim());
          if (value == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب سعراً صحيحاً.'))); return; }
          try {
            await Supabase.instance.client.rpc('submit_offer', params: {'p_request_id': r['id'], 'p_price': value, 'p_estimated_duration_minutes': null, 'p_note': note.text.trim().isEmpty ? null : note.text.trim()});
            if (context.mounted) Navigator.pop(context, true);
          } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }, child: const Text('إرسال العرض'))),
        const SizedBox(height: 20),
      ]))),
    );
    price.dispose(); note.dispose();
    if (sent == true) { await _load(); }
  }

  Future<void> setJobStatus(String status) async {
    if (activeJob == null) return;
    try {
      await Supabase.instance.client.rpc('update_job_status', params: {'p_job_id': activeJob!['id'], 'p_status': status, 'p_note': null});
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget dashboard() => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(24)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('طلبات جديدة', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('اختار الطلب المناسب، أرسل سعرك، وبعد قبول العرض ينتقل لشغلك تلقائياً.', style: TextStyle(color: Colors.white70, height: 1.5))])),
    const SizedBox(height: 20),
    Text('الطلبات المتاحة (${requests.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    if (requests.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('ما في طلبات متاحة حالياً.'))),
    ...requests.map((r) => Card(child: ListTile(isThreeLine: true, leading: const CircleAvatar(child: Icon(Icons.build)), title: Text(r['title'] ?? 'طلب', style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${modeLabel(r['pricing_mode'] ?? '')}\n${r['address_text'] ?? 'الموقع يحدد لاحقاً'}'), trailing: const Icon(Icons.chevron_left), onTap: () => requestDetails(r)))),
  ]);

  Widget active() => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('شغلي', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
    const SizedBox(height: 14),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: activeJob == null ? const Text('لسه ما عندك شغل مقبول.') : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(activeJob!['requests']?['title'] ?? 'عمل نشط', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('${activeJob!['agreed_amount']} د.أ • ${modeLabel(activeJob!['pricing_mode'] ?? '')}'),
      const SizedBox(height: 6),
      Text(activeJob!['requests']?['address_text'] ?? 'الموقع يحدد لاحقاً'),
      const Divider(height: 28),
      Text(jobMessage, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(onPressed: () => setJobStatus('en_route'), icon: const Icon(Icons.navigation), label: const Text('بالطريق')),
        FilledButton.icon(onPressed: () => setJobStatus('arrived'), icon: const Icon(Icons.location_on), label: const Text('وصلت')),
        FilledButton.icon(onPressed: () => setJobStatus('in_progress'), icon: const Icon(Icons.play_arrow), label: const Text('بدأت الشغل')),
        OutlinedButton.icon(onPressed: () => setJobStatus('completed'), icon: const Icon(Icons.check), label: const Text('إنهاء العمل')),
      ]),
    ]))),
  ]);

  Future<Map<String, dynamic>> _myProfile() async {
    final client = Supabase.instance.client;
    final p = await client.from('profiles').select('full_name,phone,city').eq('id', client.auth.currentUser!.id).single();
    final pp = await client.from('professional_profiles').select('skills,service_areas,verification_status,rating,completed_jobs,is_available').eq('user_id', client.auth.currentUser!.id).maybeSingle();
    return {...Map<String, dynamic>.from(p), ...?pp};
  }

  Widget profile() => FutureBuilder<Map<String, dynamic>>(future: _myProfile(), builder: (context, snap) {
    final p = snap.data ?? {};
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Text('حساب الصنايعي', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(p['full_name'] ?? 'صنايعي'), subtitle: Text('${p['phone'] ?? ''} • ${p['city'] ?? 'عمّان'}'))),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.verified_outlined), title: Text('الحالة: ${p['verification_status'] ?? 'pending'}')),
        ListTile(leading: const Icon(Icons.star), title: Text('التقييم: ${p['rating'] ?? 0}')),
        ListTile(leading: const Icon(Icons.task_alt), title: Text('طلبات مكتملة: ${p['completed_jobs'] ?? 0}')),
        ListTile(leading: const Icon(Icons.location_on_outlined), title: Text('مناطق العمل: ${(p['service_areas'] as List?)?.join('، ') ?? 'عمّان'}')),
      ])),
      const SizedBox(height: 8),
      Card(child: ListTile(leading: const Icon(Icons.logout), title: const Text('تسجيل الخروج'), onTap: () async { await Supabase.instance.client.auth.signOut(); if (mounted) setState(() {}); })),
    ];
  });

  @override
  void dispose() { channel?.unsubscribe(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(
    appBar: AppBar(title: const Text('MAHER | الصنايعي', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: tab == 0 ? dashboard() : tab == 1 ? active() : profile(),
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'الطلبات'),
      NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'شغلي'),
      NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
    ]),
  ));
}
