#SingleInstance, Force
#NoEnv 
#KeyHistory 0
SetWorkingDir %A_ScriptDir%
SendMode Input

#Include, JSON.ahk ; from https://github.com/cocobelgica/AutoHotkey-JSON

IniRead, GAME_NAME, Clock.ini, EngineApp, name
API_ADDRESS :=  getApiAdress()

init()

getApiAdress() {
	FileRead, JsonString, % getPropFile()
	if ErrorLevel  ; Successfully loaded.
	{
		throw "Didn't find steelseries engine properties file !"
	}

	Data := JSON.Load(JsonString)
	Address := Data.address

	Return, Address
}

getPropFile() {
	IniRead, Folder, Clock.ini, SteelSeries, folder
	IniRead, Location, Clock.ini, SteelSeries, location
	SteelProp = %Folder%%Location%
	
	SteelProp := expand(steelProp)

	Return, SteelProp
}

expand(str) {
	Loop, Parse, str, `%

	If !Mod(A_Index, 2) {
		EnvGet, v, %A_LoopField%
		StringReplace, str, str, `%%A_LoopField%`%, %v%
	} 
	Return, str
}

post(resource, data) {
	HTTP := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	
	global API_ADDRESS
	EndPoint := "http://" . API_ADDRESS . "/" . resource
	OutputDebug, [EndPoint] %EndPoint%
	;~  QueryString:=QueryString_Builder({"email":"Joe@the-Automator.com"})
	QueryString:=""



	Data := JSON.Dump(data)
	OutputDebug % "[Data] " . Data
	
	HTTP.Open("POST", EndPoint . QueryString)
	HTTP.SetRequestHeader("Content-Type", "application/json")
	HTTP.Send(Data)
	Response:= HTTP.ResponseText
	OutputDebug, [Response]  %Response%
}

QueryString_Builder(kvp) {
	for key, value in kvp
		queryString.=((A_Index="1")?(url "?"):("&amp;")) key "=" value
	return queryString
}

register_game() {
    global GAME_NAME
	IniRead, description, Clock.ini, EngineApp, description
	IniRead, developer, Clock.ini, EngineApp, developer

    data := ({"game": GAME_NAME,"game_display_name": description,"developer": developer})
	post("game_metadata", data)
}

remove_game() {
	global GAME_NAME
	data := ({"game": GAME_NAME})
	post("remove_game", data)
}

heartbeat() {
	global GAME_NAME
	data := ({"game": GAME_NAME})
	post("game_heartbeat", data)
}

bind_event(event_type, min_value, max_value, icon_id, value_optional, handlers) {
	global GAME_NAME
	For key, value in handlers
    	OutputDebug, [key value] %key% = %value%
	
	data := {"game": GAME_NAME,"event": event_type,"min_value": min_value,"max_value": max_value,"icon_id": icon_id,"value_optional": value_optional, "handlers": handlers}
	
	post("bind_game_event", data)
}

remove_event(event_type) {
	global GAME_NAME
	data := ({"game": GAME_NAME,"event": event_type})
	post("remove_game_event", data)
}

event(event_type, value, frame="") {
	global GAME_NAME
	
	data := ({"game": GAME_NAME, "event": event_type, "data": {"value": value}})
	
	if (frame != "") {
		data.data.Insert("frame", frame)
	} 

	post("game_event", data)
}

init() {
	remove_game()
	register_game()
	
	screen_handler := [{"device-type": "screened","zone": "one","mode": "screen","datas": [{"has-text": JSON.true,"bold": JSON.true,"context-frame-key": "time"}]}]
	bind_event("TIME", 0, 100, 1, JSON.true, screen_handler)

	FormatTime, T, %A_Now%, HH:mm:ss
	event("TIME", 1 , {"time": T})
}

CapsLock & `:: init()