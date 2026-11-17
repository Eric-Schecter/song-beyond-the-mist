extends RefCounted
static var language := "en"
static var translations: Dictionary = {}
static var templates: Array = []

static func setup():
	if not translations.is_empty():return
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/localization/en_reference.json"))
	source["雾尽之歌"]="Song Beyond the Mist"
	source["阵亡"]="Defeated"
	source.merge({"分配属性点":"Spend a point","重击 / 防护":"Heavy / Guard","攻速 / 暴击":"Fast / Critical","法力 / 招式":"Mana / Skills"},true)
	source.merge({"开始旅程":"New Journey","退出":"Quit","晨风":"Morningwind","旅歌":"Ballad","语言：中文":"Language: English","休息完毕，记录已更新":"Rested. Checkpoint recorded.","等级 %d！获得属性点，按 P 分配。":"Lv.%d! Attribute point earned. Press P to allocate."},true)
	for chinese in source:
		var english:String=source[chinese]
		translations[english]=chinese
		if "%" in english:
			var placeholder:=RegEx.new();placeholder.compile("%[-+0-9.]*[dfs]")
			var matches:=placeholder.search_all(english)
			if matches.is_empty():continue
			var expression:="^";var cursor:=0
			for found in matches:
				expression+=escape_regex(english.substr(cursor,found.get_start()-cursor).replace("%%","%"))+"(.+?)"
				cursor=found.get_end()
			expression+=escape_regex(english.substr(cursor).replace("%%","%"))+"$"
			var regex:=RegEx.new();regex.compile(expression)
			templates.append([regex,chinese,placeholder])

static func escape_regex(value:String)->String:
	var result:=""
	for c in value:result+=("\\" if c in "\\.^$|?*+()[]{}" else "")+c
	return result

static func text(value:String)->String:
	if language=="en":return value
	setup()
	if value.begins_with("· "):return "· "+text(value.substr(2))
	if translations.has(value):return translations[value]
	for item in templates:
		var found:RegExMatch=item[0].search(value)
		if found==null:continue
		var result:String=item[1];var slots=item[2].search_all(result)
		if slots.size()!=found.get_group_count():continue
		for i in range(slots.size()-1,-1,-1):result=result.left(slots[i].get_start())+found.get_string(i+1)+result.substr(slots[i].get_end())
		return result.replace("%%","%")
	return value

static func restore():
	var config:=ConfigFile.new()
	if config.load("user://language.cfg")==OK:language=str(config.get_value("ui","language","en"))
	if language not in ["en","zh"]:language="en"

static func toggle():
	language="zh" if language=="en" else "en"
	var config:=ConfigFile.new();config.set_value("ui","language",language);config.save("user://language.cfg")
