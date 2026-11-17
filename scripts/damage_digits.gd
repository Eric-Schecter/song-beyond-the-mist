extends RefCounted
# Original compact bitmap glyphs; independent of dialogue font and resolution.
const DIGITS=[
[14,27,27,27,27,27,14],[6,14,6,6,6,6,15],
[14,27,3,6,12,24,31],[30,3,3,14,3,3,30],
[6,14,22,22,31,6,6],[31,24,24,30,3,3,30],
[14,24,24,30,27,27,14],[31,3,6,6,12,12,12],
[14,27,27,14,27,27,14],[14,27,27,15,3,3,14]]
static func width(value:String)->float:return value.length()*6-1
static func draw(g:Node2D,value:String,critical:bool,alpha:float,age:float):
	var cells:Array[Vector2]=[]
	for i in range(value.length()):
		var ch:=value.substr(i,1)
		var lift:float=roundf(-sin(clampf((age-i*.016)/.14,0,1)*PI))
		if ch=="-":
			for x in range(4):cells.append(Vector2(i*6+x,3))
		elif ch.is_valid_int():
			for y in range(7):
				for x in range(5):
					if DIGITS[int(ch)][y] & (1<<(4-x)):cells.append(Vector2(i*6+x+ (1 if critical and y<3 else 0),y+lift))
	var origin:=Vector2(-width(value)/2,-7)
	for cell in cells:
		g.draw_rect(Rect2(origin+cell-Vector2.ONE,Vector2(3,3)),Color(.12,.075,.06,alpha))
	for cell in cells:
		var color:Color=Color("#fff7c5").lerp(Color("#ffc44c"),clampf(cell.y/6,0,1)) if critical else Color("#fffdf0").lerp(Color("#c9c4b7"),clampf(cell.y/6,0,1))
		if value.begins_with("-"):color=Color("#f0a191")
		color.a=alpha
		g.draw_rect(Rect2(origin+cell,Vector2.ONE),color)
