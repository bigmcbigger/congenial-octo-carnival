shader_type spatial;

render_mode unshaded;

uniform sampler2D intensity;

const vec3 yellow = vec3(1.0, 1.0, 0.0);
const vec3 orange = vec3(1.0, 0.1, 0.0);

void vertex() {
	// Called for every vertex the material is visible on.
	float displace = cos(VERTEX.x + TIME) + sin(VERTEX.z + TIME);
	VERTEX.y += displace * 0.05;
	UV = VERTEX.xz / 10.0;
	UV += vec2(1.0, 0.0) * TIME * 0.05;
}

void fragment() {
	// Called for every pixel the material is visible on.
	float sample = texture(intensity, UV).x;
	vec3 colour =  vec3(1.0, 0.1 + sample * 0.5, 0.0);
	ALBEDO = colour;
	EMISSION = colour * 0.5;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
