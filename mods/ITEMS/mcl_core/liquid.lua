

local liquid = {}



function liquid.get_liquidtype(def)
  return def._liquid_type or def.liquidtype
end

function liquid.get_liquidtype_n(name)
  return liquid.get_liquidtype(core.registered_nodes[name])
end


local resume_counter = 1
function liquid.register_liquid(def)

  local queue = {}
  local uniq  = {}

  local function queue_push(pos)
    local s = ''..pos.x..' '..pos.y..' '..pos.z;
    if uniq[s] == nil then
      uniq[s] = pos
      table.insert(queue, pos)
    end
  end

  local def_flowing = def.ndef_flowing
  local def_source = def.ndef_source

  local wait_count = 0

  local modname = minetest.get_current_modname()
  
  local NAME_SOURCE  = def.name_source
  assert(NAME_SOURCE)

  local NAME_FLOWING = def.name_flowing
  assert(NAME_FLOWING)

  local SLOPE_RANGE = def.liquid_slope_range or 0
  assert(SLOPE_RANGE >= 0 and SLOPE_RANGE < 8)

  local SLOPE_RANGE_MIN = def.liquid_slope_range_min or 0
  assert(SLOPE_RANGE_MIN >= 0 and SLOPE_RANGE_MIN < 8)


  local FLOW_DISTANCE = def.liquid_range or 7
  assert(FLOW_DISTANCE >= 0 and FLOW_DISTANCE < 8)

  local RENEWABLE = def.liquid_renewable or false
  local TICKS     = def.liquid_tick or 0.5

  local function get_liquid_level(node)
    if node.name == NAME_SOURCE then
      return 8
    elseif node.name == NAME_FLOWING then
      if bit.band(node.param2, 0x08) ~= 0 then
        return 8
      else 
        return bit.band(node.param2, 0x07)
      end
    else
      return nil
    end 
  end
  
  local function is_floodable(node, level)
    local name = node.name
    if name == 'air' then
      return true
  
    elseif name == NAME_FLOWING then
      local l = get_liquid_level(node)
      if l < level then
        return true
      else
        return false
      end

    else 

      local def = core.registered_nodes[name]
      if def and def.floodable then 
        return true
      else
        return false
      end
    end

    return false
  end
  
  local function is_liquid(node)
    return node.name == NAME_SOURCE or node.name == NAME_FLOWING
  end
  
  local function make_liquid(level)
  
    if level == 8 or level == 'down' then
      return {
        name = NAME_FLOWING,
        param2 = 8,
      }
  
    elseif level == 'source' then
      return {
        name = NAME_SOURCE,
      }
  
    elseif level <= 7-FLOW_DISTANCE then
      return {
        name = 'air'
      }
  
    else
      return {
        name = NAME_FLOWING,
        param2 = bit.band(level, 0x07),
      }
  
    end
  
  end
  
  
  local function find_slope(pos, max_distance, dir)
  
    for i = 1, max_distance do
      pos = pos + dir
      local n      = core.get_node(pos)
      --core.log('name: '..n.name)
      if not (n.name == 'air' or n.name == NAME_SOURCE or n.name == NAME_FLOWING) then
        return 255
      end
  
      n = core.get_node(pos + { x = 0, y = -1, z = 0 })
      if n.name == 'ignore' then
        return nil
      elseif n.name == 'air' or n.name == NAME_SOURCE or n.name == NAME_FLOWING then
        return i
      end
    end
  
    return 255
  end
  
  local function find_nearest_slope_dir(pos, max_distance, on_found)
  
    local dp011 = {x=-1,y=0,z= 0}
    local dp211 = {x= 1,y=0,z= 0}
    local dp110 = {x= 0,y=0,z=-1}
    local dp112 = {x= 0,y=0,z= 1}
  
    local d_min = 255
  
    local d011 = find_slope(pos, max_distance, dp011)
    local d211 = find_slope(pos, max_distance, dp211)
    local d110 = find_slope(pos, max_distance, dp110)
    local d112 = find_slope(pos, max_distance, dp112)
  
    if d011 == nil then return nil end
    if d211 == nil then return nil end
    if d110 == nil then return nil end
    if d112 == nil then return nil end

    if d011 < d_min then
      d_min = d011
    end
  
    if d211 < d_min then
      d_min = d211
    end
  
    if d110 < d_min then
      d_min = d110
    end
  
    if d112 < d_min then
      d_min = d112
    end
    
    if d_min < 255 then
      if d_min == d011 then on_found(pos+dp011) end
      if d_min == d211 then on_found(pos+dp211) end
      if d_min == d110 then on_found(pos+dp110) end
      if d_min == d112 then on_found(pos+dp112) end
      return true
    end
    return false
  end
  
  local function flow_iteration(pos)

    local p111 = pos
    local p011 = pos + {x=-1, y= 0, z= 0}
    local p211 = pos + {x= 1, y= 0, z= 0}
    local p101 = pos + {x= 0, y=-1, z= 0}
    local p121 = pos + {x= 0, y= 1, z= 0}
    local p110 = pos + {x= 0, y= 0, z=-1}
    local p112 = pos + {x= 0, y= 0, z= 1}
  
    local n111 = core.get_node(p111)
    local n011 = core.get_node(p011)
    local n211 = core.get_node(p211)
    local n110 = core.get_node(p110)
    local n112 = core.get_node(p112)
    local n101 = core.get_node(p101)
    local n121 = core.get_node(p121)


    if n011.name == 'ignore' or
       n211.name == 'ignore' or
       n110.name == 'ignore' or
       n112.name == 'ignore' or
       n101.name == 'ignore' or
       n121.name == 'ignore' then


       if is_liquid(n111) then
         -- TODO how to handle that?
       end
       return
     end

  
    local l111 = get_liquid_level(n111)
    local l011 = get_liquid_level(n011)
    local l211 = get_liquid_level(n211)
    local l110 = get_liquid_level(n110)
    local l112 = get_liquid_level(n112)
    local l101 = get_liquid_level(n101)
    local l121 = get_liquid_level(n121)
  
  
    if RENEWABLE then
      count_sources = 0
      if n011.name == NAME_SOURCE then count_sources = count_sources + 1 end
      if n211.name == NAME_SOURCE then count_sources = count_sources + 1 end
      if n110.name == NAME_SOURCE then count_sources = count_sources + 1 end
      if n112.name == NAME_SOURCE then count_sources = count_sources + 1 end
    
      if (n111.name == NAME_FLOWING or n111.name == 'air') and count_sources >= 2 then 
        -- Renew liquid
        core.set_node(pos, { name=NAME_SOURCE })
        if n011.name ~= NAME_SOURCE then queue_push(p011) end
        if n211.name ~= NAME_SOURCE then queue_push(p211) end
        if n110.name ~= NAME_SOURCE then queue_push(p110) end
        if n112.name ~= NAME_SOURCE then queue_push(p112) end
        return
      end
    end
  
    -- calculate the liquid level that is supported here.
    local support_level = 1
  
    if l121 ~= nil then 
      -- node above is a liquid
      support_level = 9
    elseif n111.name == NAME_SOURCE then
      -- the current node is a source
      support_level = 9
    else
      -- the neighboring node on the same Y-plan with the highest level counts
      if l011 ~= nil and support_level < l011 then
        support_level = l011
      end
      if l211 ~= nil and support_level < l211 then
        support_level = l211
      end
      if l110 ~= nil and support_level < l110 then
        support_level = l110
      end
      if l112 ~= nil and support_level < l112 then
        support_level = l112
      end
    end
    -- subtract 1 so that the level reaches from 0 to 8
    support_level = support_level - 1
  
  
    if l111 ~= nil then
      -- The current node is already a liquid
  
      if l111 == support_level then
        -- The current node is on its terminal level
        -- This means it is ready to spread.
        if n101.name == NAME_SOURCE then
          -- the current node is on top of a source node. No more flowing here.
        elseif n101.name == NAME_FLOWING then
          if l101 < 8 then
            -- turn the liquid below into down-flowing
            core.set_node(p101, make_liquid('down'))
          else
            -- The liquid already flows down
          end
        elseif n101.name == 'air' then
          -- flow down
          core.set_node(p101, make_liquid('down'))
  
        else

          -- Calculate the actual slope distance.
          -- It depends on the current level.
          local slope_dist = math.floor((l111-1) * SLOPE_RANGE / 7)

          -- But also allow a minimal distance.
          if slope_dist < SLOPE_RANGE_MIN then
            slope_dist = SLOPE_RANGE_MIN
          end

          local found = find_nearest_slope_dir(p111, slope_dist,
            function (pos)
              -- A slope had been found within the range, so the liquid shall
              -- flow only in that direction.
              local level = l111 - 1
              if is_floodable(core.get_node(pos), level) then 
                core.set_node(pos, make_liquid(level))
              end
            end)
          if found == nil then
            -- We hit an 'ignore' node
            -- TODO Find a performant solution to handle this.
            return
          elseif not found then
            -- There is no slope in the given range, the liquid shall spread in
            -- all directions.
            local level = l111 - 1
            if is_floodable(n011, level) then 
              core.set_node(p011, make_liquid(level))
            end
            if is_floodable(n211, level) then 
              core.set_node(p211, make_liquid(level))
            end
            if is_floodable(n110, level) then 
              core.set_node(p110, make_liquid(level))
            end
            if is_floodable(n112, level) then 
              core.set_node(p112, make_liquid(level))
            end
          end
        end

      elseif l111 > support_level then
        -- The liquid level is too hight here we need to reduce it.

        core.set_node(p111, make_liquid(support_level))
  
        -- Neighboring nodes might need to be reduced as well
        if l011 ~= nil then queue_push(p011) end
        if l211 ~= nil then queue_push(p211) end
        if l110 ~= nil then queue_push(p110) end
        if l112 ~= nil then queue_push(p112) end

        -- the node below might need an update as well, but only if the liquid
        -- has completely gone
        if support_level == 0 and l101 ~= nil then queue_push(p101) end

      else
        -- The liquid level is too low. This happens only in case the algorithm
        -- got interrupted. In normal circumstances this should never happen
        -- because higher level pushes to lower level.

        core.set_node(p111, make_liquid(support_level))
  
        if l011 ~= nil then queue_push(p011) end
        if l211 ~= nil then queue_push(p211) end
        if l110 ~= nil then queue_push(p110) end
        if l112 ~= nil then queue_push(p112) end
        -- We update the node below as well just in case it got stuck as well.
        if l101 ~= nil then queue_push(p101) end
      end
    else
      -- It seams that the current node is not a liquid at all.
      -- We update the neighbors because it might have been a liquid
      -- previously.
      if l011 ~= nil then queue_push(p011) end
      if l211 ~= nil then queue_push(p211) end
      if l110 ~= nil then queue_push(p110) end
      if l112 ~= nil then queue_push(p112) end
      if l101 ~= nil then queue_push(p101) end
      if l101 ~= nil then queue_push(p121) end
    end
  end
  
  
  core.register_on_placenode(queue_push)
  core.register_on_dignode(queue_push)
  

  local function set_common_defs(ndef)

    if ndef.on_construct ~= nil then
      local on_construct = ndef.on_construct
      ndef.on_construct = function(pos)
        queue_push(pos)
        on_construct(pos)
      end
    else
      ndef.on_construct = queue_push
    end

    if ndef.after_destruct ~= nil then
      local after_destruct = ndef.after_destruct
      ndef.after_destruct = function(pos)
        queue_push(pos)
        after_destruct(pos)
      end
    else
      ndef.after_destruct = queue_push
    end


    -- remove attributes that might interfere.
    ndef.liquidtype          = nil
    --ndef.liquid_viscosity    = nil
    --ndef.liquid_renewable    = nil
    --ndef.liquid_range        = nil
    --ndef.liquid_ticks        = nil


    ndef.liquid_alternative_source  = NAME_SOURCE
    ndef.liquid_alternative_flowing = NAME_FLOWING
    ndef.paramtype           = "light"
    ndef.paramtype2          = "flowingliquid"
    --ndef.pointable           = true

    if ndef.liquid_move_physics == nil then
      ndef.liquid_move_physics = true
    end


    ndef._liquid_ticks       = TICKS
    ndef._liquid_renewable   = RENEWABLE
    ndef._liquid_range       = FLOW_DISTANCE
    ndef._liquid_slope_range = SLOPE_RANGE
    
    if not ndef.groups then
      ndef.groups = { }
    end

  end


  set_common_defs(def_source)
  def_source._liquid_type           = 'source'
  def_source.drawtype               = "liquid"
  def_source.groups.liquid_source   = 1

  core.register_node(NAME_SOURCE, def_source)


  set_common_defs(def_flowing)
  def_flowing._liquid_type          = 'flowing'
  def_flowing.drawtype              = "flowingliquid"
  def_flowing.groups.liquid_flowing = 1
  core.register_node(NAME_FLOWING, def_flowing)
  
  
  core.register_lbm({
    label = "Continue the liquids",
  
    name = modname..":resume_liquid_"..resume_counter,
  
    nodenames = {NAME_SOURCE, NAME_FLOWING},
  
    run_at_every_load = true,
  
  
    bulk_action = function(pos_list, dtime_s)
      core.after(5, function(pos_list)
        for i, pos in ipairs(pos_list) do
          queue_push(pos)
        end
      end, pos_list)
    end,
  })

  resume_counter = resume_counter + 1


  local function run()
    core.after(TICKS, function()
      local q = queue
      uniq = {}
      queue = {}

      for i, pos in ipairs(q) do
        flow_iteration(pos)
      end
      run()
    end)
  end

  run()
end

return liquid

