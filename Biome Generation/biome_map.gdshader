shader_type canvas_item;

uniform sampler2D elevation_map;
uniform sampler2D temperature_map;
uniform sampler2D precipitation_map;
uniform sampler2D humidity_map;

// Biome Colors Representation - High Contrast Version
uniform vec3 ocean_color : source_color = vec3(0.02, 0.15, 0.45);            // Rich Navy
uniform vec3 desert_color : source_color = vec3(1.0, 0.85, 0.3);             // Bright Gold
uniform vec3 grassland_color : source_color = vec3(0.4, 0.85, 0.1);          // Lime Green
uniform vec3 savanna_color : source_color = vec3(0.8, 0.6, 0.2);             // Burnt Orange/Ochre
uniform vec3 tundra_color : source_color = vec3(0.85, 0.9, 1.0);             // Bright Arctic White-Blue
uniform vec3 boreal_forest_color : source_color = vec3(0.05, 0.25, 0.15);    // Deep Pine Green
uniform vec3 temperate_forest_color : source_color = vec3(0.1, 0.55, 0.05);  // Mid Grass Green
uniform vec3 woodland_color : source_color = vec3(0.6, 0.5, 0.2);            // Olive/Golden Brown
uniform vec3 rainforest_color : source_color = vec3(0.0, 0.35, 0.05);        // Lush Emerald
uniform vec3 mountain_color : source_color = vec3(0.4, 0.35, 0.3);           // Warm Slate

// Fallback colors for gaps (visible indicators)
uniform vec3 gap_color_1 : source_color = vec3(1.0, 0.0, 1.0);               // Magenta - should not appear
uniform vec3 gap_color_2 : source_color = vec3(1.0, 1.0, 0.0);               // Yellow - debug

// All thresholds now normalized between 0 and 1

// OCEAN: Covers all low-elevation areas
uniform float ocean_e_min = 0.0;
uniform float ocean_e_max = 0.25;
uniform float ocean_t_min = 0.0;
uniform float ocean_t_max = 1.0;
uniform float ocean_p_min = 0.0;
uniform float ocean_p_max = 1.0;
uniform float ocean_h_min = 0.0;
uniform float ocean_h_max = 1.0;

// DESERT: Hot and Dry
uniform float desert_e_min = 0.1;
uniform float desert_e_max = 0.9;
uniform float desert_t_min = 0.5;
uniform float desert_t_max = 1.0;
uniform float desert_p_min = 0.0;
uniform float desert_p_max = 0.2;      // Reduced for realism
uniform float desert_h_min = 0.0;
uniform float desert_h_max = 0.3;      // Reduced for realism

// GRASSLAND: Temperate, Mid-Moisture
uniform float grassland_e_min = 0.1;
uniform float grassland_e_max = 0.9;
uniform float grassland_t_min = 0.2;
uniform float grassland_t_max = 0.8;    // Increased
uniform float grassland_p_min = 0.1;
uniform float grassland_p_max = 0.5;    // REAL: Moderate precipitation
uniform float grassland_h_min = 0.2;
uniform float grassland_h_max = 0.7;    // REAL: Moderate humidity

// SAVANNA: Hot, Mid-Moisture
uniform float savanna_e_min = 0.1;
uniform float savanna_e_max = 0.9;
uniform float savanna_t_min = 0.6;      // Increased
uniform float savanna_t_max = 1.0;
uniform float savanna_p_min = 0.3;
uniform float savanna_p_max = 0.7;      // REAL: Wet/dry seasons
uniform float savanna_h_min = 0.2;
uniform float savanna_h_max = 0.7;      // REAL: Seasonal humidity

// TUNDRA: Cold - Now full range catch-all for cold regions
uniform float tundra_e_min = 0.1;
uniform float tundra_e_max = 0.9;
uniform float tundra_t_min = 0.0;
uniform float tundra_t_max = 0.4;      // Increased
uniform float tundra_p_min = 0.0;      // Reduced - polar deserts
uniform float tundra_p_max = 1.0;      // Increased - full range
uniform float tundra_h_min = 0.0;      // Reduced - cold deserts
uniform float tundra_h_max = 1.0;      // Increased - full range

// BOREAL FOREST: Cool, Moist
uniform float boreal_forest_e_min = 0.1;
uniform float boreal_forest_e_max = 0.9;
uniform float boreal_forest_t_min = 0.2;  // Increased
uniform float boreal_forest_t_max = 0.5;
uniform float boreal_forest_p_min = 0.3;  // Increased
uniform float boreal_forest_p_max = 0.8;  // REAL: Moderate precipitation
uniform float boreal_forest_h_min = 0.3;
uniform float boreal_forest_h_max = 0.9;  // REAL: Moist

// TEMPERATE FOREST: Temperate, Wet
uniform float temperate_forest_e_min = 0.1;
uniform float temperate_forest_e_max = 0.9;
uniform float temperate_forest_t_min = 0.3;
uniform float temperate_forest_t_max = 0.7;  // Increased
uniform float temperate_forest_p_min = 0.5;
uniform float temperate_forest_p_max = 1.0;
uniform float temperate_forest_h_min = 0.4;
uniform float temperate_forest_h_max = 0.9;  // REAL: Humid

// WOODLAND: Mild to Warm, Moderate Moisture (Mediterranean)
uniform float woodland_e_min = 0.1;
uniform float woodland_e_max = 0.9;
uniform float woodland_t_min = 0.4;
uniform float woodland_t_max = 0.8;      // Increased
uniform float woodland_p_min = 0.2;      // Increased
uniform float woodland_p_max = 0.6;
uniform float woodland_h_min = 0.2;
uniform float woodland_h_max = 0.7;      // REAL: Moderate

// RAINFOREST: Hot and Very Wet
uniform float rainforest_e_min = 0.1;
uniform float rainforest_e_max = 0.9;
uniform float rainforest_t_min = 0.6;
uniform float rainforest_t_max = 1.0;
uniform float rainforest_p_min = 0.8;    // Increased - extremely high precipitation
uniform float rainforest_p_max = 1.0;
uniform float rainforest_h_min = 0.6;
uniform float rainforest_h_max = 1.0;    // REAL: Extremely humid

// MOUNTAIN: Very High Elevation
uniform float mountain_e_min = 0.8;      // Reduced for more coverage
uniform float mountain_e_max = 1.0;
uniform float mountain_t_min = 0.0;
uniform float mountain_t_max = 1.0;
uniform float mountain_p_min = 0.0;
uniform float mountain_p_max = 1.0;
uniform float mountain_h_min = 0.0;
uniform float mountain_h_max = 1.0;

uniform float blend_radius = 0.05;
uniform bool debug_mode = false;

// Number of biomes
const int biome_count = 10;
const int MAX_NEAREST_BIOMES = 3; // Number of closest biomes to track for gap filling

void fragment(){
	float elevation = texture(elevation_map, UV).r;
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
		woodland_color, rainforest_color, mountain_color
	);

	float min_e[10] = float[10](
		ocean_e_min, desert_e_min, grassland_e_min, savanna_e_min,
		tundra_e_min, boreal_forest_e_min, temperate_forest_e_min,
		woodland_e_min, rainforest_e_min, mountain_e_min
	);

	float max_e[10] = float[10](
		ocean_e_max, desert_e_max, grassland_e_max, savanna_e_max,
		tundra_e_max, boreal_forest_e_max, temperate_forest_e_max,
		woodland_e_max, rainforest_e_max, mountain_e_max
	);

	float min_t[10] = float[10](
		ocean_t_min, desert_t_min, grassland_t_min, savanna_t_min,
		tundra_t_min, boreal_forest_t_min, temperate_forest_t_min,
		woodland_t_min, rainforest_t_min, mountain_t_min
	);

	float max_t[10] = float[10](
		ocean_t_max, desert_t_max, grassland_t_max, savanna_t_max,
		tundra_t_max, boreal_forest_t_max, temperate_forest_t_max,
		woodland_t_max, rainforest_t_max, mountain_t_max
	);

	float min_p[10] = float[10](
		ocean_p_min, desert_p_min, grassland_p_min, savanna_p_min,
		tundra_p_min, boreal_forest_p_min, temperate_forest_p_min,
		woodland_p_min, rainforest_p_min, mountain_p_min
	);

	float max_p[10] = float[10](
		ocean_p_max, desert_p_max, grassland_p_max, savanna_p_max,
		tundra_p_max, boreal_forest_p_max, temperate_forest_p_max,
		woodland_p_max, rainforest_p_max, mountain_p_max
	);

	float min_h[10] = float[10](
		ocean_h_min, desert_h_min, grassland_h_min, savanna_h_min,
		tundra_h_min, boreal_forest_h_min, temperate_forest_h_min,
		woodland_h_min, rainforest_h_min, mountain_h_min
	);

	float max_h[10] = float[10](
		ocean_h_max, desert_h_max, grassland_h_max, savanna_h_max,
		tundra_h_max, boreal_forest_h_max, temperate_forest_h_max,
		woodland_h_max, rainforest_h_max, mountain_h_max
	);

	float weights[10];
	bool any_biome_active = false;

	// Track multiple closest biomes for better gap filling
	int nearest_biomes[MAX_NEAREST_BIOMES];
	float nearest_distances[MAX_NEAREST_BIOMES];

	// Initialize nearest distances to large values
	for (int j = 0; j < MAX_NEAREST_BIOMES; j++) {
		nearest_distances[j] = 1e10;
		nearest_biomes[j] = 0;
	}

	// Single pass: calculate weights AND track closest biomes
	for (int i = 0; i < biome_count; i++){
		// Calculate distance to this biome's range (for fallback)
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

		// Combined distance for fallback tracking
		float distance = e_dist + t_dist + p_dist + h_dist;

		// Track multiple closest biomes
		for (int j = 0; j < MAX_NEAREST_BIOMES; j++) {
			if (distance < nearest_distances[j]) {
				// Shift existing entries
				for (int k = MAX_NEAREST_BIOMES - 1; k > j; k--) {
					nearest_distances[k] = nearest_distances[k-1];
					nearest_biomes[k] = nearest_biomes[k-1];
				}
				// Insert new closest
				nearest_distances[j] = distance;
				nearest_biomes[j] = i;
				break;
			}
		}

		// Check if within range (including blend radius)
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
		}
	}

	// If no biomes are active, use fallback system with multiple closest biomes
	if (!any_biome_active) {
		if (debug_mode) {
			// In debug mode, show bright magenta for gaps
			COLOR.rgb = gap_color_1;
		} else {
			// Calculate weights based on inverse distances
			float total_inv_dist = 0.0;
			float gap_weights[MAX_NEAREST_BIOMES];
			bool exact_match = false;

			for (int j = 0; j < MAX_NEAREST_BIOMES; j++) {
				if (nearest_distances[j] < 0.001) {
					// If distance is nearly zero, just use this biome
					COLOR.rgb = colors[nearest_biomes[j]] * 0.9; // Slightly dimmed
					exact_match = true;
					break;
				}

				gap_weights[j] = 1.0 / nearest_distances[j];
				total_inv_dist += gap_weights[j];
			}

			if (!exact_match) {
				// Normalize gap weights
				if (total_inv_dist > 0.0) {
					for (int j = 0; j < MAX_NEAREST_BIOMES; j++) {
						gap_weights[j] /= total_inv_dist;
					}
				}

				// Blend the nearest biomes
				vec3 blended_color = vec3(0.0);
				for (int j = 0; j < MAX_NEAREST_BIOMES; j++) {
					blended_color += colors[nearest_biomes[j]] * gap_weights[j];
				}

				// Slightly dimmed to indicate transition zone
				COLOR.rgb = blended_color * 0.9;
			}

			// Add subtle noise to break up uniformity in transition zones
			float noise = sin(UV.x * 100.0 + UV.y * 100.0) * 0.5 + 0.5;
			COLOR.rgb *= mix(0.95, 1.05, noise);
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

		COLOR.rgb = blended_color;
	}
}