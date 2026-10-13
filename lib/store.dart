import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
int dayIndex(DateTime d) => (d.weekday + 6) % 7; // Mon = 0

class Meal {
  final String text;
  final double kcal, p, c, f;
  Meal(this.text, this.kcal, this.p, this.c, this.f);
  Map<String, dynamic> toJson() => {'t': text, 'k': kcal, 'p': p, 'c': c, 'f': f};
  factory Meal.fromJson(Map<String, dynamic> j) =>
      Meal(j['t'], (j['k'] as num).toDouble(), (j['p'] as num).toDouble(),
          (j['c'] as num).toDouble(), (j['f'] as num).toDouble());
}

class AppState extends ChangeNotifier {
  static const _k = 'gym_app.v1';
  late SharedPreferences _prefs;

  Map<String, String> profile = {
    'name': '', 'height': '', 'age': '', 'goalKcal': '2800', 'goalProtein': '160', 'apiKey': ''
  };
  Map<String, int> done = {}; // 'date|day|ex' -> sets done
  Map<String, String> liftWeights = {}; // exercise -> kg
  Map<String, String> gifs = {}; // exercise -> gif url (user supplied)
  Map<String, List<Meal>> meals = {};
  Map<String, double> bodyWeight = {}; // date -> kg

  // rest timer
  int restLeft = 0;
  int restTotal = 0;
  Timer? _timer;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_k);
    if (raw == null) return;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    profile = {...profile, ...Map<String, String>.from(j['profile'] ?? {})};
    done = Map<String, int>.from(j['done'] ?? {});
    liftWeights = Map<String, String>.from(j['lw'] ?? {});
    gifs = Map<String, String>.from(j['gifs'] ?? {});
    bodyWeight = (j['bw'] as Map? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    meals = (j['meals'] as Map? ?? {}).map((k, v) => MapEntry(k as String,
        (v as List).map((e) => Meal.fromJson(Map<String, dynamic>.from(e))).toList()));
  }

  void _save() {
    _prefs.setString(
        _k,
        jsonEncode({
          'profile': profile,
          'done': done,
          'lw': liftWeights,
          'gifs': gifs,
          'bw': bodyWeight,
          'meals': meals.map((k, v) => MapEntry(k, v.map((m) => m.toJson()).toList())),
        }));
    notifyListeners();
  }

  // ---------- workout ----------
  String _dk(String date, int day, int ex) => '$date|$day|$ex';
  int setsDone(String date, int day, int ex) => done[_dk(date, day, ex)] ?? 0;

  /// Tap set [k] (0-based). Tapping the last done set undoes it. Starts rest timer when marking done.
  void toggleSet(String date, int day, int ex, int k) {
    final key = _dk(date, day, ex);
    final cur = done[key] ?? 0;
    if (cur == k + 1) {
      done[key] = k;
    } else {
      done[key] = k + 1;
      final e = schedule[day].exercises[ex];
      startRest(e.compound ? 150 : 75);
    }
    _save();
  }

  ({int done, int total}) dayProgress(String date, int day) {
    final w = schedule[day];
    var t = 0, d = 0;
    for (var i = 0; i < w.exercises.length; i++) {
      t += w.exercises[i].sets;
      d += setsDone(date, day, i).clamp(0, w.exercises[i].sets);
    }
    return (done: d, total: t);
  }

  void setLiftWeight(String ex, String v) {
    liftWeights[ex] = v;
    _save();
  }

  void setGif(String ex, String url) {
    url.trim().isEmpty ? gifs.remove(ex) : gifs[ex] = url.trim();
    _save();
  }

  // ---------- rest timer ----------
  void startRest(int secs) {
    _timer?.cancel();
    restLeft = restTotal = secs;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      restLeft--;
      if (restLeft <= 0) {
        restLeft = 0;
        t.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void addRest(int s) {
    if (restLeft > 0) {
      restLeft += s;
      restTotal += s;
      notifyListeners();
    }
  }

  void stopRest() {
    _timer?.cancel();
    restLeft = 0;
    notifyListeners();
  }

  // ---------- profile / body weight ----------
  void setProfile(String k, String v) {
    profile[k] = v;
    _save();
  }

  void logBodyWeight(double kg) {
    bodyWeight[dateKey(DateTime.now())] = kg;
    _save();
  }

  double? get latestWeight {
    if (bodyWeight.isEmpty) return null;
    final ks = bodyWeight.keys.toList()..sort();
    return bodyWeight[ks.last];
  }

  void resetAll() {
    _prefs.remove(_k);
    profile.updateAll((k, v) => k == 'goalKcal' ? '2800' : k == 'goalProtein' ? '160' : '');
    done.clear();
    liftWeights.clear();
    gifs.clear();
    meals.clear();
    bodyWeight.clear();
    notifyListeners();
  }

  // ---------- food ----------
  List<Meal> mealsOn(String date) => meals[date] ?? [];
  ({double kcal, double p, double c, double f}) totals(String date) {
    double k = 0, p = 0, c = 0, f = 0;
    for (final m in mealsOn(date)) {
      k += m.kcal; p += m.p; c += m.c; f += m.f;
    }
    return (kcal: k, p: p, c: c, f: f);
  }

  void deleteMeal(String date, int i) {
    meals[date]!.removeAt(i);
    _save();
  }

  /// Returns a note for the UI (e.g. fallback reason), or null on clean success. Throws on unrecognised food.
  Future<String?> analyzeAndLog(String text) async {
    String? note;
    Meal? meal;
    if (profile['apiKey']!.isNotEmpty) {
      try {
        meal = await _askClaude(text);
      } catch (e) {
        note = 'AI failed ($e), used offline estimate.';
      }
    }
    meal ??= _localEstimate(text);
    if (meal == null) {
      throw 'Could not recognise food. Try simpler words or add an API key in Profile.';
    }
    (meals[dateKey(DateTime.now())] ??= []).add(meal);
    _save();
    return note;
  }

  Future<Meal> _askClaude(String text) async {
    final res = await http.post(Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'content-type': 'application/json',
          'x-api-key': profile['apiKey']!,
          'anthropic-version': '2023-06-01',
          'anthropic-dangerous-direct-browser-access': 'true',
        },
        body: jsonEncode({
          'model': 'claude-haiku-5-5',
          'max_tokens': 200,
          'system':
              'You are a nutrition estimator. Reply with ONLY compact JSON: {"kcal":number,"p":number,"c":number,"f":number} (protein/carbs/fat in grams) for the total meal described. Assume typical Bangladeshi/South Asian portion sizes when unspecified.',
          'messages': [
            {'role': 'user', 'content': text}
          ],
        }));
    if (res.statusCode != 200) throw 'API ${res.statusCode}';
    final body = jsonDecode(res.body);
    final raw = body['content'][0]['text'] as String;
    final j = jsonDecode(RegExp(r'\{[\s\S]*\}').firstMatch(raw)!.group(0)!);
    double n(String k) => (j[k] as num).toDouble();
    return Meal(text, n('kcal'), n('p'), n('c'), n('f'));
  }

  Meal? _localEstimate(String text) {
    var rest = text.toLowerCase();
    double k = 0, p = 0, c = 0, f = 0;
    var found = false;
    final names = foods.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final name in names) {
      final re = RegExp(
          r'(\d+(?:\.\d+)?)?\s*(?:x|pcs?|bowls?|cups?|slices?|scoops?)?\s*\b' + name + r's?\b');
      rest = rest.replaceAllMapped(re, (m) {
        final q = m.group(1) == null ? 1.0 : double.parse(m.group(1)!);
        final v = foods[name]!;
        k += v[0] * q; p += v[1] * q; c += v[2] * q; f += v[3] * q;
        found = true;
        return ' ';
      });
    }
    return found ? Meal(text, k, p, c, f) : null;
  }
}
