Citizen.CreateThread(function()
    exports.ghmattimysql:execute("SELECT * FROM `moneysafes`", function(safes)
        if safes[1] ~= nil then
            for _, d in pairs(safes) do
                for safe, s in pairs(Config.Safes) do
                    if d.safe == safe then
                        Config.Safes[safe].money = d.money
                        d.transactions = json.decode(d.transactions)
                        if d.transactions ~= nil and next(d.transactions) ~= nil then
                            Config.Safes[safe].transactions = d.transactions
                        end
                        TriggerClientEvent('x-moneysafe:client:UpdateSafe', -1, Config.Safes[safe], safe)
                    end
                end
            end
        end
    end)
end)

XCore.Commands.Add("deposit", "Put money in the safe", {}, false, function(source, args)
    local Player = XCore.Functions.GetPlayer(source)
    local amount = tonumber(args[1]) or 0

    TriggerClientEvent('x-moneysafe:client:DepositMoney', source, amount)
end)

XCore.Commands.Add("withdraw", "Take money from the safe", {}, false, function(source, args)
    local Player = XCore.Functions.GetPlayer(source)
    local amount = tonumber(args[1]) or 0

    TriggerClientEvent('x-moneysafe:client:WithdrawMoney', source, amount)
end)

function AddTransaction(safe, type, amount, Player, Automated)
    local cid = nil
    local name = nil
    local _source = nil
    if not Automated then
        local src = source
        local Player = XCore.Functions.GetPlayer(src)
        cid = Player.PlayerData.citizenid
        name = Player.PlayerData.name
        _source = Player.PlayerData.source
    else
        cid = "s0me1 tha DEV"
        name = "Boete\'s"
        _source = "Automated"
    end
    table.insert(Config.Safes[safe].transactions, {
        type = type,
        amount = amount,
        safe = safe,
        citizenid = cid,
    })
    TriggerEvent("x-log:server:sendLog", cid, type, {safe = safe, type = type, amount = amount, citizenid = cid})
    local label = "withdrawn from"
    local color = "red"
    if type == "deposit" then
        label = "deposited in"
        color = "green"
    end
	TriggerEvent("x-log:server:CreateLog", "moneysafes", type, color, "**" .. name .. "** (citizenid: *" .. cid .. "* | id: *(" .. _source .. ")* has **$" .. amount .. "** " .. label .. " of **" .. safe .. "** safe.")
end

RegisterServerEvent('x-moneysafe:server:DepositMoney')
AddEventHandler('x-moneysafe:server:DepositMoney', function(safe, amount, sender)
    local src = source
    local Player = XCore.Functions.GetPlayer(src)
    
    -- if Player.PlayerData.money.cash >= amount then
    --     Player.Functions.RemoveMoney('cash', amount)
    -- else
    if Player.PlayerData.money.bank >= amount then
        Player.Functions.RemoveMoney('bank', amount)
    else
        TriggerClientEvent('XCore:NotifyNotify', src, "You do not have enough money!", "error")
        return
    end
    if sender == nil then
        AddTransaction(safe, "deposit", amount, Player, false)
    else
        AddTransaction(safe, "deposit", amount, {}, true)
    end
    exports.ghmattimysql:execute("SELECT * FROM `moneysafes` WHERE `safe` = '"..safe.."'", function(result)
        if result[1] ~= nil then
            Config.Safes[safe].money = (Config.Safes[safe].money + amount)
            exports.ghmattimysql:execute("UPDATE `moneysafes` SET money = '"..Config.Safes[safe].money.."', transactions = '"..json.encode(Config.Safes[safe].transactions).."' WHERE `safe` = '"..safe.."'")
        else
            Config.Safes[safe].money = amount
            exports.ghmattimysql:execute("INSERT INTO `moneysafes` (`safe`, `money`, `transactions`) VALUES ('"..safe.."', '"..Config.Safes[safe].money.."', '"..json.encode(Config.Safes[safe].transactions).."')")
        end
        TriggerClientEvent('x-moneysafe:client:UpdateSafe', -1, Config.Safes[safe], safe)
        TriggerClientEvent('XCore:NotifyNotify', src, "You have $"..amount..",- put in the safe", "success")
    end)
end)

RegisterServerEvent('x-moneysafe:server:WithdrawMoney')
AddEventHandler('x-moneysafe:server:WithdrawMoney', function(safe, amount)
    local src = source
    local Player = XCore.Functions.GetPlayer(src)

    if (Config.Safes[safe].money - amount) >= 0 then 
        AddTransaction(safe, "withdraw", amount, Player, false)
        Config.Safes[safe].money = (Config.Safes[safe].money - amount)
        exports.ghmattimysql:execute("UPDATE `moneysafes` SET money = '"..Config.Safes[safe].money.."', transactions = '"..json.encode(Config.Safes[safe].transactions).."' WHERE `safe` = '"..safe.."'")
        TriggerClientEvent('x-moneysafe:client:UpdateSafe', -1, Config.Safes[safe], safe)
        TriggerClientEvent('XCore:NotifyNotify', src, "You have $"..amount..",- taken out of safe!", "success")
        Player.Functions.AddMoney('cash', amount)
    else
        TriggerClientEvent('XCore:NotifyNotify', src, "There is not enough money in the safe", "error")
    end
end)