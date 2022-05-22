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
	property bool		runPump: false
	property int		pumpInterval: 24*60*60*1000 // 24 hrs
	property int		runDuration: 10*60*1000 // 10 mins
	property string		switchIP: "192.168.1.100"
	property bool 		tasmotaMode: true
	property string  	selecteddeviceuuid : "aaaaaaa-aaaa-1111-2222-ccccccc"
	property string  	selecteddevicename : "pump switch"
	property string  	selectedtasmotaIP : "192.168.1.100"

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
	
	signal pumpUpdated
	
	property variant pumpSwitchSettingsJson : {
		'tasmotaMode': "",
		'selectedtasmotaIP': "",
		'selecteddevicename': "",
		'selecteddeviceuuid': ""	,	
	}
	
	FileIO {
		id: pumpSwitchSettingsFile
		source: "file:///mnt/data/tsc/pumpSwitch_userSettings.json"
	}
	
	
	Component.onCompleted: {
		pumpSwitchSettingsJson = JSON.parse(pumpSwitchSettingsFile.read())
		if (debugOutput) console.log("*********pumpSwitch pumpSwitchSettingsJson : " + pumpSwitchSettingsJson)
		try {
				if (debugOutput) console.log("*********pumpSwitch loading settings" )
				var tasmotaModeTXT= pumpSwitchSettingsJson['tasmotaMode']
				if (tasmotaModeTXT == 'Tasmota'){
					tasmotaMode = true
				}else{
					tasmotaMode = false
				}
				selectedtasmotaIP = pumpSwitchSettingsJson['selectedtasmotaIP']
				selecteddevicename = pumpSwitchSettingsJson['selecteddevicename']
				selecteddeviceuuid = pumpSwitchSettingsJson['selecteddeviceuuid']
				if (debugOutput) console.log("*********pumpSwitch selecteddeviceuuid : " + selecteddeviceuuid)
				
		} catch(e) {
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
			if(!runTimer.running){setPumpStatus(false)}
			break;
		case 1:
			//heating
			if (debugOutput) console.log("*********pumpSwitch requesting on")
			setPumpStatus(true)
			break;
		case 4:
			//Error
			if (debugOutput) console.log("*********pumpSwitch runPump requesting off")
			if(!runTimer.running){setPumpStatus(false)}
			break;
		}
	}
	
	
	function setPumpStatus(pumpFunction) {
		var url
		if(pumpFunction){
			runPump = true
			intervalTimer.running = false
			runTimer.running = false
			if(tasmotaMode){
				url = "http://" + selectedtasmotaIP + "/cm?cmnd=Power%20On"
				var http = new XMLHttpRequest()
				http.open("GET", url, true);
				http.send();
			}else{
				var msg = bxtFactory.newBxtMessage(BxtMessage.ACTION_INVOKE, selecteddeviceuuid , "SwitchPower", "SetTarget");
				msg.addArgument("NewTargetValue", "1");
				bxtClient.sendMsg(msg);
			}
			
		}else{
			runPump = false
			intervalTimer.running = true
			if(tasmotaMode){
				url = "http://" + selectedtasmotaIP + "/cm?cmnd=Power%20off"
				var http = new XMLHttpRequest()
				http.open("GET", url, true);
				http.send();
			}else{
				var msg = bxtFactory.newBxtMessage(BxtMessage.ACTION_INVOKE, selecteddeviceuuid , "SwitchPower", "SetTarget");
				msg.addArgument("NewTargetValue", "0");
				bxtClient.sendMsg(msg);
			}
		}
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
		id: runTimer   //time that the pump is running
		interval: runDuration
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
		interval: pumpInterval
		repeat: false
		running: false
		triggeredOnStart: false
		onTriggered: {
			setPumpStatus(true)
			if (debugOutput) console.log("*********pumpSwitch runPump switch on after 24hrs standstill : " + runPump)
			runTimer.running = true
			intervalTimer.running = true
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
			"selectedtasmotaIP" : selectedtasmotaIP,
			"selecteddevicename" : selecteddevicename,
			"selecteddeviceuuid" : selecteddeviceuuid
			
			
		}
  		pumpSwitchSettingsFile.write(JSON.stringify(pumpSwitchSettingsJson))
	}

}