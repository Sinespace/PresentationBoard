
local myChannel = channel or "space.sine.presentationboard";

local myObj = Space.Host.ExecutingObject;

local myName = "presentation-"..myObj.GlobalID;

local myBoard = Space.Host.GetReference("Board");
local myCanvas = Space.Host.GetReference("Canvas");
local mySlideInfo = myCanvas.FindInChildren("SlideInfo");
local myJumpSlide = myCanvas.FindInChildren("JumpSlide");

local currentSlide = 0;
local slideImages = Space.Resources;
local slideCount = #slideImages;

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
        Space.Log(myChannel .. ' - ' .. Space.Host.ExecutingObject.Name .. ' - ' .. logEntry .. payload, true)
    end
end

function setSlide(slide, network)
    if slide >= 1 and slide <= slideCount and slide ~= currentSlide then
        currentSlide = slide;
        myBoard.Renderer.Material.SetTexture("_MainTex", slideImages[currentSlide]);
        updateSlideInfo();
        if network ~= false then
            sendToServer({cmd="presentation slide", presentation=myName, slide=currentSlide});
        end
    end
end

function updateSlideInfo()
    mySlideInfo.UIText.Text = tostring(currentSlide).." / "..tostring(slideCount);
end

function nextSlide() setSlide(currentSlide + 1); end

function prevSlide() setSlide(currentSlide - 1); end

function jumpSlide()
    local jump = tonumber(myJumpSlide.UIInputField.Text);
    if jump ~= nil then
        if jump < 1 then
            jump = 1;
        elseif jump > slideCount then
            jump = slideCount;
        end
        myJumpSlide.UIInputField.Text = "";
        setSlide(jump);
    end
end

function toggleControls()
    logger.log("Current object owner: ", {owner=myObj.Owner, player=Space.Scene.PlayerAvatar.ID});
    if Space.InEditor or Space.Scene.PlayerAvatar.ID == myObj.Owner or Space.Scene.PlayerIsOwner then
        myCanvas.Active = not myCanvas.Active;
    end
end

function handleBroadcastMessage(data)
	logger.log("Presentation Board message", data);
	for d=1,#data,1 do
        if data[d]['cmd'] == 'show presentation slide' then
            if data[d]['presentation'] == myName then
                setSlide(data[d]['slide'], false); -- false on networking
            end
        end
    end
end

function sendToServer(data)
	data['time'] = Space.ServerTimeUnix;
	data['player'] = Space.Scene.PlayerAvatar.ID;
	if Space.InEditor then
		Space.Shared.CallBroadcastFunction(myChannel, 'to local server', {data});
	else
		Space.Network.SendNetworkMessage(myChannel, data, true); -- Send to server. Server will send to everyone else if needed.
	end
end

function networkMessage(args)
	handleBroadcastMessage(args.Message);
end

-- Initialize with first slide.
setSlide(1, false);

if Space.InEditor then
	Space.Shared.RegisterBroadcastFunction(myChannel, 'from local server', handleBroadcastMessage);
else
	Space.Network.SubscribeToNetwork(myChannel, networkMessage);
end

updateSlideInfo();

sendToServer({cmd="presentation checkin", presentation=myName, slide=currentSlide});

