shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
	//VERTEX *= sin(TIME*5.0);
	UV *= 2.0;
	UV -= vec2(1.0, 1.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	//ALBEDO = vec3(UV.y, 0, 0);
	float t = sqrt((UV.x*UV.x)+(UV.y*UV.y));
	if (t > 0.9 && t <= 1.0) {
		ALBEDO = vec3(1, 0, 0);
	} else {
		ALPHA = 0.0;
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
