-- Virtual Device Driver API for ComputerCraft
-- Made by Loewe_111

vdd = {}

function vdd:new(args)
    -- Class stuff
    local o = {}
    setmetatable(o, self)
    self.__index = self
    -- Input validation
    if not args.type then
        return false, "No type specified"
    end
    self.type = args.type
    if args.name and peripheral.isPresent(args.name) then
        return false, "Peripheral with that name already exists"
    end
    self.name = args.name or self:_generateName(self.type)
    self.methods = args.methods or {}

    -- Inject into the peripheral API
    self:_inject()
    local device = {
        name = self.name,
        type = self.type,
        methods = self.methods
    }
    peripheral.vdd.devices[self.name] = device
    os.queueEvent("peripheral", self.name)
    return o
end

function vdd:stop()
    peripheral.vdd.devices[self.name] = nil
    os.queueEvent("peripheral_detach", self.name)
end

function vdd:_generateName(type)
    local name = string.format("vdd_%s_0", type)
    local i = 0
    while peripheral.isPresent(name) do
        i = i + 1
        name = string.format("vdd_%s_%d", type, i)
    end
    return name
end

function vdd:_inject()
    if peripheral.vdd_injected then
        return
    end
    peripheral.vdd = {
        devices = {}
    }
    old_peripheral = self:_tableDeepCopy(peripheral)
    -- Modify peripheral functions, if needed
    peripheral.getNames = function()
        local names = old_peripheral.getNames()
        for k, v in pairs(peripheral.vdd.devices) do
            table.insert(names, v.name)
        end
        return names
    end

    peripheral.isPresent = function(name)
        if peripheral.vdd.devices[name] then
            return true
        end
        return old_peripheral.isPresent(name)
    end

    peripheral.getType = function(name)
        if type(name) == "string" and peripheral.vdd.devices[name] then
            return peripheral.vdd.devices[name].type
        end
        return old_peripheral.getType(name)
    end

    peripheral.hasType = function(name, type)
        if peripheral.vdd.devices[name] then
            return peripheral.vdd.devices[name].type == type
        end
        return old_peripheral.hasType(name, type)
    end
    
    peripheral.getMethods = function(name)
        if peripheral.vdd.devices[name] then
            local methods = {}
            for k, v in pairs(peripheral.vdd.devices[name].methods) do
                table.insert(methods, k)
            end
            return methods
        end
        return old_peripheral.getMethods(name)
    end

    peripheral.call = function(name, method, ...)
        if peripheral.vdd.devices[name] then
            local device = peripheral.vdd.devices[name]
            if device.methods[method] then
                return device.methods[method](...)
            end
            return error("No such method")
        end
        return old_peripheral.call(name, method, ...)
    end

    -- VDD injection complete
    peripheral.vdd_injected = true
end

function vdd:_tableDeepCopy(oldTable)
    local newTable = {}
    for k,v in pairs(oldTable) do
        newTable[k] = v
    end
    return newTable
end

function vdd.remove_vdd()
    peripheral.vdd = nil
    peripheral.vdd_injected = false
end

return vdd