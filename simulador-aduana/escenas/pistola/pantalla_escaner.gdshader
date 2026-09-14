shader_type spatial;
// Esto hace que no tenga sombras, que los colores se sumen al superponerse, y que se vea de ambos lados
render_mode unshaded, blend_add, cull_disabled;

// Esto crea un cuadrito de color en el Inspector para que lo cambies fácil
uniform vec4 color_rayos_x : source_color = vec4(0.2, 0.5, 1.0, 1.0);

void fragment() {
	// Calculamos los bordes (Efecto Fresnel)
	float borde = 1.0 - dot(NORMAL, VIEW);
	borde = pow(borde, 1.5); // Esto hace que el borde sea más definido

	// Pintamos el objeto
	ALBEDO = color_rayos_x.rgb;
	// Hacemos que el centro sea invisible y los bordes brillen
	ALPHA = borde * color_rayos_x.a;
}