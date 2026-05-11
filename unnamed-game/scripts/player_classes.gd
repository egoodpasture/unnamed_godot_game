class_name PlayerClasses

# Registry of all available player classes.
# To add a new class:
#   1. Copy one of the dictionaries in ALL_CLASSES below.
#   2. Give it a unique "id" and fill in the other fields.
#   3. Create a new Player scene variant if the class needs different stats/appearance.
#   4. Set "scene_path" to point at your new scene (or reuse the default Player.tscn).
# See scripts/classes/template_class_example.gd for a documented template.

const ALL_CLASSES: Array = [
	{
		"id": "adventurer",
		"display_name": "Construct",
		"description": "A discarded experiment that harnesses the power of darkness.\nHP: 3  |  Speed: Normal",
		"scene_path": "res://scenes/Classes/Construct.tscn",
	},
	# --- Paste new class blocks here ---
]


# Returns the class dictionary for a given id, or an empty dict if not found.
static func get_class_by_id(id: String) -> Dictionary:
	for c in ALL_CLASSES:
		if c["id"] == id:
			return c
	return {}
