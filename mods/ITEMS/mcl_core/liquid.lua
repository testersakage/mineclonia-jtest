

local liquid = { }

local resume_counter = 1
function liquid.register_liquid(def)

  local queue = {}
  local uniq  = {}

  local function queue_push(item)
    local pos = item.pos
    local s = ''..pos.x..' '..pos.y..' '..pos.z;
    core.log('push '..s)
    if uniq[s] == nil then
      uniq[s] = item
      table.insert(queue, item)
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


  level_tb = {}
  for i = 0, 8 do
    level_tb[i+1] = math.round(math.floor(i * (FLOW_DISTANCE+1) /  8) * 8 / (FLOW_DISTANCE+1))
  end

  core.log(dump(level_tb))

  local MAX_FLOW_LEVEL = level_tb[8]



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


  local function is_floodable(n)
    if n.name == 'air' or n.name == NAME_FLOWING then
      return 1
    elseif n.name == 'ignore' then
      core.log('ignore')
      return nil
    else
      local ndef = core.registered_nodes[n.name]
      if ndef and ndef.floodable then
        return 1
      end
    end
    return 0
  end
  

  local function path_find(pos)

    local y = pos.y

    local function calc_hash(pos)
      return pos.x..' '..pos.y..' '..pos.z
    end


    local list = {}
    local kmap = {}



    local found = {}

    local function step(pos, level)
      local h = calc_hash(pos)
      if kmap[h] == nil then
        local n = core.get_node(pos)
        local f = n and is_floodable(n)

        if f and f == 1 then
          kmap[h] = level
          list[#list+1] = pos

          local n = core.get_node(pos+vector.new(0,-1,0))
          local f = n and is_floodable(n)
          if f and f == 1 then
            found[#found+1] = pos
          end
        end
      end
    end

    local level = 8
    kmap[calc_hash(pos)] = level


    list[#list+1] = pos

    for i = 1, 8  do
      local l = list
      list = {}

      level = level - 1
      for i, p in ipairs(l) do
        step(p + vector.new(-1, 0, 0), level)
        step(p + vector.new( 1, 0, 0), level)
        step(p + vector.new( 0, 0,-1), level)
        step(p + vector.new( 0, 0, 1), level)
      end
      if #found > 0 then
        break
      end
    end 

    --core.log('{')
    --for i, m in pairs(kmap) do
    --  core.log('  kmap['..i..'] = '..m)
    --end
    --core.log('}')


    --for x = -8,8 do
    --  line = '> '
    --  for z = -8,8 do
    --    local level = kmap[calc_hash(pos + vector.new(x, 0, z))]
    --    if level then
    --      line = line..level..' '
    --    else
    --      line = line..'. '
    --    end
    --  end
    --  core.log(line)
    --end


    --core.log('list = '..dump(list))

    local rmap = {}
    if #found == 0 then
      rmap = kmap
    else 
      list = found


      for nlevel = level, 8 do
        l = list
        list = {}
        for i, p in ipairs(l) do
          local h = calc_hash(p)
          rmap[h] = kmap[h]

          local function back_trace(p)
            local h = calc_hash(p)
            local m = kmap[h]
            if m and m > nlevel then
              list[#list+1] = p
            end
          end

          back_trace(p + vector.new(-1, 0, 0))
          back_trace(p + vector.new( 1, 0, 0))
          back_trace(p + vector.new( 0, 0,-1))
          back_trace(p + vector.new( 0, 0, 1))
        end
      end
    end

    core.log('--------------------------')
    for x = -8,8 do
      line = '> '
      for z = -8,8 do
        local level = rmap[calc_hash(pos + vector.new(x, 0, z))]
        if level then
          line = line..level..' '
        else
          line = line..'. '
        end
      end
      core.log(line)
    end


    return function (pos)
      return rmap[calc_hash(pos)]
    end
  end
  
  
  local function flow_iteration(item)

    local pos = item.pos
    local map = item.map

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
  
  
    -- if the mapblocks surrounding are not active we try later again.
    if n111.name == 'ignore' then
      return
    elseif not (
       core.compare_block_status(pos + {x=-16,y= 0,z= 0}, 'active') and
       core.compare_block_status(pos + {x= 16,y= 0,z= 0}, 'active') and
       core.compare_block_status(pos + {x= 0,y=-16,z= 0}, 'active') and
       core.compare_block_status(pos + {x= 0,y= 16,z= 0}, 'active') and
       core.compare_block_status(pos + {x= 0,y= 0,z=-16}, 'active') and
       core.compare_block_status(pos + {x= 0,y= 0,z= 16}, 'active') 
       ) then
  
      -- TODO There should be a better way to do that.
      --core.after(5, flow_iteration, pos)
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
        if n011.name ~= NAME_SOURCE then queue_push({pos=p011}) end
        if n211.name ~= NAME_SOURCE then queue_push({pos=p211}) end
        if n110.name ~= NAME_SOURCE then queue_push({pos=p110}) end
        if n112.name ~= NAME_SOURCE then queue_push({pos=p112}) end
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

          if not map then
            map = path_find(p111)
          end

          local m011 = map(p011)
          local m211 = map(p211)
          local m110 = map(p110)
          local m112 = map(p112)

          if m011 and l111 > m011 and is_floodable(p011) then
            queue_push({pos=p011, map=map})
            core.set_node(p011, make_liquid(m011))
          end

          if m211 and l111 > m211 and is_floodable(p211) then
            queue_push({pos=p211, map=map})
            core.set_node(p211, make_liquid(m211))
          end

          if m110 and l111 > m110 and is_floodable(p110) then
            queue_push({pos=p110, map=map})
            core.set_node(p110, make_liquid(m110))
          end

          if m112 and l111 > m112 and is_floodable(p112) then
            queue_push({pos=p112, map=map})
            core.set_node(p112, make_liquid(m112))
          end
        end

      elseif l111 > support_level then
        -- The liquid level is too hight here we need to reduce it.

        core.set_node(p111, make_liquid(support_level))
  
        -- Neighboring nodes might need to be reduced as well
        if l011 ~= nil then queue_push({pos=p011}) end
        if l211 ~= nil then queue_push({pos=p211}) end
        if l110 ~= nil then queue_push({pos=p110}) end
        if l112 ~= nil then queue_push({pos=p112}) end

        -- the node below might need an update as well, but only if the liquid
        -- has completely gone
        if support_level == 0 and l101 ~= nil then queue_push({pos=p101}) end

      else
        -- The liquid level is too low. This happens only in case the algorithm
        -- got interrupted. In normal circumstances this should never happen
        -- because higher level pushes to lower level.

        core.set_node(p111, make_liquid(support_level))
  
        if l011 ~= nil then queue_push({pos=p011}) end
        if l211 ~= nil then queue_push({pos=p211}) end
        if l110 ~= nil then queue_push({pos=p110}) end
        if l112 ~= nil then queue_push({pos=p112}) end
        -- We update the node below as well just in case it got stuck as well.
        if l101 ~= nil then queue_push({pos=p101}) end
      end
    else
      -- It seams that the current node is not a liquid at all.
      -- We update the neighbors because it might have been a liquid
      -- previously.
      if l011 ~= nil then queue_push({pos=p011}) end
      if l211 ~= nil then queue_push({pos=p211}) end
      if l110 ~= nil then queue_push({pos=p110}) end
      if l112 ~= nil then queue_push({pos=p112}) end
      if l101 ~= nil then queue_push({pos=p101}) end
    end

  end
  
  local function liquid_update(pos)
    core.log('liquid_update')
    queue_push({pos = pos})
  end
  
  core.register_on_placenode(liquid_update)
  core.register_on_dignode(liquid_update)
  

  local function set_common_defs(ndef)

    if ndef.on_construct ~= nil then
      local on_construct = ndef.on_construct
      ndef.on_construct = function(pos)
        liquid_update(pos)
        on_construct(pos)
      end
    else
      ndef.on_construct = liquid_update
    end

    if ndef.after_destruct ~= nil then
      local after_destruct = ndef.after_destruct
      ndef.after_destruct = function(pos)
        liquid_update(pos)
        after_destruct(pos)
      end
    else
      ndef.after_destruct = liquid_update
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


  core.register_on_mods_loaded(function()
    -- Luanti activates the builtin liquid transformation based on the
    -- `liquidtype`. Therefor we need to set it's value to 'none'.
    -- BUT many mods also read that value to check if this node is a liquid.
    -- This hack sets the value to the respective liquid type after Luanti red
    -- its value.
    -- This way mods see what they need, at least their callbacks do.

    function set_liquidtype(name, liquidtype)
      local mt = getmetatable(core.registered_nodes[name])
      local oldidx = mt.__index
      mt.__index = function(tbl, k)
        if k == "liquidtype" then
          return liquidtype
        end
        if type(oldidx) == "function" then return oldidx(tbl, k) end
        if type(oldidx) == "table" and not rawget(tbl, k) then return oldidx[k] end
        return tbl[k]
      end
      setmetatable(core.registered_nodes[name], mt)
    end

    set_liquidtype(NAME_SOURCE, 'source')
    set_liquidtype(NAME_FLOWING, 'flowing')

    assert(core.registered_nodes[NAME_SOURCE].liquidtype == 'source')
    assert(core.registered_nodes[NAME_FLOWING].liquidtype == 'flowing')

  end)
  
  
  core.register_lbm({
    label = "Continue the liquids",
  
    name = modname..":resume_liquid_"..resume_counter,
  
    nodenames = {NAME_SOURCE, NAME_FLOWING},
  
    run_at_every_load = true,
  
  
    bulk_action = function(pos_list, dtime_s)

      core.log('ok')
      core.after(5, function(pos_list)
        for i, pos in ipairs(pos_list) do
          liquid_update(pos)
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

      for i, item in ipairs(q) do
        --local kmap = path_find(item.pos)

        --for x = -8,8 do
        --  for z = -8,8 do
        --    local p = item.pos + vector.new(x, 0, z)
        --    local level = kmap(p)
        --    if level then
        --      --core.set_node(p, make_liquid(level))
        --    end
        --  end
        --end
        flow_iteration(item)


      end

      run()
    end)
  end

  run()
end

return liquid

