// ============================================================
//  ROTINA TEA — Ponto de entrada do aplicativo
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'provedores/provedor_tarefas.dart';
import 'provedores/provedor_tema.dart';
import 'telas/tela_splash.dart';
import 'utilitarios/constantes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // Carrega a preferência de tema salva antes de exibir qualquer
  // tela, para evitar um "flash" do tema errado na abertura do app.
  final provedorTema = ProvedorTema();
  await provedorTema.carregar();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProvedorTarefas()),
        ChangeNotifierProvider.value(value: provedorTema),
      ],
      child: const RotinaTeaApp(),
    ),
  );
}

class RotinaTeaApp extends StatelessWidget {
  const RotinaTeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<ProvedorTema>();
    return MaterialApp(
      title: 'Rotina TEA',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      locale: const Locale('pt', 'BR'),
      theme: _construirTema(CoresApp.claro, Brightness.light),
      darkTheme: _construirTema(CoresApp.escuro, Brightness.dark),
      themeMode: tema.modo,
      home: const TelaSplash(),
    );
  }

  ThemeData _construirTema(CoresApp cores, Brightness brilho) => ThemeData(
        useMaterial3: true,
        brightness: brilho,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cores.azul,
          brightness: brilho,
        ),
        scaffoldBackgroundColor: cores.fundo,
        fontFamily: 'Roboto',
        // Espaçamento extra entre linhas/letras e leve aumento de
        // tamanho ajudam a leitura para pessoas com sensibilidade
        // visual ou dificuldades de leitura — sem exagerar, para
        // não descaracterizar o layout original.
        textTheme:
            const TextTheme().apply(bodyColor: cores.texto, displayColor: cores.texto),
        visualDensity: VisualDensity.comfortable,
        splashFactory: InkRipple.splashFactory,
        appBarTheme: AppBarTheme(
          backgroundColor: cores.azul,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: cores.cartao,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        // Transições de página mais suaves e curtas evitam
        // movimento brusco na tela, que pode ser desconfortável.
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        extensions: [cores],
      );
}
