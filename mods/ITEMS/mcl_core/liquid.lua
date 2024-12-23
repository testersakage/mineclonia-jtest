

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
  
  local vm = VoxelManip()
  
  local function flow_iteration(item)
    core.log(dump(vm))

    local map = item.map
    local p111 = item.pos

    core.log('iteration ('..p111.x..' '..p111.y..' '..p111.z..')')
    local n111 = core.get_node(p111)

    local l111 = get_liquid_level(n111)

    local n111_max = false
    local n111_liquid = false


    if not l111 and is_floodable(n111) == 1 then
      local p121 = p111 + vector.new( 0, 1, 0)
      local n121 = core.get_node(p121)
      if is_liquid(n121) then
        core.set_node(p111, make_liquid('down'))
        --vm:set_node_at(p111, ake_liquid('down'))
        n111_max = true
        n111_liquid = true
        l111 = 8
      elseif map then
        local level = map(p111)
        if level then
          core.set_node(p111, make_liquid(level))
          --vm:set_node_at(p111, make_liquid(level))
          n111_liquid = true
          l111 = level
        end
      end
    elseif l111 == 8 then
      n111_max = true
      n111_liquid = true
    elseif l111 then
      n111_liquid = true
    end

    if n111_liquid then
      local p101 = p111 + vector.new( 0,-1, 0)
      local n101 = core.get_node(p101)
      if is_floodable(n101) == 1 then
        queue_push({pos = p101})
        return
      end
    end

    if n111_max then
      map = path_find(p111)
    end

    if n111_liquid and map then

      local p011 = p111 + vector.new(-1, 0, 0)
      local p211 = p111 + vector.new( 1, 0, 0)
      local p110 = p111 + vector.new( 0, 0,-1)
      local p112 = p111 + vector.new( 0, 0, 1)

      l011 = map(p011)
      l211 = map(p211)
      l110 = map(p110)
      l112 = map(p112)

      if l011 and l011 < l111 then queue_push({pos = p011, map = map}) end
      if l211 and l211 < l111 then queue_push({pos = p211, map = map}) end
      if l110 and l110 < l111 then queue_push({pos = p110, map = map}) end
      if l112 and l112 < l111 then queue_push({pos = p112, map = map}) end
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

