extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 var scene=load("res://assets/models/verdant_mobile/high.gltf").instantiate()
 for id in ["boulder_01_001", "boulder_01_002"]:
  var node=scene.find_child(id,true,false)
  assert(node!=null)
  var smoothed=ArrayMesh.new()
  for surface in range(node.mesh.get_surface_count()):
   var arrays=node.mesh.surface_get_arrays(surface)
   var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
   var sums={}
   for i in range(vertices.size()):
    var key=Vector3i((vertices[i]*10000.0).round())
    sums[key]=sums.get(key,Vector3.ZERO)+normals[i]
   for i in range(vertices.size()):
    normals[i]=sums[Vector3i((vertices[i]*10000.0).round())].normalized()
   arrays[Mesh.ARRAY_NORMAL]=normals
   smoothed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   smoothed.surface_set_material(surface,node.mesh.surface_get_material(surface))
  assert(ResourceSaver.save(smoothed,"res://assets/models/verdant_mobile/near_"+id+".res")==OK)
 scene.free()
 quit()
