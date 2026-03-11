extends Node

class_name RealTimeLogger

# File for logging
var file: FileAccess
var elapsed_time = 0.0
var sample_interval = 0.1  # Sample every 0.1 seconds
var is_logging = false  # Start as false, only true when manually started
var main_viewport_rid: RID

# Store Config values for logging
var algorithm_name: String = "Unknown"
var round_number: int = 0
var seed: int

func _ready():
	print("RealTimeLogger: _ready() called")
	# Store the main viewport RID
	main_viewport_rid = get_viewport().get_viewport_rid()
	print("RealTimeLogger: Viewport RID = ", main_viewport_rid)
	
	# Don't enable GPU measurement or start logging automatically
	# Wait for explicit function call

func get_size_folder(size_value: int) -> String:
	match size_value:
		1000:
			return "Small"
		3000:
			return "Medium"
		5000:
			return "Large"
		_:
			return str(size_value)

func start_logging():
	print("RealTimeLogger: start_logging() called")
	print("RealTimeLogger: is_logging = ", is_logging)
	
	if is_logging:
		print("GPU Logger: Already logging")
		return
	
	# Check if viewport RID is valid
	if not main_viewport_rid.is_valid():
		print("RealTimeLogger: Viewport RID invalid, trying to get it again")
		main_viewport_rid = get_viewport().get_viewport_rid()
		print("RealTimeLogger: New viewport RID = ", main_viewport_rid)
		
		if not main_viewport_rid.is_valid():
			printerr("RealTimeLogger: FATAL - Viewport RID still invalid!")
			return
	
	var Config: WorldConfigResource = load("res://world_config.tres")
	print("RealTimeLogger: Config loaded, size = ", Config.size)
	
	# Store Config values for logging
	algorithm_name = "Simplex" if Config.noise_type == 0 else "Perlin"
	round_number = Config.round
	seed = Config.seed
	
	# Ensure any previous file is closed
	if file:
		stop_logging()
	
	# ⚠️ IMPORTANT: Enable GPU time measurement on the viewport
	print("RealTimeLogger: Enabling GPU measurement")
	RenderingServer.viewport_set_measure_render_time(main_viewport_rid, true)
	
	# Get size folder name
	var size_folder = get_size_folder(Config.size)
	
	# Create logs directory with size subfolder
	var logs_dir = "user://real-time-logs/%s/" % size_folder
	print("RealTimeLogger: Attempting to create directory: ", logs_dir)
	
	# Check if directory exists, create if it doesn't
	var dir = DirAccess.open("user://")
	if dir:
		print("RealTimeLogger: Successfully opened user:// directory")
		
		# Check if real-time-logs exists
		if not dir.dir_exists("real-time-logs"):
			print("RealTimeLogger: Creating real-time-logs directory")
			var result = dir.make_dir("real-time-logs")
			print("RealTimeLogger: real-time-logs creation result: ", result)
		
		# Navigate to real-time-logs
		if dir.dir_exists("real-time-logs"):
			dir.change_dir("real-time-logs")
			print("RealTimeLogger: Changed to real-time-logs directory")
			
			# Check if size folder exists
			if not dir.dir_exists(size_folder):
				print("RealTimeLogger: Creating %s directory" % size_folder)
				var result = dir.make_dir(size_folder)
				print("RealTimeLogger: %s creation result: %s" % [size_folder, result])
	else:
		printerr("RealTimeLogger: Could not open user:// directory!")
		# Try an alternative approach
		logs_dir = "user://real-time-logs/%s/" % size_folder
		var error = DirAccess.make_dir_absolute(logs_dir)
		print("RealTimeLogger: Alternative directory creation result: ", error)
	
	# Generate filename with timestamp
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var filename = logs_dir + "gpu_data_%s_%s_Round%d.csv" % [timestamp, algorithm_name, round_number]
	var full_path = ProjectSettings.globalize_path(filename)
	print("RealTimeLogger: Filename = ", filename)
	print("RealTimeLogger: Global Filename = ", full_path)
	
	# Create/open the file
	print("RealTimeLogger: Attempting to create file...")
	file = FileAccess.open(filename, FileAccess.WRITE)
	
	if file:
		# Write CSV header with new columns
		file.store_line("Timestamp (s),GPU Frame Time (ms),CPU Frame Time (ms),Draw Calls,Video Memory (MB),FPS,Algorithm,Round,Seed")
		# Flush to ensure header is written
		file.flush()
		
		is_logging = true
		elapsed_time = 0.0
		print("GPU Logger started: ", full_path)
		
		# Verify file was created
		if FileAccess.file_exists(filename):
			print("RealTimeLogger: File verified at: ", filename)
		else:
			print("RealTimeLogger: WARNING - File doesn't exist after creation!")
	else:
		var error_code = FileAccess.get_open_error()
		printerr("RealTimeLogger: Failed to create log file! Error code: ", error_code)

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
		
		# Format: timestamp, gpu_time, cpu_time, draw_calls, video_mem, fps, algorithm, round
		var line = "%.3f,%.3f,%.3f,%d,%.2f,%.1f,%s,%d,%d" % [
			Time.get_ticks_msec() / 1000.0,
			gpu_time,
			cpu_time,
			draw_calls,
			video_mem,
			fps,
			algorithm_name,
			round_number,
			seed
		]
		
		# Write line and flush immediately to ensure data is saved
		file.store_line(line)
		file.flush()  # Force write to disk
		
		# Debug print every 10 samples to confirm it's working
		if int(elapsed_time * 10) % 10 == 0:
			print("RealTimeLogger: Logged sample - FPS: ", fps, ", GPU: ", gpu_time, "ms")
		
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
			# Final flush before closing
			file.flush()
			file = null
		print("GPU Logger: Logging stopped")
		
		# Optional: Disable GPU measurement when stopping
		if main_viewport_rid.is_valid():
			RenderingServer.viewport_set_measure_render_time(main_viewport_rid, false)

# Clean up when game exits
func _exit_tree():
	stop_logging()
