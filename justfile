# Launch Godot editor
dev:
    nohup godot ./godot/project.godot &> /dev/null & disown

# Run opening scene
play:
    godot run --path . --scene ./godot/scenes/arachnoise.tscn

# Serve the preview files
serve:
    bunx vite ./godot/export/html/

# Export
export:
    godot --export-release Web ./godot/export/html/index.html
