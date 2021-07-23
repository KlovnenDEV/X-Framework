Citizen.CreateThread(function()
    exports.ghmattimysql:execute("SELECT * FROM `companies`", function(result)
        if result[1] ~= nil then
            for k, v in pairs(result) do
                Config.Companies[v.name] = {
                    name = v.name,
                    label = v.label,
                    employees = v.employees ~= nil and json.decode(v.employees) or {},
                    owner = v.owner,
                    money = v.money,
                }
            end
        end
        TriggerClientEvent("x-companies:client:setCompanies", -1, Config.Companies)
    end)
end)

RegisterServerEvent('x-companies:server:loadCompanies')
AddEventHandler('x-companies:server:loadCompanies', function()
    local src = source
    TriggerClientEvent("x-companies:client:setCompanies", src, Config.Companies)
end)

RegisterServerEvent('x-companies:server:createCompany')
AddEventHandler('x-companies:server:createCompany', function(name)
    local src = source
    local Player = XCore.Functions.GetPlayer(src)
    local bankAmount = Player.PlayerData.money["bank"]
    local cashAmount = Player.PlayerData.money["cash"]
    if cashAmount >= Config.CompanyPrice or bankAmount >= Config.CompanyPrice then
        if name ~= nil then 
            local companyLabel = escapeSqli(name)
            local companyName = escapeSqli(name:gsub("%s+", ""):lower())
            if companyName ~= "" then
                if IsNameAvailable(companyName) then
                    if cashAmount >= Config.CompanyPrice then
                        Player.Functions.RemoveMoney("cash", Config.CompanyPrice, "company-created")
                        exports.ghmattimysql:execute("INSERT INTO `companies` (`name`, `label`, `owner`) VALUES ('"..companyName.."', '"..companyLabel.."', '"..Player.PlayerData.citizenid.."')")
                        Config.Companies[companyName] = {
                            name = companyName,
                            label = name,
                            employees = {},
                            owner = Player.PlayerData.citizenid,
                            money = 0,
                        }
                        TriggerClientEvent("x-companies:client:setCompanies", -1, Config.Companies)
                        TriggerClientEvent('XCore:NotifyNotify', src, "Congratulations, you are the proud owner of: "..companyLabel)
                    else
                        Player.Functions.RemoveMoney("bank", Config.CompanyPrice, "company-created")
                        exports.ghmattimysql:execute("INSERT INTO `companies` (`name`, `label`, `owner`) VALUES ('"..companyName.."', '"..companyLabel.."', '"..Player.PlayerData.citizenid.."')")
                        Config.Companies[companyName] = {
                            name = companyName,
                            label = name,
                            employees = {},
                            owner = Player.PlayerData.citizenid,
                            money = 0,
                        }
                        TriggerClientEvent("x-companies:client:setCompanies", -1, Config.Companies)
                        TriggerClientEvent('XCore:NotifyNotify', src, "Congratulations, you are the proud owner of: "..companyLabel)
                    end
                else
                    TriggerClientEvent('XCore:NotifyNotify', src, 'The name: ' .. companyLabel .. ' is occupied..', 'error', 4000)
                end
            else
                TriggerClientEvent('XCore:NotifyNotify', src, 'The name cannot be empty..', 'error', 4000)
            end
        else
            TriggerClientEvent('XCore:NotifyNotify', src, 'The name cannot be empty', 'error', 4000)
        end
    else
        TriggerClientEvent('XCore:NotifyNotify', src, 'You do not have enough money', 'error', 4000)
    end
end)

RegisterServerEvent('x-companies:server:removeCompany')
AddEventHandler('x-companies:server:removeCompany', function(companyName)
    local src = source
    local Player = XCore.Functions.GetPlayer(src)
    if companyName ~= nil then 
        if IsCompanyOwner(companyName, Player.PlayerData.citizenid) then
            companyLabel = Config.Companies[companyName].label
            XCore.Functions.ExecuteSql(true, "DELETE FROM `companies` WHERE `name` = '"..escapeSqli(companyName).."'")
            Config.Companies[companyName] = nil
            TriggerClientEvent("x-companies:client:setCompanies", -1, Config.Companies)
            TriggerClientEvent("x-phone:client:setupCompanies", src)
            TriggerClientEvent("x-phone:client:InPhoneNotify", src, "Businesses", "success", "You have " .. companyLabel .. " deleted!")
        else
            TriggerClientEvent('XCore:NotifyNotify', src, 'You do not own this business ..', 'error', 4000)
        end
    else
        TriggerClientEvent('XCore:NotifyNotify', src, 'Name cannot be empty ..', 'error', 4000)
    end
end)

RegisterServerEvent('x-companies:server:quitCompany')
AddEventHandler('x-companies:server:quitCompany', function(companyName)
    local src = source
    local Player = XCore.Functions.GetPlayer(src)
    if companyName ~= nil then 
        if IsEmployee(companyName, Player.PlayerData.citizenid) then
            companyLabel = Config.Companies[companyName].label
            Config.Companies[companyName].employees[Player.PlayerData.citizenid] = nil

            TriggerClientEvent("x-companies:client:setCompanies", -1, Config.Companies)
            TriggerClientEvent("x-phone:client:setupCompanies", src)
            TriggerClientEvent("x-phone:client:InPhoneNotify", src, "Businesses", "success", "You resigned from" .. companyLabel .. "!")

            local updatedEmployees = {}
            for employee, info in pairs(Config.Companies[companyName].employees) do
                updatedEmployees[employee] = info
            end
            exports.ghmattimysql:execute("UPDATE `companies` SET `employees` = '"..json.encode(updatedEmployees).."' WHERE `name` = '"..escapeSqli(companyName).."'")
        else
            TriggerClientEvent('XCore:NotifyNotify', src, 'You do not own this business ..', 'error', 4000)
        end
    else
        TriggerClientEvent('XCore:NotifyNotify', src, 'Name cannot be empty ..', 'error', 4000)
    end
end)

RegisterServerEvent('x-companies:server:addEmployee')
AddEventHandler('x-companies:server:addEmployee', function(playerCitizenId, companyName, rank)
    local src = source
    local Player = XCore.Functions.GetPlayer(src)
    local OtherPlayer = XCore.Functions.GetPlayerByCitizenId(playerCitizenId)
    local rank = tonumber(rank)
    if OtherPlayer ~= nil then 
        if IsCompanyOwner(companyName, Player.PlayerData.citizenid) then
            if rank > 0 and rank < Config.MaxRank then
                Config.Companies[companyName].employees[OtherPlayer.PlayerData.citizenid] {
                    name = OtherPlayer.PlayerData.charinfo.firstname .. " " .. OtherPlayer.PlayerData.charinfo.lastname,
                    citizenid = OtherPlayer.PlayerData.citizenid,
                    rank = rank,
                }
                exports.ghmattimysql:execute("UPDATE `companies` SET `employees` = '"..json.encode(Config.Companies[companyName].employees).."' WHERE `name` = '"..escapeSqli(companyName).."'")
                TriggerClientEvent("x-companies:client:setCompanies", -1, Config.Companies)
                TriggerClientEvent('XCore:NotifyNotify', src, 'You have ' .. OtherPlayer.PlayerData.firstname .. ' ' .. OtherPlayer.PlayerData.lastname .. ' added to employees (rank: '..rank..')')
                TriggerClientEvent('XCore:NotifyNotify', OtherPlayer.PlayerData.source, 'You have been added to company ' .. Config.Companies[companyName].label .. "(rank: " ..rank..")")
            else
                TriggerClientEvent('XCore:NotifyNotify', src, 'Min rank is 1 en max rank is '..(Config.MaxRank-1)..'..', 'error', 4000)
            end
        else
            TriggerClientEvent('XCore:NotifyNotify', src, 'You do not own this business ..', 'error', 4000)
        end
    else
        TriggerClientEvent('XCore:NotifyNotify', src, 'Person is not present..', 'error', 4000)
    end
end)

RegisterServerEvent('x-companies:server:alterEmployee')
AddEventHandler('x-companies:server:alterEmployee', function(playerCitizenId, companyName, isPromote)
    local src = source
    local Player = XCore.Functions.GetPlayer(src)
    local otherCitizenId = playerCitizenId:upper()
    if CanAlterEmployee(companyName, Player.PlayerData.citizenid) then
        if Config.Companies[companyName].employees[otherCitizenId] ~= nil then 
            if isPromote then
                local newRank = Config.Companies[companyName].employees[otherCitizenId].rank + 1
                if newRank < Config.MaxRank then
                    Config.Companies[companyName].employees[otherCitizenId].rank = newRank
                    exports.ghmattimysql:execute("UPDATE `companies` SET `employees` = '"..json.encode(Config.Companies[companyName].employees).."' WHERE `name` = '"..escapeSqli(companyName).."'")
                    TriggerClientEvent("x-companies:client:setCompanies", -1, Config.Companies)
                    TriggerClientEvent('XCore:NotifyNotify', src, 'Werknemer rank geupdate naar: ' ..newRank)
                else
                    TriggerClientEvent('XCore:NotifyNotify', src, 'Person cannot be promoted further ..', 'error', 4000)
                end
            else
                local newRank = Config.Companies[companyName].employees[otherCitizenId].rank - 1
                if newRank > 0 then
                    Config.Companies[companyName].employees[otherCitizenId].rank = newRank
                    exports.ghmattimysql:execute("UPDATE `companies` SET `employees` = '"..json.encode(Config.Companies[companyName].employees).."' WHERE `name` = '"..escapeSqli(companyName).."'")
                    TriggerClientEvent("x-companies:client:setCompanies", -1, Config.Companies)
                    TriggerClientEvent('XCore:NotifyNotify', src, 'Employee rank updated to: ' ..newRank)
                else
                    TriggerClientEvent('XCore:NotifyNotify', src, 'Person cannot go further down..', 'error', 4000)
                end
            end
        else
            TriggerClientEvent('XCore:NotifyNotify', src, 'Person is not an employee of your company ..', 'error', 4000)
        end
    else
        TriggerClientEvent('XCore:NotifyNotify', src, 'You do not own this business ..', 'error', 4000)
    end
end)

function IsEmployee(companyName, citizenid)
    local retval = false
    if Config.Companies[companyName] ~= nil then 
        if Config.Companies[companyName].employees ~= nil then 
            if Config.Companies[companyName].employees[citizenid] ~= nil then 
                retval = true
            elseif Config.Companies[companyName].owner == citizenid then
                retval = true
            end
        else
            if Config.Companies[companyName].owner == citizenid then
                retval = true
            end
        end
    end
    return retval
end

function CanAlterEmployee(companyName, citizenid)
    local retval = false
    if Config.Companies[companyName] ~= nil then 
        if Config.Companies[companyName].owner == citizenid then
            retval = true
        elseif Config.Companies[companyName].employees[citizenid] ~= nil then 
            if Config.Companies[companyName].employees[citizenid].rank == (Config.MaxRank - 1) then
                retval = true
            end
        end
    end
    return retval
end

function IsCompanyOwner(companyName, citizenid)
    local retval = false
    if Config.Companies[companyName] ~= nil then 
        if Config.Companies[companyName].owner == citizenid then
            retval = true
        end
    end
    return retval
end

function IsNameAvailable(name)
    local retval = false
    XCore.Functions.ExecuteSql(true, "SELECT * FROM `companies` WHERE `name` = '"..name.."'", function(result)
        if result[1] ~= nil then 
            retval = false
        else
            retval = true
        end
    end)
    return retval
end

function escapeSqli(str)
    local replacements = { ['"'] = '\\"', ["'"] = "\\'" }
    return str:gsub( "['\"]", replacements ) -- or string.gsub( source, "['\"]", replacements )
end