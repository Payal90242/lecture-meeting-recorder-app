import 'package:flutter_test/flutter_test.dart';
import 'package:ai_voice_summarizer/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EchoGeminiApp());
    expect(find.byType(EchoGeminiApp), findsOneWidget);
  });
}
