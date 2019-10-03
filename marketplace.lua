-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta


local function in_area(pos, pos1, pos2)
	return pos.x >= pos1.x and pos.x <= pos2.x
		and pos.y >= pos1.y and pos.y <= pos2.y
		and pos.z >= pos1.z and pos.z <= pos2.z
end

local function micro_areas(center)
	local i = 0
	local tbl = {
--		{x = 4, y = 0, z = 5},
--		{x = -5, y = 0, z = 4},
--		{x = 5, y = 0, z = -4},
--		{x = -4, y = 0, z = -5},
		{x = 5, y = 0, z = 5},
		{x = -5, y = 0, z = 5},
		{x = 5, y = 0, z = -5},
		{x = -5, y = 0, z = -5},
	}
	return function()
		i = i + 1
		if i <= #tbl then
			local mc = vector.add(center, tbl[i])  -- micro_area_center
			local pos1 = {x = mc.x - 2, y = mc.y - 3, z = mc.z - 2}
			local pos2 = {x = mc.x + 2, y = mc.y + 5, z = mc.z + 2}
			return pos1, pos2
		end
	end
end

local function digger_is_owner(digger_name, pos1, pos2)
	for _,pos in ipairs(minetest.find_nodes_in_area(pos1, pos2, {"shop:shop"})) do
		local owner = M(pos):get_string("owner") or ""
		return owner == digger_name
	end
	return true
end


local function mark_region(pos1, pos2)
	local thickness = 0.2
	local sizex, sizey, sizez = (1 + pos2.x - pos1.x) / 2, (1 + pos2.y - pos1.y) / 2, (1 + pos2.z - pos1.z) / 2
	local markers = {}

	--XY plane markers
	for _, z in ipairs({pos1.z - 0.5, pos2.z + 0.5}) do
		local marker = minetest.add_entity({x=pos1.x + sizex - 0.5, y=pos1.y + sizey - 0.5, z=z}, "protector:region_cube")
		if marker ~= nil then
			marker:set_properties({
				visual_size={x=sizex * 2, y=sizey * 2},
				--collisionbox = {-sizex, -sizey, -thickness, sizex, sizey, thickness},
				collisionbox = {0,0,0, 0,0,0},
			})
			table.insert(markers, marker)
		end
	end

	--YZ plane markers
	for _, x in ipairs({pos1.x - 0.5, pos2.x + 0.5}) do
		local marker = minetest.add_entity({x=x, y=pos1.y + sizey - 0.5, z=pos1.z + sizez - 0.5}, "protector:region_cube")
		if marker ~= nil then
			marker:set_properties({
				visual_size={x=sizez * 2, y=sizey * 2},
				--collisionbox = {-thickness, -sizey, -sizez, thickness, sizey, sizez},
				collisionbox = {0,0,0, 0,0,0},
			})
			marker:setyaw(math.pi / 2)
			table.insert(markers, marker)
		end
	end
end

minetest.register_entity(":protector:region_cube", {
	initial_properties = {
		visual = "upright_sprite",
		textures = {"techage_cube_mark.png"},
		use_texture_alpha = true,
		physical = false,
	},
	timer = 0,

	on_step = function(self, dtime)

		self.timer = self.timer + dtime

		-- remove after 20 seconds
		if self.timer > 20 then
			self.object:remove()
		end
	end,
})


function protector.marketplace_owner(center, dig_pos, digger_name, radius)
	if minetest.get_node(center).name == "protector:protect3" then
		for pos1, pos2 in micro_areas(center) do
			if in_area(dig_pos, pos1, pos2) then
				return digger_is_owner(digger_name, pos1, pos2)
			end
		end
	end
	return false
end

function protector.mark_micro_areas(center)
	if minetest.get_node(center).name == "protector:protect3" then
		for pos1, pos2 in micro_areas(center) do
			mark_region(pos1, pos2)
		end
	end
end
