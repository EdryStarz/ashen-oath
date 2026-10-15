extends SceneTree
func _initialize():call_deferred("run")
func run():
 var w=load("res://scripts/world.gd").new()
 root.add_child(w)
 w.set_reduced_motion(true)
 await process_frame
 await process_frame
 print("SKELETON_BASIS ",w.hero_skeleton.global_basis)
 print("ARM_BASIS ",w.right_arm.basis)
 print("HAND_GLOBAL ",w.right_arm.get_parent().global_transform)
 print("WEAPON_BASIS ",w.weapon.global_basis)
 quit()
