// ============================================================
//  UTILITÁRIO: chave de data
//  Usado para identificar, de forma única, a ocorrência de uma
//  tarefa em um dia específico (ex.: "1720137600000#2026-07-05"),
//  já que uma mesma tarefa recorrente (diária/semanal/mensal) pode
//  estar concluída em um dia e pendente em outro.
// ============================================================

String chaveDoDia(int idTarefa, DateTime dia) =>
    '$idTarefa#${dia.year.toString().padLeft(4, '0')}-'
    '${dia.month.toString().padLeft(2, '0')}-'
    '${dia.day.toString().padLeft(2, '0')}';
