extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 var scene = load("res://assets/models/verdant_mobile/high.gltf").instantiate()
 root.add_child(scene)
 await process_frame
 var rows=[]
 for node in scene.find_children("*", "MeshInstance3D",true,false):
  var box: AABB=node.global_transform * node.mesh.get_aabb()
  rows.append({"name":node.name,"position":str(node.position),"center":str(box.get_center()),"size":str(box.size)})
 var f=FileAccess.open("res://artifacts/location-layout.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(rows,"  "))
 scene.free()
 quit()
