-- visualtext mod by eye_mine,QQ:11758980  IRC:eye_mine  (usual offline)
-- modified from signs mod
-- License: LGPLv2+

-- Font: 04.jp.org  --今后扩展unicode用到的字体下载网址  
--TODO:彩色字,大字体,UNICODE编码支持等后续功能,可参考homedecor_modpack\signs_lib这个mod的代码.目前是6px字体,大约距离5米能看到,有待加大字体.
vtalk_data={}  --保存所有玩家的vtalk数据

local chars_file = io.open(minetest.get_modpath("vtext").."/characters", "r")
local charmap = {}
-- CONSTANTS
local max_chars = 50   --字数限制仍然只有17个,不知哪句代码有BUG.
local vtext_maxage=2000    --默认60秒后隐藏message,  注:一个step=30ms,经实测
local showtext_height=1.8  --显示在头顶的文字离玩家坐标多少米
local modname="vtext"
local texturespath=minetest.get_modpath(modname).."/textures"
minetest.register_on_chat_message(function(name, message)

	local player = core.get_player_by_name(name)
	if player == nil then
		core.log("error", "player is nil")
		return false, "Unable to get current position; player is nil"
	end
	
	local owner=player
	local pos=player:getpos()
	local radians=player:get_look_yaw()+math.pi / 2  --让对面的人能看到正面的字               --radians:弧度
	vtalk_data[name].vtextent:set_properties({textures={generate_texture(create_lines(message))}})	
	vtalk_data[name].vtextent:set_properties({is_visible = true})
	vtalk_data[name].vtextent:setyaw(radians)
	vtalk_data[name].lastpos=pos
	vtalk_data[name].lastyaw=radians
	vtalk_data[name].vtext_age=0
end
)
minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = vector.round(player:getpos())
		local radians=player:get_look_yaw()+math.pi / 2  --让对面的人能看到正面的字             --radians:弧度
		local vtextpos={x=pos.x,y=pos.y+showtext_height,z=pos.z}
		if vtalk_data[name].vtextent~=nil and vtalk_data[name].vtext_age~=nil then
		vtalk_data[name].vtext_age=vtalk_data[name].vtext_age+1
		
			if vtalk_data[name].vtext_age>vtext_maxage then --默认60秒后隐藏message,  注:一个step=30ms,经实测
			vtalk_data[name].vtextent:set_properties({is_visible = false})
			vtalk_data[name].vtext_age=nil
			elseif pos~=vtalk_data[name].oldpos then
			vtalk_data[name].vtextent:moveto(vtextpos)
			vtalk_data[name].vtextent:setyaw(radians)
			elseif radians~=vtalk_data[name].vtextent.lastyaw  then
			vtalk_data[name].vtextent:setyaw(radians)
			end
		end
	end
end)

if not chars_file then
    print("[vtext] E: character map file not found")
else
    while true do
        local char = chars_file:read("*l")
        if char == nil then
            break
        end
        local img = chars_file:read("*l")
        chars_file:read("*l")
        charmap[char] = img
    end
end

local add_vtextent = function(player_name,pos)
	local vtextent=minetest.env:add_entity({x = pos.x ,
										y = pos.y + showtext_height,
										z = pos.z }, "vtext:text")
	local player = core.get_player_by_name(player_name)
	vtalk_data[player_name].vtextent=vtextent
end
minetest.register_entity("vtext:text", {
    collisionbox = { 0, 0, 0, 0, 0, 0 },
    visual = "upright_sprite",
    textures = {},
	is_visible = false,
    on_activate = function(self)
        local meta = minetest.env:get_meta(self.object:getpos())
        self.object:set_properties({textures={texturespath.."/_0.png"},is_visible = false})	--默认贴图为字符0,不显示
    end
})

-- CONSTANTS
local VTEXT_WITH = 110
local VTEXT_PADDING = 8

local LINE_LENGTH = 50
local NUMBER_OF_LINES = 4

local LINE_HEIGHT = 14
local CHAR_WIDTH = 5

string_to_array = function(str)
	local tab = {}
	for i=1,string.len(str) do
		table.insert(tab, string.sub(str, i,i))
	end
	return tab
end

string_to_word_array = function(str)
	local tab = {}
	local current = 1
	tab[1] = ""
	for _,char in ipairs(string_to_array(str)) do
		if char ~= " " then
			tab[current] = tab[current]..char
		else
			current = current+1
			tab[current] = ""
		end
	end
	return tab
end

create_lines = function(text)
	local line = ""
	local line_num = 1
	local tab = {}
	for _,word in ipairs(string_to_word_array(text)) do
		if string.len(line)+string.len(word) < LINE_LENGTH and word ~= "|" then
			if line ~= "" then
				line = line.." "..word
			else
				line = word
			end
		else
			table.insert(tab, line)
			if word ~= "|" then
				line = word
			else
				line = ""
			end
			line_num = line_num+1
			if line_num > NUMBER_OF_LINES then
				return tab
			end
		end
	end
	table.insert(tab, line)
	return tab
end

generate_texture = function(lines)
    local texture = "[combine:"..VTEXT_WITH.."x"..VTEXT_WITH
    local ypos = 12
    for i = 1, #lines do
        texture = texture..generate_line(lines[i], ypos)
        ypos = ypos + LINE_HEIGHT
    end
    return texture
end

generate_line = function(s, ypos)
    local i = 1
    local parsed = {}
    local width = 0
    local chars = 0
    while chars < max_chars and i <= #s do
        local file = nil
        if charmap[s:sub(i, i)] ~= nil then
            file = charmap[s:sub(i, i)]
            i = i + 1
        elseif i < #s and charmap[s:sub(i, i + 1)] ~= nil then
            file = charmap[s:sub(i, i + 1)]
            i = i + 2
        else
            print("[vtext] W: unknown symbol in '"..s.."' at "..i.." (probably "..s:sub(i, i)..")")
            i = i + 1
        end
        if file ~= nil then
            width = width + CHAR_WIDTH
            table.insert(parsed, file)
            chars = chars + 1
        end
    end
    width = width - 1

    local texture = ""
    local xpos = math.floor((VTEXT_WITH - 2 * VTEXT_PADDING - width) / 2 + VTEXT_PADDING)
    for i = 1, #parsed do
        texture = texture..":"..xpos..","..ypos.."="..parsed[i]..".png"
        xpos = xpos + CHAR_WIDTH + 1
    end
    return texture
end

minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	local pos = vector.round(player:getpos())
	--local vtalkconf = datastorage.get(player_name, "vtalkconf")  --今后可能要增加
	table.insert(vtalk_data,player_name)
	vtalk_data[player_name]={vtext=nil,vtext_age=nil,lastpos=nil,lastyaw=nil}
	add_vtextent(player_name,pos)
end)     

minetest.register_on_leaveplayer(function(player)
	table.remove(vtalk_data,player:get_player_name())--删除角色的数据缓存
end)

if minetest.setting_getbool("log_mod") then
	local diffTime = os.clock() - vtext.startTime
	minetest.log("action", "vtext loaded in "..diffTime.."s.")
end

