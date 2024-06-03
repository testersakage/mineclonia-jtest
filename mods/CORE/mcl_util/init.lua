-- legacy file
--
-- all functions below have been moved to `CORE/mineclonia`.
-- These shims exist solely for the purpose of backward compatibility.

mcl_util = {}

mcl_util.get_luaentity_by_id = mineclonia.get_luaentity_by_id

mcl_util.mcl_log = mineclonia.log

mcl_util.file_exists = mineclonia.file_exists

mcl_util.rotate_axis_and_place = mineclonia.rotate_axis_and_place

mcl_util.rotate_axis = mineclonia.rotate_axis

mcl_util.is_pointing_above_middle = mineclonia.is_pointing_above_middle

mcl_util.get_double_container_neighbor_pos = mineclonia.get_double_container_neighbor_pos

mcl_util.get_eligible_transfer_item_slot = mineclonia.get_eligible_transfer_item_slot

mcl_util.move_item = mineclonia.move_item

mcl_util.move_item_container = mineclonia.move_item_container

mcl_util.get_first_occupied_inventory_slot = mineclonia.get_first_occupied_inventory_slot

mcl_util.drop_item_stack = mineclonia.drop_item_stack

mcl_util.drop_items_from_meta_container = mineclonia.drop_items_from_meta_container

mcl_util.is_fuel = mineclonia.is_fuel

mcl_util.generate_on_place_plant_function = mineclonia.generate_on_place_plant_function

mcl_util.get_object_center = mineclonia.get_object_center

mcl_util.get_color = mineclonia.get_color

mcl_util.call_on_rightclick = mineclonia.call_on_rightclick

mcl_util.calculate_durability = mineclonia.calculate_durability

mcl_util.use_item_durability = mineclonia.use_item_durability

mcl_util.deal_damage = mineclonia.deal_damage

mcl_util.get_hp = mineclonia.get_hp

mcl_util.get_inventory = mineclonia.get_inventory

mcl_util.get_wielded_item = mineclonia.get_wielded_item

mcl_util.get_object_name = mineclonia.get_object_name

mcl_util.replace_mob = mineclonia.replace_mob

mcl_util.get_pointed_thing = mineclonia.get_pointed_thing

mcl_util.set_properties = mineclonia.set_properties

mcl_util.set_bone_position = mineclonia.set_bone_position

mcl_util.bypass_buildable_to = mineclonia.bypass_buildable_to

mcl_util.check_area_protection = mineclonia.check_area_protection

mcl_util.check_position_protection = mineclonia.check_position_protection

mcl_util.safe_place = mineclonia.safe_place

mcl_util.get_pos_p2 = mineclonia.get_pos_p2

mcl_util.in_cube = mineclonia.in_cube

mcl_util.traverse_tower = mineclonia.traverse_tower

mcl_util.replace_node_vm = mineclonia.replace_node_vm

mcl_util.circle_replace_node_vm = mineclonia.circle_replace_node_vm

mcl_util.bulk_set_node_vm = mineclonia.bulk_set_node_vm

mcl_util.circle_bulk_set_node_vm = mineclonia.circle_bulk_set_node_vm

mcl_util.create_ground_turnip = mineclonia.create_ground_turnip
