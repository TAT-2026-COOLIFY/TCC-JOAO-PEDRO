// ============================================================
//  CONSTANTES compartilhadas por toda a interface do aplicativo.
//
//  Paleta pensada para conforto sensorial: cores dessaturadas e
//  tons quentes/neutros no lugar de cores puras e muito vibrantes,
//  para reduzir o cansaço visual e o excesso de estímulo. O
//  contraste texto/fundo é mantido alto o suficiente para leitura
//  confortável (acessibilidade), mas evitando o "brilho" de preto
//  puro sobre branco puro.
// ============================================================

import 'package:flutter/material.dart';

import '../modelos/tarefa.dart';

// Cores principais — versões suavizadas/dessaturadas das cores
// vivas originais, mantendo identidade visual reconhecível.
const corAzul = Color(0xFF4A7BA6); // azul acinzentado, calmo
const corRoxo = Color(0xFF8577A8); // lavanda suave
const corVerde = Color(0xFF6FAE8B); // verde-sálvia (sucesso)
const corLaranja = Color(0xFFE0A458); // âmbar quente (prioridade média)
const corVermelha = Color(0xFFD97B7B); // coral suave (alerta/excluir)
const corAmarela = Color(0xFFE8C170); // dourado suave (pendente)

// Fundo levemente amarelado (marfim) em vez de um branco/azulado
// frio — reduz o brilho da tela e o contraste "duro" com o texto.
const corFundo = Color(0xFFF8F5F0);
const corCartao = Color(0xFFFFFFFE);

// Texto em cinza-quente escuro (não preto puro) e cinza médio para
// texto secundário, preservando boa legibilidade sem excesso de
// contraste, que pode ser desconfortável para algumas pessoas.
const corTexto = Color(0xFF3A3733);
const corTextoSecundario = Color(0xFF77726A);
const corDivisor = Color(0xFFE7E1D8);

const listaCoresPreDefinidas = [
  0xFF4A7BA6, // azul calmo
  0xFF8577A8, // lavanda
  0xFF6FAE8B, // verde-sálvia
  0xFFE0A458, // âmbar
  0xFFD97B7B, // coral
  0xFF5FA8A0, // verde-água
  0xFFC98B7A, // terracota suave
  0xFF9CAF88, // verde-oliva claro
  0xFFCE93B0, // rosa-antigo
  0xFF7B93B5, // azul-acinzentado
  0xFF8D9A93, // cinza-esverdeado
  0xFFE0B96D, // dourado suave
];

// ------------------------------------------------------------
// Tema claro/escuro
//
// As telas leem as cores da interface (fundo, texto, cartões etc.)
// através de [coresDe], que busca o conjunto adequado ao tema atual
// (claro ou escuro). As cores fixas acima continuam existindo à
// parte para usos que não dependem do tema, como a tela de abertura
// (identidade visual da marca) e a paleta de cores que o usuário
// escolhe para cada tarefa.
// ------------------------------------------------------------

@immutable
class CoresApp extends ThemeExtension<CoresApp> {
  final Color fundo;
  final Color cartao;
  final Color texto;
  final Color textoSecundario;
  final Color divisor;
  final Color azul;
  final Color roxo;
  final Color verde;
  final Color laranja;
  final Color vermelha;
  final Color amarela;

  const CoresApp({
    required this.fundo,
    required this.cartao,
    required this.texto,
    required this.textoSecundario,
    required this.divisor,
    required this.azul,
    required this.roxo,
    required this.verde,
    required this.laranja,
    required this.vermelha,
    required this.amarela,
  });

  /// Paleta clara — mesmos tons suaves definidos acima.
  static const claro = CoresApp(
    fundo: corFundo,
    cartao: corCartao,
    texto: corTexto,
    textoSecundario: corTextoSecundario,
    divisor: corDivisor,
    azul: corAzul,
    roxo: corRoxo,
    verde: corVerde,
    laranja: corLaranja,
    vermelha: corVermelha,
    amarela: corAmarela,
  );

  /// Paleta escura — fundo em cinza-marrom bem escuro (não preto
  /// puro, para não criar um contraste "duro" demais) e as mesmas
  /// cores de identidade, clareadas o suficiente para manter bom
  /// contraste sobre o fundo escuro.
  static const escuro = CoresApp(
    fundo: Color(0xFF201D19),
    cartao: Color(0xFF2C2822),
    texto: Color(0xFFEDE7DD),
    textoSecundario: Color(0xFFB6AEA0),
    divisor: Color(0xFF443F37),
    azul: Color(0xFF86ADD1),
    roxo: Color(0xFFACA1CE),
    verde: Color(0xFF8FCBA9),
    laranja: Color(0xFFE7BC81),
    vermelha: Color(0xFFE59B9B),
    amarela: Color(0xFFEDCD87),
  );

  @override
  CoresApp copyWith({
    Color? fundo,
    Color? cartao,
    Color? texto,
    Color? textoSecundario,
    Color? divisor,
    Color? azul,
    Color? roxo,
    Color? verde,
    Color? laranja,
    Color? vermelha,
    Color? amarela,
  }) =>
      CoresApp(
        fundo: fundo ?? this.fundo,
        cartao: cartao ?? this.cartao,
        texto: texto ?? this.texto,
        textoSecundario: textoSecundario ?? this.textoSecundario,
        divisor: divisor ?? this.divisor,
        azul: azul ?? this.azul,
        roxo: roxo ?? this.roxo,
        verde: verde ?? this.verde,
        laranja: laranja ?? this.laranja,
        vermelha: vermelha ?? this.vermelha,
        amarela: amarela ?? this.amarela,
      );

  @override
  CoresApp lerp(ThemeExtension<CoresApp>? other, double t) {
    if (other is! CoresApp) return this;
    return CoresApp(
      fundo: Color.lerp(fundo, other.fundo, t)!,
      cartao: Color.lerp(cartao, other.cartao, t)!,
      texto: Color.lerp(texto, other.texto, t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
      divisor: Color.lerp(divisor, other.divisor, t)!,
      azul: Color.lerp(azul, other.azul, t)!,
      roxo: Color.lerp(roxo, other.roxo, t)!,
      verde: Color.lerp(verde, other.verde, t)!,
      laranja: Color.lerp(laranja, other.laranja, t)!,
      vermelha: Color.lerp(vermelha, other.vermelha, t)!,
      amarela: Color.lerp(amarela, other.amarela, t)!,
    );
  }
}

/// Busca as cores do tema atual (claro ou escuro) a partir do
/// contexto. Usar no início de cada `build`, ex.:
/// `final cores = coresDe(context);`.
CoresApp coresDe(BuildContext context) =>
    Theme.of(context).extension<CoresApp>() ?? CoresApp.claro;

// ------------------------------------------------------------
// Ícones das tarefas
//
// Usamos emojis (em vez de ícones de linha monocromáticos) como
// pictogramas: são figuras coloridas e concretas, no estilo dos
// cartões de comunicação visual (PECS) usados em rotinas para
// pessoas autistas, e por isso costumam ser reconhecidos mais
// rápido do que símbolos abstratos de contorno.
//
// As chaves (ex.: 'tooth', 'school') são o que fica salvo em cada
// tarefa — nunca renomeie ou remova uma chave já existente, apenas
// adicione novas, para não invalidar ícones de tarefas já salvas.
// ------------------------------------------------------------

const mapaIcones = <String, String>{
  // Higiene
  'tooth': '🪥',
  'shower': '🚿',
  'wash_hands': '🧼',
  'hair': '💇',
  'toilet': '🚽',
  'nails': '💅',
  // Alimentação
  'food': '🍽️',
  'water': '💧',
  'snack': '🍎',
  'milk': '🥛',
  'cake': '🎂',
  // Escola
  'school': '🎒',
  'book': '📖',
  'homework': '✏️',
  'study': '📚',
  // Saúde
  'medicine': '💊',
  'doctor': '🩺',
  'therapy': '🧠',
  'speech': '🗣️',
  'hospital': '🏥',
  // Sono
  'sleep': '🛏️',
  'nap': '😴',
  'moon': '🌙',
  // Lazer
  'sport': '⚽',
  'play': '🎮',
  'music': '🎵',
  'art': '🎨',
  'toy': '🧸',
  'bike': '🚲',
  'swim': '🏊',
  'walk': '🚶',
  // Rotina
  'dress': '👕',
  'tidy': '🧹',
  'basket': '🧺',
  'door': '🚪',
  'clock': '⏰',
  // Social
  'home': '🏠',
  'family': '👪',
  'bus': '🚌',
  'car': '🚗',
  'party': '🎉',
  'heart': '❤️',
  'star': '⭐',
};

/// Agrupamento dos ícones acima em categorias, na ordem em que devem
/// aparecer no seletor de ícones do formulário — agrupar por tema
/// deixa a busca visual mais previsível do que uma grade única com
/// dezenas de opções misturadas.
const categoriasIcones = <String, List<String>>{
  'Higiene': ['tooth', 'shower', 'wash_hands', 'hair', 'toilet', 'nails'],
  'Alimentação': ['food', 'water', 'snack', 'milk', 'cake'],
  'Escola': ['school', 'book', 'homework', 'study'],
  'Saúde': ['medicine', 'doctor', 'therapy', 'speech', 'hospital'],
  'Sono': ['sleep', 'nap', 'moon'],
  'Lazer': ['sport', 'play', 'music', 'art', 'toy', 'bike', 'swim', 'walk'],
  'Rotina': ['dress', 'tidy', 'basket', 'door', 'clock'],
  'Social': ['home', 'family', 'bus', 'car', 'party', 'heart', 'star'],
};

String iconePara(String nome) => mapaIcones[nome] ?? mapaIcones['star']!;

/// Métodos auxiliares de exibição para o modelo [Tarefa], mantendo o
/// modelo em si livre de dependências do Flutter (Material).
extension TarefaVisual on Tarefa {
  Color get cor => Color(valorCor);
}
