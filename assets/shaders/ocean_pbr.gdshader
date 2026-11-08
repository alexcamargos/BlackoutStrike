shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.08, 0.65, 0.72, 1.0);
uniform vec4 deep_color : source_color = vec4(0.01, 0.08, 0.22, 1.0);
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
    float depth_raw = texture(depth_texture, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w;
    float linear_depth = -view.z;
    float water_depth = linear_depth - VERTEX.z;

    float depth_factor = clamp(water_depth / depth_distance, 0.0, 1.0);
    vec4 base_water = mix(shallow_color, deep_color, depth_factor);

    vec2 uv_1 = UV + wave_speed_1 * TIME;
    vec2 uv_2 = UV + wave_speed_2 * TIME;
    vec3 n1 = texture(wave_normal_1, uv_1).rgb * 2.0 - 1.0;
    vec3 n2 = texture(wave_normal_2, uv_2).rgb * 2.0 - 1.0;
    vec3 normal_blended = normalize(n1 + n2);

    float foam_edge = 1.0 - smoothstep(0.0, foam_intersection_depth, water_depth);
    vec3 final_color = mix(base_water.rgb, foam_color.rgb, foam_edge);

    ALBEDO = final_color;
    NORMAL_MAP = normal_blended;
    ROUGHNESS = roughness;
    METALLIC = metallic;
    SPECULAR = 0.8;
}
