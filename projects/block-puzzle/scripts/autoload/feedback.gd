extends Node
## Lightweight synthesized sound and haptic feedback; no imported audio assets required.

var _player: AudioStreamPlayer
var _active_tweens: Array[Tween] = []

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)

func play(effect: String) -> void:
	if not bool(SaveData.get_setting("sound", true)):
		return
	var frequency := 440.0
	var duration := 0.075
	match effect:
		"place":
			frequency = 520.0
			duration = 0.055
		"clear":
			frequency = 880.0
			duration = 0.13
		"combo":
			frequency = 1046.5
			duration = 0.18
		"error":
			frequency = 190.0
			duration = 0.10
		"reward":
			frequency = 1320.0
			duration = 0.20
	_player.stream = _make_tone(frequency, duration)
	_player.play()

func vibrate(duration_ms: int = 25) -> void:
	if not bool(SaveData.get_setting("vibration", true)):
		return
	if OS.has_feature("Android"):
		Input.vibrate_handheld(clampi(duration_ms, 10, 150))

func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	const RATE := 22050
	var sample_count := int(RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var envelope := 1.0 - float(i) / sample_count
		var sample := sin(TAU * frequency * float(i) / RATE) * envelope * 0.22
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream
