shader_type spatial;

uniform float max_height = 100.0;  // will be set from Config.amplitude
uniform sampler2D temperature_map;
uniform sampler2D precipitation_map;
uniform sampler2D humidity_map;

// Biome Colors Representation - High Contrast Version
uniform vec3 ocean_color = vec3(0.02, 0.15, 0.45);            // Rich Navy
uniform vec3 desert_color = vec3(1.0, 0.85, 0.3);             // Bright Gold
uniform vec3 grassland_color = vec3(0.4, 0.85, 0.1);          // Lime Green
uniform vec3 savanna_color = vec3(0.8, 0.6, 0.2);             // Burnt Orange/Ochre
uniform vec3 tundra_color = vec3(0.85, 0.9, 1.0);             // Bright Arctic White-Blue
uniform vec3 boreal_forest_color = vec3(0.05, 0.25, 0.15);    // Deep Pine Green
uniform vec3 temperate_forest_color = vec3(0.1, 0.55, 0.05);  // Mid Grass Green
uniform vec3 rainforest_color = vec3(0.0, 0.35, 0.05);        // Lush Emerald
uniform vec3 mountain_color = vec3(0.4, 0.35, 0.3);           // Warm Slate
uniform vec3 alpine_tundra_color = vec3(0.75, 0.8, 0.9);      // Light gray-blue

// Fallback colors for gaps (visible indicators)
uniform vec3 gap_color_1 = vec3(1.0, 0.0, 1.0);               // Magenta - should not appear
uniform vec3 gap_color_2 = vec3(1.0, 1.0, 0.0);               // Yellow - debug

// All thresholds are normalized between 0 and 1.
// They are adjusted to ensure the entire 4‑dimensional space [0,1]⁴ is covered.
// The lake biome has been removed.

// OCEAN: covers all low‑elevation areas
uniform float ocean_e_min = 0.0;
uniform float ocean_e_max = 0.25;
uniform float ocean_t_min = 0.0;
uniform float ocean_t_max = 1.0;
uniform float ocean_p_min = 0.0;
uniform float ocean_p_max = 1.0;
uniform float ocean_h_min = 0.0;
uniform float ocean_h_max = 1.0;

// DESERT: hot and dry, extended to higher elevations
uniform float desert_e_min = 0.15;
uniform float desert_e_max = 0.9;
uniform float desert_t_min = 0.6;
uniform float desert_t_max = 1.0;
uniform float desert_p_min = 0.0;
uniform float desert_p_max = 0.35;
uniform float desert_h_min = 0.0;
uniform float desert_h_max = 0.35;

// GRASSLAND: temperate, now covers all moisture levels
uniform float grassland_e_min = 0.2;
uniform float grassland_e_max = 0.9;
uniform float grassland_t_min = 0.25;
uniform float grassland_t_max = 0.65;
uniform float grassland_p_min = 0.0;
uniform float grassland_p_max = 1.0;
uniform float grassland_h_min = 0.0;
uniform float grassland_h_max = 1.0;

// SAVANNA: hot, now covers moist to wet
uniform float savanna_e_min = 0.15;
uniform float savanna_e_max = 0.9;
uniform float savanna_t_min = 0.6;
uniform float savanna_t_max = 1.0;
uniform float savanna_p_min = 0.3;
uniform float savanna_p_max = 1.0;
uniform float savanna_h_min = 0.3;
uniform float savanna_h_max = 1.0;

// TUNDRA: cold, now covers all moisture levels
uniform float tundra_e_min = 0.2;
uniform float tundra_e_max = 0.9;
uniform float tundra_t_min = 0.0;
uniform float tundra_t_max = 0.35;
uniform float tundra_p_min = 0.0;
uniform float tundra_p_max = 1.0;
uniform float tundra_h_min = 0.0;
uniform float tundra_h_max = 1.0;

// BOREAL FOREST: cool (0.35–0.5), all moisture levels
uniform float boreal_forest_e_min = 0.2;
uniform float boreal_forest_e_max = 0.9;
uniform float boreal_forest_t_min = 0.35;
uniform float boreal_forest_t_max = 0.5;
uniform float boreal_forest_p_min = 0.0;
uniform float boreal_forest_p_max = 1.0;
uniform float boreal_forest_h_min = 0.0;
uniform float boreal_forest_h_max = 1.0;

// TEMPERATE FOREST: wet temperate, kept for variety
uniform float temperate_forest_e_min = 0.2;
uniform float temperate_forest_e_max = 0.9;
uniform float temperate_forest_t_min = 0.3;
uniform float temperate_forest_t_max = 0.7;
uniform float temperate_forest_p_min = 0.6;
uniform float temperate_forest_p_max = 0.85;
uniform float temperate_forest_h_min = 0.6;
uniform float temperate_forest_h_max = 0.85;

// RAINFOREST: hot and very wet
uniform float rainforest_e_min = 0.15;
uniform float rainforest_e_max = 0.9;
uniform float rainforest_t_min = 0.65;
uniform float rainforest_t_max = 1.0;
uniform float rainforest_p_min = 0.7;
uniform float rainforest_p_max = 1.0;
uniform float rainforest_h_min = 0.7;
uniform float rainforest_h_max = 1.0;

// MOUNTAIN: very high elevation, now covers all temperatures
uniform float mountain_e_min = 0.9;
uniform float mountain_e_max = 1.0;
uniform float mountain_t_min = 0.0;
uniform float mountain_t_max = 1.0;
uniform float mountain_p_min = 0.0;
uniform float mountain_p_max = 1.0;
uniform float mountain_h_min = 0.0;
uniform float mountain_h_max = 1.0;

// ALPINE TUNDRA: high cold variant, now all moisture
uniform float alpine_tundra_e_min = 0.75;
uniform float alpine_tundra_e_max = 0.95;
uniform float alpine_tundra_t_min = 0.0;
uniform float alpine_tundra_t_max = 0.35;
uniform float alpine_tundra_p_min = 0.0;
uniform float alpine_tundra_p_max = 1.0;
uniform float alpine_tundra_h_min = 0.0;
uniform float alpine_tundra_h_max = 1.0;

uniform float blend_radius = 0.05;
uniform bool debug_mode = false;

// Number of biomes (lake removed)
const int biome_count = 10;

void fragment(){
	    // Convert view-space VERTEX to world space
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float height = world_pos.y;

    // Normalize to [0,1] assuming height ranges from -max_height to +max_height
    float elevation = (height + max_height) / (2.0 * max_height);
    elevation = clamp(elevation, 0.0, 1.0);
	float temperature = texture(temperature_map, UV).r;
	float precipitation = texture(precipitation_map, UV).r;
	float humidity = texture(humidity_map, UV).r;

	// Ensure all values are clamped to 0-1 range
	elevation = clamp(elevation, 0.0, 1.0);
	temperature = clamp(temperature, 0.0, 1.0);
	precipitation = clamp(precipitation, 0.0, 1.0);
	humidity = clamp(humidity, 0.0, 1.0);

	vec3 colors[10] = vec3[10](
		ocean_color, desert_color, grassland_color, savanna_color,
		tundra_color, boreal_forest_color, temperate_forest_color,
		rainforest_color, mountain_color, alpine_tundra_color
	);

	float min_e[10] = float[10](
		ocean_e_min, desert_e_min, grassland_e_min, savanna_e_min,
		tundra_e_min, boreal_forest_e_min, temperate_forest_e_min,
		rainforest_e_min, mountain_e_min, alpine_tundra_e_min
	);

	float max_e[10] = float[10](
		ocean_e_max, desert_e_max, grassland_e_max, savanna_e_max,
		tundra_e_max, boreal_forest_e_max, temperate_forest_e_max,
		rainforest_e_max, mountain_e_max, alpine_tundra_e_max
	);

	float min_t[10] = float[10](
		ocean_t_min, desert_t_min, grassland_t_min, savanna_t_min,
		tundra_t_min, boreal_forest_t_min, temperate_forest_t_min,
		rainforest_t_min, mountain_t_min, alpine_tundra_t_min
	);

	float max_t[10] = float[10](
		ocean_t_max, desert_t_max, grassland_t_max, savanna_t_max,
		tundra_t_max, boreal_forest_t_max, temperate_forest_t_max,
		rainforest_t_max, mountain_t_max, alpine_tundra_t_max
	);

	float min_p[10] = float[10](
		ocean_p_min, desert_p_min, grassland_p_min, savanna_p_min,
		tundra_p_min, boreal_forest_p_min, temperate_forest_p_min,
		rainforest_p_min, mountain_p_min, alpine_tundra_p_min
	);

	float max_p[10] = float[10](
		ocean_p_max, desert_p_max, grassland_p_max, savanna_p_max,
		tundra_p_max, boreal_forest_p_max, temperate_forest_p_max,
		rainforest_p_max, mountain_p_max, alpine_tundra_p_max
	);

	float min_h[10] = float[10](
		ocean_h_min, desert_h_min, grassland_h_min, savanna_h_min,
		tundra_h_min, boreal_forest_h_min, temperate_forest_h_min,
		rainforest_h_min, mountain_h_min, alpine_tundra_h_min
	);

	float max_h[10] = float[10](
		ocean_h_max, desert_h_max, grassland_h_max, savanna_h_max,
		tundra_h_max, boreal_forest_h_max, temperate_forest_h_max,
		rainforest_h_max, mountain_h_max, alpine_tundra_h_max
	);

	float weights[10];
	bool any_biome_active = false;

	// Add elevation bias for tundra (index 5) to further emphasize high altitude preference
	float tundra_elevation_bias = 1.0;
	if (elevation >= 0.5) {
		// Boost tundra weight at higher elevations
		tundra_elevation_bias = 1.0 + (elevation - 0.5) * 2.0; // Up to 2.0 at max elevation
	}

	// First pass: calculate raw weights
	for (int i = 0; i < biome_count; i++){
		// Check if completely outside all ranges (with blend radius)
		if (elevation < min_e[i] - blend_radius || elevation > max_e[i] + blend_radius ||
			temperature < min_t[i] - blend_radius || temperature > max_t[i] + blend_radius ||
			precipitation < min_p[i] - blend_radius || precipitation > max_p[i] + blend_radius ||
			humidity < min_h[i] - blend_radius || humidity > max_h[i] + blend_radius) {
			weights[i] = 0.0;
		} else {
			any_biome_active = true;

			// Calculate individual dimension weights
			float e_weight = 1.0;
			float t_weight = 1.0;
			float p_weight = 1.0;
			float h_weight = 1.0;

			// Elevation weight
			if (elevation < min_e[i]) {
				e_weight = smoothstep(min_e[i] - blend_radius, min_e[i], elevation);
			} else if (elevation > max_e[i]) {
				e_weight = 1.0 - smoothstep(max_e[i], max_e[i] + blend_radius, elevation);
			}

			// Temperature weight
			if (temperature < min_t[i]) {
				t_weight = smoothstep(min_t[i] - blend_radius, min_t[i], temperature);
			} else if (temperature > max_t[i]) {
				t_weight = 1.0 - smoothstep(max_t[i], max_t[i] + blend_radius, temperature);
			}

			// Precipitation weight
			if (precipitation < min_p[i]) {
				p_weight = smoothstep(min_p[i] - blend_radius, min_p[i], precipitation);
			} else if (precipitation > max_p[i]) {
				p_weight = 1.0 - smoothstep(max_p[i], max_p[i] + blend_radius, precipitation);
			}

			// Humidity weight
			if (humidity < min_h[i]) {
				h_weight = smoothstep(min_h[i] - blend_radius, min_h[i], humidity);
			} else if (humidity > max_h[i]) {
				h_weight = 1.0 - smoothstep(max_h[i], max_h[i] + blend_radius, humidity);
			}

			// Combined weight (multiplicative gives sharper transitions)
			weights[i] = e_weight * t_weight * p_weight * h_weight;

			// Apply elevation bias for tundra (index 5)
			if (i == 5) { // Tundra
				weights[i] *= tundra_elevation_bias;
			}
		}
	}

	// If no biomes are active, use fallback system
	if (!any_biome_active) {
		if (debug_mode) {
			// In debug mode, show bright magenta for gaps
			ALBEDO.rgb = gap_color_1;
		} else {
			// In production, find closest biome as fallback
			float best_match = 0.0;
			int best_index = 0;

			for (int i = 0; i < biome_count; i++) {
				// Calculate distance to each biome's ideal range
				float e_dist = 0.0;
				float t_dist = 0.0;
				float p_dist = 0.0;
				float h_dist = 0.0;

				// Elevation distance
				if (elevation < min_e[i]) {
					e_dist = min_e[i] - elevation;
				} else if (elevation > max_e[i]) {
					e_dist = elevation - max_e[i];
				}

				// Temperature distance
				if (temperature < min_t[i]) {
					t_dist = min_t[i] - temperature;
				} else if (temperature > max_t[i]) {
					t_dist = temperature - max_t[i];
				}

				// Precipitation distance
				if (precipitation < min_p[i]) {
					p_dist = min_p[i] - precipitation;
				} else if (precipitation > max_p[i]) {
					p_dist = precipitation - max_p[i];
				}

				// Humidity distance
				if (humidity < min_h[i]) {
					h_dist = min_h[i] - humidity;
				} else if (humidity > max_h[i]) {
					h_dist = humidity - max_h[i];
				}

				// Combined distance (Euclidean-like)
				float distance = e_dist + t_dist + p_dist + h_dist;
				float match = 1.0 / (1.0 + distance * 10.0); // Convert to match score

				if (match > best_match) {
					best_match = match;
					best_index = i;
				}
			}

			// Use the closest biome with reduced opacity to indicate it's a gap
			ALBEDO.rgb = colors[best_index] * 0.7; // Slightly dimmed to indicate fallback
		}

	} else {

		// Normalize weights
		float total_weight = 0.0;
		for (int i = 0; i < biome_count; i++){
			total_weight += weights[i];
		}

		// Only normalize if we have positive weights
		if (total_weight > 0.001) {
			for (int i = 0; i < biome_count; i++){
				weights[i] /= total_weight;
			}
		} else {
			// Fallback if weights sum to near zero
			for (int i = 0; i < biome_count; i++){
				weights[i] = 0.0;
			}
			weights[0] = 1.0; // Default to ocean
		}

		// Blend colors based on weights
		vec3 blended_color = vec3(0.0);
		for (int i = 0; i < biome_count; i++){
			blended_color += colors[i] * weights[i];
		}

		ALBEDO.rgb = blended_color;
	}
}