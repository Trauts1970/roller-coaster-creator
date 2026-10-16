@static_unload
extends RefCounted
## Resolution-independent procedural materials. Presentation never mutates game models.
static func gradient(c: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
 c.draw_polygon(PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]),PackedColorArray([top,top,bottom,bottom]))

static var glow_texture: ImageTexture
static func glow(c: CanvasItem, p: Vector2, radius: float, color: Color, strength: float = 0.35) -> void:
 if glow_texture == null:
  var im := Image.create(96,96,false,Image.FORMAT_RGBA8)
  for yy in 96:
   for xx in 96:
    var d := Vector2((xx-47.5)/47.5,(yy-47.5)/47.5).length_squared()
    im.set_pixel(xx,yy,Color(1,1,1,pow(maxf(0.0,1.0-d),3.0)))
  glow_texture=ImageTexture.create_from_image(im)
 c.draw_texture_rect(glow_texture,Rect2(p-Vector2.ONE*radius,Vector2.ONE*radius*2),false,Color(color,strength))

static func line(c: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
 c.draw_line(a,b,Color(color,0.045),width*6.0,true)
 c.draw_line(a,b,Color(color,0.12),width*3.0,true)
 c.draw_line(a,b,color,width,true)

static func poly(c: CanvasItem, pts: PackedVector2Array, color: Color, edge: Color = Color.TRANSPARENT, width: float = 0.7) -> void:
 c.draw_colored_polygon(pts,color)
 if edge.a > 0:
  var border := pts.duplicate()
  border.append(pts[0])
  c.draw_polyline(border,edge,width,true)

static func panel(c: CanvasItem, r: Rect2, color: Color = Color("0a1729"), accent: Color = Color("48ddd7"), radius: float = 5.0) -> void:
 var pts := PackedVector2Array()
 var centers := [r.position+Vector2(radius,radius),Vector2(r.end.x-radius,r.position.y+radius),r.end-Vector2(radius,radius),Vector2(r.position.x+radius,r.end.y-radius)]
 for corner in 4:
  for step in 5:
   var angle := PI+corner*PI/2.0+step*PI/8.0
   pts.append(centers[corner]+Vector2.from_angle(angle)*radius)
 poly(c,pts,color,Color(accent,0.3),0.65)
 c.draw_line(r.position+Vector2(radius,0),Vector2(r.end.x-radius,r.position.y),Color(accent,0.65),0.7,true)

static func text(c: CanvasItem, value: String, p: Vector2, size: int, color: Color = Color("e3f5fc"), centered: bool = false) -> void:
 var font := ThemeDB.fallback_font
 if centered: p.x -= font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*0.5
 c.draw_string(font,p+Vector2(0,1),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color(0.01,0.025,0.045,0.8))
 c.draw_string(font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

static func stars(c: CanvasItem, r: Rect2, t: float, count: int = 65) -> void:
 for i in count:
  var x := r.position.x+fposmod(i*137.71-t*(1.0+i%3),r.size.x)
  var y := r.position.y+fposmod(i*73.19,r.size.y)
  var a := 0.25+0.35*(0.5+0.5*sin(t*0.6+i*3.0))
  c.draw_circle(Vector2(x,y),0.35+(i%3)*0.16,Color(0.66,0.85,1.0,a),true,-1,true)

static func tree(c: CanvasItem, p: Vector2, height: float, color: Color, wind: float = 0.0) -> void:
 c.draw_line(p,p-Vector2(-wind,height*0.8),color.darkened(0.35),height*0.055,true)
 for i in range(3):
  var y := height*(0.25+i*0.22)
  poly(c,PackedVector2Array([p+Vector2(-height*(0.28-i*0.045),-y),p+Vector2(wind,-height*(0.68+i*0.16)),p+Vector2(height*(0.28-i*0.045),-y)]),color.lightened(i*0.025))

static func theme_ui(root: Control) -> void:
 var theme := Theme.new()
 theme.default_font_size = 18
 for type in ["Button","OptionButton","ItemList","PanelContainer","ProgressBar"]:
  for state in ["normal","panel","background"]:
   var style := StyleBoxFlat.new()
   style.bg_color = Color("0b2638")
   style.border_color = Color("285669")
   style.set_border_width_all(1)
   style.set_corner_radius_all(9)
   style.content_margin_left = 13
   style.content_margin_right = 13
   theme.set_stylebox(state,type,style)
  for state in ["hover","pressed","focus","selected","fill"]:
   var style := StyleBoxFlat.new()
   style.bg_color = Color("14606a") if state != "focus" else Color(0.1,0.4,0.45,0.2)
   style.border_color = Color("64eadd")
   style.set_border_width_all(1)
   style.set_corner_radius_all(9)
   theme.set_stylebox(state,type,style)
  theme.set_color("font_color",type,Color("dbf7f5"))
 root.theme = theme
