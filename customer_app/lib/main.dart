import 'package:flutter/material.dart';

const navy = Color(0xFF111827);
const orange = Color(0xFFF97316);
const bg = Color(0xFFF8FAFC);

void main() => runApp(const CustomerApp());

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MAHER | العميل',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: orange, scaffoldBackgroundColor: bg, fontFamily: 'Arial'),
        home: const CustomerHome(),
      );
}

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int tab = 0;
  String service = 'سباكة';
  String type = 'بالساعة';
  String status = 'لا يوجد طلب';
  final desc = TextEditingController();

  final services = ['سباكة','كهرباء','تكييف','دهان','نجارة','تنظيف','نقل وتركيب','تقنية','صيانة عامة'];

  @override void dispose() { desc.dispose(); super.dispose(); }

  void createRequest() {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => StatefulBuilder(builder: (context, setSheet) {
      return Directionality(textDirection: TextDirection.rtl, child: Padding(
        padding: EdgeInsets.fromLTRB(20,20,20,20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('طلب خدمة جديد', style: TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
          const SizedBox(height:18),
          DropdownButtonFormField<String>(value: service, decoration: const InputDecoration(labelText:'نوع الخدمة',border:OutlineInputBorder()), items: services.map((s)=>DropdownMenuItem(value:s,child:Text(s))).toList(), onChanged:(v){if(v!=null)setSheet(()=>service=v);}),
          const SizedBox(height:12),
          const Text('طريقة التسعير',style:TextStyle(fontWeight:FontWeight.w800)),
          const SizedBox(height:8),
          Wrap(spacing:8, children:['بالساعة','يومي','مقاولة'].map((v)=>ChoiceChip(label:Text(v),selected:type==v,onSelected:(_)=>setSheet(()=>type=v))).toList()),
          const SizedBox(height:12),
          TextField(controller:desc,maxLines:4,decoration:const InputDecoration(labelText:'وصف الطلب',hintText:'مثلاً: بدي تركيب بسكليت/تصليح تسريب...',border:OutlineInputBorder())),
          const SizedBox(height:12),
          ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.location_on_outlined),title:const Text('الموقع'),subtitle:const Text('عمّان — تحديد الموقع لاحقاً عبر الخريطة')), 
          ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.schedule_outlined),title:const Text('الموعد'),subtitle:const Text('الآن / اختيار موعد لاحق')), 
          const SizedBox(height:8),
          SizedBox(width:double.infinity,child:FilledButton(onPressed:(){setState(()=>status='بانتظار عروض الصنايعية');Navigator.pop(context);},child:const Text('نشر الطلب'))),
        ]))));
    }));
  }

  void showOffers() => showModalBottomSheet(context:context,builder:(_)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[
    const Text('العروض المستلمة',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:12),
    offer('محمد العجارمة','4.9','25 د.أ','128 طلب مكتمل'),offer('أحمد الخطيب','4.8','20 د.أ','94 طلب مكتمل'),offer('يزن حداد','4.7','30 د.أ','76 طلب مكتمل'),
  ]))));

  Widget offer(String name,String rating,String price,String jobs)=>Card(child:ListTile(isThreeLine:true,leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(name,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('★ $rating  •  $jobs\nمحترف موثّق  •  سباكة'),trailing:FilledButton(onPressed:(){setState(()=>status='تم اختيار $name — بانتظار الوصول');Navigator.pop(context);},child:const Text('اختيار'))));

  Widget home() => ListView(padding:const EdgeInsets.all(18),children:[
    Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:navy,borderRadius:BorderRadius.circular(24)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('شو بدك يتصلّح؟',style:TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.w900)),SizedBox(height:8),Text('اطلب صنايعي قريب منك، قارن العروض واختار الشخص المناسب.',style:TextStyle(color:Colors.white70,height:1.5))])),
    const SizedBox(height:22),const Text('الخدمات',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:12),
    GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:services.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:8,mainAxisSpacing:8,childAspectRatio:1.05),itemBuilder:(_,i)=>Card(child:InkWell(onTap:(){service=services[i];createRequest();},borderRadius:BorderRadius.circular(14),child:Center(child:Text(services[i],textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w800))))))),
    const SizedBox(height:18),
    if(status!='لا يوجد طلب') Card(child:ListTile(title:const Text('طلبك الحالي',style:TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('$service • $type\n$status'),isThreeLine:true,trailing:status.contains('بانتظار')?TextButton(onPressed:showOffers,child:const Text('العروض')):const Icon(Icons.chevron_left))),
  ]);

  Widget requests() => ListView(padding:const EdgeInsets.all(18),children:[const Text('طلباتي',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900)),const SizedBox(height:14),Card(child:ListTile(leading:const Icon(Icons.receipt_long),title:Text(status=='لا يوجد طلب'?'لا توجد طلبات':'$service — $type'),subtitle:Text(status),onTap:status.contains('بانتظار')?showOffers:null))]);

  Widget profile() => ListView(padding:const EdgeInsets.all(18),children:[const Text('حسابي',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900)),const SizedBox(height:14),const Card(child:ListTile(leading:CircleAvatar(child:Icon(Icons.person)),title:Text('حساب العميل'),subtitle:Text('رقم الهاتف موثّق • عمّان'))),const SizedBox(height:8),const Card(child:Column(children:[ListTile(leading:Icon(Icons.verified_user_outlined),title:Text('التحقق والخصوصية')),ListTile(leading:Icon(Icons.payment_outlined),title:Text('طرق الدفع')),ListTile(leading:Icon(Icons.support_agent_outlined),title:Text('الدعم والمساعدة'))]))]);

  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('MAHER',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:(){},icon:const Icon(Icons.notifications_none))]),body:tab==0?home():tab==1?requests():profile(),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'الرئيسية'),NavigationDestination(icon:Icon(Icons.assignment_outlined),selectedIcon:Icon(Icons.assignment),label:'طلباتي'),NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'حسابي')]),floatingActionButton:tab==0?FloatingActionButton.extended(backgroundColor:orange,foregroundColor:Colors.white,onPressed:createRequest,icon:const Icon(Icons.add),label:const Text('اطلب خدمة')):null));
}
