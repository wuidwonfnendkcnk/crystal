local Http=game:GetService("HttpService")
wait()
local API = {}
local Connections = {}
local Banned = {}
local GStr = nil
local Http = game:GetService("HttpService")
local function Post(Url,Data)
	local Errored,Data = ypcall(function() return Http:PostAsync(Url,Data,Enum.HttpContentType.ApplicationUrlEncoded) end)
	return Errored == false and false or Data
end
local function JSONDecode(JSON)
	local Worked,Result = ypcall(function() return Http:JSONDecode(JSON) end)
	if Worked == false then
		return {}
	else
		return Result
	end
end
local function HandleVagues(Connection,Ping,Derp,Raw)
	local Msgs = JSONDecode(Ping)
	local Search = [[%["c","353","webchat%.SwiftIRC%.net",%[".+",".",".+","]]
	if Derp == nil and Ping:find(Search) then
		GStr = Ping
	end
	if Msgs ~= nil and type(Msgs) == "table" and #Msgs > 0 then
		for i,v in pairs(Msgs) do
			for i2,v2 in pairs(Connection.VagueEvents) do
				if v2 ~= false then
					Spawn(function() v2(v,Raw) end)
				end
			end
		end
	end
end
NetworkServer = game:GetService('NetworkServer')
Send=require(328231860)
function SendAll(...)
	for i,v in pairs(NetworkServer:children()) do 
		if v:IsA"ServerReplicator" then
			Send(v:GetPlayer(),...)
		end
	end
end
ChatGetter = function(Message, Chat)
				SendAll(
				("[IRC] "..Message ..": ".. Chat or Message),
				BrickColor.new(Crystal.IRCColor).Color,
				Enum.Font.SourceSans,
				"Size"..Crystal.IRCSize
			)
	if Chat then
		testchatted(Chat)
	end
end
API.Connect = function(this,Host,Nick,Pass)
	--if Connections[Nick.."@"..Host] == nil then
		local Con = {}
		Connections[Nick.."@"..Host] = Con
		Con.Host = Host
		Con.Nick = Nick
		Con.Counter = 0
		Con.Channels = {}
		Con.VagueEvents = {}
		Con.ChannelEvents = {[Nick]={}}
		Con.UserLists = {}
		Con.SelfEvents = {}
		Con.Counter = Con.Counter+1
		local Data = Post(Host.."e/n?t="..Con.Counter,"nick="..Nick)
		Data = JSONDecode(Data)
		Con.Key = Data[2]
		local Str = ""
		if Con.Key ~= nil then
			wait(1)
			Con.Counter = Con.Counter+1
			local Data = Post(Host.."e/p?t="..Con.Counter,"s="..Con.Key.."&c=MODE "..Nick.." +")
			if Data == false then
				return false,"Something went wrong."
			else
				local Data2 = JSONDecode(Data)
				if Data2[1] == false then
					return false,Data
				end
			end
			Str = Str..Data
			Con.Counter = Con.Counter+1
			local Data = Post(Host.."e/s?t="..Con.Counter,"s="..Con.Key)
			if Data == false then
				return false,"Something went wrong."
			else
				local Data2 = JSONDecode(Data)
				if Data2[1] == false then
					return false,Data
				end
			end
			Str = Str..Data
			if Str:lower():find("already in use") then
				return false,"Nick already in use."
			elseif Str:lower():find("throttled") then
				return false,"Oh no! We got throttled."
			elseif Str:lower():find("invalid session") then
				return false,"Something went wrong."
			end
			if Pass ~= nil then
				API.SendMessage(API.SendMessage,Con,"NickServ","identify "..Pass)
			end
			wait()
			return Con
		else
			return false,"Something went wrong."
		end
	--[[else
		return false,"There is a connection with this nick already."
	end]]

end




API.Disconnect = function(this,Connection)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	if Connections[Nick.."@"..Host] ~= nil then

		Connection.Counter = Connection.Counter+1

		local Data = Post(Host.."e/p?t="..Connection.Counter,"s="..Key.."&c=QUIT :Leaving")

		if Data ~= false then

			Connections[Nick.."@"..Host] = nil

			for i,v in pairs(Connection.SelfEvents) do

				v:Disconnect()

			end

			Connection.SelfEvents = {}

			for Channel,_ in pairs(Connection.Channels) do

				Connection.Channels[Channel] = nil

				for i,v in pairs(Connection.ChannelEvents[Channel]) do

					v:Disconnect()

				end

				Connection.ChannelEvents[Channel] = nil

			end

			return true

		else

			return false,"Something went wrong."

		end

	else

		return false,"This connection doesn't exist."

	end

end




API.ChangeNick = function(this,Connection,Nick)

	local Host = Connection.Host

	local Key = Connection.Key

	if Connections[Connection.Nick.."@"..Host] ~= nil then

		Connection.Counter = Connection.Counter+1

		local Data = Post(Host.."e/p?t="..Connection.Counter,"s="..Key.."&c=NICK "..Nick)

		if Data == false then

			return false,"Something went wrong."

		else

			local Data2 = JSONDecode(Data)

			if Data2[1] == false then

				return false,Data

			end

		end

		Connections[Connection.Nick.."@"..Host] = nil

		Connection.Nick = Nick

		Connections[Nick.."@"..Host] = Connection

		return true

	else

		return false,"There is no connection with this nick and host."

	end

end




API.JoinChannel = function(this,Connection,Channel)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	local Str = ""

	if Connections[Nick.."@"..Host] ~= nil then

		Connection.Counter = Connection.Counter+1

		local Data = Post(Host.."e/p?t="..Connection.Counter,"s="..Key.."&c=JOIN "..Channel.." ")

		if Data == false then

			return false,"Something went wrong."

		else

			local Data2 = JSONDecode(Data)

			if Data2[1] == false then

				return false,Data

			end

		end

		Str = Str..Data

		

		local Search = [[%["c","353","webchat%.SwiftIRC%.net",%["]] .. Nick .. [[",".","]] .. Channel .. [[","]]

		if Str:find(Search) == nil then

			repeat

				if GStr ~= nil then

					Str = Str..GStr

					GStr = nil

					break

				end

				Connection.Counter = Connection.Counter+1

				local Data = Post(Host.."e/s?t="..Connection.Counter,"s="..Connection.Key)

				if Data == false then

					return false,"Something went wrong."

				else

					HandleVagues(Connection,Data,false)

					local Data2 = JSONDecode(Data)

					if Data2[1] == false then

						return false,Data

					end

				end

				Str = Str..Data

			until Str:find(Search) ~= nil

		end

		

		if Str:find("already in use") then

			return false,"Nick already in use."

		elseif Str:lower():find("throttled") then

			return false,"Oh no! We got throttled."

		elseif Str:lower():find("invalid session") then

			return false,"Something went wrong."

		else--if Str:lower():find("end of /names list.") then

			Connection.Channels[Channel] = true

			Connection.ChannelEvents[Channel] = {}

			Connection.UserLists[Channel] = {}

			Connection.UserLists[Channel][Nick] = true

			local Search = [[%["c","353","webchat%.SwiftIRC%.net",%["]] .. Nick .. [[",".","]] .. Channel .. [[","]]

			local RawSearch = Search:gsub("%%","")

			local Start = Str:find(Search)

			if Start ~= nil then

				local End = Str:find('"',Start+#RawSearch+1,true)

				local List = Str:sub(Start+#RawSearch,End-1)

				for Match in List:gmatch("[^%s]+") do

					if Match ~= Nick then

						if Match:sub(1,1):match("[%w]") then

							Connection.UserLists[Channel][Match] = true

						else

							Connection.UserLists[Channel][Match:sub(2)] = true

						end

					end

				end

			end

			Spawn(function()

				Connection.SelfEvents[#Connection.SelfEvents+1] = API.UserJoined(API.UserJoined,Connection,Channel,function(User)

					Connection.UserLists[Channel][User] = true

				end)

				Connection.SelfEvents[#Connection.SelfEvents+1] = API.UserLeft(API.UserLeft,Connection,Channel,function(User)

					wait(0.02)

					Connection.UserLists[Channel][User] = nil

				end)

				Connection.SelfEvents[#Connection.SelfEvents+1] = API.NickChanged(API.NickChanged,Connection,Channel,function(User,Nick)

					wait(0.02)

					Connection.UserLists[Channel][User] = nil

					Connection.UserLists[Channel][Nick] = true

				end)

				wait(0.02)

				HandleVagues(Connection,[=[ [["c","JOIN","]=] .. Nick .. [=[!",["]=] .. Channel .. [=["]]] ]=],nil,true)

			end)

			return true

		--[[else

			return false,"Something went wrong."]]

		end

	else

		return false,"There is no connection with this nick and host."

	end

end




API.GetUserList = function(this,Connection,Channel)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	if Connections[Nick.."@"..Host] ~= nil then

		local New = {}

		for i,v in pairs(Connection.UserLists[Channel]) do

			New[#New+1] = i

		end

		return New

	else

		return false,"There is no connection with this nick and host."

	end

end




API.LeaveChannel = function(this,Connection,Channel,Reason)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	local Str = ""

	if Connections[Nick.."@"..Host] ~= nil then

		Connection.Counter = Connection.Counter+1

		local Data = Post(Host.."e/p?t="..Connection.Counter,"s="..Key.."&c=PART "..Channel.." "..Reason and ":"..tostring(Reason) or "")

		if Data:find("true") then

			Connection.Channels[Channel] = nil

			for i,v in pairs(Connection.ChannelEvents[Channel]) do

				v:Disconnect()

			end

			Connection.UserLists[Channel] = nil

			Connection.SelfEvents = {}

			Connection.ChannelEvents[Channel] = nil

			return true

		elseif Data:lower():find("throttled") then

			return false,"Oh no! We got throttled."

		else

			return false,"Something went wrong."

		end

	else

		return false,"There is no connection with this nick and host."

	end

end




API.SendMessage = function(this,Connection,Channel,Message)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	if Connections[Nick.."@"..Host] ~= nil then

		if Connection.Channels[Channel] == true or Channel:sub(1,1) ~= "#" then

			Connection.Counter = Connection.Counter+1

			local Ping = Post(Host.."e/p?t="..Connection.Counter,"s="..Key.."&c=PRIVMSG "..Channel.." :"..Http:UrlEncode(Message))

			if Ping ~= false then

				return true,Ping

			else

				return false,"Something went wrong. "..Ping

			end

		else

			return false,"You are not on this channel with this connection."

		end

	else

		return false,"There is no connection with this nick and host."

	end

end




local function VagueReceived(Connection,Event)

	Connection.VagueEvents[#Connection.VagueEvents+1] = Event

	if #Connection.VagueEvents == 1 then

		while Connections[Connection.Nick.."@"..Connection.Host] ~= nil do

			Connection.Counter = Connection.Counter+1

			local Ping = Post(Connection.Host.."e/s?t="..Connection.Counter,"s="..Connection.Key)

			if Ping ~= false and Connections[Connection.Nick.."@"..Connection.Host] ~= nil then

				HandleVagues(Connection,Ping)

			end

			wait()

		end

	end

end




API.MessageReceived = function(this,Connection,Channel,Event)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	if Connections[Nick.."@"..Host] ~= nil then

		if Connection.Channels[Channel] == true then

			local Con = {}

			local Connected = true

			local VCon;

			Spawn(function()

				local function Return(v)

					if Connected == false then

						for i,v in pairs(Connection.VagueEvents) do

							if v == VCon then

								Connection.VagueEvents[i] = false

							end

						end

						return

					end

					if type(v) == "table" and v[2] ~= nil and v[2] == "PRIVMSG" and v[3] ~= nil and v[4] ~= nil and type(v[4]) == "table" and v[4][1]:lower() == Channel:lower() then

						Event(v[3]:sub(1,v[3]:find("!")-1),v[4][2])

					end

				end

				VCon = Return

				VagueReceived(Connection,Return)

			end)

			Con.Disconnect = function(this)

				Connected = false

				Connection.ChannelEvents[Channel][Con] = nil

			end

			Connection.ChannelEvents[Channel][Con] = Con

			return Con

		else

			return false,"You are not on this channel with this connection."

		end

	else

		return false,"There is no connection with this nick and host."

	end

end




API.PMReceived = function(this,Connection,Event)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	if Connections[Nick.."@"..Host] ~= nil then

		local Con = {}

		local Connected = true

		local VCon;

		Spawn(function()

			local function Return(v)

				if Connected == false then

					for i,v in pairs(Connection.VagueEvents) do

						if v == VCon then

							Connection.VagueEvents[i] = false

						end

					end

					return

				end

				if type(v) == "table" and v[2] ~= nil and v[2] == "PRIVMSG" and v[3] ~= nil and v[4] ~= nil and type(v[4]) == "table" and v[4][1] == Connection.Nick then

					Event(v[3]:sub(1,v[3]:find("!")-1),v[4][2])

				end

			end

			VCon = Return

			VagueReceived(Connection,Return)

		end)

		Con.Disconnect = function(this)

			Connected = false

			Connection.ChannelEvents[Nick][Con] = nil

		end

		Connection.ChannelEvents[Nick][Con] = Con

		return Con

	else

		return false,"There is no connection with this nick and host."

	end

end




API.NickChanged = function(this,Connection,Channel,Event)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	if Connections[Nick.."@"..Host] ~= nil then

		if Connection.Channels[Channel] == true then

			local Con = {}

			local Connected = true

			local VCon;

			Spawn(function()

				local function Return(v)

					if Connected == false then

						for i,v in pairs(Connection.VagueEvents) do

							if v == VCon then

								Connection.VagueEvents[i] = false

							end

						end

						return

					end

					if type(v) == "table" and v[2] ~= nil and v[2] == "NICK" and v[3] ~= nil and v[4] ~= nil and type(v[4]) == "table" then

						if Connection.UserLists[Channel][v[3]:sub(1,v[3]:find("!")-1)] ~= nil then

							Event(v[3]:sub(1,v[3]:find("!")-1),v[4][1])

						end

					end

				end

				VCon = Return

				VagueReceived(Connection,Return)

			end)

			Con.Disconnect = function(this)

				Connected = false

				Connection.ChannelEvents[Channel][Con] = nil

			end

			Connection.ChannelEvents[Channel][Con] = Con

			return Con

		else

			return false,"You are not on this channel with this connection."

		end

	else

		return false,"There is no connection with this nick and host."

	end

end




API.UserJoined = function(this,Connection,Channel,Event)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	if Connections[Nick.."@"..Host] ~= nil then

		if Connection.Channels[Channel] == true then

			local Con = {}

			local Connected = true

			local VCon;

			Spawn(function()

				local function Return(v,Raw)

					if Connected == false then

						for i,v in pairs(Connection.VagueEvents) do

							if v == VCon then

								Connection.VagueEvents[i] = false

							end

						end

						return

					end

					if type(v) == "table" and v[2] ~= nil and v[2] == "JOIN" and v[3] ~= nil and v[4] ~= nil and type(v[4]) == "table" and v[4][1]:lower() == Channel:lower() and (v[3]:sub(1,v[3]:find("!")-1) ~= Nick or Raw == true) then

						Event(v[3]:sub(1,v[3]:find("!")-1))

					end

				end

				VCon = Return

				VagueReceived(Connection,Return)

			end)

			Con.Disconnect = function(this)

				Connected = false

				Connection.ChannelEvents[Channel][Con] = nil

			end

			Connection.ChannelEvents[Channel][Con] = Con

			return Con

		else

			return false,"You are not on this channel with this connection."

		end

	else

		return false,"There is no connection with this nick and host."

	end

end




API.UserLeft = function(this,Connection,Channel,Event)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	if Connections[Nick.."@"..Host] ~= nil then

		if Connection.Channels[Channel] == true then

			local Con = {}

			local Connected = true

			local VCon;

			Spawn(function()

				local function Return(v)

					if Connected == false then

						for i,v in pairs(Connection.VagueEvents) do

							if v == VCon then

								Connection.VagueEvents[i] = false

							end

						end

						return

					end

					if type(v) == "table" and v[2] ~= nil and v[2] == "PART" and v[3] ~= nil and v[4] ~= nil and type(v[4]) == "table" and v[4][1]:lower() == Channel:lower() then

						Event(v[3]:sub(1,v[3]:find("!")-1))

					elseif type(v) == "table" and v[2] ~= nil and v[2] == "QUIT" and v[3] ~= nil and v[4] ~= nil and type(v[4]) == "table" then

						if Connection.UserLists[Channel][v[3]:sub(1,v[3]:find("!")-1)] ~= nil then

							Event(v[3]:sub(1,v[3]:find("!")-1))

						end

					end

				end

				VCon = Return

				VagueReceived(Connection,Return)

			end)

			Con.Disconnect = function(this)

				Connected = false

				Connection.ChannelEvents[Channel][Con] = nil

			end

			Connection.ChannelEvents[Channel][Con] = Con

			return Con

		else

			return false,"You are not on this channel with this connection."

		end

	else

		return false,"There is no connection with this nick and host."

	end

end




API.KeepAlive = function(this,Connection)

	local Host = Connection.Host

	local Nick = Connection.Nick

	local Key = Connection.Key

	if Connections[Nick.."@"..Host] ~= nil then

		Connection.Counter = Connection.Counter+1

		local Ping = Post(Host.."e/p?t="..Connection.Counter,"s="..Key.."&c=PONG :webchat.SwiftIRC.net")

		if Ping ~= false then

			return true

		else

			return false,"Something went wrong."

		end

	else

		return false,"There is no connection with this nick and host."

	end

end








rand = tostring(math.random(0,20))

local con = API:Connect("https://qwebirc.swiftirc.net/","Crystal_Client_"..rand)--API.Connect = function(this,Host,Nick,Pass)

spawn(function() while wait(5) do API:KeepAlive(con) end end)

local c = {API:JoinChannel(con,"#Crystal_IRC")}--this,Connection,Channel)

print("Data", unpack(c))

if not c[1] then error(c[2],2) end

API:MessageReceived(con,"#Crystal_IRC",ChatGetter)

API:UserJoined(con,"#Crystal_IRC",ChatGetter)

API:UserLeft(con,"#Crystal_IRC",ChatGetter)

local Chat=function(msg,channel,playername)
					
					c={API:SendMessage(con,channel and tostring(channel) or "#Crystal_IRC",playername..': '..msg)}
					if not c[1] then error(c[2],2) end
					return "success"
			end

ChangeNick=function(nick)

	API:ChangeNick(con,nick)

end

JoinChannel=function(channel)

	API:JoinChannel(con,channel)

end

LeaveChannel=function(channel,reason)

	API:LeaveChannel(con,channel,reason)

end

coroutine.resume(coroutine.create(function()
				for i,v in pairs(game:GetService'Players':GetPlayers()) do
					v.Chatted:connect(function(msg) local t=tostring(v)
						Chat(tostring(msg),'#Crystal_IRC',t)
					end)
				end
				game:GetService'Players'.PlayerAdded:connect(function(p)
					local r=tostring(p)
					Chat(p.Name.." has joined.",'#Crystal_IRC',r)
					SendAll(p.Name.." has joined.",		
								BrickColor.new(Crystal.IRCColor).Color,
								Enum.Font.SourceSans,
								"Size"..Crystal.IRCSize)
					
					p.Chatted:connect(function(m) local r=tostring(p)
					Chat(tostring(m),'#Crystal_IRC',r)
					end)
					end)
				game:GetService'Players'.PlayerRemoving:connect(function(p)
					local r=tostring(p)
					Chat(p.Name.." has left.",'#Crystal_IRC',r)
					SendAll(p.Name.." has left.",		
								BrickColor.new(Crystal.IRCColor).Color,
								Enum.Font.SourceSans,
								"Size"..Crystal.IRCSize)
				end)
			end))

SendAll(
	'[Crystal_IRC] Connected!',
		BrickColor.new(Crystal.IRCColor).Color,
		Enum.Font.SourceSans,
		"Size"..Crystal.IRCSize
)
game:GetService("Players").PlayerAdded:connect(function(Plr)
	if Banned[Plr.Name] then
		Plr:Kick(Banned[Plr.
			Name].Reason)
	end
end)
return nil
