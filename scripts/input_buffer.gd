class_name FightInputBuffer
extends RefCounted
## Commands expire after a short window, independent of render frame rate.
const WINDOW := GameSettings.INPUT_WINDOW
var commands: Array[Dictionary] = []
var clock := 0.0

func advance(delta: float) -> void:
	clock += delta
	commands = commands.filter(
		func(command: Dictionary) -> bool:
			return clock - command.time <= WINDOW
	)

func push(command: StringName) -> void:
	if commands.size() >= GameSettings.MAX_BUFFER_COMMANDS:
		commands.pop_front()
	commands.append({"command": command, "time": clock})

func consume(command: StringName) -> bool:
	for i in range(commands.size()):
		if commands[i].command == command:
			commands.remove_at(i)
			return true
	return false

func clear() -> void:
	commands.clear()
