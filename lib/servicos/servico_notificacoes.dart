// ============================================================
//  SERVIÇO: Notificações locais
//  Agenda, atualiza e cancela notificações de tarefas, mesmo com
//  o aplicativo fechado (usa AlarmManager/UNUserNotificationCenter
//  por baixo dos panos através do flutter_local_notifications).
//
//  Quando o horário da tarefa chega, o próprio sistema operacional
//  exibe a notificação na tela (heads-up, com o app aberto, em
//  segundo plano ou fechado) e toca o som padrão de notificação —
//  não é necessário nenhum temporizador manual dentro do app.
// ============================================================

// Conditional export to provide a web-specific implementation that
// uses the browser Notification API and a platform implementation
// that uses flutter_local_notifications for Android/iOS/desktop.
export 'servico_notificacoes_io.dart'
    if (dart.library.html) 'servico_notificacoes_web.dart';
