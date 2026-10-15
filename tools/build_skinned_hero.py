"""Blender 4.5: adapt CC BY Sintel source into an animated mobile GLB.
Run with --disable-autoexec. No source scripts are executed.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector, Quaternion

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models/iara_skinned'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='DESELECT')
objects = [o for o in bpy.data.objects if o.type == 'MESH']
for o in list(bpy.data.objects):
    if o.type != 'MESH': bpy.data.objects.remove(o, do_unlink=True)

def material(name, color, rough=.8, source=None, metal=0):
    m=bpy.data.materials.new(name);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Roughness'].default_value=rough
    bs.inputs['Metallic'].default_value=metal
    if source:
        for filename,slot in [('color.jpg','Base Color'),('roughness.jpg','Roughness')]:
            node=m.node_tree.nodes.new('ShaderNodeTexImage')
            node.image=bpy.data.images.load(str(ROOT/'assets/materials'/source/filename),check_existing=True)
            if slot!='Base Color': node.image.colorspace_settings.name='Non-Color'
            m.node_tree.links.new(node.outputs['Color'],bs.inputs[slot])
        tex=m.node_tree.nodes.new('ShaderNodeTexImage')
        tex.image=bpy.data.images.load(str(ROOT/'assets/materials'/source/'normal.png'),check_existing=True)
        tex.image.colorspace_settings.name='Non-Color'
        normal=m.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.35
        m.node_tree.links.new(tex.outputs['Color'],normal.inputs['Color'])
        m.node_tree.links.new(normal.outputs['Normal'],bs.inputs['Normal'])
    return m

mats={
 'skin':material('Iara_skin',(.43,.25,.18),.7),
 'shirt':material('Iara_jerkin',(.15,.13,.1),source='leather'),
 'pants':material('Iara_woven',(.08,.1,.09),source='cloth'),
 'boots':material('Iara_boots',(.09,.06,.04),source='leather'),
 'metal':material('Iara_buckles',(.25,.20,.12),.7,'metal',.65),
 'ceramic':material('Iara_prosthesis',(.42,.47,.42),.58,metal=.08),
 'eye':material('Iara_eyes',(.72,.69,.58),.26),
 'iris':material('Iara_iris',(.055,.12,.09),.28),
 'pupil':material('Iara_pupil',(.004,.005,.004),.2),
 'hair':material('Iara_hair',(.018,.013,.009),.72),
}
for o in objects:
    bpy.context.view_layer.objects.active=o;o.select_set(True)
    for mod in list(o.modifiers):
        if mod.type in ('SUBSURF','MULTIRES'):
            mod.levels=1
        try:bpy.ops.object.modifier_apply(modifier=mod.name)
        except RuntimeError:o.modifiers.remove(mod)
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    if o.name in ['GEO-body','GEO-gloves']:
        for vertex in o.data.vertices:
            x=abs(vertex.co.x)
            if x>.64 and vertex.co.z>1.20:
                side=1 if vertex.co.x>0 else -1
                angle=min(2.8,(x-.64)*22)
                vertex.co.x=side*(.64+math.sin(angle)*.036)
                vertex.co.z-=(1-math.cos(angle))*.034
    o.data.materials.clear()
    key='shirt' if 'shirt' in o.name else 'boots' if 'boots' in o.name or 'gloves' in o.name or 'belt' in o.name else 'pants' if 'pants' in o.name else 'eye' if 'eye' in o.name or 'cornea' in o.name else 'skin'
    if any(s in o.name for s in ['buckle','rivets','hooks']):key='metal'
    o.data.materials.append(mats[key])
    for poly in o.data.polygons:poly.use_smooth=True
    # Ceramic left prosthesis retains the source's actual arm/hand anatomy.
    if o.name in ['GEO-body','GEO-gloves']:
        o.data.materials.append(mats['ceramic'])
        for poly in o.data.polygons:
            center=sum((o.data.vertices[i].co for i in poly.vertices),Vector())/len(poly.vertices)
            if center.x < -.23 and center.z > 1.20:poly.material_index=1
    o.select_set(False)

# A fitted swept hair cap and individual locks, rather than a helmet sphere.
verts=[];faces=[]
for row in range(17):
    t=row/16
    for col in range(49):
        a=col/48*math.tau
        # Higher frontal hairline; nape and side locks descend around the head.
        lower=1.46+.11*max(0,-math.sin(a))
        theta=t*math.acos(max(-1,min(1,(lower-1.57)/.12)))
        z=1.57+.12*math.cos(theta)
        radius=math.sin(theta)
        ripple=1+.022*math.sin(a*31+t*8)
        verts.append((math.cos(a)*.086*radius*ripple, .004+math.sin(a)*.098*radius*ripple,z))
for r in range(16):
    for c in range(48):
        i=r*49+c;faces.append((i,i+1,i+50,i+49))
mesh=bpy.data.meshes.new('Swept_hair');mesh.from_pydata(verts,[],faces);mesh.update()
hair=bpy.data.objects.new('Iara_hair_cap',mesh);bpy.context.collection.objects.link(hair);hair.data.materials.append(mats['hair']);objects.append(hair)
for p in mesh.polygons:p.use_smooth=True

def sphere(name,location,scale,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=location)
    o=bpy.context.object;o.name=name;o.scale=scale
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    o.data.materials.append(mat)
    for p in o.data.polygons:p.use_smooth=True
    objects.append(o);return o
for side in [-1,1]:
    sphere('Iris', (side*.033,-.082,1.525),(.014,.005,.014),mats['iris'])
    sphere('Pupil',(side*.033,-.087,1.525),(.006,.002,.008),mats['pupil'])
    for i in range(11):
        sphere('Hair_lock',(side*(.081+.012*math.sin(i*1.5)),.01+i*.001,1.54-i*.022),(.017,.017,.028),mats['hair'])

# Fitted, closed shoulder/sleeve shell from the anatomical surface.
body=bpy.data.objects['GEO-body']
verts=[tuple(v.co+v.normal*.0035) for v in body.data.vertices]
faces=[]
for poly in body.data.polygons:
    p=sum((body.data.vertices[i].co for i in poly.vertices),Vector())/len(poly.vertices)
    if .99 < p.z < 1.41 and abs(p.x)<.46:
        if abs(p.x)<.055 and p.z>1.35:continue
        if p.x < -.24:continue
        faces.append(tuple(poly.vertices))
mesh=bpy.data.meshes.new('Fitted_coat_shell');mesh.from_pydata(verts,[],faces);mesh.update()
coat=bpy.data.objects.new('Iara_fitted_coat',mesh);bpy.context.collection.objects.link(coat)
coat.data.materials.append(mats['shirt']);objects.append(coat)
for p in mesh.polygons:p.use_smooth=True
# Tailored split skirt: narrower waist, weighted drape and asymmetric hem.
for side in [-1,1]:
    vertices=[];polygons=[]
    for row in range(17):
        v=row/16
        for col in range(25):
            u=col/24;angle=side*(.10+u*2.8)
            r=.145+.045*math.sin(v*math.pi*.7)
            y=-math.cos(angle)*(r*.80)+math.sin(u*math.pi*6+v)*v*.006
            vertices.append((math.sin(angle)*r,.003+y, .965-v*(.60 if side<0 else .51)+math.sin(u*math.pi*4)*v*v*.009))
    for row in range(16):
        for col in range(24):
            k=row*25+col;polygons.append((k,k+1,k+26,k+25))
    mesh=bpy.data.meshes.new('Tailored_coat');mesh.from_pydata(vertices,[],polygons);mesh.update()
    skirt=bpy.data.objects.new('Iara_coat_'+str(side),mesh);bpy.context.collection.objects.link(skirt);skirt.data.materials.append(mats['shirt']);objects.append(skirt)
    for p in mesh.polygons:p.use_smooth=True
    bpy.context.view_layer.objects.active=skirt;skirt.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project();bpy.ops.object.mode_set(mode='OBJECT');skirt.select_set(False)

# Deformation skeleton in the source's Z-up metre coordinates.
bpy.ops.object.armature_add()
rig=bpy.context.object;rig.name='IaraRig'
bpy.ops.object.mode_set(mode='EDIT');rig.data.edit_bones.remove(rig.data.edit_bones[0])
segments={}
def bone(name,head,tail,parent=None):
    b=rig.data.edit_bones.new(name);b.head=head;b.tail=tail
    if parent:b.parent=rig.data.edit_bones[parent]
    segments[name]=(Vector(head),Vector(tail));return b
bone('pelvis',(0,0,.88),(0,0,1.02))
bone('spine',(0,0,1.02),(0,0,1.20),'pelvis')
bone('chest',(0,0,1.20),(0,0,1.34),'spine')
bone('neck',(0,0,1.34),(0,0,1.43),'chest')
bone('head',(0,0,1.43),(0,0,1.65),'neck')
for side,suffix in [(1,'R'),(-1,'L')]:
    bone('clavicle.'+suffix,(0,0,1.31),(side*.13,0,1.31),'chest')
    bone('upper_arm.'+suffix,(side*.13,0,1.31),(side*.36,0,1.31),'clavicle.'+suffix)
    bone('forearm.'+suffix,(side*.36,0,1.31),(side*.57,0,1.31),'upper_arm.'+suffix)
    bone('hand.'+suffix,(side*.57,0,1.31),(side*.71,0,1.31),'forearm.'+suffix)
    bone('thigh.'+suffix,(side*.074,0,.9),(side*.083,0,.52),'pelvis')
    bone('shin.'+suffix,(side*.083,0,.52),(side*.083,0,.09),'thigh.'+suffix)
    bone('foot.'+suffix,(side*.083,0,.09),(side*.083,-.15,.045),'shin.'+suffix)
bpy.ops.object.mode_set(mode='OBJECT')
def dist(p,a,b):
    return (p-(a+(b-a)*max(0,min(1,(p-a).dot(b-a)/(b-a).length_squared)))).length
for o in objects:
    groups={name:o.vertex_groups.new(name=name) for name in segments}
    for v in o.data.vertices:
        p=v.co
        candidates=list(segments)
        if 'Hair' in o.name or 'hair' in o.name or 'Iris' in o.name or 'Pupil' in o.name or 'eye' in o.name or 'cornea' in o.name:candidates=['head']
        elif p.z>1.42:candidates=['head','neck']
        elif abs(p.x)>.18 and p.z>1.20:
            suffix='R' if p.x>0 else 'L';candidates=['clavicle.'+suffix,'upper_arm.'+suffix,'forearm.'+suffix,'hand.'+suffix,'chest']
        elif p.z<.85:
            suffix='R' if p.x>=0 else 'L';candidates=['thigh.'+suffix,'shin.'+suffix,'foot.'+suffix,'pelvis']
        else:candidates=['pelvis','spine','chest','neck']
        if o.name in ["GEO-body","GEO-shirt","GEO-pants","GEO-boots","Iara_fitted_coat"]: candidates=list(segments)
        nearest=sorted([(dist(p,*segments[n]),n) for n in candidates])[:4]
        weights=[math.exp(-d*45) for d,n in nearest];total=sum(weights)
        for (_,n),weight in zip(nearest,weights):groups[n].add([v.index],weight/total,'REPLACE')
    mod=o.modifiers.new('Skin','ARMATURE');mod.object=rig;o.parent=rig

def world_rotation(name,axis,angle):
    b=rig.pose.bones[name];q=rig.data.bones[name].matrix_local.to_quaternion()
    b.rotation_mode='QUATERNION';b.rotation_quaternion=q.inverted()@Quaternion(axis,angle)@q
def pose(frame,attack=0,breath=0,hurt=0):
    for b in rig.pose.bones:b.rotation_mode='QUATERNION';b.rotation_quaternion=Quaternion()
    world_rotation('upper_arm.L',(0,1,0),-1.18+.04*breath)
    world_rotation('upper_arm.R',(0,1,0),1.05-attack*.80)
    world_rotation('forearm.R',(0,0,1),-.27-attack*.55)
    world_rotation('forearm.L',(0,0,1),.12)
    world_rotation('chest',(0,0,1),attack*.28)
    world_rotation('spine',(1,0,0),breath*.008+hurt*.2)
    world_rotation('head',(1,0,0),-breath*.012-hurt*.10)
    for suffix in ['L','R']:world_rotation('thigh.'+suffix,(1,0,0),.03)
    for b in rig.pose.bones:b.keyframe_insert('rotation_quaternion',frame=frame)
rig.animation_data_create()
for name,length,keys in [('idle',72,[(1,0,0,0),(19,0,1,0),(37,0,0,0),(55,0,-1,0),(73,0,0,0)]),('strike',28,[(1,0,0,0),(9,-.35,0,0),(15,1,0,0),(21,.3,0,0),(29,0,0,0)]),('hit',20,[(1,0,0,0),(7,0,0,1),(21,0,0,0)])]:
    action=bpy.data.actions.new(name);rig.animation_data.action=action
    for key in keys:pose(*key)
    action.use_fake_user=True
    track=rig.animation_data.nla_tracks.new();track.name=name
    strip=track.strips.new(name,1,action)
rig.animation_data.action=None
bpy.context.scene.frame_set(1)
bpy.context.scene.render.fps=24
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
for o in objects:o.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(OUT/'iara.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_skins=True,export_yup=True)
print('SKINNED_HERO_EXPORTED',len(objects),'meshes',len(rig.data.bones),'bones')
