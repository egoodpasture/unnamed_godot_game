# template_class_example.gd
#
# HOW TO ADD A NEW PLAYER CLASS
# ==============================
# This file documents the format used by PlayerClasses.ALL_CLASSES.
# To create a new class:
#
#   1. Open scripts/player_classes.gd
#   2. Copy the dictionary block below into ALL_CLASSES.
#   3. Fill in each field as described in the comments.
#   4. (Optional) Duplicate scenes/Player.tscn, rename it, and adjust
#      stats/animations for the new class. Point "scene_path" at your new scene.
#
# Dictionary format:
# {
#     "id": "unique_snake_case_id",   # Must be unique across ALL_CLASSES.
#     "display_name": "Human Name",   # Shown in the class-select menu.
#     "description": "One-liner.\nSecond line with stats.",  # Shown as tooltip.
#     "scene_path": "res://scenes/YourPlayerScene.tscn",     # Player scene to spawn.
# }
#
# Example – a hypothetical "Knight" class:
# {
#     "id": "knight",
#     "display_name": "Knight",
#     "description": "Heavy armour and a shield.\nHP: 5  |  Speed: Slow",
#     "scene_path": "res://scenes/PlayerKnight.tscn",
# }
