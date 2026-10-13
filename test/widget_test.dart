import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/data.dart';

void main() {
  test('schedule follows the 5-day PPL-UL split with rest on Thu and Sun', () {
    expect(schedule.length, 7);
    expect(schedule.map((d) => d.isRest).toList(),
        [false, false, false, true, false, false, true]);
  });
}
