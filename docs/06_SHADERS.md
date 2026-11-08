# 06_SHADERS.md: Especificação de Shaders em GDShader e Efeitos Visuais PBR

Para atingir a qualidade visual de *Sky Force Anniversary / Reloaded*, os shaders utilizam o renderizador **Forward+** do Godot 4 com precisão matemática em espaço de visão (*view space*).

---

## 1. Shader do Oceano com Profundidade e Espuma (`ocean_pbr.gdshader`)

Este shader implementa atenuação ótica pela profundidade d'água (*Beer-Lambert Law* simplificada), duas camadas de normais em sentidos opostos para ondas e cálculo de espuma de intersecção com a terra por leitura do `sampler2D depth_texture`.

```glsl
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.08, 0.65, 0.72, 1.0); // Turquesa litorâneo
uniform vec4 deep_color : source_color = vec4(0.01, 0.08, 0.22, 1.0);    // Azul-marinho abissal
uniform float depth_distance : hint_range(0.1, 15.0) = 4.0;

uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float foam_intersection_depth : hint_range(0.01, 2.0) = 0.45;

uniform sampler2D wave_normal_1 : hint_normal;
uniform sampler2D wave_normal_2 : hint_normal;
uniform vec2 wave_speed_1 = vec2(0.02, 0.01);
uniform vec2 wave_speed_2 = vec2(-0.01, 0.03);

uniform float roughness : hint_range(0.0, 1.0) = 0.12;
uniform float metallic : hint_range(0.0, 1.0) = 0.2;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

void fragment() {
    // Cálculo da coordenada de profundidade da cena atrás da água
    float depth_raw = texture(depth_texture, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w;
    float linear_depth = -view.z;
    float water_depth = linear_depth + VERTEX.z;

    // Gradiente de atenuação de cor
    float depth_factor = clamp(water_depth / depth_distance, 0.0, 1.0);
    vec4 base_water = mix(shallow_color, deep_color, depth_factor);

    // Amostragem das texturas de normais cruzadas
    vec2 uv_1 = UV + wave_speed_1 * TIME;
    vec2 uv_2 = UV + wave_speed_2 * TIME;
    vec3 n1 = texture(wave_normal_1, uv_1).rgb * 2.0 - 1.0;
    vec3 n2 = texture(wave_normal_2, uv_2).rgb * 2.0 - 1.0;
    vec3 normal_blended = normalize(n1 + n2);

    // Cálculo da espuma de contato com terreno e estruturas rochosas
    float foam_edge = 1.0 - smoothstep(0.0, foam_intersection_depth, water_depth);
    vec3 final_color = mix(base_water.rgb, foam_color.rgb, foam_edge);

    ALBEDO = final_color;
    NORMAL_MAP = normal_blended * 0.5 + 0.5;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    SPECULAR = 0.8;
}
```

---

## 2. Shader do Anel Holográfico de Resgate (`rescue_ring.gdshader`)

Projeta um anel circular de alta visibilidade no chão sob os sobreviventes que preenche dinamicamente seu arco de $0^\circ$ a $360^\circ$ conforme o progresso do resgate.

```glsl
shader_type spatial;
render_mode blend_add, cull_disabled, unshaded;

uniform vec4 ring_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform vec4 suppressed_color : source_color = vec4(1.0, 0.25, 0.1, 1.0);
uniform bool is_suppressed = false; // Ativado quando há inimigos a <= 10m dos civis
uniform float progress : hint_range(0.0, 1.0) = 0.0; // Controlado via GDScript
uniform float inner_radius : hint_range(0.1, 1.0) = 0.65;
uniform float outer_radius : hint_range(0.1, 1.0) = 0.85;

void fragment() {
    // Converte UV centrada em coordenadas polares (-1.0 a 1.0)
    vec2 centered_uv = UV * 2.0 - 1.0;
    float dist = length(centered_uv);
    float angle = (atan(centered_uv.y, centered_uv.x) + PI) / (2.0 * PI); // Normalizado 0.0 a 1.0

    // Verifica limites geométricos do anel
    float ring_mask = step(inner_radius, dist) * (1.0 - step(outer_radius, dist));

    // Quando suprimido, exibe o anel inteiro piscando em vermelho/laranja; caso contrário, preenche conforme o progresso
    float progress_mask = is_suppressed ? 1.0 : step(angle, progress);
    vec4 active_color = is_suppressed ? suppressed_color : ring_color;

    // Borda pulsante com emissão HDR (Bloom)
    float pulse = 0.8 + 0.2 * sin(TIME * (is_suppressed ? 14.0 : 6.0));
    vec3 emission = active_color.rgb * 2.5 * pulse;

    ALBEDO = emission;
    ALPHA = ring_mask * progress_mask * active_color.a;
}
```

---

## 3. Shader de Ondulação por Vento de Hélice no Mar (`rotor_wash.gdshader`)

Projetado como um decalque planar (`Decal` ou `MeshInstance3D`) logo abaixo da aeronave sobre o mar. Utiliza uma função de onda polar para gerar anéis concêntricos que simulam o ar expelido pelo rotor empurrando a superfície da água.

```glsl
shader_type spatial;
render_mode blend_mix, cull_back, unshaded;

uniform vec4 wash_color : source_color = vec4(1.0, 1.0, 1.0, 0.6);
uniform float ring_frequency = 18.0;
uniform float expansion_speed = 4.0;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);

    // Gera círculos concêntricos em expansão com decaimento nas bordas
    float wave = sin(dist * ring_frequency - TIME * expansion_speed);
    float falloff = 1.0 - smoothstep(0.1, 0.95, dist);

    float alpha_mask = clamp(wave * falloff * intensity, 0.0, 1.0);

    ALBEDO = wash_color.rgb;
    ALPHA = alpha_mask * wash_color.a;
}
```
