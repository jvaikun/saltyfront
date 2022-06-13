shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0);
uniform float smoothing : hint_range(0.0, 1.0);
uniform sampler2D mask : hint_albedo;

void fragment()
{
	float value = texture(mask, UV).r;
	float alpha = smoothstep(progress, progress + smoothing, value * (1.0 - smoothing) + smoothing);
	COLOR = vec4(texture(TEXTURE, UV).rgb, alpha);
}