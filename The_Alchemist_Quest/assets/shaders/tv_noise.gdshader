shader_type canvas_item;

// Uniforms để điều chỉnh hiệu ứng từ GDScript (nếu cần)
uniform float noise_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_speed : hint_range(0.0, 20.0) = 8.0;
uniform float flicker_intensity : hint_range(0.0, 2.0) = 1.2;

// Hàm tạo số ngẫu nhiên đơn giản
float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // Nhiễu trắng (White Noise)
    // Nhân với TIME để tạo hiệu ứng động
    float noise = rand(FRAGCOORD.xy * 0.01 * TIME);
    vec3 noise_color = vec3(noise) * noise_opacity;

    // Đường quét (Scanlines)
    // Tạo các đường ngang di chuyển theo thời gian
    float scanline = sin(FRAGCOORD.y * 0.5 + TIME * scanline_speed) * scanline_opacity;
    vec3 scanline_color = vec3(max(0.0, scanline));

    // Chớp giật (Flicker)
    // Thay đổi độ sáng chung một cách ngẫu nhiên
    float flicker = (rand(vec2(TIME)) * flicker_intensity) + (1.0 - flicker_intensity);

    // Kết hợp các hiệu ứng
    vec3 final_color = (noise_color + scanline_color) * flicker;

    // Màu cuối cùng là màu của hiệu ứng
    COLOR = vec4(final_color, 1.0);
} 