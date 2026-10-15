import bpy,json
from pathlib import Path
records=[]
for o in bpy.data.objects:
 records.append({'name':o.name,'type':o.type,'vertices':len(o.data.vertices) if o.type=='MESH' else 0,'polygons':len(o.data.polygons) if o.type=='MESH' else 0,'dimensions':list(o.dimensions),'location':list(o.location),'materials':[m.name if m else "None" for m in o.data.materials] if o.type=='MESH' else [],'modifiers':[(m.name,m.type) for m in o.modifiers],'bones':list(o.data.bones.keys()) if o.type=='ARMATURE' else []})
Path('.tools/art-source/sintel-inspect.json').write_text(json.dumps(records,indent=2))
print('CHARACTER', [(o['name'],o['vertices']) for o in records if o['type']=='MESH'])

for o in bpy.data.objects:
 if o.type=='MESH':
  pts=[o.matrix_world@v.co for v in o.data.vertices]
  print('BOUNDS',o.name,[(min(p[k] for p in pts),max(p[k] for p in pts)) for k in range(3)],'UV',len(o.data.uv_layers))
print('TEXTS',list(bpy.data.texts.keys()))
