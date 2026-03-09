extends Node

# Singleton name: "GPULogger"

# File for logging
var file: FileAccess
var elapsed_time = 0.0
var sample_interval = 0.1  # Sample every 0.1 seconds
var is_logging = false  # Start as false, only true when manually started
var main_viewport_rid: RID

func _ready():
	# Store the main viewport RID
	main_viewport_rid = get_viewport().get_viewport_rid()
	
	# Don't enable GPU measurement or start logging automatically
	# Wait for explicit function call

func start_logging():
	if is_logging:
		print("GPU Logger: Already logging")
		return
	
	# Ensure any previous file is closed
	if file:
		stop_logging()
	
	# ⚠️ IMPORTANT: Enable GPU time measurement on the viewport
	RenderingServer.viewport_set_measure_render_time(main_viewport_rid, true)
	
	# Create logs directory if it doesn't exist
	var logs_dir = "user://logs/"
	DirAccess.make_dir_absolute(logs_dir)
	
	# Generate filename with timestamp
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var filename = logs_dir + "gpu_data_%s.csv" % timestamp
	
	# Create/open the file
	file = FileAccess.open(filename, FileAccess.WRITE)
	
	if file:
		# Write CSV header
		file.store_line("Timestamp (s),GPU Frame Time (ms),CPU Frame Time (ms),Draw Calls,Video Memory (MB),FPS")
		is_logging = true
		elapsed_time = 0.0
		print("GPU Logger started: ", ProjectSettings.globalize_path(filename))
	else:
		printerr("GPU Logger: Failed to create log file!")

func _process(delta):
	if not is_logging or not file:
		return
		
	elapsed_time += delta
	
	# Sample at regular intervals
	if elapsed_time >= sample_interval:
		var gpu_time = get_gpu_frame_time()
		var cpu_time = get_cpu_frame_time()
		var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var video_mem = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / (1024.0 * 1024.0)
		var fps = Performance.get_monitor(Performance.TIME_FPS)
		
		# Format: timestamp, gpu_time, cpu_time, draw_calls, video_mem, fps
		var line = "%.3f,%.3f,%.3f,%d,%.2f,%.1f" % [
			Time.get_ticks_msec() / 1000.0,
			gpu_time,
			cpu_time,
			draw_calls,
			video_mem,
			fps
		]
		
		file.store_line(line)
		elapsed_time = 0.0

func get_gpu_frame_time() -> float:
	# Now this will return actual values since measurement is enabled when logging starts
	return RenderingServer.viewport_get_measured_render_time_gpu(main_viewport_rid)

func get_cpu_frame_time() -> float:
	return RenderingServer.viewport_get_measured_render_time_cpu(main_viewport_rid)

func stop_logging():
	if is_logging:
		is_logging = false
		if file:
			file = null
		print("GPU Logger: Logging stopped")
		
		# Optional: Disable GPU measurement when stopping
		if main_viewport_rid.is_valid():
			RenderingServer.viewport_set_measure_render_time(main_viewport_rid, false)

# Clean up when game exits
func _exit_tree():
	stop_logging()
