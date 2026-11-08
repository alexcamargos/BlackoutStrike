// Shader do Anel Holografico de Resgate (res://assets/shaders/rescue_ring.gdshader)
// Projeta um anel circular no chao sob sobreviventes com preenchimento polar de 0 a 360 graus.
shader_type spatial;
render_mode blend_add, cull_disabled, unshaded;

uniform vec4 ring_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform vec4 suppressed_color : source_color = vec4(1.0, 0.15, 0.05, 1.0);
uniform bool is_suppressed = false; // Ativado quando ha inimigos a <= 10m dos civis
uniform float progress : hint_range(0.0, 1.0) = 0.0; // Controlado via GDScript
uniform float inner_radius : hint_range(0.1, 1.0) = 0.65;
uniform float outer_radius : hint_range(0.1, 1.0) = 0.85;

void fragment() {
    // Converte UV centrada em coordenadas polares (-1.0 a 1.0)
    vec2 centered_uv = UV * 2.0 - 1.0;
    float dist = length(centered_uv);
    float angle = (atan(centered_uv.y, centered_uv.x) + PI) / (2.0 * PI); // Normalizado 0.0 a 1.0

    // Verifica limites geometricos do anel
    float ring_mask = step(inner_radius, dist) * (1.0 - step(outer_radius, dist));

    // Quando suprimido, exibe o anel inteiro piscando em vermelho/laranja; caso contrario, preenche conforme o progresso
    float progress_mask = is_suppressed ? 1.0 : step(angle, progress);
    vec4 active_color = is_suppressed ? suppressed_color : ring_color;

    // Borda pulsante com emissao HDR (Bloom)
    float pulse = 0.8 + 0.2 * sin(TIME * (is_suppressed ? 14.0 : 6.0));
    vec3 emission = active_color.rgb * 2.5 * pulse;

    ALBEDO = emission;
    ALPHA = ring_mask * progress_mask * active_color.a;
}
