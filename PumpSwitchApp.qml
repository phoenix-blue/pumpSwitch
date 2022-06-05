//2-2022
//by oepi-loepi

import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0;
import BxtClient 1.0
import ThermostatUtils 1.0
import FileIO 1.0

App {
	id: pumpSwitchApp
	property bool 		debugOutput: false
	property url 		tileUrl : "PumpSwitchTile.qml"
	property 			PumpSwitchTile pumpSwitchTile
	property url 		pumpSwitchConfigScreenUrl : "PumpSwitchConfigScreen.qml"
	property			PumpSwitchConfigScreen  pumpSwitchConfigScreen
	
	property url 		pumpSwitchScreenUrl : "PumpSwitchScreen.qml"
	property			PumpSwitchScreen  pumpSwitchScreen
	
	property url 		thumbnailIcon: "qrc:/tsc/refresh.png"

	property string 	thermostatUuid
	property string 	pumpStatus : "Auto"
	property bool		timerRunning: false
	property bool		pumpError: false
	property bool		runPump: false
	property var		lastCurrentUsage: 0.00
	property bool		manualOn: false
	property bool		manualOff: false
	property bool		automaticMode: true
	property int		oldPumpstatus: -1
	property int		pumpInterval: 24 // hours
	property int		runDuration: 10 //  mins
	property int		offDelay: 5 // mins
	
	
	property string 	nextSwitchTime

	property int 		lastOffTimeUnix:0
	property int 		lastOnTimeUnix:0
	property int 		savedMinutes:0
	property var 		savedEuros :0.00
	
	property string		switchIP: "192.168.1.100"
	property bool 		tasmotaMode: true
	property string  	selecteddeviceuuid : "aaaaaaa-aaaa-1111-2222-ccccccc"
	property string  	selecteddevicename : "pump switch"
	property string  	selectedtasmotaIP : "192.168.1.100"
		
	property bool 		firstStart: true

	property variant thermInfo : {
		'currentTemp': 0,
		'currentSetpoint': 0,
		'currentDisplayTemp': 0,
		'realSetpoint': 0,
		'programState': 0,
		'setByLoadShifting': 0,
		'activeState': 0,
		'nextProgram': 0,
		'nextState': 0,
		'nextTime': 0,
		'nextSetpoint': 0,
		'randomConfigId': 0,
		'errorFound': 0,
		'hasBoilerFault': 0,
		'boilerModuleConnected': 0,
		'zwaveOthermConnected' : 0,
		'burnerInfo': 0,
		'preheating': 0,
		'otCommError': 0,
		'currentModulationLevel': 0,
		'haveOTBoiler': 0,
		'maxPreheatTime': 0
	}
	
	property variant deviceStatusInfo : {
		'DevUUID': "",
		'Name': "",
		'CurrentUsage': 0,
		'DayUsage': 0,
		'AvgUsage': 0,
		'CurrentState': 0,
		'IsConnected': 0,
		'NetworkHealthState': 0
	}
	
	
	signal pumpUpdated
	
	property variant pumpSwitchSettingsJson : {
		'tasmotaMode': "",
		'pumpInterval': "",
		'runDuration': "",
		'offDelay': "",
		'selectedtasmotaIP': "",
		'selecteddevicename': "",
		'selecteddeviceuuid': ""	
	}
	
	FileIO {
		id: pumpSwitchSettingsFile
		source: "file:///mnt/data/tsc/pumpSwitch_userSettings.json"
	}
	
	FileIO {
		id: pumpSwitchSavings
		source: "file:///mnt/data/tsc/appData/pumpSwitch_savings.txt"
	}
	
	Component.onCompleted: {
		try {
			pumpSwitchSettingsJson = JSON.parse(pumpSwitchSettingsFile.read())
			if (debugOutput) console.log("*********pumpSwitch pumpSwitchSettingsJson : " + pumpSwitchSettingsJson)
			if (debugOutput) console.log("*********pumpSwitch loading settings" )
			var tasmotaModeTXT= pumpSwitchSettingsJson['tasmotaMode']
			if (tasmotaModeTXT == 'Tasmota'){
				tasmotaMode = true
			}else{
				tasmotaMode = false
			}
			offDelay = pumpSwitchSettingsJson['offDelay']
			runDuration = pumpSwitchSettingsJson['runDuration']
			pumpInterval = pumpSwitchSettingsJson['pumpInterval']
			selectedtasmotaIP = pumpSwitchSettingsJson['selectedtasmotaIP']
			selecteddevicename = pumpSwitchSettingsJson['selecteddevicename']
			selecteddeviceuuid = pumpSwitchSettingsJson['selecteddeviceuuid']
			if (debugOutput) console.log("*********pumpSwitch selecteddeviceuuid : " + selecteddeviceuuid)
		} catch(e) {
		}
		
		try {
			var pumpSwitchSavingsJson = JSON.parse(pumpSwitchSavings.read())
			savedMinutes =  pumpSwitchSavingsJson['savedMinutes']
			savedEuros = pumpSwitchSavingsJson['savedEuros']
		} catch(e) {
		}

		if(firstStart){
			pumpStatus = "Eerste start"
			//setPumpStatus(true)
		}
	}


	function init() {
		registry.registerWidget("tile", tileUrl, this, "pumpSwitchTile", {thumbLabel: qsTr("pumpSwitch"), thumbIcon: thumbnailIcon, thumbCategory: "general", thumbWeight: 30, baseTileWeight: 10, baseTileSolarWeight: 10, thumbIconVAlignment: "center"})
		registry.registerWidget("screen", pumpSwitchConfigScreenUrl, this, "pumpSwitchConfigScreen")
		registry.registerWidget("screen", pumpSwitchScreenUrl, this, "pumpSwitchScreen")
	}
	

	function setPumpStatusfromThermostat(node) {
		var tempInfo = thermInfo
		var tempNode = node.child
		while (tempNode) {
			tempInfo[tempNode.name] = parseFloat(tempNode.text)
			tempNode = tempNode.sibling
		}
		thermInfo = tempInfo;
		if (debugOutput) console.log("*********pumpSwitch thermInfo : " + thermInfo)
		// burnerInfo 0=off, 1=heat, 2=water, 3=preheat, 4=error
		var burnerInfo = thermInfo['burnerInfo']
		if (debugOutput) console.log("*********pumpSwitch burnerInfo : " + burnerInfo)
				
		//When burner is set to on (heating or preheating) use the modulation level as a guide
		switch (burnerInfo) {
		case 0: 
			//off
			if (debugOutput) console.log("*********pumpSwitch runPump requesting off")
			//if the pump was running because of heating, give some time to switch off the pump and use all heat from the pipes.
			if ((oldPumpstatus == 1 || oldPumpstatus == 3) & !manualOn & !runTimer.running ){offDelayTimer.running = true;pumpStatus = "Naloop"}
			if (oldPumpstatus == -1  & !manualOn & !runTimer.running ){setPumpStatus(false);pumpStatus = "Auto uit"}
			
			oldPumpstatus = 0
			break;
		case 1:
			//heating
			if (debugOutput) console.log("*********pumpSwitch requesting on")
			if(!manualOff){
				pumpStatus = "Auto aan"
				setPumpStatus(true)
				oldPumpstatus = 1
			}

			break;
		case 2:
			//water
			break;
		case 3:
			//preheating
			if (debugOutput) console.log("*********pumpSwitch requesting on")
			if(!manualOff){
				pumpStatus = "Auto aan"
				setPumpStatus(true)
				oldPumpstatus = 3
			}
			break;
		case 4:
			//Error
			if (debugOutput) console.log("*********pumpSwitch runPump requesting off")
			if(!runTimer.running){setPumpStatus(false)}
			oldPumpstatus = 4
			pumpStatus = "Fout"
			break;
		}
	}
	


	function manualOnClicked() {
			pumpStatus = "Hand aan"
			manualOn = true
			manualOff = false
			automaticMode = false
			setPumpStatus(true)
	}

	function manualOffClicked() {
			pumpStatus = "Hand uit"
			manualOn = false
			manualOff = true
			automaticMode = false
			setPumpStatus(false)
	}	

	function autoClicked() {
		if(manualOn){
			offDelayTimer.running = true
			pumpStatus = "Naloop"
			manualOn = false
			manualOff = false
			automaticMode = true
		}
		if(manualOff){
			pumpStatus = "Auto"
			manualOn = false
			manualOff = false
			automaticMode = true
		}
	}
	
	function setPumpStatus(pumpFunction) {		
		var url
        var thishour = new Date()
		if (debugOutput) console.log("*********pumpSwitch thishour : " + thishour)
		if(pumpFunction){
			runPump = true
			timerRunning = false
			runTimer.running = false
			lastOnTimeUnix = thishour.getTime()/1000
			if (debugOutput) console.log("*********pumpSwitch lastOnTimeUnix : " + lastOnTimeUnix)
			if (debugOutput) console.log("*********pumpSwitch lastOffTimeUnix : " + lastOffTimeUnix)
			savedMinutes = savedMinutes + parseInt((lastOnTimeUnix - lastOffTimeUnix)/60)
			if (debugOutput) console.log("*********pumpSwitch savedMinutes : " + savedMinutes)			
			if(tasmotaMode){
				url = "http://" + selectedtasmotaIP + "/cm?cmnd=Power%20On"
				var http = new XMLHttpRequest()
				http.open("GET", url, true);
				http.send();
			}else{
				savedEuros = savedEuros + (parseFloat((lastOnTimeUnix - lastOffTimeUnix)/3600) * lastCurrentUsage) * (0.23/1000)
				if (debugOutput) console.log("*********pumpSwitch savedEuros : " + savedEuros)
				var msg = bxtFactory.newBxtMessage(BxtMessage.ACTION_INVOKE, selecteddeviceuuid , "SwitchPower", "SetTarget");
				msg.addArgument("NewTargetValue", "1");
				bxtClient.sendMsg(msg);
				bxtClient.sendMsg(msg); // do it twice because sometimes the plug does not respond
			}
			
			
		}else{
			if (!manualOn){
				runPump = false
				timerRunning = true
				calculateSwitchTime()
				
				lastOffTimeUnix = thishour.getTime()/1000
				if (debugOutput) console.log("*********pumpSwitch lastOffTimeUnix : " + lastOffTimeUnix)
				if(tasmotaMode){
					url = "http://" + selectedtasmotaIP + "/cm?cmnd=Power%20off"
					var http = new XMLHttpRequest()
					http.open("GET", url, true);
					http.send();
				}else{
					var msg = bxtFactory.newBxtMessage(BxtMessage.ACTION_INVOKE, selecteddeviceuuid , "SwitchPower", "SetTarget");
					msg.addArgument("NewTargetValue", "0");
					bxtClient.sendMsg(msg);
					bxtClient.sendMsg(msg); // do it twice because sometimes the plug does not respond
				}
			}
		}
		
		var pumpSwitchSavingsJson = {
			"savedMinutes" : savedMinutes,
			"savedEuros" : savedEuros
		}
  		pumpSwitchSavings.write(JSON.stringify(pumpSwitchSavingsJson))
		if (debugOutput) console.log("*********pumpSwitch runPump : " + runPump)
	}
	
	
	BxtDatasetHandler {
	    id: thermstatInfoDsHandler
        dataset: "thermostatInfo"
        discoHandler: thermstatDiscoHandler
        onDatasetUpdate: setPumpStatusfromThermostat(update)
    }
	
	BxtDiscoveryHandler {
		id: thermstatDiscoHandler
		deviceType: "happ_thermstat"
		onDiscoReceived: {
			thermostatUuid = deviceUuid;
		}
	}
	
	Timer {
		id: offDelayTimer   //delay after heating is switched off
		interval: offDelay*60*1000
		repeat: false
		running: false
		triggeredOnStart: false
		onTriggered: {
			pumpStatus = "Auto uit"
			setPumpStatus(false)
        }
    }
	
	Timer {
		id: runTimer   //time that the pump is running
		interval: runDuration*60*1000
		repeat: false
		running: false
		triggeredOnStart: false
		onTriggered: {
			setPumpStatus(false)
			if (debugOutput) console.log("*********pumpSwitch runPump switch off after 30 mins running : " + runPump)
        }
    }
	
	Timer {
		id: intervalTimer   //time between running the pump
		interval: pumpInterval*60*60*1000
		repeat: false
		running: timerRunning
		triggeredOnStart: false
		onTriggered: {
			setPumpStatus(true)
			calculateSwitchTime()
			pumpStatus = "Timer aan"
			if (debugOutput) console.log("*********pumpSwitch runPump switch on after ..hrs standstill : " + runPump)
			runTimer.running = true
			intervalTimer.running = timerRunning
        }
    }	

	function saveSettings() {
		var temptasmotaMode = ""
		if (tasmotaMode){
			temptasmotaMode = "Tasmota"
		}else{
			temptasmotaMode = "Fibaro"
		}
 		var pumpSwitchSettingsJson = {
			"tasmotaMode" : temptasmotaMode,
			"offDelay" : offDelay,
			"runDuration" : runDuration,
			"pumpInterval" : pumpInterval,
			"selectedtasmotaIP" : selectedtasmotaIP,
			"selecteddevicename" : selecteddevicename,
			"selecteddeviceuuid" : selecteddeviceuuid
		}
  		pumpSwitchSettingsFile.write(JSON.stringify(pumpSwitchSettingsJson))
	}
	
	
	function calculateSwitchTime(){
		var nextSwitch = new Date();
		nextSwitch.setMinutes (nextSwitch.getMinutes() + (60*pumpInterval));  //60*pumpInterval minutes extra
		nextSwitchTime = parseInt(Qt.formatDateTime(nextSwitch,"dd")) + "-" +parseInt(Qt.formatDateTime(nextSwitch,"MM")) + " " + parseInt(Qt.formatDateTime(nextSwitch,"hh")) + ":" +  parseInt(Qt.formatDateTime(nextSwitch,"mm"))
	}
	
	function parseDeviceStatusInfo(update) {
		var infoList = deviceStatusInfo;
		var infoNode = update.getChild("device", 0);
		while (infoNode && infoNode.name === "device") {
			var uuidNode = infoNode.getChild("DevUUID");
			var device = infoList[uuidNode.text];
			if (!device)device = {};
			var childNode = infoNode.child;
			while (childNode) {
				device[childNode.name] = childNode.text;
				if (debugOutput) console.log("*********pumpSwitch "+ childNode.name + " : " + childNode.text)
				childNode = childNode.sibling;
			}
			infoList[uuidNode.text] = device;
			if (uuidNode.text == selecteddeviceuuid){
				if (debugOutput) console.log("*********pumpSwitch FOUND: : " + uuidNode.text)
				deviceStatusInfo = infoList[uuidNode.text]
				
			}
			infoNode = infoNode.next;		
		}
		if (debugOutput) console.log("*********pumpSwitch deviceStatusInfo.Name : " + deviceStatusInfo.Name)
		if (debugOutput) console.log("*********pumpSwitch deviceStatusInfo.CurrentUsage : " + deviceStatusInfo.CurrentUsage)
		if (!isNaN(deviceStatusInfo.CurrentUsage) && deviceStatusInfo.CurrentUsage > 0){lastCurrentUsage = parseFloat(deviceStatusInfo.CurrentUsage).toFixed(2)}
		if (debugOutput) console.log("*********pumpSwitch lastCurrentUsage : " + lastCurrentUsage)
		
		if (debugOutput) console.log("*********pumpSwitch tasmotaMode : " + tasmotaMode)
		if (debugOutput) console.log("*********pumpSwitch deviceStatusInfo.CurrentState : " + deviceStatusInfo.CurrentState)
		if (debugOutput) console.log("*********pumpSwitch deviceStatusInfo.IsConnected : " + deviceStatusInfo.IsConnected)
		
		if (!tasmotaMode & ((runPump & deviceStatusInfo.CurrentState == 0) || (!runPump & deviceStatusInfo.CurrentState == 1) || deviceStatusInfo.IsConnected == 0 )){
			pumpError = true
		}else{
			pumpError = false
		}
		if (debugOutput) console.log("*********pumpSwitch pumpError : " + pumpError)
	}
		
	BxtDatasetHandler {
		id: deviceStatusInfoDataset
		dataset: "deviceStatusInfo"
		discoHandler: smartplugDiscoHandler
		onDatasetUpdate: parseDeviceStatusInfo(update)
	}
	
	BxtDiscoveryHandler {
		id: smartplugDiscoHandler
		deviceType: "happ_smartplug"
		onDiscoReceived: smartplugUuid = deviceUuid
	}
}