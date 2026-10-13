import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'data.dart';
import 'store.dart';

const kAccent = Color(0xFFFF5A36);
const kOk = Color(0xFF2ECC71);
const kCard = Color(0xFF1A1D24);
const kCard2 = Color(0xFF232732);

final state = AppState();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await state.load();
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'IronPlan Gym',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F1115),
          colorScheme: const ColorScheme.dark(primary: kAccent, surface: kCard),
          cardTheme: CardThemeData(
            color: kCard,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF2C3140))),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: kCard2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xFF14171D)),
        ),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  int viewDay = dayIndex(DateTime.now());

  void goTo(int t, [int? day]) => setState(() {
        tab = t;
        if (day != null) viewDay = day;
      });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final pages = [
          DashboardPage(goTo: goTo),
          ExercisePage(day: viewDay, onDay: (d) => setState(() => viewDay = d)),
          const FoodPage(),
          const ProfilePage(),
        ];
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: pages[tab],
              ),
            ),
          ),
          bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
            if (state.restLeft > 0) const RestBar(),
            NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (i) => goTo(i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Exercise'),
                NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Food AI'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- helpers
List<String> weekDates() {
  final n = DateTime.now();
  final mon = DateTime(n.year, n.month, n.day).subtract(Duration(days: dayIndex(n)));
  return List.generate(7, (i) => dateKey(mon.add(Duration(days: i))));
}

Widget page(String title, List<Widget> children) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...children,
      ],
    );

Widget pad(Widget child, [double v = 14]) => Padding(padding: EdgeInsets.all(v), child: child);
const mut = TextStyle(color: Color(0xFF8B93A5), fontSize: 13);

Widget progress(double v, {Color? color}) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: v.clamp(0, 1).toDouble(),
          minHeight: 8,
          backgroundColor: kCard2,
          color: color ?? (v >= 1 ? kOk : kAccent),
        ),
      ),
    );

class RestBar extends StatelessWidget {
  const RestBar({super.key});
  @override
  Widget build(BuildContext context) {
    final m = state.restLeft ~/ 60, s = state.restLeft % 60;
    return Container(
      color: kCard2,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(children: [
        const Icon(Icons.timer_outlined, color: kAccent),
        const SizedBox(width: 10),
        Text('Rest  $m:${s.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(onPressed: () => state.addRest(30), child: const Text('+30s')),
        IconButton(onPressed: state.stopRest, icon: const Icon(Icons.close)),
      ]),
    );
  }
}

// ---------------------------------------------------------------- Dashboard
class DashboardPage extends StatelessWidget {
  final void Function(int tab, [int? day]) goTo;
  const DashboardPage({super.key, required this.goTo});

  @override
  Widget build(BuildContext context) {
    final t = dayIndex(DateTime.now());
    final today = dateKey(DateTime.now());
    final day = schedule[t];
    final pr = state.dayProgress(today, t);
    final tot = state.totals(today);
    final gk = double.tryParse(state.profile['goalKcal']!) ?? 2800;
    final gp = double.tryParse(state.profile['goalProtein']!) ?? 160;
    final wd = weekDates();

    var wkDone = 0, wkTotal = 0;
    final daySets = <double>[];
    for (var i = 0; i < 7; i++) {
      final p = state.dayProgress(wd[i], i);
      daySets.add(p.done.toDouble());
      if (!schedule[i].isRest) {
        wkTotal++;
        if (p.total > 0 && p.done >= p.total) wkDone++;
      }
    }
    final name = state.profile['name']!;

    return page(name.isEmpty ? 'Welcome 👋' : 'Hi, $name 👋', [
      Card(
        child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Today · ${day.short}', style: mut),
          Row(children: [
            Text(day.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const Spacer(),
            Flexible(child: Text(day.focus, style: mut, textAlign: TextAlign.right)),
          ]),
          if (day.isRest)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Rest day. Sleep well, eat enough protein, a light walk is fine.', style: mut))
          else ...[
            progress(pr.total == 0 ? 0 : pr.done / pr.total),
            const SizedBox(height: 6),
            Text('${pr.done}/${pr.total} sets done', style: mut),
            const SizedBox(height: 10),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: () => goTo(1, t),
                    child: Text(pr.done > 0 ? 'Continue workout' : 'Start workout'))),
          ],
        ])),
      ),
      Row(children: [
        Expanded(
            child: Card(
                child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Weekly workouts', style: mut),
          Text('$wkDone/$wkTotal', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          progress(wkTotal == 0 ? 0 : wkDone / wkTotal),
        ])))),
        const SizedBox(width: 10),
        Expanded(
            child: Card(
                child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Body weight', style: mut),
          Text(state.latestWeight == null ? '-- kg' : '${state.latestWeight!.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        ])))),
      ]),
      Card(
        child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Nutrition today', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton(onPressed: () => goTo(2), child: const Text('Log food →')),
          ]),
          Text('Calories ${tot.kcal.round()} / ${gk.round()}', style: mut),
          progress(tot.kcal / gk, color: kAccent),
          const SizedBox(height: 10),
          Text('Protein ${tot.p.round()} / ${gp.round()} g', style: mut),
          progress(tot.p / gp),
        ])),
      ),
      Card(
        child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sets completed this week', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(height: 150, child: WeekChart(values: daySets, todayIdx: t)),
        ])),
      ),
      Card(
        child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Body weight trend', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const BodyWeightChart(),
          const SizedBox(height: 8),
          const LogWeightRow(),
        ])),
      ),
    ]);
  }
}

class WeekChart extends StatelessWidget {
  final List<double> values;
  final int todayIdx;
  const WeekChart({super.key, required this.values, required this.todayIdx});
  @override
  Widget build(BuildContext context) {
    return BarChart(BarChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      alignment: BarChartAlignment.spaceAround,
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(schedule[v.toInt()].short, style: mut)),
          ),
        ),
      ),
      barGroups: [
        for (var i = 0; i < 7; i++)
          BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: values[i],
              width: 18,
              borderRadius: BorderRadius.circular(4),
              color: i == todayIdx ? kAccent : const Color(0xFF5B6275),
            )
          ]),
      ],
    ));
  }
}

class BodyWeightChart extends StatelessWidget {
  const BodyWeightChart({super.key});
  @override
  Widget build(BuildContext context) {
    final keys = state.bodyWeight.keys.toList()..sort();
    if (keys.length < 2) {
      return const SizedBox(
          height: 60,
          child: Center(child: Text('Log your weight on 2+ days to see the trend.', style: mut)));
    }
    final last = keys.length > 30 ? keys.sublist(keys.length - 30) : keys;
    final spots = [for (var i = 0; i < last.length; i++) FlSpot(i.toDouble(), state.bodyWeight[last[i]]!)];
    return SizedBox(
      height: 150,
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0), style: mut))),
        ),
        lineBarsData: [
          LineChartBarData(
              spots: spots,
              isCurved: true,
              color: kAccent,
              barWidth: 3,
              dotData: const FlDotData(show: true)),
        ],
      )),
    );
  }
}

class LogWeightRow extends StatefulWidget {
  const LogWeightRow({super.key});
  @override
  State<LogWeightRow> createState() => _LogWeightRowState();
}

class _LogWeightRowState extends State<LogWeightRow> {
  final c = TextEditingController();
  void submit() {
    final v = double.tryParse(c.text.trim());
    if (v == null || v <= 0) return;
    state.logBodyWeight(v);
    c.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: "Today's weight (kg)", isDense: true),
          onSubmitted: (_) => submit(),
        )),
        const SizedBox(width: 10),
        FilledButton(onPressed: submit, child: const Text('Log')),
      ]);
}

// ---------------------------------------------------------------- Exercise
class ExercisePage extends StatelessWidget {
  final int day;
  final void Function(int) onDay;
  const ExercisePage({super.key, required this.day, required this.onDay});

  @override
  Widget build(BuildContext context) {
    final w = schedule[day];
    final today = dayIndex(DateTime.now());
    final date = weekDates()[day];
    return page('Exercise', [
      SizedBox(
        height: 56,
        child: Row(children: [
          for (var i = 0; i < 7; i++)
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onDay(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: i == day ? kAccent : kCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: i == today && i != day ? kAccent : const Color(0xFF2C3140)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(schedule[i].short, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(schedule[i].isRest ? 'Rest' : schedule[i].name.split(' ').first,
                        style: TextStyle(fontSize: 9, color: i == day ? Colors.white : const Color(0xFF8B93A5)),
                        overflow: TextOverflow.clip,
                        maxLines: 1),
                  ]),
                ),
              ),
            )),
        ]),
      ),
      const SizedBox(height: 12),
      Card(
        child: pad(Row(children: [
          Text(w.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const Spacer(),
          Flexible(child: Text(w.focus, style: mut, textAlign: TextAlign.right)),
        ])),
      ),
      if (w.isRest)
        Card(
          child: pad(const Column(children: [
            Text('😴 Rest Day', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Full systemic recovery. Muscles grow while you rest: sleep 7–9 hrs and hit your protein.',
                style: mut, textAlign: TextAlign.center),
          ]), 28),
        )
      else
        for (var i = 0; i < w.exercises.length; i++)
          ExerciseCard(key: ValueKey('$day-$i'), day: day, index: i, date: date),
      const SizedBox(height: 8),
      const Text('Progression & Load Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Card(
        child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final r in rules) ...[
            Text(r[0], style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(r[1], style: mut),
            const SizedBox(height: 12),
          ],
        ])),
      ),
    ]);
  }
}

class ExerciseCard extends StatefulWidget {
  final int day, index;
  final String date;
  const ExerciseCard({super.key, required this.day, required this.index, required this.date});
  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  late final TextEditingController kg;
  bool showGif = false;
  Exercise get e => schedule[widget.day].exercises[widget.index];

  @override
  void initState() {
    super.initState();
    kg = TextEditingController(text: state.liftWeights[e.name] ?? '');
  }

  Future<void> editGif() async {
    final c = TextEditingController(text: state.gifs[e.name] ?? '');
    final url = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Exercise GIF link'),
              content: TextField(
                  controller: c,
                  decoration: const InputDecoration(hintText: 'https://.../exercise.gif')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Save')),
              ],
            ));
    if (url != null) {
      state.setGif(e.name, url);
      setState(() => showGif = url.trim().isNotEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = state.setsDone(widget.date, widget.day, widget.index);
    final gif = state.gifs[e.name];
    return Card(
      child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('${widget.index + 1}. ${e.name}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
          if (e.compound)
            const Chip(label: Text('Compound', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
          IconButton(
            tooltip: 'GIF',
            icon: Icon(Icons.play_circle_outline, color: gif == null ? const Color(0xFF8B93A5) : kAccent),
            onPressed: () => gif == null ? editGif() : setState(() => showGif = !showGif),
          ),
        ]),
        Text(e.target, style: mut),
        const SizedBox(height: 8),
        Row(children: [
          Text('${e.sets} × ${e.reps}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          const Text('kg ', style: mut),
          SizedBox(
              width: 84,
              child: TextField(
                controller: kg,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(isDense: true, hintText: '0'),
                onChanged: (v) => state.setLiftWeight(e.name, v),
              )),
        ]),
        if (e.form.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('💡 ${e.form}', style: mut)),
        if (showGif && gif != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(gif,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Text('GIF could not be loaded.', style: mut))),
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: editGif, child: const Text('Change GIF'))),
        ],
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var k = 0; k < e.sets; k++)
            SizedBox(
              width: 46,
              height: 46,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: k < n ? kOk : kCard2,
                    foregroundColor: k < n ? const Color(0xFF06210F) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => state.toggleSet(widget.date, widget.day, widget.index, k),
                child: Text('${k + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ])),
    );
  }
}

// ---------------------------------------------------------------- Food AI
class FoodPage extends StatefulWidget {
  const FoodPage({super.key});
  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  final c = TextEditingController();
  bool busy = false;
  String msg = '';

  Future<void> analyze() async {
    final text = c.text.trim();
    if (text.isEmpty) return;
    setState(() {
      busy = true;
      msg = '';
    });
    try {
      final note = await state.analyzeAndLog(text);
      c.clear();
      msg = note ?? '';
    } catch (e) {
      msg = '$e';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final today = dateKey(DateTime.now());
    final list = state.mealsOn(today);
    final t = state.totals(today);
    final hasKey = state.profile['apiKey']!.isNotEmpty;
    return page('Food AI', [
      Card(
        child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Describe what you ate. AI estimates calories & macros.', style: mut),
          const SizedBox(height: 8),
          TextField(
              controller: c,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'e.g. 3 eggs, 2 roti, 1 bowl dal, 1 banana')),
          const SizedBox(height: 10),
          SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: busy ? null : analyze, child: Text(busy ? 'Analyzing…' : 'Analyze & Log'))),
          const SizedBox(height: 6),
          Text(hasKey ? 'Using Claude AI.' : 'Offline estimator in use. Add an Anthropic API key in Profile for smarter AI results.', style: mut),
          if (msg.isNotEmpty) Text(msg, style: const TextStyle(color: kAccent, fontSize: 13)),
        ])),
      ),
      Card(
        child: pad(Wrap(spacing: 28, runSpacing: 10, children: [
          _stat('Calories', t.kcal.round().toString()),
          _stat('Protein', '${t.p.round()} g'),
          _stat('Carbs', '${t.c.round()} g'),
          _stat('Fat', '${t.f.round()} g'),
        ])),
      ),
      const Text("Today's meals", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Card(
        child: list.isEmpty
            ? pad(const Text('Nothing logged yet.', style: mut))
            : Column(children: [
                for (var i = 0; i < list.length; i++)
                  ListTile(
                    title: Text(list[i].text),
                    subtitle: Text(
                        '${list[i].kcal.round()} kcal · P ${list[i].p.round()} · C ${list[i].c.round()} · F ${list[i].f.round()}',
                        style: mut),
                    trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => state.deleteMeal(today, i)),
                  ),
              ]),
      ),
    ]);
  }

  Widget _stat(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: mut),
        Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      ]);
}

// ---------------------------------------------------------------- Profile
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget field(String k, String label, {bool number = false, bool secret = false, String hint = ''}) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextFormField(
          initialValue: state.profile[k],
          obscureText: secret,
          keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(labelText: label, hintText: hint),
          onChanged: (v) => state.profile[k] = v, // saved on blur/leave via setProfile below
          onFieldSubmitted: (v) => state.setProfile(k, v),
          onTapOutside: (_) => state.setProfile(k, state.profile[k]!),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return page('Profile', [
      Card(child: pad(Column(children: [
        field('name', 'Name'),
        field('height', 'Height (cm)', number: true),
        field('age', 'Age', number: true),
      ]))),
      Card(child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Daily goals', style: TextStyle(fontWeight: FontWeight.w700)),
        field('goalKcal', 'Calories (kcal)', number: true),
        field('goalProtein', 'Protein (g)', number: true),
      ]))),
      Card(child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Body weight', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const LogWeightRow(),
      ]))),
      Card(child: pad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('AI settings', style: TextStyle(fontWeight: FontWeight.w700)),
        field('apiKey', 'Anthropic API key (optional)', secret: true, hint: 'sk-ant-...'),
        const SizedBox(height: 8),
        const Text('Stored only on this device and used for Food AI. Without it, a built-in offline estimator is used.', style: mut),
      ]))),
      OutlinedButton(
        onPressed: () async {
          final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                    title: const Text('Delete all data?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ));
          if (ok == true) state.resetAll();
        },
        child: const Text('Reset all data'),
      ),
    ]);
  }
}
