shader_type spatial;
render_mode cull_disabled;
// Ranges from 0 to 1 over the course of the transition.
uniform float progress : hint_range(0, 1);
uniform sampler2D tex : hint_albedo;

void fragment() {
	if (UV.y < progress) {
		ALBEDO = texture(tex, UV).rgb;
	}
	else {
		ALPHA = 0.0;
	}
}