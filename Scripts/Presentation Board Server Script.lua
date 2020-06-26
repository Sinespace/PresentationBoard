
---------------------- Variables ----------------------

local myChannel = "space.sine.presentationboard";

local presentations = {};
presentations.state = {};

---------------------- Logger ----------------------

logger = {enabled = false}
logger.log = function(logEntry, data)
    if logger.enabled then
        local payload = ''
        if data ~= nil then
            if type(data) == 'table' then
                if json ~= nil then
                    payload = ' - (table) length: ' .. tostring(#data) .. ' - values: ' .. json.serialize(data)
                else
                    payload = ' - (table) length: ' .. tostring(#data) .. ' - values: (no json) ' .. tostring(data)
                end
            else
                payload = ' - ' .. tostring(data)
            end
        end
        Space.Log(myChannel .. ' - SERVER - ' .. logEntry .. payload, true)
    end
end

function handleBroadcastMessage(data)
	logger.log("Presentation Board server message", data);
	local everyone = {};
	local response = {};
	local player = data['player'];
	if data['cmd'] == "presentation checkin" then
		local state = presentations.state[data['presentation']];
		if state ~= nil then
			table.insert(response, {cmd='show presentation slide', presentation=state['presentation'], slide=state['slide']});
		end
	elseif data['cmd'] == "presentation slide" then
		presentations.state[data['presentation']] = {presentation=data['presentation'], slide=data['slide']};
		table.insert(everyone, {cmd='show presentation slide', presentation=data['presentation'], slide=data['slide']});
	end
	if #response > 0 then
		sendResponse(response, myChannel, player);
	end
	if #everyone > 0 then
		sendResponse(everyone, myChannel);
	end
end

function OnScriptServerMessage(channel, data)
	-- Is it a network we care about?
	if channel == myChannel then
		-- Are they talking to us specifically?
		handleBroadcastMessage(data);
	end
end

function sendResponse(data, who, client)
	if who == nil then
		who = myChannel;
	end
	if client ~= 0 then
		if Space.InEditor then
			Space.Shared.CallBroadcastFunction(who, 'from local server', {data});
		elseif client ~= nil then
			Space.SendMessageToClientScripts(client, who, data);
		else
			Space.SendMessageToAllClientScripts(who, data);
		end
	end
end

if Space.InEditor then
	Space.Shared.RegisterBroadcastFunction(myChannel, 'to local server', handleBroadcastMessage);
end

sendResponse({{cmd="server init"}}, myChannel);

---------------------- End of server script ----------------------
