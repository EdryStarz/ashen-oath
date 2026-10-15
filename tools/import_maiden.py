"""Convert a user-owned RFA Unity package into a private Godot GLB. No Unity scripts run."""
import argparse, tarfile, hashlib, json, sys
from pathlib import Path
import bpy
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
p=argparse.ArgumentParser(); p.add_argument('--package',required=True); p.add_argument('--output',required=True); a=p.parse_args(args)
root=Path.cwd(); src=root/'.tools/art-source/maiden'; src.mkdir(parents=True,exist_ok=True)
with tarfile.open(a.package) as t:
 members={m.name:m for m in t.getmembers()}
 for m in t.getmembers():
  if not m.name.endswith('/pathname'): continue
  name=t.extractfile(m).read().decode().strip(); target=(src/name).resolve()
  if not target.is_relative_to(src.resolve()): raise ValueError(name)
  entry=members.get(m.name.rsplit('/',1)[0]+'/asset')
  if entry and entry.isfile() and not target.exists():
   target.parent.mkdir(parents=True,exist_ok=True); target.write_bytes(t.extractfile(entry).read())
base=src/'Assets/RFA'; out=Path(a.output).resolve(); out.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(base/'Default Render/Models/RFA_Model.fbx'))
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE'); original=set(bpy.data.objects)
for o in list(bpy.data.objects):
 if o.name in ('Sword','Dagger'): bpy.data.objects.remove(o,do_unlink=True)
from mathutils import Matrix
# Godot requires skinned mesh coordinates in the skeleton's frame; bake FBX geo transforms.
bpy.context.view_layer.update()
for obj in [o for o in bpy.data.objects if o.type=='MESH']:
 transform=Matrix.Rotation(1.5707963267948966,4,'X') @ rig.matrix_world.inverted() @ obj.matrix_world
 obj.data.transform(transform)
 obj.parent=rig; obj.matrix_parent_inverse=Matrix.Identity(4); obj.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()
tex=base/'Common/Textures'
for mat in bpy.data.materials:
 name={'Cloth_mtl':'Clothes','Sword_mtl':'Weapon'}.get(mat.name,mat.name.replace('_mtl',''))
 mat.use_nodes=True; nodes=mat.node_tree.nodes; nodes.clear(); links=mat.node_tree.links
 bs=nodes.new('ShaderNodeBsdfPrincipled'); output=nodes.new('ShaderNodeOutputMaterial'); links.new(bs.outputs['BSDF'],output.inputs['Surface'])
 bs.inputs['Roughness'].default_value=.68
 for kind in ('BaseColor','Normal','AO'):
  path=tex/(name+'_'+kind+'.tga')
  if not path.exists(): continue
  img=bpy.data.images.load(str(path),check_existing=True)
  size=2048 if name=='Head' else 1024
  img.scale(size,size); img.filepath_raw=str(out.parent/(name+'_'+kind+'.png')); img.file_format='PNG'; img.save()
  node=nodes.new('ShaderNodeTexImage'); node.image=img
  if kind=='BaseColor':
   links.new(node.outputs['Color'],bs.inputs['Base Color'])
   if name=='Hair':
    links.new(node.outputs['Alpha'],bs.inputs['Alpha']); mat.surface_render_method='DITHERED'; mat.use_backface_culling=False
  elif kind=='Normal':
   img.colorspace_settings.name='Non-Color'; normal=nodes.new('ShaderNodeNormalMap'); links.new(node.outputs['Color'],normal.inputs['Color']); links.new(normal.outputs['Normal'],bs.inputs['Normal'])
# Imported animation FBXs use the same bind skeleton. Reuse their actions, not duplicate rigs.
for clip, file in [('idle','Idle'),('strike','Attack'),('hit','TakingDamage')]:
 before=set(bpy.data.objects); old=set(bpy.data.actions)
 bpy.ops.import_scene.fbx(filepath=str(base/('Common/Animations/RFA_'+file+'.fbx')))
 source_rig=next(o for o in set(bpy.data.objects)-before if o.type=='ARMATURE')
 source_action=source_rig.animation_data.action
 first,last=map(int,source_action.frame_range)
 action=bpy.data.actions.new(clip); action.use_fake_user=True
 rig.animation_data_create(); rig.animation_data.action=action
 for bone in rig.pose.bones: bone.rotation_mode='QUATERNION'
 for frame in range(first,last+1):
  bpy.context.scene.frame_set(frame); bpy.context.view_layer.update()
  poses={bone.name:bone.matrix.copy() for bone in source_rig.pose.bones}
  for bone in rig.pose.bones:
   if bone.name not in poses: continue
   if bone.parent:
    bone.matrix_basis=bone.bone.matrix_local.inverted() @ bone.parent.bone.matrix_local @ poses[bone.parent.name].inverted() @ poses[bone.name]
   else: bone.matrix_basis=bone.bone.matrix_local.inverted() @ poses[bone.name]
   for prop in ('location','rotation_quaternion','scale'): bone.keyframe_insert(data_path=prop,frame=frame-first+1,group=bone.name)
 for obj in list(set(bpy.data.objects)-before): bpy.data.objects.remove(obj,do_unlink=True)
 track=rig.animation_data.nla_tracks.new(); track.name=clip
 strip=track.strips.new(clip,1,action); strip.action_frame_start=1; strip.action_frame_end=last-first+1
 rig.animation_data.action=None
for track in rig.animation_data.nla_tracks: track.mute=True
from mathutils import Matrix
for bone in rig.pose.bones: bone.matrix_basis=Matrix.Identity(4)
bpy.context.scene.frame_set(0); bpy.context.view_layer.update()
bpy.context.scene.render.fps=30
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_materials='EXPORT',export_texcoords=True,export_normals=True)
manifest={'source':'https://www.cgtrader.com/free-3d-models/character/woman/unity-female-warrior-assassin','author':'RetroStyleGames','license':'CGTrader Royalty Free (no AI); do not redistribute raw resources','source_sha256':hashlib.sha256(Path(a.package).read_bytes()).hexdigest(),'derived_sha256':hashlib.sha256(out.read_bytes()).hexdigest(),'bones':len(rig.data.bones),'clips':['idle','strike','hit'],'changes':'Godot GLB conversion, mobile texture sizes, removed source weapons; original authored rig and animation retained'}
(root/'assets/provenance/maiden-assassin.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('MAIDEN_EXPORT',out,'BONES',len(rig.data.bones))
