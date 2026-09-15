// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl=String.fromEnvironment('SUPABASE_URL');
const supabaseKey=String.fromEnvironment('SUPABASE_KEY');
const primary=Color(0xFF006B55);
SupabaseClient get db=>Supabase.instance.client;
String get uid=>db.auth.currentUser?.id??'';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url:supabaseUrl,publishableKey:supabaseKey);
  runApp(const App());
}
void note(BuildContext c,String s)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));
double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;
String money(dynamic v)=>n(v).toStringAsFixed(2);
Widget fld(TextEditingController c,String l,{bool number=false})=>TextField(controller:c,keyboardType:number?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:l));

class App extends StatelessWidget{
  const App({super.key});
  @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'SMETA TJ',theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:primary),scaffoldBackgroundColor:const Color(0xFFF4F7F6),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)))),home:const Gate());
}
class Gate extends StatelessWidget{
  const Gate({super.key});
  @override Widget build(BuildContext c)=>StreamBuilder<AuthState>(stream:db.auth.onAuthStateChange,builder:(c,s)=>db.auth.currentSession==null?const Login():const Home());
}
class Login extends StatefulWidget{const Login({super.key});@override State<Login> createState()=>_LoginState();}
class _LoginState extends State<Login>{
  final e=TextEditingController(),p=TextEditingController();bool signup=false,busy=false;
  Future<void> go()async{if(e.text.trim().isEmpty||p.text.length<6){note(context,'Email ва рамзи 6+ аломат лозим.');return;}setState(()=>busy=true);try{if(signup){await db.auth.signUp(email:e.text.trim(),password:p.text,emailRedirectTo:'tj.smetatj.app://login-callback/');if(mounted)note(context,'Email-ро тасдиқ кунед.');}else{await db.auth.signInWithPassword(email:e.text.trim(),password:p.text);}}on AuthException catch(x){if(mounted)note(context,x.message);}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext c)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),child:Column(children:[const Icon(Icons.architecture,size:72,color:primary),const Text('SMETA TJ',style:TextStyle(fontSize:34,fontWeight:FontWeight.w900)),const SizedBox(height:24),fld(e,'Email'),const SizedBox(height:10),TextField(controller:p,obscureText:true,decoration:const InputDecoration(labelText:'Рамз')),const SizedBox(height:14),SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:go,child:Text(signup?'Сабти ном':'Ворид шудан'))),TextButton(onPressed:()=>setState(()=>signup=!signup),child:Text(signup?'Ворид шудан':'Ҳисоби нав'))])))));
}
class Home extends StatefulWidget{const Home({super.key});@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{
 int i=0,k=0;
 final names=const['Асосӣ','Объектҳо','Сметаҳо','Меъёрҳо','Нархҳо','Ҳуҷҷатҳо','Назорати техникӣ','Online / Sync','Marketplace','AI SMETA TJ'];
 List<Widget> pages()=>[Dashboard(key:ValueKey('d$k')),Projects(key:ValueKey('p$k')),Estimates(key:ValueKey('e$k')),Standards(key:ValueKey('s$k')),Prices(key:ValueKey('r$k')),const Documents(),const Technical(),const Sync(),const Market(),const Ai()];
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(names[i],style:const TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:()=>setState(()=>k++),icon:const Icon(Icons.refresh)),IconButton(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout))]),drawer:Drawer(child:SafeArea(child:ListView(children:[const ListTile(title:Text('SMETA TJ',style:TextStyle(fontWeight:FontWeight.w900))),for(int x=0;x<10;x++)ListTile(selected:i==x,title:Text('${x+1}. ${names[x]}'),onTap:(){Navigator.pop(c);setState(()=>i=x);})]))),body:IndexedStack(index:i,children:pages()),bottomNavigationBar:NavigationBar(selectedIndex:i<5?i:0,onDestinationSelected:(x)=>setState(()=>i=x),destinations:const[NavigationDestination(icon:Icon(Icons.dashboard),label:'Асосӣ'),NavigationDestination(icon:Icon(Icons.apartment),label:'Объект'),NavigationDestination(icon:Icon(Icons.calculate),label:'Смета'),NavigationDestination(icon:Icon(Icons.menu_book),label:'Меъёр'),NavigationDestination(icon:Icon(Icons.payments),label:'Нарх')]));
}

class Dashboard extends StatefulWidget{const Dashboard({super.key});@override State<Dashboard> createState()=>_DashboardState();}
class _DashboardState extends State<Dashboard>{
 int pc=0,ec=0,sc=0,rc=0;double total=0;bool busy=true;
 @override void initState(){super.initState();load();}
 Future<void> load()async{try{final p=await db.from('projects').select('id');final e=await db.from('estimates').select('id,total');final s=await db.from('construction_standards').select('id');final r=await db.from('prices').select('id');if(mounted)setState((){pc=p.length;ec=e.length;sc=s.length;rc=r.length;total=e.fold(0,(a,b)=>a+n(b['total']));busy=false;});}catch(x){if(mounted){setState(()=>busy=false);note(context,'Dashboard: $x');}}}
 Widget card(String t,String v,IconData ic)=>Card(child:ListTile(leading:Icon(ic,color:primary),title:Text(t),trailing:Text(v,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900))));
 @override Widget build(BuildContext c)=>RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[const Text('SMETA TJ ONLINE',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900)),Text(db.auth.currentUser?.email??''),const SizedBox(height:12),if(busy)const LinearProgressIndicator(),card('Объектҳо','$pc',Icons.apartment),card('Сметаҳо','$ec',Icons.calculate),card('Меъёрҳо','$sc',Icons.menu_book),card('Нархҳо','$rc',Icons.payments),card('Ҷамъи сметаҳо','${money(total)} сом.',Icons.wallet)]));
}

class Projects extends StatefulWidget {
  const Projects({super.key});
  @override
  State<Projects> createState() => _ProjectsState();
}

class _ProjectsState extends State<Projects> {
  List<Map<String, dynamic>> rows = [];
  bool busy = true;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final x = await db.from('projects').select().order('created_at', ascending: false);
      if (mounted) setState(() { rows = List<Map<String, dynamic>>.from(x); busy = false; });
    } catch (x) { if (mounted) { setState(() => busy = false); note(context, 'Объект: $x'); } }
  }

  Future<void> edit([Map<String, dynamic>? old]) async {
    final a = TextEditingController(text: '${old?['name'] ?? ''}');
    final b = TextEditingController(text: '${old?['address'] ?? ''}');
    final c = TextEditingController(text: '${old?['customer'] ?? ''}');
    final d = TextEditingController(text: '${old?['contractor'] ?? ''}');
    final f = TextEditingController(text: '${old?['engineer'] ?? ''}');
    final g = TextEditingController(text: '${old?['budget'] ?? ''}');
    final ok = await showDialog<bool>(context: context, builder: (z) => AlertDialog(
      title: Text(old == null ? 'Объекти нав' : 'Тағйир'),
      content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        fld(a, 'Ном'), const SizedBox(height: 7), fld(b, 'Суроға'), const SizedBox(height: 7),
        fld(c, 'Фармоишгар'), const SizedBox(height: 7), fld(d, 'Пудратчӣ'), const SizedBox(height: 7),
        fld(f, 'Муҳандис'), const SizedBox(height: 7), fld(g, 'Буҷет', number: true),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(z, false), child: const Text('Бекор')), FilledButton(onPressed: () => Navigator.pop(z, true), child: const Text('Сабт'))],
    )) ?? false;
    if (!ok || a.text.trim().isEmpty) return;
    final data = {'name': a.text.trim(), 'address': b.text.trim(), 'customer': c.text.trim(), 'contractor': d.text.trim(), 'engineer': f.text.trim(), 'budget': n(g.text), 'status': 'Дар кор'};
    try {
      if (old == null) { await db.from('projects').insert({...data, 'user_id': uid}); }
      else { await db.from('projects').update(data).eq('id', old['id']); }
      await load();
    } catch (x) { if (mounted) note(context, 'Сабт: $x'); }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    floatingActionButton: FloatingActionButton(onPressed: () => edit(), child: const Icon(Icons.add)),
    body: busy ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        ...rows.map((r) => Card(child: ListTile(
          title: Text('${r['name']}'), subtitle: Text('${r['address']} • ${money(r['budget'])} сом.'),
          onTap: () => edit(r),
          trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () async {
            try { await db.from('projects').delete().eq('id', r['id']); await load(); }
            catch (x) { if (mounted) note(context, 'Нест кардан: $x'); }
          }),
        ))),
      ]),
    ),
  );
}

class Estimates extends StatefulWidget{const Estimates({super.key});@override State<Estimates> createState()=>_EstimatesState();}
class _EstimatesState extends State<Estimates>{
 List<Map<String,dynamic>> rows=[],projects=[];bool busy=true;@override void initState(){super.initState();load();}
 Future<void> load()async{try{final a=await db.from('estimates').select().order('created_at',ascending:false);final p=await db.from('projects').select('id,name');if(mounted)setState((){rows=List<Map<String,dynamic>>.from(a);projects=List<Map<String,dynamic>>.from(p);busy=false;});}catch(x){if(mounted){setState(()=>busy=false);note(context,'Смета: $x');}}}
 Future<void> add()async{if(projects.isEmpty){note(context,'Аввал объект созед.');return;}final t=TextEditingController(),v=TextEditingController();String pid='${projects.first['id']}';final ok=await showDialog<bool>(context:context,builder:(z)=>StatefulBuilder(builder:(z,setD)=>AlertDialog(title:const Text('Сметаи нав'),content:SizedBox(width:480,child:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<String>(initialValue:pid,items:projects.map((p)=>DropdownMenuItem(value:'${p['id']}',child:Text('${p['name']}'))).toList(),onChanged:(x)=>setD(()=>pid=x??pid),decoration:const InputDecoration(labelText:'Объект')),const SizedBox(height:8),fld(t,'Номи смета'),const SizedBox(height:8),fld(v,'Маблағ',number:true)])),actions:[TextButton(onPressed:()=>Navigator.pop(z,false),child:const Text('Бекор')),FilledButton(onPressed:()=>Navigator.pop(z,true),child:const Text('Сабт'))])))??false;if(!ok||t.text.isEmpty)return;try{await db.from('estimates').insert({'user_id':uid,'project_id':pid,'title':t.text.trim(),'estimate_type':'Локалӣ','status':'Лоиҳа','subtotal':n(v.text),'total':n(v.text)});await load();}catch(x){if(mounted)note(context,'Сабт: $x');}}
 @override Widget build(BuildContext c)=>Scaffold(floatingActionButton:FloatingActionButton(onPressed:add,child:const Icon(Icons.add)),body:busy?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[...rows.map((r)=>Card(child:ListTile(title:Text('${r['title']}'),subtitle:Text('${money(r['total'])} сомонӣ'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>Items(estimate:r))))))]));
}

class Items extends StatefulWidget{final Map<String,dynamic> estimate;const Items({super.key,required this.estimate});@override State<Items> createState()=>_ItemsState();}
class _ItemsState extends State<Items>{
 List<Map<String,dynamic>> rows=[];@override void initState(){super.initState();load();}
 Future<void> load()async{try{final x=await db.from('estimate_items').select().eq('estimate_id',widget.estimate['id']);if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(x));}catch(x){if(mounted)note(context,'Корҳои смета: $x');}}
 Future<void> add()async{final a=TextEditingController(),u=TextEditingController(),q=TextEditingController(),p=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(z)=>AlertDialog(title:const Text('Кори нав'),content:SizedBox(width:450,child:Column(mainAxisSize:MainAxisSize.min,children:[fld(a,'Номи кор'),const SizedBox(height:7),fld(u,'Воҳид'),const SizedBox(height:7),fld(q,'Миқдор',number:true),const SizedBox(height:7),fld(p,'Нарх',number:true)])),actions:[FilledButton(onPressed:()=>Navigator.pop(z,true),child:const Text('Сабт'))]))??false;if(!ok)return;try{await db.from('estimate_items').insert({'user_id':uid,'estimate_id':widget.estimate['id'],'work_name':a.text,'unit':u.text,'quantity':n(q.text),'unit_price':n(p.text),'coefficient':1,'total_price':n(q.text)*n(p.text)});await load();}catch(x){if(mounted)note(context,'Сабт: $x');}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text('${widget.estimate['title']}')),floatingActionButton:FloatingActionButton(onPressed:add,child:const Icon(Icons.add)),body:ListView(padding:const EdgeInsets.all(16),children:[...rows.map((r)=>Card(child:ListTile(title:Text('${r['work_name']}'),subtitle:Text('${r['quantity']} ${r['unit']} × ${money(r['unit_price'])}'),trailing:Text('${money(r['total_price'])} сом.'))))]));
}

class Standards extends StatefulWidget{const Standards({super.key});@override State<Standards> createState()=>_StandardsState();}
class _StandardsState extends State<Standards>{
 final q=TextEditingController();List<Map<String,dynamic>> rows=[];@override void initState(){super.initState();load();}
 Future<void> load()async{try{final x=await db.from('construction_standards').select().order('code');if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(x));}catch(x){if(mounted)note(context,'Меъёр: $x');}}
 @override Widget build(BuildContext c){final f=rows.where((r)=>'${r['code']} ${r['title']} ${r['document_type']}'.toLowerCase().contains(q.text.toLowerCase())).toList();return ListView(padding:const EdgeInsets.all(16),children:[TextField(controller:q,onChanged:(_)=>setState((){}),decoration:const InputDecoration(labelText:'Ҷустуҷӯи меъёр',prefixIcon:Icon(Icons.search))),const SizedBox(height:10),...f.map((r)=>Card(child:ListTile(title:Text('${r['code']}'),subtitle:Text('${r['title']}\n${r['document_type']} • ${r['edition_year']}'))))]);}
}

class Prices extends StatefulWidget{const Prices({super.key});@override State<Prices> createState()=>_PricesState();}
class _PricesState extends State<Prices>{
 List<Map<String,dynamic>> rows=[];@override void initState(){super.initState();load();}
 Future<void> load()async{try{final x=await db.from('prices').select().order('created_at',ascending:false);if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(x));}catch(x){if(mounted)note(context,'Нарх: $x');}}
 Future<void> add()async{final c=TextEditingController(),a=TextEditingController(),u=TextEditingController(),p=TextEditingController(),r=TextEditingController(text:'Душанбе'),s=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(z)=>AlertDialog(title:const Text('Нархи нав'),content:SizedBox(width:470,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[fld(c,'Категория'),const SizedBox(height:7),fld(a,'Ном'),const SizedBox(height:7),fld(u,'Воҳид'),const SizedBox(height:7),fld(p,'Нарх',number:true),const SizedBox(height:7),fld(r,'Минтақа'),const SizedBox(height:7),fld(s,'Таъминкунанда')]))),actions:[FilledButton(onPressed:()=>Navigator.pop(z,true),child:const Text('Сабт'))]))??false;if(!ok)return;try{await db.from('prices').insert({'owner_user_id':uid,'category':c.text,'name':a.text,'unit':u.text,'price':n(p.text),'currency':'TJS','region':r.text,'supplier':s.text,'is_official':false});await load();}catch(x){if(mounted)note(context,'Сабти нарх: $x');}}
 @override Widget build(BuildContext c)=>Scaffold(floatingActionButton:FloatingActionButton(onPressed:add,child:const Icon(Icons.add)),body:ListView(padding:const EdgeInsets.all(16),children:[...rows.map((r)=>Card(child:ListTile(title:Text('${r['name']}'),subtitle:Text('${r['category']} • ${r['unit']} • ${r['supplier']}'),trailing:Text('${money(r['price'])} сом.'))))]));
}

class Documents extends StatelessWidget{const Documents({super.key});@override Widget build(BuildContext c)=>FutureBuilder<List<Map<String,dynamic>>>(future:db.from('estimates').select().then((x)=>List<Map<String,dynamic>>.from(x)),builder:(c,s)=>s.connectionState!=ConnectionState.done?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[const Text('Смета / Санад / Ҳисобот',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),...(s.data ?? <Map<String,dynamic>>[]).map((r)=>Card(child:ListTile(leading:const Icon(Icons.description,color:primary),title:Text('${r['title']}'),subtitle:Text('${money(r['total'])} сомонӣ'),trailing:PopupMenuButton(itemBuilder:(_)=>const[PopupMenuItem(child:Text('Смета')),PopupMenuItem(child:Text('Санад')),PopupMenuItem(child:Text('Ҳисобот'))])))) ]));}
class Technical extends StatefulWidget{const Technical({super.key});@override State<Technical> createState()=>_TechnicalState();}
class _TechnicalState extends State<Technical>{final m={'Мутобиқат ба лоиҳа':false,'Сифати бетон':false,'Арматура':false,'Андоза ва отметка':false,'Бехатарӣ':false,'Корҳои пӯшида':false};@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('Checklist назорати техникӣ',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),...m.keys.map((k)=>Card(child:CheckboxListTile(title:Text(k),value:m[k],onChanged:(v)=>setState(()=>m[k]=v??false))))]);}
class Sync extends StatelessWidget{const Sync({super.key});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[Card(child:ListTile(leading:const Icon(Icons.cloud_done,color:primary),title:const Text('Supabase Online'),subtitle:Text(db.auth.currentSession==null?'Offline':'Online • ${db.auth.currentUser?.email??''}'))),FilledButton.icon(onPressed:()async{try{await db.from('projects').select('id').limit(1);if(c.mounted)note(c,'Sync OK');}catch(x){if(c.mounted)note(c,'Sync: $x');}},icon:const Icon(Icons.sync),label:const Text('Санҷидани Sync'))]);}
class Market extends StatelessWidget{const Market({super.key});@override Widget build(BuildContext c)=>FutureBuilder<List<Map<String,dynamic>>>(future:db.from('prices').select().then((x)=>List<Map<String,dynamic>>.from(x)),builder:(c,s)=>s.connectionState!=ConnectionState.done?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[const Text('Marketplace',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),...(s.data ?? <Map<String,dynamic>>[]).where((r)=>'${r['supplier']??''}'.isNotEmpty).map((r)=>Card(child:ListTile(leading:const Icon(Icons.storefront,color:primary),title:Text('${r['name']}'),subtitle:Text('${r['supplier']} • ${r['region']}'),trailing:Text('${money(r['price'])} сом.')))) ]));}
class Ai extends StatefulWidget{const Ai({super.key});@override State<Ai> createState()=>_AiState();}
class _AiState extends State<Ai>{final q=TextEditingController();String a='';Future<void> run()async{try{final s=await db.from('construction_standards').select().limit(100);final p=await db.from('prices').select().limit(100);final w=q.text.toLowerCase().split(RegExp(r'\s+')).where((x)=>x.length>2);final sm=s.where((r)=>w.any((x)=>'${r['code']} ${r['title']}'.toLowerCase().contains(x))).take(5);final pm=p.where((r)=>w.any((x)=>'${r['name']} ${r['category']}'.toLowerCase().contains(x))).take(5);final b=StringBuffer();for(final r in sm){b.writeln('МЕЪЁР: ${r['code']} — ${r['title']}');}for(final r in pm){b.writeln('НАРХ: ${r['name']} — ${money(r['price'])} сом/${r['unit']}');}if(b.isEmpty)b.write('Дар база маълумоти мувофиқ нест.');if(mounted)setState(()=>a=b.toString());}catch(x){if(mounted)setState(()=>a='Хато: $x');}}@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('AI SMETA TJ',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const Text('Ҷустуҷӯи интеллектуалӣ дар базаи меъёрҳо ва нархҳо.'),const SizedBox(height:12),TextField(controller:q,maxLines:3,decoration:const InputDecoration(labelText:'Савол')),const SizedBox(height:10),FilledButton.icon(onPressed:run,icon:const Icon(Icons.auto_awesome),label:const Text('Таҳлил')),const SizedBox(height:12),SelectableText(a)]);}

// ===== SMETA TJ 1–10 — FILE END =====
