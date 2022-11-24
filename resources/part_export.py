import bpy
import os

# Blender application is needed
source_dirs = [
    'D:/Projects/saltyfront/resources/mechparts/arml',
    'D:/Projects/saltyfront/resources/mechparts/armr',
    'D:/Projects/saltyfront/resources/mechparts/body',
    'D:/Projects/saltyfront/resources/mechparts/legs',
    ]
output_dirs = [
    'D:/Projects/saltyfront/source/scenes/parts/arml/models',
    'D:/Projects/saltyfront/source/scenes/parts/armr/models',
    'D:/Projects/saltyfront/source/scenes/parts/body/models',
    'D:/Projects/saltyfront/source/scenes/parts/legs/models',
    ]

for i in range(4):
    files = [f for f in os.listdir(source_dirs[i]) if f.endswith('.blend')]
    print(f'Found {len(files)} blend files. Processing...')
    for f in files:
        if not f.endswith('.blend'):
            continue
        path = os.path.join(source_dirs[i], f)
        bpy.ops.wm.open_mainfile(filepath=path)
        bpy.ops.object.select_all(action='DESELECT')
        just_name = f.replace('.blend', '')
        out_path = os.path.join(output_dirs[i], just_name)

        window = bpy.context.window_manager.windows[0]
        with bpy.context.temp_override(window=window):
            bpy.ops.export_scene.gltf(
                filepath=out_path,
                export_format='GLB',
                use_selection=False,)