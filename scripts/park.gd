extends Node3D
## Seeded scenery is separate from track geometry and physics.
var materials := {}
var forest_positions: Array[Vector3]=[]
func mat(color: Color, metal: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
 var key := str(color)+str(metal)+str(emission)
 if materials.has(key): return materials[key]
 var m := StandardMaterial3D.new()
 m.albedo_color=color
 m.metallic=metal
 m.roughness=.35 if metal>0 else .86
 if emission>0:
  m.emission_enabled=true
  m.emission=color
  m.emission_energy_multiplier=emission
 materials[key]=m
 return m
func primitive(shape: Mesh, p: Vector3, color: Color, metal: float = 0.0) -> MeshInstance3D:
 var n := MeshInstance3D.new()
 n.mesh=shape
 n.material_override=mat(color,metal)
 n.position=p
 add_child(n)
 return n
func block(p: Vector3, size: Vector3, color: Color, metal: float = 0.0) -> MeshInstance3D:
 var m := BoxMesh.new()
 m.size=size
 return primitive(m,p,color,metal)
func cylinder(p: Vector3, radius: float, height: float, color: Color, top: float = -1) -> MeshInstance3D:
 var mesh := CylinderMesh.new()
 mesh.bottom_radius=radius
 mesh.top_radius=radius if top<0 else top
 mesh.height=height
 mesh.radial_segments=10
 return primitive(mesh,p,color)
func setup(samples: Array) -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var ground := PlaneMesh.new()
 ground.size=Vector2(1600,1600)
 var terrain := primitive(ground,Vector3(0,-.08,-100),Color("537a68"))
 var shader := Shader.new()
 shader.code = """shader_type spatial;
render_mode cull_disabled;
void fragment(){
 vec2 p=UV*800.0;
 float n=fract(sin(dot(floor(p),vec2(127.1,311.7)))*43758.5453);
 float patch=sin(p.x*0.047)*sin(p.y*0.081);
 ALBEDO=mix(vec3(0.16,0.30,0.25),vec3(0.32,0.43,0.27),n*0.28+patch*0.22+0.35);
 ROUGHNESS=0.95;
}"""
 var sm := ShaderMaterial.new();sm.shader=shader;terrain.material_override=sm
 var rng := RandomNumberGenerator.new();rng.seed=1970
 # Smooth mountain terrain with analytic normals, beyond the editable demonstration area.
 var vertices:=PackedVector3Array()
 var normals:=PackedVector3Array()
 var indices:=PackedInt32Array()
 var grid:=60
 for zz in range(grid+1):
  for xx in range(grid+1):
   var x:float=-600+xx*20.0
   var z:float=-700+zz*20.0
   var h:=hill_height(x,z)
   vertices.append(Vector3(x,h,z))
   normals.append(Vector3(hill_height(x-1,z)-hill_height(x+1,z),2.0,hill_height(x,z-1)-hill_height(x,z+1)).normalized())
 for zz in grid:
  for xx in grid:
   var i:=zz*(grid+1)+xx
   indices.append_array(PackedInt32Array([i,i+grid+1,i+1,i+1,i+grid+1,i+grid+2]))
 var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
 var hills:=ArrayMesh.new();hills.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 primitive(hills,Vector3.ZERO,Color("577b79"))
 # Instance the forest to keep draw calls bounded on Deck.
 var trunks := MultiMesh.new();trunks.transform_format=MultiMesh.TRANSFORM_3D
 var trunk := CylinderMesh.new();trunk.bottom_radius=.4;trunk.top_radius=.2;trunk.height=5;trunk.radial_segments=6;trunks.mesh=trunk
 var crowns := MultiMesh.new();crowns.transform_format=MultiMesh.TRANSFORM_3D
 var crown := CylinderMesh.new();crown.bottom_radius=3.8;crown.top_radius=.2;crown.height=11;crown.radial_segments=12;crowns.mesh=crown
 forest_positions.clear()
 var locations: Array[Vector3]=forest_positions
 for i in 380:
  var p := Vector3(rng.randf_range(-220,220),0,rng.randf_range(-340,100))
  var near_track := false
  for j in range(0,samples.size(),10):
   var track: Vector3=samples[j].p
   if Vector2(track.x,track.z).distance_to(Vector2(p.x,p.z))<12: near_track=true;break
  if p.x>80 and p.z<-100: near_track=true
  if p.z>-19 and absf(p.x)<18: near_track=true
  if not near_track:locations.append(p)
 trunks.instance_count=locations.size();crowns.instance_count=locations.size()*3
 for i in locations.size():
  var scale_value := rng.randf_range(.8,1.6)
  trunks.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_value),locations[i]+Vector3.UP*2.5*scale_value))
  for layer in 3:
   var size_value:=scale_value*(1.0-layer*.22)
   crowns.set_instance_transform(i*3+layer,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*size_value),locations[i]+Vector3.UP*(6+layer*3.5)*scale_value))
 for entry in [[trunks,Color("534b3f")],[crowns,Color("28564b")]]:
  var n := MultiMeshInstance3D.new();n.multimesh=entry[0];n.material_override=mat(entry[1]);add_child(n)
 # Reflective lake to the east, with animated normal variation.
 var lake := PlaneMesh.new();lake.size=Vector2(190,300)
 var water := primitive(lake,Vector3(178,.03,-248),Color("3f8793"))
 var ws := Shader.new();ws.code="""shader_type spatial;
render_mode cull_disabled;
void fragment(){
 float w=sin(UV.x*170.0+TIME)*sin(UV.y*210.0+TIME*0.6);
 ALBEDO=vec3(0.08,0.31,0.38)+w*0.025;
 ROUGHNESS=0.22; METALLIC=0.35;
 NORMAL=normalize(vec3(sin(UV.x*140.0+TIME)*0.09,cos(UV.y*160.0+TIME)*0.08,1.0));
}"""
 var wm:=ShaderMaterial.new();wm.shader=ws;water.material_override=wm
 # Station canopy, illuminated ticket building, promenade and low path lights.
 block(Vector3(0,.04,7),Vector3(19,.08,70),Color("899792"))
 block(Vector3(0,1.5,-5),Vector3(8,.5,16),Color("8a9b9c"),.2)
 for xx in [-4.5,4.5]:
  for zz in [-11.0,1.0]:cylinder(Vector3(xx,3.2,zz),.16,6.4,Color("263e54"))
 block(Vector3(0,6.6,-5),Vector3(11,.3,19),Color("25485a"),.4)
 for zz in [-13.0,3.0]:
  var light := block(Vector3(0,6.36,zz),Vector3(8,.05,.15),Color("76ece2"));light.material_override=mat(Color("76ece2"),.2,1.0)
 block(Vector3(-12,2,13),Vector3(9,4,8),Color("d4c5a5"))
 block(Vector3(-12,4.2,13),Vector3(10,.5,9),Color("294554"),.3)
 for xx in [-14.0,-10.0]:block(Vector3(xx,2.2,17.03),Vector3(2.2,1.9,.05),Color("4eafbe"),.3)
 for i in 10:
  for xx in [-7.0,7.0]:
   cylinder(Vector3(xx,.65,12+i*5),.13,1.3,Color("233e4a"))
   var lamp:=cylinder(Vector3(xx,1.35,12+i*5),.2,.18,Color("f7d39d"));lamp.material_override=mat(Color("f7d39d"),0,1.2)

func hill_height(x:float,z:float) -> float:
 var d:=Vector2(x,z+100).length()
 var fade:=smoothstep(220.0,410.0,d)
 return -0.5+fade*(64.0+sin(x*.014)*31.0+cos(z*.017)*27.0+sin(x*.027+z*.018)*17.0)
