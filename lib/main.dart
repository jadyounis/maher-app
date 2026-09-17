import 'package:flutter/material.dart';

void main() => runApp(const MaherApp());

class MaherApp extends StatelessWidget {
  const MaherApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'MAHER',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFF97316), fontFamily: 'Arial'),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool request = false;
  bool offers = false;
  final services = const ['🔧 سباكة','⚡ كهرباء','❄️ تكييف','🎨 دهان','🪚 نجارة','🧹 تنظيف','🚚 نقل وتركيب','💻 تقنية'];
  void newRequest([String? service]) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => RequestSheet(service: service, onDone: () => setState(() => request = true)));
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MAHER', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_none))]),
    body: tab == 0 ? home() : tab == 1 ? requests() : profile(),
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v)=>setState(()=>tab=v), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label:'الرئيسية'),NavigationDestination(icon: Icon(Icons.assignment_outlined), label:'طلباتي'),NavigationDestination(icon: Icon(Icons.person_outline), label:'حسابي')]),
    floatingActionButton: tab == 0 ? FloatingActionButton.extended(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white, onPressed: ()=>newRequest(), icon: const Icon(Icons.add), label: const Text('اطلب خدمة')) : null,
  );
  Widget home() => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(24)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('شو بدك يتصلّح؟', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)), SizedBox(height:8), Text('اطلب الخدمة وخلي المحترفين القريبين منك يتنافسوا بعروضهم.', style: TextStyle(color: Color(0xFFD6DAE2), height:1.5))])),
    const SizedBox(height:24), const Text('الخدمات', style: TextStyle(fontSize:19,fontWeight:FontWeight.w900)), const SizedBox(height:12),
    GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:services.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.7),itemBuilder:(c,i)=>Card(child:InkWell(onTap:()=>newRequest(services[i].substring(2)),child:Center(child:Text(services[i],style:const TextStyle(fontWeight:FontWeight.w800))))))),
    const SizedBox(height:22), if(request) Card(child:ListTile(title:const Text('طلبك الحالي',style:TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(offers?'وصلتك عروض من محترفين':'منشور — بانتظار العروض'),trailing:offers?TextButton(onPressed:()=>showOffers(),child:const Text('العروض')):TextButton(onPressed:()=>setState(()=>offers=true),child:const Text('محاكاة عروض'))))
  ]);
  Widget requests()=>ListView(padding:const EdgeInsets.all(18),children:[const Text('طلباتي',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:15),Card(child:ListTile(title:Text(request?'طلب خدمة':'لا توجد طلبات'),subtitle:Text(request?'قيد المتابعة':'ابدأ أول طلب من الرئيسية')))]);
  Widget profile()=>ListView(padding:const EdgeInsets.all(18),children:[const Text('حسابي',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:15),const Card(child:ListTile(leading:CircleAvatar(child:Icon(Icons.person)),title:Text('العميل التجريبي'),subtitle:Text('عمّان، الأردن')))]);
  void showOffers()=>showModalBottomSheet(context:context,builder:(_)=>ListView(padding:const EdgeInsets.all(20),children:[const Text('العروض المستلمة',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),...['محمد العجارمة — 25 د.أ','أحمد الخطيب — 20 د.أ','يزن حداد — 30 د.أ'].map((x)=>Card(child:ListTile(title:Text(x),subtitle:const Text('✓ محترف موثّق • ★ 4.9'),trailing:TextButton(onPressed:(){Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم اختيار المحترف')));},child:const Text('اختيار')))))]));
}

class RequestSheet extends StatefulWidget {
  final String? service; final VoidCallback onDone;
  const RequestSheet({super.key,this.service,required this.onDone});
  @override State<RequestSheet> createState()=>_RequestSheetState();
}
class _RequestSheetState extends State<RequestSheet>{late String service;final desc=TextEditingController();@override void initState(){super.initState();service=widget.service??'سباكة';}@override void dispose(){desc.dispose();super.dispose();}@override Widget build(BuildContext context)=>Padding(padding:EdgeInsets.only(left:20,right:20,top:20,bottom:20+MediaQuery.of(context).viewInsets.bottom),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('إنشاء طلب',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:15),DropdownButtonFormField<String>(initialValue:service,items:['سباكة','كهرباء','تكييف','دهان','نجارة','تنظيف','نقل وتركيب','تقنية'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>service=v!),decoration:const InputDecoration(labelText:'الخدمة',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:desc,maxLines:3,decoration:const InputDecoration(labelText:'وصف المطلوب',border:OutlineInputBorder())),const SizedBox(height:15),SizedBox(width:double.infinity,child:FilledButton(onPressed:(){Navigator.pop(context);widget.onDone();},child:const Text('نشر الطلب'))),const SizedBox(height:10)]));
}
