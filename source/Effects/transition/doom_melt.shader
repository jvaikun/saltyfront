shader_type canvas_item;

// Animation progress
uniform float progress : hint_range(0, 1);
// Number of total bars/columns
uniform int bars = 30; // = 30
// Multiplier for speed ratio. 0 = no variation when going down, higher = some elements go much faster
uniform float amplitude = 2; // = 2
// Speed variation horizontally. the bigger the value, the shorter the waves
uniform float frequency = 0.5f; // = 0.5

float wave(int num) {
  float fn = float(num) * frequency * 0.1 * float(bars);
  return cos(fn * 0.5) * cos(fn * 0.13) * sin((fn+10.0) * 0.3) / 2.0 + 0.5;
}

void fragment() {
	int bar = int(UV.x * (float(bars)));
	float scale = 1.0 + wave(bar) * amplitude;
	float phase = progress * scale;
	float posY = UV.y;
	vec2 p;
	vec4 c;
	if (posY - phase >= 0.0) {
		p = vec2(UV.x, UV.y - mix(0.0, 1.0, phase));
		c = texture(TEXTURE, p);
	} else {
		c = texture(TEXTURE, UV);
		c.a = 0.0;
	}
	COLOR = c;
}

