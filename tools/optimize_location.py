"""Build two static Android scene LODs from the CC0 Verdant Trail source."""
import bpy,sys,json,math,hashlib
from pathlib import Path
from mathutils import Vector
root=Path.cwd(); output=root/'assets/models/verdant_mobile'; output.mkdir(parents=True,exist_ok=True)
# Remove procedural scatter before evaluating any mesh to avoid millions of generated instances.
keep=[]; source_triangles=0
for o in list(bpy.data.objects):
 if o.type!='MESH' or o.name in ('IvyLeaves','trail_foliage','fog_volume','shadow_cubes','shadow_tree','particles_volume','particles') or o.name.startswith(('particle_','background_','bacground_','monster')) or not (-10<o.location.x<11 and -8<o.location.y<17):
  bpy.data.objects.remove(o,do_unlink=True); continue
 if o.name not in ('ground','sand') and math.hypot(o.location.x,o.location.y)<1.75:
  bpy.data.objects.remove(o,do_unlink=True); continue
 o.data=o.data.copy()
 o.shape_key_clear()
 for mod in list(o.modifiers): o.modifiers.remove(mod)
 o.hide_render=False; o.hide_viewport=False; o.hide_set(False)
 source_triangles+=sum(len(p.vertices)-2 for p in o.data.polygons)
 if o.name in ('ground','sand'):
  o.data=o.data.copy(); inv=o.matrix_world.inverted()
  for v in o.data.vertices:
   w=o.matrix_world@v.co; d=math.hypot(w.x,w.y)
   if d<3.0: w.z*=max(0,min(1,(d-1.8)/1.2)); v.co=inv@w
 keep.append(o)
used={m for o in keep for m in o.data.materials if m}
texture_bytes=0; texture_count=0; image_cache={}
for mat in used:
 images=[n.image for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image] if mat.use_nodes else []
 def choose(token): return next((i for i in images if any(t in i.name.lower() or t in i.filepath.lower() for t in token)),None)
 diffuse=choose(('_diff','basecolor','albedo')); normal=choose(('_nor_gl','normal')); rough=choose(('_rough',))
 mat.use_nodes=True; mat.node_tree.nodes.clear(); nodes=mat.node_tree.nodes; links=mat.node_tree.links
 bs=nodes.new('ShaderNodeBsdfPrincipled'); dest=nodes.new('ShaderNodeOutputMaterial'); links.new(bs.outputs['BSDF'],dest.inputs['Surface']); bs.inputs['Roughness'].default_value=.9
 for role,img in [('color',diffuse),('normal',normal),('roughness',rough)]:
  if not img: continue
  key=(img.name,role)
  if key not in image_cache:
   copy=img.copy(); size=1024; w,h=copy.size; copy.scale(max(1,int(w*min(1,size/max(w,h)))),max(1,int(h*min(1,size/max(w,h)))))
   copy.file_format='PNG' if role=='normal' or (role=='color' and img.channels==4) else 'JPEG'
   folder=root/'.tools/art-source/locations/mobile-textures'; folder.mkdir(exist_ok=True)
   path=folder/(hashlib.sha256((img.name+role).encode()).hexdigest()[:12]+('.png' if copy.file_format=='PNG' else '.jpg')); copy.filepath_raw=str(path); copy.save(); texture_bytes+=path.stat().st_size; texture_count+=1; image_cache[key]=copy
  node=nodes.new('ShaderNodeTexImage'); node.image=image_cache[key]
  if role=='color':
   links.new(node.outputs['Color'],bs.inputs['Base Color'])
   if any(t in mat.name.lower() for t in ('shrub','leaves','tree_small')):
    links.new(node.outputs['Alpha'],bs.inputs['Alpha']); mat.surface_render_method='DITHERED'; mat.use_backface_culling=False
  elif role=='normal':
   node.image.colorspace_settings.name='Non-Color'; n=nodes.new('ShaderNodeNormalMap'); links.new(node.outputs['Color'],n.inputs['Color']); links.new(n.outputs['Normal'],bs.inputs['Normal'])
  else:
   node.image.colorspace_settings.name='Non-Color'; links.new(node.outputs['Color'],bs.inputs['Roughness'])
profiles=[]
for profile,cap in [('high',7000),('low',2200)]:
 for o in keep:
  bpy.context.view_layer.objects.active=o; o.select_set(True)
  count=sum(len(p.vertices)-2 for p in o.data.polygons)
  if count>cap:
   mod=o.modifiers.new('Android simplification','DECIMATE'); mod.ratio=cap/count; mod.use_collapse_triangulate=True
   bpy.ops.object.modifier_apply(modifier=mod.name)
  o.select_set(False)
 total=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in keep)
 path=output/(profile+'.gltf')
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLTF_SEPARATE',export_animations=False,export_cameras=False,export_lights=False,export_apply=False)
 profiles.append({'profile':profile,'triangles':total,'objects':len(keep),'gltf_json_bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
 print('MOBILE_PROFILE',profiles[-1],flush=True)
manifest={'source':'Poly Haven A Verdant Trail','license':'CC0','source_triangles_selected':source_triangles,'textures':texture_count,'maximum_texture_edge':1024,'texture_source_bytes':texture_bytes,'profiles':profiles,'removed':'render-only fog/particles, scatter nodes, external background and asset-library meshes; flattened central staging area'}
files=[f for f in output.iterdir() if f.suffix in ('.gltf','.bin','.png','.jpg')]
manifest['total_resource_bytes']=sum(f.stat().st_size for f in files)
manifest['files']=[{'name':f.name,'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in sorted(files)]
(root/'assets/provenance/verdant-mobile.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
