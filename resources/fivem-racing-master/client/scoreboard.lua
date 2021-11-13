AddEventHandler('racing:showScoreboard', function (results)
local rows = {}
table.insert(rows, "<tr><th>Pos</th><th>Name</th><th>Time</th></tr>")
local results = json.decode(results)
for position, result in ipairs(results) do
	local name = result.Key
	local time = result.Value
	if tonumber(time) ~= nil then
		time = GetTimeAsString(math.floor(tonumber(time)))
	else
		time = "N/A"
	end
	local row = string.format("<tr><td>%d</td><td>%s</td><td>%s</td>", position, name, time)
	table.insert(rows, row)
end
	SendNUIMessage({meta = 'show', text = table.concat(rows)})
	showScoreboard = true
end)

AddEventHandler('racing:hideScoreboard', function ()
	SendNUIMessage({meta = 'hide'})
end)

function stringsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end