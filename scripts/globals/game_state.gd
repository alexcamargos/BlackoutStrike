## Gerenciador global do ciclo de vida da incursao (Run State).
##
## Controla o status da sessao de combate, passageiros resgatados na missao
## e a lista de boons acumulados na incursao ativa.
extends Node

## Estados possiveis da incursao atual.
enum RunStatus {
	IDLE,
	IN_PROGRESS,
	PAUSED_BOON,
	VICTORY,
	FAILED
}

## Status de execucao da run.
var current_status: RunStatus = RunStatus.IDLE

## Total de civis extraidos com sucesso durante a incursao corrente.
var rescued_in_current_run: int = 0

## Identificadores de boons taticos ativos durante a incursao.
var active_run_boons: Array[String] = []


## Inicializa uma nova incursao resetando os estados temporarios.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func start_new_run() -> void:
	current_status = RunStatus.IN_PROGRESS
	rescued_in_current_run = 0
	active_run_boons.clear()


## Registra civis extraidos para a base aliada na incursao ativa.
##
## Args:
##     count (int): Quantidade de civis entregues com sucesso no heliponto.
##
## Returns:
##     void
func register_extracted_civilians(count: int) -> void:
	if count <= 0:
		return
	rescued_in_current_run += count
	if EventBus != null:
		EventBus.civilian_extracted.emit(rescued_in_current_run)


## Finaliza a incursao marcando condicao de vitoria.
##
## Args:
##     Nenhum.
##
## Returns:
##     void
func complete_run_victory() -> void:
	current_status = RunStatus.VICTORY
	if EventBus != null:
		EventBus.mission_accomplished.emit()


## Finaliza a incursao marcando condicao de derrota com o motivo informado.
##
## Args:
##     reason (String): Descricao do motivo do fracasso da missao.
##
## Returns:
##     void
func fail_run(reason: String) -> void:
	current_status = RunStatus.FAILED
	if EventBus != null:
		EventBus.mission_failed.emit(reason)
