class Exercise {
  final String name, target, form;
  final int sets;
  final String reps;
  final bool compound;
  const Exercise(this.name, this.target, this.sets, this.reps,
      {this.form = '', this.compound = false});
}

class WorkoutDay {
  final String short, name, focus;
  final List<Exercise> exercises;
  const WorkoutDay(this.short, this.name, this.focus, [this.exercises = const []]);
  bool get isRest => exercises.isEmpty;
}

// Index 0 = Monday
const schedule = <WorkoutDay>[
  WorkoutDay('Mon', 'Push', 'Chest, Front/Side Delts, Triceps', [
    Exercise('Flat Barbell Bench Press', 'Mid/Lower Chest', 3, '6–8',
        compound: true,
        form: 'Retract scapulae, touch lower sternum, press in a slight arc back over shoulders.'),
    Exercise('Incline Dumbbell Press (30°)', 'Upper Chest / Clavicular Head', 3, '8–10',
        compound: true,
        form: 'Control the descent; deep stretch at the bottom without flaring elbows past 75°.'),
    Exercise('Cable Chest Flyes', 'Pectoral Sternal Adduction', 3, '12–15',
        form: 'Keep a slight bend in the elbows, squeeze hard at peak contraction for 1 second.'),
    Exercise('Seated Dumbbell Overhead Press', 'Anterior Deltoid', 3, '8–10', compound: true),
    Exercise('Cable/Dumbbell Lateral Raises', 'Lateral Deltoid / Width', 4, '12–15'),
    Exercise('Rope Triceps Pushdowns', 'Triceps Lateral & Medial Heads', 3, '10–12'),
    Exercise('Overhead Cable Triceps Extension', 'Triceps Long Head', 3, '12–15'),
  ]),
  WorkoutDay('Tue', 'Pull', 'Lats, Upper Back, Rear Delts, Biceps', [
    Exercise('Barbell Bent-Over / Chest-Supported Row', 'Rhomboids & Mid-Traps', 3, '6–8',
        compound: true,
        form: 'Pull toward the lower rib cage with torso at ~45°, driving elbows behind the body.'),
    Exercise('Lat Pulldown (Neutral/Wide Grip)', 'Latissimus Dorsi / Width', 3, '8–10',
        compound: true,
        form: 'Initiate by depressing scapulae; pull elbows down toward hips, not backward.'),
    Exercise('Single-Arm Dumbbell Row', 'Lower Lat Focus (each side)', 3, '10–12'),
    Exercise('Face Pulls (external rotation)', 'Rear Delts & Rotator Cuff', 4, '15',
        form: 'Pull rope toward eye level while spreading hands apart and rotating wrists back.'),
    Exercise('Incline Dumbbell Curl', 'Biceps Long Head Stretch', 3, '10–12'),
    Exercise('Standing EZ-Bar / Hammer Curl', 'Brachialis & Brachioradialis', 3, '10–12'),
  ]),
  WorkoutDay('Wed', 'Legs & Abs', 'Quad Emphasis', [
    Exercise('Barbell Back Squat / Hack Squat', 'Quads & Glutes', 4, '6–8',
        compound: true,
        form: 'Knees track toes, hit parallel or below, drive through whole foot.'),
    Exercise('Romanian Deadlift (RDL)', 'Hamstrings & Glutes', 3, '8–10',
        compound: true,
        form: 'Soft bend in knees, push hips back until hamstrings reach full tension; flat spine.'),
    Exercise('Walking Dumbbell Lunges', 'Quads & Glute Medius (per leg)', 3, '10'),
    Exercise('Leg Extensions', 'Rectus Femoris — pause at top', 3, '12–15'),
    Exercise('Standing Calf Raises', 'Gastrocnemius — 2s dead stop at bottom', 4, '10–12'),
    Exercise('Hanging Leg/Knee Raises', 'Rectus Abdominis / Core', 3, '12–15'),
  ]),
  WorkoutDay('Thu', 'Rest', 'Full Systemic Recovery'),
  WorkoutDay('Fri', 'Upper Body', 'Balance & Hypertrophy', [
    Exercise('Incline Barbell Bench Press', 'Upper Chest', 3, '8–10', compound: true),
    Exercise('Neutral-Grip Pull-ups / Lat Pulldowns', 'Lats & Biceps', 3, '8–10', compound: true),
    Exercise('Seated Cable Row', 'Mid-Back & Upper Lats', 3, '10–12'),
    Exercise('Dumbbell Flat Press / Weighted Dips', 'Chest & Triceps', 3, '10–12'),
    Exercise('Lean-Away Cable Lateral Raises', 'Lateral Deltoid', 4, '12–15'),
    Exercise('Rope Pushdown / Skull Crushers SS Preacher Curl', 'Superset: triceps + biceps', 3, '10–12 each'),
  ]),
  WorkoutDay('Sat', 'Lower Body', 'Posterior Chain Emphasis', [
    Exercise('Deadlift (Conventional / Trap Bar)', 'Posterior Chain & Systemic Strength', 3, '5',
        compound: true),
    Exercise('Bulgarian Split Squats', 'Quads, Glutes & Adductors (per leg)', 3, '8–10'),
    Exercise('Lying / Seated Leg Curls', 'Hamstrings Knee-Flexion', 3, '10–12'),
    Exercise('Leg Press (high & wide feet)', 'Glutes & Hamstrings', 3, '10–12'),
    Exercise('Seated Calf Raises', 'Soleus', 3, '15'),
    Exercise('Cable Woodchoppers / Pallof Press', 'Obliques & Core Anti-Rotation (per side)', 3, '12'),
  ]),
  WorkoutDay('Sun', 'Rest', 'Full Systemic Recovery'),
];

const rules = <List<String>>[
  ['Proximity to failure',
    'Stop 1–2 reps short of failure (1–2 RIR) on all compound barbell lifts. Use failure (0 RIR) only on the final set of isolation exercises (curls, lateral raises, leg extensions).'],
  ['Rest periods',
    'Rest 2–3 minutes between heavy compound sets (Squat, Bench, Deadlift, Rows) and 60–90 seconds between isolation movements.'],
  ['Overload rule',
    'Keep weights identical across all sets of an exercise. Once you hit the top rep count across all sets with pristine technique, add 2.5 kg (5 lbs) to upper-body movements or 5 kg (10 lbs) to lower-body movements.'],
];

/// Offline fallback: per serving [kcal, protein, carbs, fat]
const foods = <String, List<double>>{
  'egg': [78, 6, 0.6, 5], 'rice': [205, 4, 45, 0.4], 'roti': [100, 3, 18, 2],
  'chicken breast': [165, 31, 0, 3.6], 'chicken': [165, 31, 0, 3.6],
  'dal': [150, 9, 20, 3], 'fish': [140, 22, 0, 5], 'beef': [250, 26, 0, 15],
  'milk': [120, 8, 12, 5], 'banana': [105, 1.3, 27, 0.4], 'apple': [95, 0.5, 25, 0.3],
  'oats': [150, 5, 27, 3], 'bread': [80, 3, 15, 1], 'paneer': [265, 18, 1.2, 20],
  'potato': [160, 4, 37, 0.2], 'whey': [120, 24, 3, 1.5],
  'peanut butter': [190, 7, 7, 16], 'yogurt': [100, 10, 6, 3], 'curd': [100, 10, 6, 3],
  'khichuri': [300, 10, 50, 6], 'vegetable': [60, 3, 10, 1], 'salad': [40, 2, 8, 0.5],
  'biryani': [450, 18, 55, 16], 'burger': [500, 25, 40, 25], 'pizza': [285, 12, 36, 10],
};
