# 07_ASSETS.md: Manifesto de Ativos Públicos e Diretrizes de Importação

Todos os ativos utilizados no MVP devem manter conformidade com licenças permissivas (**CC0**, **Domínio Público** ou **MIT**).

---

## 1. Modelagem 3D e Estruturas Geométricas

| Ativo / Pacote | Fonte / Autor | Licença | Caminho no Projeto | Diretrizes de Importação |
| :--- | :--- | :---: | :--- | :--- |
| **Military Kit** | Kenney.nl | CC0 | `res://assets/models/military/` | Escala: $0.6$; gerar colisores `Box` simplificados para prédios. |
| **Vehicle Kit** | Kenney.nl | CC0 | `res://assets/models/vehicles/` | Extrair peças móveis (esteiras de tanques e hélices) como nós filhos isolados. |
| **Low-Poly Humans** | Kay Lousberg | CC0 | `res://assets/models/characters/` | Importar malhas de cientistas e civis com esqueletos (*skeletons*) básicos de corrida. |
| **Navio de Combate** | Kenney / Sketchfab | CC0 / CC-BY | `res://assets/models/boss/` | Separar a malha do casco principal das malhas das torretas giratórias de proa e popa. |

---

## 2. Texturas e Mapas PBR

Para manter a taxa de quadros e o padrão visual de *Sky Force*, todas as texturas devem respeitar os seguintes limites de resolução:
- **Resolução de Texturas do Helicóptero do Jogador e Chefe:** $2048 \times 2048$ pixels (canais: Albedo com transparência, ORM map empacotado: $R=\text{Occlusion}$, $G=\text{Roughness}$, $B=\text{Metallic}$).
- **Resolução de Texturas de Estruturas e Terreno:** $1024 \times 1024$ pixels em repetição contínua (*seamless*).
- **Texturas de Projéteis e Feixes de Energia:** $256 \times 256$ pixels (emissivo puro em HDR para alimentar o nó de *Bloom*).

---

## 3. Design de Áudio (SFX) e Parâmetros Acústicos

Os áudios são importados preferencialmente no formato `.ogg` (loops de motor) e `.wav` de 16-bit / 44.1 kHz (efeitos de impacto e detonações).

| Efeito Sonoro | Arquivo | Origem | Bus de Áudio | Configuração no Godot |
| :--- | :--- | :--- | :--- | :--- |
| **Rotor Principal do Helicóptero** | `sfx_helo_loop.ogg` | Freesound (CC0) | `SFX_Player` | Loop ativo; modulação de pitch entre $0.95$ e $1.15$ baseada na velocidade linear. |
| **Disparo de Canhão Vulcan 20mm** | `sfx_vulcan_shot.wav` | Sonniss GDC | `SFX_Weapons` | Reprodução com variação randômica de pitch ($\pm 5\%$) para evitar monotonia. |
| **Lançamento de Foguete Hydra** | `sfx_rocket_launch.wav` | Freesound (CC0) | `SFX_Weapons` | Volume $-3.0\text{ dB}$, prioridade alta no player de som. |
| **Impacto Balístico em Blindagem** | `sfx_armor_hit.wav` | Sonniss GDC | `SFX_Combat` | Atenuação espacial 3D com distância máxima de corte de $35\text{ m}$. |
| **Alarme de Combustível Crítico** | `sfx_alarm_fuel.wav` | Freesound (CC0) | `UI_Alarms` | Bipe contínuo não espacializado disparado ao atingir combustível $\le 20\%$. |
| **Chime de Resgate de Refém** | `sfx_rescue_ping.wav` | Freesound (CC0) | `UI_Chimes` | Tom agudo harmônico emitido a cada ciclo de preenchimento do anel holográfico. |

---

## 4. Perfil de Pós-Processamento (`world_environment.tres`)

Configurações obrigatórias para reproduzir a iluminação saturada e contrastada:

```text
[Environment]
Background Mode: Custom Color (Azul névoa distante: #1A3048)
Ambient Light: Sky Contribution 0.4, Color #C4E0E5
Tonemap Mode: Filmic (para evitar queima estourada de brancos em explosões)
Tonemap Exposure: 1.05
Tonemap White: 1.2

[Glow / Bloom]
Enabled: True
Levels/1: 0.0
Levels/2: 0.8
Levels/3: 1.2
Levels/4: 0.4
Intensity: 0.85
Strength: 1.05
Blend Mode: Additive
HDR Threshold: 1.15 (Apenas projéteis, lasers e reflexos fortes entram no brilho)

[SSAO (Screen Space Ambient Occlusion)]
Enabled: True
Radius: 1.5
Intensity: 1.8
Power: 1.5
```

---

## 5. Política de Placeholders Procedurais para Execução Autônoma (SDD / Headless)

Enquanto os pacotes externos `.glb` e `.wav`/`.ogg` listados nas seções 1 e 3 não estiverem importados localmente em `res://assets/`, os agentes autônomos devem construir todas as cenas `.tscn` utilizando **primitivas geométricas e materiais PBR nativos do Godot 4** serializados em texto plano:
- **Fuselagem e Veículos:** Composição de `BoxMesh`, `CapsuleMesh` e `CylinderMesh` com `StandardMaterial3D` configurado (`metallic = 0.8`, `roughness = 0.25`, cores de facção contrastantes: cinza-azulado `#3B4D5E` para JTF Vanguard e antracite/vermelho `#22252A` / `#D9381E` para Aetheris).
- **Projéteis e Explosões:** `SphereMesh` ou `BoxMesh` com `emission_enabled = true` e `emission_energy_multiplier = 2.5` para acionar o *Bloom* do `WorldEnvironment`.
- **Áudio Seguro em Headless:** Os nós `AudioStreamPlayer` e `AudioStreamPlayer3D` devem verificar se o `stream` está atribuído antes de invocar `play()` (ou utilizar `AudioStreamGenerator` / recursos vazios válidos), garantindo zero erros ou avisos durante a execução dos testes via `godot --headless`.
