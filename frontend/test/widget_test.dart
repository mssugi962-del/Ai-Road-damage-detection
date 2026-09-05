import 'package:ai_road_damage_detection/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows splash screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const RoadDamageApp());

    expect(find.text('AI Road Damage Detection'), findsOneWidget);
    expect(find.text('Detect • Analyze • Report'), findsOneWidget);
  });
}
