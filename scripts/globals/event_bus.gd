## EventBus global para comunicacao desacoplada em Blackout Strike.
##
## Centraliza todos os sinais de eventos globais de recursos, arsenal, resgate,
## sistema roguelite, chefe e transmissoes de radio militar.
extends Node

# Eventos de Recursos e Vida da Aeronave
signal player_health_changed(current: float, max_health: float)
signal player_fuel_changed(current: float, max_fuel: float)
signal player_fuel_depleted()
signal player_died(cause: String)

# Eventos de Arsenal e Balistica
signal weapon_selected(slot_index: int, weapon_name: String)
signal weapon_ammo_changed(slot_index: int, current: int, max_ammo: int)
signal target_locked(target: Node3D)
signal target_lost()

# Eventos de Resgate e Sobrevivencia
signal civilian_boarded(current_cargo: int, max_cargo: int)
signal civilian_extracted(total_rescued: int)
signal civilian_killed(total_lost: int)
signal rescue_zone_suppressed(is_suppressed: bool)
signal shelter_destroyed(shelter_position: Vector3, survivor_count: int)

# Eventos do Sistema Roguelite
signal data_crate_opened(available_boons: Array)
signal boon_applied(boon_id: String)

# Eventos do Chefe e Progressao de Missao
signal boss_phase_changed(boss_name: String, phase_index: int)
signal boss_defeated(boss_name: String)
signal mission_accomplished()
signal mission_failed(reason: String)

# Eventos de Narrativa e Transmissao de Radio
signal radio_transmission_requested(speaker_id: String, callsign: String, message: String, duration: float)
