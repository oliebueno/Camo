import 'package:flutter_test/flutter_test.dart';
import 'package:camo_precios/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Renderiza la aplicación CamoPreciosApp
    await tester.pumpWidget(const CamoPreciosApp());

    // Verifica que el título de la barra de navegación aparezca
    expect(find.text('Camo Precios'), findsOneWidget);
  });
}
