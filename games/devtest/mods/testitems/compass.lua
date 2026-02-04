S = core.get_translator("testitems")

local compass_item_name = "testitems:compass"
local compass_texture_template = "compass_%d.png"
local compass_number_frames = 32
local inv_list_name = "main"

local meta_target = "target"
local meta_current_frame = "current_frame"
local meta_inventory_image = "inventory_image"
local meta_wield_image = "wield_image"

local TAU = 2 * math.pi

local UPDATE_INTERVAL = 0.1

core.register_craftitem(compass_item_name, {
    description = S("Compass") .. "\n" ..
        S("The item is needed to test prevent wield animation when stack metadata changes") .. "\n" ..
        S("The compass in your hand should switch images without twitching") .. "\n" ..
        S("Right-clicking on a node saves the new target position in the stack metadata"),
    inventory_image = compass_texture_template:format(0),
    wield_image = compass_texture_template:format(0),
    stack_max = 1,
    skip_wield_anim_on_meta = true,

    on_place = function(itemstack, placer, pointed_thing)
        itemstack:get_meta():set_string(meta_target, pointed_thing.under:to_string())
        core.chat_send_player(placer:get_player_name(), S("Compass target set to: ") .. core.pos_to_string(pointed_thing.under))
        return itemstack
    end
})

-- Any logic for obtaining a target position.
-- * (0, 0, 0)
-- * metadata
-- * friend position
local function get_target(player, itemstack)
    local meta = itemstack:get_meta()
    local target_str = meta:get_string(meta_target)
    local target = target_str and vector.from_string(target_str) or vector.new(0, 0, 0)
    return target
end

local accumulator = 0
core.register_globalstep(function(dtime)
    accumulator = accumulator + dtime
    if accumulator < UPDATE_INTERVAL then
        return
    end
    accumulator = accumulator - UPDATE_INTERVAL

    for _, player in ipairs(core.get_connected_players()) do
        --- @cast player PlayerObjectRef
        local inv = player:get_inventory()
        if not inv then return end

        local list = inv:get_list(inv_list_name)
        if list then
            for slot = 1, 32 do
                local stack = list[slot]
                local meta = stack:get_meta()

                local target_pos = get_target(player, stack)
                local player_pos = player:get_pos()
                local dx, dz =
                    target_pos.x - player_pos.x,
                    target_pos.z - player_pos.z

                local target_angle = math.atan2(dx, dz)
                local player_dir = player:get_look_horizontal()
                local relative_angle = (player_dir + target_angle) - TAU
                local radians_per_step = TAU / compass_number_frames
                local step_number = math.floor((relative_angle / radians_per_step) + 0.5) % compass_number_frames

                local texture_name = compass_texture_template:format(step_number)

                if stack:get_name() == compass_item_name then
                    if meta:get_int(meta_current_frame) ~= step_number then
                        meta:set_string(meta_inventory_image, texture_name)
                        meta:set_string(meta_wield_image, texture_name)
                        meta:set_int(meta_current_frame, step_number)

                        inv:set_stack(inv_list_name, slot, stack)
                    end
                end
            end
        end
    end
end)
