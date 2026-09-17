import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/ads_service.dart';
import 'widgets/banner_ad.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdsService.instance.initialize();
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});
  @override State<CalculatorApp> createState() => _CalculatorAppState();
}
class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode mode = ThemeMode.system;
  bool haptics = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await SharedPreferences.getInstance(); if (!mounted) return; setState(() { mode = ThemeMode.values.firstWhere((e) => e.name == (p.getString('theme') ?? 'system'), orElse: () => ThemeMode.system); haptics = p.getBool('haptics') ?? true; }); }
  Future<void> setTheme(ThemeMode v) async { final p = await SharedPreferences.getInstance(); await p.setString('theme', v.name); if (mounted) setState(() => mode = v); }
  Future<void> setHaptics(bool v) async { final p = await SharedPreferences.getInstance(); await p.setBool('haptics', v); if (mounted) setState(() => haptics = v); }
  @override Widget build(BuildContext context) {
    const seed = Color(0xFF4F46E5);
    final light = ColorScheme.fromSeed(seedColor: seed);
    final dark = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return MaterialApp(debugShowCheckedModeBanner: false, title: 'All-in-One Calculator', themeMode: mode,
      theme: ThemeData(useMaterial3: true, colorScheme: light, scaffoldBackgroundColor: const Color(0xFFF7F7FB)),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: dark, scaffoldBackgroundColor: const Color(0xFF0F1015)),
      home: Home(haptics: haptics, onHaptics: setHaptics, mode: mode, onTheme: setTheme));
  }
}

class Home extends StatefulWidget {
  final bool haptics; final ValueChanged<bool> onHaptics; final ThemeMode mode; final ValueChanged<ThemeMode> onTheme;
  const Home({super.key, required this.haptics, required this.onHaptics, required this.mode, required this.onTheme});
  @override State<Home> createState() => _HomeState();
}
class _HomeState extends State<Home> {
  int index = 0;
  final pages = const [CalculatorPage(), FinancePage(), ConverterPage(), ToolsPage()];
  final titles = const ['Calculator', 'Finance', 'Convert', 'Tools'];
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(titles[index], style: const TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => _settings(context))]),
    body: SafeArea(child: IndexedStack(index: index, children: pages)), bottomSheet: const BannerAdWidget(),
    bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate), label: 'Calculator'),
      NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Finance'),
      NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Convert'), NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Tools')]),
  );
  void _settings(BuildContext c) => showModalBottomSheet<void>(context: c, showDragHandle: true, builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Align(alignment: Alignment.centerLeft, child: Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
    SwitchListTile(value: widget.haptics, onChanged: widget.onHaptics, title: const Text('Haptic feedback')),
    ListTile(title: const Text('Theme'), trailing: DropdownButton<ThemeMode>(value: widget.mode, items: const [DropdownMenuItem(value: ThemeMode.system, child: Text('System')), DropdownMenuItem(value: ThemeMode.light, child: Text('Light')), DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark'))], onChanged: (v) { if (v != null) widget.onTheme(v); })),
    const ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy-first design'), subtitle: Text('Calculations stay on your device.')),
    ListTile(leading: const Icon(Icons.tune), title: const Text('Ad privacy options'), onTap: () => AdsService.instance.showPrivacyOptions()),
    const Text('All-in-One Calculator • v1.5.1', style: TextStyle(fontSize: 12)),
  ])));
}

class CalculatorPage extends StatefulWidget { const CalculatorPage({super.key}); @override State<CalculatorPage> createState() => _CalculatorPageState(); }
class _CalculatorPageState extends State<CalculatorPage> {
  String display = '0'; double? first; String? op; bool fresh = true; final history = <String>[];
  void tap(String key) { HapticFeedback.selectionClick(); setState(() {
    if (key == 'C') { display = '0'; first = null; op = null; fresh = true; return; }
    if (key == '⌫') { display = display.length <= 1 ? '0' : display.substring(0, display.length - 1); return; }
    if (key == '±') { if (display != '0') display = display.startsWith('-') ? display.substring(1) : '-$display'; return; }
    if (key == '%') { display = fmt((double.tryParse(display) ?? 0) / 100); return; }
    if ('0123456789.'.contains(key)) { if (fresh) { display = key == '.' ? '0.' : key; fresh = false; } else if (!(key == '.' && display.contains('.'))) display += key; return; }
    if ('+-×÷'.contains(key)) { final v = double.tryParse(display) ?? 0; if (first != null && op != null && !fresh) calc(v); else first = v; op = key; fresh = true; return; }
    if (key == '=' && first != null && op != null) { calc(double.tryParse(display) ?? 0); first = null; op = null; fresh = true; }
  }); }
  void calc(double b) { final a = first ?? 0; final o = op ?? '+'; double? r; switch (o) { case '+': r = a + b; case '-': r = a - b; case '×': r = a * b; case '÷': if (b != 0) r = a / b; } if (r == null || !r.isFinite) display = 'Error'; else { display = fmt(r); history.insert(0, '${fmt(a)} $o ${fmt(b)} = $display'); if (history.length > 20) history.removeLast(); } }
  String fmt(double n) => n == n.roundToDouble() ? NumberFormat('#,##0').format(n) : NumberFormat('#,##0.##########').format(n);
  @override Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; const keys = [['C','⌫','%','÷'],['7','8','9','×'],['4','5','6','-'],['1','2','3','+'],['±','0','.','=']]; return Padding(padding: const EdgeInsets.all(16), child: Column(children: [Expanded(child: Align(alignment: Alignment.bottomRight, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(display, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800))))), const SizedBox(height: 12), Expanded(flex: 2, child: GridView.builder(itemCount: 20, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.18), itemBuilder: (_, i) { final k = keys[i ~/ 4][i % 4]; final special = k == '=' || ['÷','×','+','-'].contains(k); return FilledButton(style: FilledButton.styleFrom(backgroundColor: special ? cs.primary : cs.surfaceContainerHighest, foregroundColor: special ? cs.onPrimary : cs.onSurface), onPressed: () => tap(k), child: Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))); })), if (history.isNotEmpty) Text(history.first, overflow: TextOverflow.ellipsis)])); }
}

class FinancePage extends StatelessWidget { const FinancePage({super.key}); @override Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(16), children: [const SectionTitle('Popular calculators', 'Quick answers for money decisions'),
  ToolCard(icon: Icons.percent, title: 'Percentage', subtitle: 'Find a percentage of an amount', onTap: () => open(c, const PercentagePage())), ToolCard(icon: Icons.receipt_long, title: 'GST Calculator', subtitle: 'Add GST to an amount', onTap: () => open(c, const GstPage())), ToolCard(icon: Icons.payments, title: 'EMI Calculator', subtitle: 'Loan EMI and repayment', onTap: () => open(c, const EmiPage())), ToolCard(icon: Icons.trending_up, title: 'SIP Calculator', subtitle: 'Estimated SIP growth', onTap: () => open(c, const SipPage())), ToolCard(icon: Icons.savings, title: 'FD Calculator', subtitle: 'Fixed-deposit maturity estimate', onTap: () => open(c, const FdPage())), ToolCard(icon: Icons.percent_outlined, title: 'Simple Interest', subtitle: 'Interest and maturity', onTap: () => open(c, const SimpleInterestPage())), ToolCard(icon: Icons.functions, title: 'Compound Interest', subtitle: 'Compounded growth', onTap: () => open(c, const CompoundPage())), ToolCard(icon: Icons.account_balance, title: 'RD Calculator', subtitle: 'Recurring-deposit estimate', onTap: () => open(c, const RdPage()))]); }
}

class ConverterPage extends StatefulWidget { const ConverterPage({super.key}); @override State<ConverterPage> createState() => _ConverterPageState(); }
class _ConverterPageState extends State<ConverterPage> { String type='Length', from='Meter', to='Kilometer'; double value=1; final units = const {'Length':['Meter','Kilometer','Centimeter','Mile','Foot','Inch'],'Weight':['Kilogram','Gram','Pound','Ounce'],'Temperature':['Celsius','Fahrenheit','Kelvin'],'Data':['Byte','Kilobyte','Megabyte','Gigabyte']}; double convert() { if(type=='Temperature'){final c=from=='Celsius'?value:from=='Fahrenheit'?(value-32)*5/9:value-273.15; return to=='Celsius'?c:to=='Fahrenheit'?c*9/5+32:c+273.15;} const f={'Meter':1.0,'Kilometer':1000.0,'Centimeter':.01,'Mile':1609.344,'Foot':.3048,'Inch':.0254,'Kilogram':1.0,'Gram':.001,'Pound':.45359237,'Ounce':.0283495231,'Byte':1.0,'Kilobyte':1024.0,'Megabyte':1048576.0}; return value*(f[from]??1)/(f[to]??1); } @override Widget build(BuildContext c){final list=units[type]!; if(!list.contains(from))from=list.first;if(!list.contains(to))to=list.last;return ListView(padding:const EdgeInsets.all(16),children:[const SectionTitle('Unit converter','Fast everyday conversions'),DropdownButtonFormField<String>(initialValue:type,items:units.keys.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>type=v!),decoration:const InputDecoration(labelText:'Category',border:OutlineInputBorder())),const SizedBox(height:14),TextField(decoration:const InputDecoration(labelText:'Value',border:OutlineInputBorder()),keyboardType:const TextInputType.numberWithOptions(decimal:true),onChanged:(v)=>value=double.tryParse(v)??0),const SizedBox(height:14),Row(children:[Expanded(child:drop('From',from,list,(v)=>setState(()=>from=v!))),const Icon(Icons.swap_horiz),Expanded(child:drop('To',to,list,(v)=>setState(()=>to=v!)))]),const SizedBox(height:20),ResultCard(label:'Result',value:convert().toStringAsFixed(6),detail:'$value $from = ${convert().toStringAsFixed(6)} $to')]);} Widget drop(String label,String v,List<String> l,ValueChanged<String?> f)=>DropdownButtonFormField<String>(initialValue:v,items:l.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:f,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())); }

class ToolsPage extends StatelessWidget { const ToolsPage({super.key}); @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[const SectionTitle('Everyday tools','Useful everyday utilities'),ToolCard(icon:Icons.cake_outlined,title:'Age Calculator',subtitle:'Calculate exact age',onTap:()=>open(c,const AgePage())),ToolCard(icon:Icons.monitor_weight_outlined,title:'BMI Calculator',subtitle:'BMI from height and weight',onTap:()=>open(c,const BmiPage())),ToolCard(icon:Icons.calendar_month,title:'Date Difference',subtitle:'Days between two dates',onTap:()=>open(c,const DateDiffPage())),ToolCard(icon:Icons.speed,title:'Fuel Cost Calculator',subtitle:'Trip fuel-cost estimate',onTap:()=>open(c,const FuelPage()))]); }
}

void open(BuildContext c, Widget page)=>Navigator.of(c).push(MaterialPageRoute(builder:(_)=>page));
class SectionTitle extends StatelessWidget { final String title, subtitle; const SectionTitle(this.title,this.subtitle,{super.key}); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),Text(subtitle,style:TextStyle(color:Theme.of(c).colorScheme.onSurfaceVariant))])); }
class ToolCard extends StatelessWidget { final IconData icon; final String title,subtitle; final VoidCallback onTap; const ToolCard({super.key,required this.icon,required this.title,required this.subtitle,required this.onTap}); @override Widget build(BuildContext c)=>Card(child:ListTile(leading:CircleAvatar(child:Icon(icon)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right),onTap:onTap)); }
class ResultCard extends StatelessWidget { final String label,value,detail; const ResultCard({super.key,required this.label,required this.value,required this.detail}); @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label),const SizedBox(height:6),Text(value,style:const TextStyle(fontSize:30,fontWeight:FontWeight.w800)),Text(detail)]))); }

class CalcPage extends StatefulWidget { final String title,subtitle; final List<String> labels; final double Function(List<double>) compute; final String resultLabel; const CalcPage({super.key,required this.title,required this.subtitle,required this.labels,required this.compute,required this.resultLabel}); @override State<CalcPage> createState()=>_CalcPageState(); }
class _CalcPageState extends State<CalcPage>{late final List<TextEditingController> ctrls; double result=0; @override void initState(){super.initState();ctrls=widget.labels.map((_)=>TextEditingController(text:'0')).toList();} @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.title)),body:ListView(padding:const EdgeInsets.all(16),children:[Text(widget.subtitle),const SizedBox(height:16),...List.generate(widget.labels.length,(i)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:ctrls[i],keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:widget.labels[i],border:const OutlineInputBorder())))),FilledButton(onPressed:()=>setState(()=>result=widget.compute(ctrls.map((x)=>double.tryParse(x.text)??0).toList())),child:const Text('Calculate')),const SizedBox(height:20),ResultCard(label:widget.resultLabel,value:result.toStringAsFixed(2),detail:'Calculated from your inputs') ]));}
class PercentagePage extends StatelessWidget { const PercentagePage({super.key}); @override Widget build(BuildContext c)=>CalcPage(title:'Percentage',subtitle:'Find a percentage of an amount.',labels:const ['Amount','Percentage'],compute:(x)=>x[0]*x[1]/100,resultLabel:'Result'); }
class GstPage extends StatelessWidget { const GstPage({super.key}); @override Widget build(BuildContext c)=>CalcPage(title:'GST Calculator',subtitle:'Add GST to a base amount.',labels:const ['Base amount','GST %'],compute:(x)=>x[0]*(1+x[1]/100),resultLabel:'Total'); }
class EmiPage extends StatelessWidget { const EmiPage({super.key}); @override Widget build(BuildContext c)=>CalcPage(title:'EMI Calculator',subtitle:'Estimate monthly repayment.',labels:const ['Loan amount','Annual interest %','Months'],compute:(x){final r=x[1]/1200,n=x[2];return r==0?(n==0?0:x[0]/n):x[0]*r*math.pow(1+r,n)/(math.pow(1+r,n)-1);},resultLabel:'Monthly EMI'); }
class SipPage extends StatelessWidget { const SipPage({super.key}); @override Widget build(BuildContext c)=>CalcPage(title:'SIP Calculator',subtitle:'Estimate SIP future value.',labels:const ['Monthly investment','Annual return %','Years'],compute:(x){final r=x[1]/1200,n=x[2]*12;return r==0?x[0]*n:x[0]*(math.pow(1+r,n)-1)/r*(1+r);},resultLabel:'Estimated value'); }
class FdPage extends StatelessWidget { const FdPage({super.key}); @override Widget build(BuildContext c)=>CalcPage(title:'FD Calculator',subtitle:'Estimate fixed-deposit maturity.',labels:const ['Principal','Annual interest %','Years'],compute:(x)=>x[0]*math.pow(1+x[1]/400,4*x[2]),resultLabel:'Maturity amount'); }
class SimpleInterestPage extends StatelessWidget { const SimpleInterestPage({super.key}); @override Widget build(BuildContext c)=>CalcPage(title:'Simple Interest',subtitle:'Calculate maturity amount.',labels:const ['Principal','Annual interest %','Years'],compute:(x)=>x[0]*(1+x[1]*x[2]/100),resultLabel:'Maturity amount'); }
class CompoundPage extends StatelessWidget { const CompoundPage({super.key}); @override Widget build(BuildContext c)=>CalcPage(title:'Compound Interest',subtitle:'Calculate compounded growth.',labels:const ['Principal','Annual interest %','Years','Compounds/year'],compute:(x)=>x[0]*math.pow(1+x[1]/100/x[3],x[3]*x[2]),resultLabel:'Maturity amount'); }
class RdPage extends StatelessWidget { const RdPage({super.key}); @override Widget build(BuildContext c)=>CalcPage(title:'RD Calculator',subtitle:'Estimate recurring-deposit maturity.',labels:const ['Monthly deposit','Annual interest %','Months'],compute:(x)=>x[0]*x[2]*(1+x[1]*x[2]/2400),resultLabel:'Approx. maturity'); }
class AgePage extends StatefulWidget { const AgePage({super.key}); @override State<AgePage> createState()=>_AgePageState(); }
class _AgePageState extends State<AgePage>{DateTime dob=DateTime(1990,1,1); @override Widget build(BuildContext c){final now=DateTime.now();var y=now.year-dob.year;if(DateTime(now.year,dob.month,dob.day).isAfter(now))y--;return Scaffold(appBar:AppBar(title:const Text('Age Calculator')),body:ListView(padding:const EdgeInsets.all(16),children:[ListTile(title:const Text('Date of birth'),subtitle:Text(DateFormat.yMMMd().format(dob)),onTap:()async{final d=await showDatePicker(context:c,firstDate:DateTime(1900),lastDate:DateTime.now(),initialDate:dob);if(d!=null)setState(()=>dob=d);}),ResultCard(label:'Your age',value:'$y years',detail:'Based on today') ]));}}
class BmiPage extends StatelessWidget { const BmiPage({super.key}); @override Widget build(BuildContext c)=>CalcPage(title:'BMI Calculator',subtitle:'BMI from height and weight.',labels:const ['Height (cm)','Weight (kg)'],compute:(x){final m=x[0]/100;return m<=0?0:x[1]/(m*m);},resultLabel:'BMI'); }
class DateDiffPage extends StatefulWidget { const DateDiffPage({super.key}); @override State<DateDiffPage> createState()=>_DateDiffPageState(); }
class _DateDiffPageState extends State<DateDiffPage>{DateTime a=DateTime.now(),b=DateTime.now().add(const Duration(days:30)); @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Date Difference')),body:ListView(padding:const EdgeInsets.all(16),children:[ListTile(title:const Text('Start date'),subtitle:Text(DateFormat.yMMMd().format(a)),onTap:()=>pick(true)),ListTile(title:const Text('End date'),subtitle:Text(DateFormat.yMMMd().format(b)),onTap:()=>pick(false)),ResultCard(label:'Difference',value:'${b.difference(a).inDays.abs()} days',detail:'Absolute calendar-day difference') ]));} Future<void> pick(bool start)async{final d=await showDatePicker(context:context,firstDate:DateTime(1900),lastDate:DateTime(2100),initialDate:start?a:b);if(d!=null)setState(()=>start?a=d:b=d);}}
class FuelPage extends StatelessWidget { const FuelPage({super.key}); @override Widget build(BuildContext c)=>CalcPage(title:'Fuel Cost Calculator',subtitle:'Estimate trip fuel cost.',labels:const ['Distance (km)','Mileage (km/l)','Fuel price/litre'],compute:(x)=>x[1]<=0?0:x[0]/x[1]*x[2],resultLabel:'Trip cost'); }
