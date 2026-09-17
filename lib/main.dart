import 'package:flutter/material.dart';

void main() {
  runApp(const MaherApp());
}

class MaherApp extends StatelessWidget {
  const MaherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MAHER',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFF97316),
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool hasRequest = false;
  bool hasOffers = false;

  final services = const [
    '🔧 سباكة',
    '⚡ كهرباء',
    '❄️ تكييف',
    '🎨 دهان',
    '🪚 نجارة',
    '🧹 تنظيف',
    '🚚 نقل وتركيب',
    '💻 تقنية',
  ];

  void newRequest([String? selectedService]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RequestSheet(
        service: selectedService,
        onDone: () {
          setState(() {
            hasRequest = true;
            hasOffers = false;
          });
        },
      ),
    );
  }

  void showOffers() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        final offers = [
          'محمد العجارمة — 25 د.أ',
          'أحمد الخطيب — 20 د.أ',
          'يزن حداد — 30 د.أ',
        ];

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'العروض المستلمة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              ...offers.map(
                (offer) => Card(
                  child: ListTile(
                    title: Text(offer),
                    subtitle: const Text('✓ محترف موثّق • ★ 4.9'),
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم اختيار المحترف')),
                        );
                      },
                      child: const Text('اختيار'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'MAHER',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        body: tab == 0
            ? home()
            : tab == 1
                ? requests()
                : profile(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) {
            setState(() => tab = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'طلباتي',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
        floatingActionButton: tab == 0
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                onPressed: () => newRequest(),
                icon: const Icon(Icons.add),
                label: const Text('اطلب خدمة'),
              )
            : null,
      ),
    );
  }

  Widget home() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'شو بدك يتصلّح؟',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'اطلب الخدمة وخلي المحترفين القريبين منك يتنافسوا بعروضهم.',
                style: TextStyle(
                  color: Color(0xFFD6DAE2),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'الخدمات',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
          ),
          itemBuilder: (context, index) {
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => newRequest(services[index].substring(2)),
                child: Center(
                  child: Text(
                    services[index],
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            );
          },
        ),
        if (hasRequest) ...[
          const SizedBox(height: 22),
          Card(
            child: ListTile(
              title: const Text(
                'طلبك الحالي',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                hasOffers ? 'وصلتك عروض من محترفين' : 'منشور — بانتظار العروض',
              ),
              trailing: hasOffers
                  ? TextButton(
                      onPressed: showOffers,
                      child: const Text('العروض'),
                    )
                  : TextButton(
                      onPressed: () {
                        setState(() => hasOffers = true);
                      },
                      child: const Text('محاكاة عروض'),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget requests() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'طلباتي',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 15),
        Card(
          child: ListTile(
            title: Text(hasRequest ? 'طلب خدمة' : 'لا توجد طلبات'),
            subtitle: Text(
              hasRequest ? 'قيد المتابعة' : 'ابدأ أول طلب من الرئيسية',
            ),
          ),
        ),
      ],
    );
  }

  Widget profile() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'حسابي',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 15),
        const Card(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('العميل التجريبي'),
            subtitle: Text('عمّان، الأردن'),
          ),
        ),
      ],
    );
  }
}

class RequestSheet extends StatefulWidget {
  final String? service;
  final VoidCallback onDone;

  const RequestSheet({
    super.key,
    this.service,
    required this.onDone,
  });

  @override
  State<RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<RequestSheet> {
  late String service;
  final description = TextEditingController();

  final serviceOptions = const [
    'سباكة',
    'كهرباء',
    'تكييف',
    'دهان',
    'نجارة',
    'تنظيف',
    'نقل وتركيب',
    'تقنية',
  ];

  @override
  void initState() {
    super.initState();
    service = widget.service ?? 'سباكة';
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إنشاء طلب',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: service,
                items: serviceOptions
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => service = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'الخدمة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'وصف المطلوب',
                  hintText: 'اكتب شو المشكلة أو الخدمة المطلوبة...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDone();
                  },
                  child: const Text('نشر الطلب'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
