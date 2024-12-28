import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bookswapv5/main.dart';
import 'package:bookswapv5/styles/theme_notifier.dart';
import 'package:bookswapv5/auth_notifier.dart';

void main() {
  testWidgets('BookSwap home screen displays title', (WidgetTester tester) async {
    // Wrap MyApp with MultiProvider to provide the necessary dependencies
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => AuthNotifier()),  
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app shows the title "BookSwap"
    expect(find.text('BookSwap'), findsOneWidget);

    // Optionally, test navigation or other functionality here
  });
}
