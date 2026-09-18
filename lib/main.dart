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
  ThemeMode _mode = ThemeMode.system;
  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _mode = ThemeMode.values.firstWhere((e) => e.name == (p.getString('theme') ?? 'system'), orElse: () => ThemeMode.system);
      _haptics = p.getBool('haptics') ?? true;
    });
  }

  Future<void> _setTheme(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('theme', mode.name);
    if (mounted) setState(() => _mode = mode);
  }

  Future<void> _setHaptics(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('haptics', value);
    if (mounted) setState(() => _haptics = value);
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F46E5);
    final light = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    final dark = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'All-in-One Calculator',
      themeMode: _mode,
      theme: ThemeData(useMaterial3: true, colorScheme: light, scaffoldBackgroundColor: const Color(0xFFF7F7FB), cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0)),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: dark, scaffoldBackgroundColor: const Color(0xFF0F1015), cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0)),
      home: HomeScreen(haptics: _haptics, onHapticsChanged: _setHaptics, themeMode: _mode, onThemeChanged: _setTheme),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool haptics;
  final ValueChanged<bool> onHapticsChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  const HomeScreen({super.key, required this.haptics, required this.onHapticsChanged, required this.themeMode, required this.onThemeChanged});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _pages = const [CalculatorPage(), FinancePage(), ConverterPage(), ToolsPage()];
  final _titles = const ['Calculator', 'Finance', 'Convert', 'Tools'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index], style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(tooltip: 'Settings', onPressed: () => _showSettings(context), icon: const Icon(Icons.settings_outlined))],
      ),
      body: SafeArea(child: IndexedStack(index: _index, children: _pages)),
      bottomSheet: const BannerAdWidget(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate), label: 'Calculator'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Finance'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), selectedIcon: Icon(Icons.swap_horiz), label: 'Convert'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Tools'),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheet) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(alignment: Alignment.centerLeft, child: Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          SwitchListTile(value: widget.haptics, onChanged: (v) { widget.onHapticsChanged(v); setSheet(() {}); }, title: const Text('Haptic feedback'), subtitle: const Text('Gentle feedback on calculator keys'), contentPadding: EdgeInsets.zero),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Theme'), subtitle: Text(widget.themeMode.name[0].toUpperCase() + widget.themeMode.name.substring(1)), trailing: DropdownButton<ThemeMode>(value: widget.themeMode, underline: const SizedBox.shrink(), items: const [DropdownMenuItem(value: ThemeMode.system, child: Text('System')), DropdownMenuItem(value: ThemeMode.light, child: Text('Light')), DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark'))], onChanged: (v) { if (v != null) { widget.onThemeChanged(v); setSheet(() {}); } })),
          const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy-first design'), subtitle: Text('Calculations stay on your device. No account is required.')),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.tune), title: const Text('Ad privacy options'), subtitle: const Text('Manage available advertising consent choices.'), onTap: () => AdsService.instance.showPrivacyOptions()),
          const SizedBox(height: 4),
          const Text('All-in-One Calculator • v1.5.0', style: TextStyle(fontSize: 12)),
        ]),
      )),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});
  @override State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _display = '0';
  double? _first;
  String? _op;
  bool _fresh = true;
  final List<String> _history = [];

  void _tap(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == 'C') { _display = '0'; _first = null; _op = null; _fresh = true; return; }
      if (key == '⌫') { if (_display.length <= 1 || (_display.startsWith('-') && _display.length == 2)) _display = '0'; else _display = _display.substring(0, _display.length - 1); return; }
      if (key == '±') { if (_display != '0') _display = _display.startsWith('-') ? _display.substring(1) : '-$_display'; return; }
      if (key == '%') { final v = double.tryParse(_display) ?? 0; _display = _fmt(v / 100); return; }
      if ('0123456789.'.contains(key)) {
        if (_fresh) { _display = key == '.' ? '0.' : key; _fresh = false; }
        else if (key == '.' && _display.contains('.')) {} else _display += key;
        return;
      }
      if ('+-×÷'.contains(key)) {
        final v = double.tryParse(_display) ?? 0;
        if (_first != null && _op != null && !_fresh) _calculate(v);
        else _first = v;
        _op = key; _fresh = true; return;
      }
      if (key == '=') {
        if (_first != null && _op != null) { final v = double.tryParse(_display) ?? 0; _calculate(v); _op = null; _first = null; _fresh = true; }
      }
    });
  }

  void _calculate(double second) {
    final a = _first ?? 0; final op = _op ?? '+';
    double? result;
    switch (op) { case '+': result = a + second; break; case '-': result = a - second; break; case '×': result = a * second; break; case '÷': if (second != 0) result = a / second; break; }
    if (result == null || result.isNaN || result.isInfinite) { _display = 'Error'; } else { _display = _fmt(result); _history.insert(0, '${_fmt(a)} $op ${_fmt(second)} = $_display'); if (_history.length > 20) _history.removeLast(); }
  }

  String _fmt(double n) { if (n == n.roundToDouble()) return NumberFormat('#,##0').format(n); return NumberFormat('#,##0.##########').format(n); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final keys = [['C', '⌫', '%', '÷'], ['7','8','9','×'], ['4','5','6','−'], ['1','2','3','+'], ['±','0','.','=']];
    return Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), child: Column(children: [
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        if (_op != null && _first != null) Align(alignment: Alignment.centerRight, child: Text('${_fmt(_first!)} $_op', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 18))),
        SingleChildScrollView(scrollDirection: Axis.horizontal, reverse: true, child: Text(_display, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: -1.5))),
        const SizedBox(height: 16),
      ])),
      Expanded(flex: 2, child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 20, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.18), itemBuilder: (context, i) {
        final key = keys[i ~/ 4][i % 4];
        final special = key == '=' || ['÷','×','+','−'].contains(key);
        return FilledButton(style: FilledButton.styleFrom(backgroundColor: special ? cs.primary : cs.surfaceContainerHighest, foregroundColor: special ? cs.onPrimary : cs.onSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), onPressed: () => _tap(key == '−' ? '-' : key), child: Text(key, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)));
      })),
      const SizedBox(height: 10),
      if (_history.isNotEmpty) SizedBox(height: 34, child: Row(children: [const Icon(Icons.history, size: 18), const SizedBox(width: 6), Expanded(child: Text(_history.first, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant))), TextButton(onPressed: () => setState(_history.clear), child: const Text('Clear'))]))
    ]));
  }
}

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const SectionTitle('Popular calculators', 'Quick answers for money decisions'),
    ToolCard(icon: Icons.percent, title: 'Percentage & Discount', subtitle: 'Percentage, increase/decrease, discount price', onTap: () => _open(context, const PercentageCalculator())),
    ToolCard(icon: Icons.receipt_long_outlined, title: 'GST Calculator', subtitle: 'Add or remove GST from any amount', onTap: () => _open(context, const GstCalculator())),
    ToolCard(icon: Icons.payments_outlined, title: 'EMI Calculator', subtitle: 'Loan EMI, total interest and repayment', onTap: () => _open(context, const EmiCalculator())),
    ToolCard(icon: Icons.trending_up, title: 'SIP Calculator', subtitle: 'Estimated wealth and invested amount', onTap: () => _open(context, const SipCalculator())),
    ToolCard(icon: Icons.savings_outlined, title: 'FD Calculator', subtitle: 'Fixed deposit maturity estimate', onTap: () => _open(context, const FdCalculator())),
    ToolCard(icon: Icons.percent_outlined, title: 'Simple Interest', subtitle: 'Interest and maturity amount', onTap: () => _open(context, const SimpleInterestCalculator())),
    ToolCard(icon: Icons.functions_outlined, title: 'Compound Interest', subtitle: 'Compounding growth and maturity', onTap: () => _open(context, const CompoundInterestCalculator())),
    ToolCard(icon: Icons.account_balance_outlined, title: 'RD Calculator', subtitle: 'Recurring deposit maturity estimate', onTap: () => _open(context, const RdCalculator())),
    ToolCard(icon: Icons.work_outline, title: 'Salary Calculator', subtitle: 'Estimate annual and monthly take-home', onTap: () => _open(context, const SalaryCalculator())),
  ]);
}

class ConverterPage extends StatefulWidget { const ConverterPage({super.key}); @override State<ConverterPage> createState() => _ConverterPageState(); }
class _ConverterPageState extends State<ConverterPage> {
  String _type = 'Length'; double _value = 1; String _from = 'Meter'; String _to = 'Kilometer';
  final Map<String, List<String>> units = const {'Length':['Meter','Kilometer','Centimeter','Millimeter','Mile','Foot','Inch'], 'Weight':['Kilogram','Gram','Milligram','Pound','Ounce'], 'Temperature':['Celsius','Fahrenheit','Kelvin'], 'Area':['Square meter','Square kilometer','Square foot','Acre'], 'Data':['Byte','Kilobyte','Megabyte','Gigabyte','Terabyte']};
  double _convert() { final v=_value; if (_type=='Temperature') { double c; if(_from=='Celsius')c=v;else if(_from=='Fahrenheit')c=(v-32)*5/9;else c=v-273.15; if(_to=='Celsius')return c;if(_to=='Fahrenheit')return c*9/5+32;return c+273.15; } final factors={'Meter':1.0,'Kilometer':1000.0,'Centimeter':.01,'Millimeter':.001,'Mile':1609.344,'Foot':.3048,'Inch':.0254,'Kilogram':1.0,'Gram':.001,'Milligram':.000001,'Pound':.45359237,'Ounce':.0283495231,'Square meter':1.0,'Square kilometer':1000000.0,'Square foot':.09290304,'Acre':4046.8564224,'Byte':1.0,'Kilobyte':1024.0,'Megabyte':1048576.0,'Gigabyte':1073741824.0,'Terabyte':1099511627776.0}; return v*(factors[_from]??1)/(factors[_to]??1); }
  @override Widget build(BuildContext context) { final list=units[_type]!; if(!list.contains(_from))_from=list.first;if(!list.contains(_to))_to=list.last; return ListView(padding: const EdgeInsets.all(16), children:[const SectionTitle('Unit converter','Fast everyday conversions'), DropdownButtonFormField<String>(value:_type,decoration:const InputDecoration(labelText:'Category',border:OutlineInputBorder()),items:units.keys.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>_type=v!)),const SizedBox(height:14),TextField(keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Value',border:OutlineInputBorder()),onChanged:(v)=>_value=double.tryParse(v)??0),const SizedBox(height:14),Row(children:[Expanded(child:_drop('From',_from,list,(v)=>setState(()=>_from=v!))),const Padding(padding:EdgeInsets.symmetric(horizontal:8),child:Icon(Icons.swap_horiz)),Expanded(child:_drop('To',_to,list,(v)=>setState(()=>_to=v!)))]),const SizedBox(height:20),ResultCard(label:'Result',value:_fmt(_convert()),detail:'$_value $_from = ${_fmt(_convert())} $_to')]); }
  Widget _drop(String label,String value,List<String> list,ValueChanged<String?> onChanged)=>DropdownButtonFormField<String>(value:value,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),items:list.map((e)=>DropdownMenuItem(value:e,child:Text(e,overflow:TextOverflow.ellipsis))).toList(),onChanged:onChanged);
  String _fmt(double n)=>NumberFormat('#,##0.##########').format(n);
}

class ToolsPage extends StatelessWidget { const ToolsPage({super.key}); @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[const SectionTitle('Everyday tools','Small tools you will actually use'),ToolCard(icon:Icons.cake_outlined,title:'Age Calculator',subtitle:'Exact age in years, months and days',onTap:()=>_open(context,const AgeCalculator())),ToolCard(icon:Icons.monitor_weight_outlined,title:'BMI Calculator',subtitle:'BMI with healthy-range guidance',onTap:()=>_open(context,const BmiCalculator())),ToolCard(icon:Icons.calendar_month_outlined,title:'Date Difference',subtitle:'Days between two dates',onTap:()=>_open(context,const DateDifferenceCalculator())),ToolCard(icon:Icons.calculate_outlined,title:'Word & Character Counter',subtitle:'Count words, characters and lines',onTap:()=>_open(context,const WordCounter())),ToolCard(icon:Icons.speed_outlined,title:'Fuel Cost Calculator',subtitle:'Trip cost from distance, mileage and fuel price',onTap:()=>_open(context,const FuelCalculator()))]); }

void _open(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

class SectionTitle extends StatelessWidget { final String title,subtitle; const SectionTitle(this.title,this.subtitle,{super.key}); @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(subtitle,style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant))])); }
class ToolCard extends StatelessWidget { final IconData icon; final String title,subtitle; final VoidCallback onTap; const ToolCard({super.key,required this.icon,required this.title,required this.subtitle,required this.onTap}); @override Widget build(BuildContext context)=>Card(child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:8),leading:CircleAvatar(radius:24,child:Icon(icon)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right),onTap:onTap)); }
class ResultCard extends StatelessWidget { final String label,value,detail; const ResultCard({super.key,required this.label,required this.value,required this.detail}); @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),const SizedBox(height:6),Text(value,style:const TextStyle(fontSize:32,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(detail)]))); }

class FormPage extends StatefulWidget { final String title,subtitle; final List<Widget> fields; final Widget result; const FormPage({super.key,required this.title,required this.subtitle,required this.fields,required this.result}); @override State<FormPage> createState()=>_FormPageState(); }
class _FormPageState extends State<FormPage> { @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.title)),body:ListView(padding:const EdgeInsets.all(16),children:[Text(widget.subtitle,style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),const SizedBox(height:16),...widget.fields,const SizedBox(height:20),widget.result])); }

class PercentageCalculator extends StatefulWidget { const PercentageCalculator({super.key}); @override State<PercentageCalculator> createState()=>_PercentageCalculatorState(); }
class _PercentageCalculatorState extends State<PercentageCalculator>{final a=TextEditingController(text:'1000'),b=TextEditingController(text:'10');double result=0;void calc()=>setState(()=>result=(double.tryParse(a.text)??0)*(double.tryParse(b.text)??0)/100);@override Widget build(BuildContext c)=>FormPage(title:'Percentage',subtitle:'Find a percentage of an amount.',fields:[NumField('Amount',a),NumField('Percentage',b),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Result',value:result.toStringAsFixed(2),detail:'${b.text}% of ${a.text}') );}
class GstCalculator extends StatefulWidget { const GstCalculator({super.key}); @override State<GstCalculator> createState()=>_GstCalculatorState(); }
class _GstCalculatorState extends State<GstCalculator>{final a=TextEditingController(text:'1000'),g=TextEditingController(text:'18');double add=1180, tax=180;void calc()=>setState((){final x=double.tryParse(a.text)??0;final r=(double.tryParse(g.text)??0)/100;tax=x*r;add=x+tax;});@override Widget build(BuildContext c)=>FormPage(title:'GST Calculator',subtitle:'Add GST to a base amount.',fields:[NumField('Base amount',a),NumField('GST %',g),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Total',value:add.toStringAsFixed(2),detail:'GST: ${tax.toStringAsFixed(2)}') );}
class EmiCalculator extends StatefulWidget { const EmiCalculator({super.key}); @override State<EmiCalculator> createState()=>_EmiCalculatorState(); }
class _EmiCalculatorState extends State<EmiCalculator>{final p=TextEditingController(text:'500000'),r=TextEditingController(text:'8.5'),n=TextEditingController(text:'60');double emi=0,total=0;void calc()=>setState((){final P=double.tryParse(p.text)??0;final rate=(double.tryParse(r.text)??0)/1200;final N=double.tryParse(n.text)??0;if(rate==0){emi=N==0?0:P/N;}else{emi=(P*rate*math.pow(1+rate,N)/(math.pow(1+rate,N)-1)).toDouble();}total=emi*N;});@override Widget build(BuildContext c)=>FormPage(title:'EMI Calculator',subtitle:'Estimate monthly loan repayment.',fields:[NumField('Loan amount',p),NumField('Annual interest %',r),NumField('Tenure (months)',n),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Monthly EMI',value:emi.toStringAsFixed(2),detail:'Total repayment: ${total.toStringAsFixed(2)}') );}
class SipCalculator extends StatefulWidget { const SipCalculator({super.key}); @override State<SipCalculator> createState()=>_SipCalculatorState(); }
class _SipCalculatorState extends State<SipCalculator>{final p=TextEditingController(text:'5000'),r=TextEditingController(text:'12'),n=TextEditingController(text:'10');double future=0,invested=0;void calc()=>setState((){final m=double.tryParse(p.text)??0;final monthly=(double.tryParse(r.text)??0)/1200;final months=(double.tryParse(n.text)??0)*12;future=monthly==0?m*months:(m*((math.pow(1+monthly,months)-1)/monthly)*(1+monthly)).toDouble();invested=m*months;});@override Widget build(BuildContext c)=>FormPage(title:'SIP Calculator',subtitle:'Estimate potential SIP growth.',fields:[NumField('Monthly investment',p),NumField('Expected annual return %',r),NumField('Years',n),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Estimated value',value:future.toStringAsFixed(2),detail:'Invested: ${invested.toStringAsFixed(2)} • Estimated gain: ${(future-invested).toStringAsFixed(2)}') );}
class FdCalculator extends StatefulWidget { const FdCalculator({super.key}); @override State<FdCalculator> createState()=>_FdCalculatorState(); }
class _FdCalculatorState extends State<FdCalculator>{final p=TextEditingController(text:'100000'),r=TextEditingController(text:'7'),n=TextEditingController(text:'5');double maturity=0;void calc()=>setState((){final P=double.tryParse(p.text)??0;final rate=(double.tryParse(r.text)??0)/100;final years=double.tryParse(n.text)??0;maturity=(P*math.pow(1+rate/4,4*years)).toDouble();});@override Widget build(BuildContext c)=>FormPage(title:'FD Calculator',subtitle:'Estimate fixed-deposit maturity.',fields:[NumField('Principal',p),NumField('Annual interest %',r),NumField('Years',n),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Maturity amount',value:maturity.toStringAsFixed(2),detail:'Estimated interest: ${(maturity-(double.tryParse(p.text)??0)).toStringAsFixed(2)}') );}



class SimpleInterestCalculator extends StatefulWidget { const SimpleInterestCalculator({super.key}); @override State<SimpleInterestCalculator> createState()=>_SimpleInterestCalculatorState(); }
class _SimpleInterestCalculatorState extends State<SimpleInterestCalculator>{
  final p=TextEditingController(text:'100000'),r=TextEditingController(text:'8'),t=TextEditingController(text:'3'); double interest=24000,total=124000;
  void calc()=>setState((){final P=double.tryParse(p.text)??0;final R=double.tryParse(r.text)??0;final T=double.tryParse(t.text)??0;interest=P*R*T/100;total=P+interest;});
  @override Widget build(BuildContext c)=>FormPage(title:'Simple Interest',subtitle:'Calculate simple interest and maturity amount.',fields:[NumField('Principal',p),NumField('Annual interest %',r),NumField('Time (years)',t),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Maturity amount',value:total.toStringAsFixed(2),detail:'Interest: ${interest.toStringAsFixed(2)}') );
}

class CompoundInterestCalculator extends StatefulWidget { const CompoundInterestCalculator({super.key}); @override State<CompoundInterestCalculator> createState()=>_CompoundInterestCalculatorState(); }
class _CompoundInterestCalculatorState extends State<CompoundInterestCalculator>{
  final p=TextEditingController(text:'100000'),r=TextEditingController(text:'8'),t=TextEditingController(text:'5'),n=TextEditingController(text:'4'); double maturity=146933.28;
  void calc()=>setState((){final P=double.tryParse(p.text)??0;final R=(double.tryParse(r.text)??0)/100;final T=double.tryParse(t.text)??0;final N=double.tryParse(n.text)??4;if(N<=0){maturity=P;return;}maturity=(P*math.pow(1+R/N,N*T)).toDouble();});
  @override Widget build(BuildContext c)=>FormPage(title:'Compound Interest',subtitle:'Calculate compounded growth over time.',fields:[NumField('Principal',p),NumField('Annual interest %',r),NumField('Time (years)',t),NumField('Compounds per year',n),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Maturity amount',value:maturity.toStringAsFixed(2),detail:'Interest earned: ${(maturity-(double.tryParse(p.text)??0)).toStringAsFixed(2)}') );
}

class RdCalculator extends StatefulWidget { const RdCalculator({super.key}); @override State<RdCalculator> createState()=>_RdCalculatorState(); }
class _RdCalculatorState extends State<RdCalculator>{
  final p=TextEditingController(text:'5000'),r=TextEditingController(text:'7'),n=TextEditingController(text:'24'); double maturity=0,invested=0;
  void calc()=>setState((){final M=double.tryParse(p.text)??0;final annual=(double.tryParse(r.text)??0)/100;final months=(double.tryParse(n.text)??0).round();invested=M*months;if(months<=0){maturity=0;return;}final q=math.pow(1+annual/4,4/12).toDouble();maturity=M*((q*(math.pow(q,months)-1))/(q-1));});
  @override Widget build(BuildContext c)=>FormPage(title:'RD Calculator',subtitle:'Estimate recurring-deposit maturity.',fields:[NumField('Monthly deposit',p),NumField('Annual interest %',r),NumField('Tenure (months)',n),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Maturity amount',value:maturity.toStringAsFixed(2),detail:'Deposited: ${invested.toStringAsFixed(2)} • Interest: ${(maturity-invested).toStringAsFixed(2)}') );
}

class SalaryCalculator extends StatefulWidget { const SalaryCalculator({super.key}); @override State<SalaryCalculator> createState()=>_SalaryCalculatorState(); }
class _SalaryCalculatorState extends State<SalaryCalculator>{
  final annual=TextEditingController(text:'600000'),ded=TextEditingController(text:'50000'); double monthly=0,netAnnual=0;
  void calc()=>setState((){final a=double.tryParse(annual.text)??0;final d=double.tryParse(ded.text)??0;netAnnual=math.max(0,a-d).toDouble();monthly=netAnnual/12;});
  @override Widget build(BuildContext c)=>FormPage(title:'Salary Calculator',subtitle:'Simple annual-to-monthly take-home estimate.',fields:[NumField('Annual salary',annual),NumField('Annual deductions',ded),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Estimated monthly',value:monthly.toStringAsFixed(2),detail:'Estimated annual after deductions: ${netAnnual.toStringAsFixed(2)}') );
}

class AgeCalculator extends StatefulWidget { const AgeCalculator({super.key}); @override State<AgeCalculator> createState()=>_AgeCalculatorState(); }
class _AgeCalculatorState extends State<AgeCalculator>{DateTime dob=DateTime(1990,1,1);String out='Select date of birth';void calc(){final now=DateTime.now();int y=now.year-dob.year,m=now.month-dob.month,d=now.day-dob.day;if(d<0){m--;d+=DateTime(now.year,now.month,0).day;}if(m<0){y--;m+=12;}setState(()=>out='$y years, $m months, $d days');} @override Widget build(BuildContext c)=>FormPage(title:'Age Calculator',subtitle:'Calculate exact age from date of birth.',fields:[ListTile(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),tileColor:Theme.of(c).colorScheme.surfaceContainerHighest,title:const Text('Date of birth'),subtitle:Text(DateFormat.yMMMd().format(dob)),trailing:const Icon(Icons.calendar_month),onTap:()async{final d=await showDatePicker(context:c,firstDate:DateTime(1900),lastDate:DateTime.now(),initialDate:dob);if(d!=null)setState(()=>dob=d);}),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Your age',value:out,detail:'Based on today') );}
class BmiCalculator extends StatefulWidget { const BmiCalculator({super.key}); @override State<BmiCalculator> createState()=>_BmiCalculatorState(); }
class _BmiCalculatorState extends State<BmiCalculator>{final h=TextEditingController(text:'170'),w=TextEditingController(text:'70');double bmi=0;void calc()=>setState((){final m=(double.tryParse(h.text)??0)/100;final kg=double.tryParse(w.text)??0;bmi=m<=0?0:kg/(m*m);});String cat()=>bmi<18.5?'Underweight':bmi<25?'Healthy range':bmi<30?'Overweight':'Obesity';@override Widget build(BuildContext c)=>FormPage(title:'BMI Calculator',subtitle:'Body mass index from height and weight.',fields:[NumField('Height (cm)',h),NumField('Weight (kg)',w),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'BMI',value:bmi.toStringAsFixed(1),detail:bmi==0?'Enter your values':cat()) );}
class DateDifferenceCalculator extends StatefulWidget { const DateDifferenceCalculator({super.key}); @override State<DateDifferenceCalculator> createState()=>_DateDifferenceCalculatorState(); }
class _DateDifferenceCalculatorState extends State<DateDifferenceCalculator>{DateTime a=DateTime.now(),b=DateTime.now().add(const Duration(days:30));String out='30 days';void calc()=>setState(()=>out='${b.difference(a).inDays.abs()} days');@override Widget build(BuildContext c)=>FormPage(title:'Date Difference',subtitle:'Find the number of days between dates.',fields:[_dateTile(c,'Start date',a,(d)=>setState(()=>a=d)),_dateTile(c,'End date',b,(d)=>setState(()=>b=d)),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Difference',value:out,detail:'Absolute calendar-day difference') );}Widget _dateTile(BuildContext c,String t,DateTime d,ValueChanged<DateTime> f)=>ListTile(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),tileColor:Theme.of(c).colorScheme.surfaceContainerHighest,title:Text(t),subtitle:Text(DateFormat.yMMMd().format(d)),onTap:()async{final x=await showDatePicker(context:c,firstDate:DateTime(1900),lastDate:DateTime(2100),initialDate:d);if(x!=null)f(x);});}
class WordCounter extends StatefulWidget { const WordCounter({super.key}); @override State<WordCounter> createState()=>_WordCounterState(); }
class _WordCounterState extends State<WordCounter>{final c=TextEditingController();int words=0,chars=0,lines=0;void calc(){final t=c.text;setState((){chars=t.length;words=t.trim().isEmpty?0:t.trim().split(RegExp(r'\s+')).length;lines=t.isEmpty?0:t.split('\n').length;});}@override Widget build(BuildContext cxt)=>Scaffold(appBar:AppBar(title:const Text('Word Counter')),body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[TextField(controller:c,maxLines:10,decoration:const InputDecoration(hintText:'Paste or type text here…',border:OutlineInputBorder())),const SizedBox(height:12),FilledButton(onPressed:calc,child:const Text('Count')),const SizedBox(height:16),Row(children:[Expanded(child:ResultCard(label:'Words',value:'$words',detail:'')),const SizedBox(width:8),Expanded(child:ResultCard(label:'Characters',value:'$chars',detail:'')),const SizedBox(width:8),Expanded(child:ResultCard(label:'Lines',value:'$lines',detail:''))])])));}
class FuelCalculator extends StatefulWidget { const FuelCalculator({super.key}); @override State<FuelCalculator> createState()=>_FuelCalculatorState(); }
class _FuelCalculatorState extends State<FuelCalculator>{final d=TextEditingController(text:'100'),m=TextEditingController(text:'15'),p=TextEditingController(text:'100');double cost=0;void calc()=>setState(()=>cost=(double.tryParse(d.text)??0)/(double.tryParse(m.text)??1)*(double.tryParse(p.text)??0));@override Widget build(BuildContext c)=>FormPage(title:'Fuel Cost',subtitle:'Estimate the fuel cost of a trip.',fields:[NumField('Distance (km)',d),NumField('Mileage (km/l)',m),NumField('Fuel price / litre',p),FilledButton(onPressed:calc,child:const Text('Calculate'))],result:ResultCard(label:'Estimated fuel cost',value:cost.toStringAsFixed(2),detail:'Fuel needed: ${((double.tryParse(d.text)??0)/(double.tryParse(m.text)??1)).toStringAsFixed(2)} litres') );}

class NumField extends StatelessWidget { final String label; final TextEditingController controller; const NumField(this.label,this.controller,{super.key}); @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:controller,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()))); }