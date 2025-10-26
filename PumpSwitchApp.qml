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
	property bool 		debugOutput: true
	property url 		tileUrl : "PumpSwitchTile.qml"
	property 			PumpSwitchTile pumpSwitchTile
	property url 		pumpSwitchConfigScreenUrl : "PumpSwitchConfigScreen.qml"
	property			PumpSwitchConfigScreen  pumpSwitchConfigScreen
	
	property url 		pumpSwitchScreenUrl : "PumpSwitchScreen.qml"
	property			PumpSwitchScreen  pumpSwitchScreen
	
	property url 		thumbnailIcon: "qrc:/tsc/refresh.png"

	property string 	thermostatUuid
	property string 	smartplugUuid
	property string 	pwrUsageUuid
	property string 	pumpStatus : "Auto"
	property bool		tasmotaHasPower: false
	property bool		shellyHasPower: false
	property bool		pumpError: false
	property bool		runPump: false
	property var		lastCurrentUsage: 0.00
	property var		powerReadings: []  // Array to store power readings
	property var		avgPowerDuringRun: 0.00  // Average power during pump run
	property int		powerReadingStartTime: 0  // When we started collecting readings
	property bool		manualOn: false
	property bool		manualOff: false
	property bool		automaticMode: true
	property bool		timerRunning: false
	property int		oldPumpstatus: -1
	property int		pumpInterval: 24 // hours
	property int		runDuration: 10 //  mins
	property int		offDelay: 5 // mins
	
	
	property string 	nextSwitchTime

	property int 		lastOffTimeUnix:0
	property int 		lastOnTimeUnix:0
	property int 		savedMinutes:0
	property var 		savedEuros :0.00
	property var 		priceKWH :0.23
	
	property string		switchIP: "192.168.1.100"
	property bool 		tasmotaMode: false
	property bool 		shellyMode: false
	property string		deviceType: "Toon"  // "Toon", "Tasmota", "Shelly"
	property string  	selecteddeviceuuid : "aaaaaaa-aaaa-1111-2222-ccccccc"
	property string  	selecteddevicename : "pump switch"
	property string  	selectedtasmotaIP : "192.168.1.100"
	property string  	selectedShellyIP : "192.168.1.200"
		
	property bool 		firstStart: true
	property variant 	billingInfos: ({})

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
		'shellyMode': "",
		'deviceType': "",
		'pumpInterval': "",
		'runDuration': "",
		'offDelay': "",
		'selectedtasmotaIP': "",
		'selectedShellyIP': "",
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
			
			// Load device type and modes
			deviceType = pumpSwitchSettingsJson['deviceType'] || "Tasmota"
			var tasmotaModeTXT= pumpSwitchSettingsJson['tasmotaMode']
			var shellyModeTXT= pumpSwitchSettingsJson['shellyMode']
			
			if (tasmotaModeTXT == 'Tasmota' || deviceType == 'Tasmota'){
				tasmotaMode = true
				shellyMode = false
			} else if (shellyModeTXT == 'Shelly' || deviceType == 'Shelly'){
				tasmotaMode = false
				shellyMode = true
			} else {
				tasmotaMode = false
				shellyMode = false
			}
			
			offDelay = pumpSwitchSettingsJson['offDelay']
			runDuration = pumpSwitchSettingsJson['runDuration']
			pumpInterval = pumpSwitchSettingsJson['pumpInterval']
			selectedtasmotaIP = pumpSwitchSettingsJson['selectedtasmotaIP']
			selectedShellyIP = pumpSwitchSettingsJson['selectedShellyIP'] || "192.168.1.200"
			selecteddevicename = pumpSwitchSettingsJson['selecteddevicename']
			selecteddeviceuuid = pumpSwitchSettingsJson['selecteddeviceuuid']
			if (debugOutput) console.log("*********pumpSwitch selecteddeviceuuid : " + selecteddeviceuuid)
		} catch(e) {
		}
		
		try {
			var pumpSwitchSavingsJson = JSON.parse(pumpSwitchSavings.read())
			savedMinutes =  pumpSwitchSavingsJson['savedMinutes']
			savedEuros = pumpSwitchSavingsJson['savedEuros']
			if (debugOutput) console.log("*********pumpSwitch savedMinutes : " + savedMinutes);
			if (debugOutput) console.log("*********pumpSwitch savedEuros : " + savedEuros);
		} catch(e) {
		}

		if(firstStart){
			intervalTimer.start()
			timerRunning = true
			calculateSwitchTime()
			pumpStatus = "Eerste start"
		}
	}


	function init() {
		registry.registerWidget("tile", tileUrl, this, "pumpSwitchTile", {thumbLabel: qsTr("pumpSwitch"), thumbIcon: thumbnailIcon, thumbCategory: "general", thumbWeight: 30, baseTileWeight: 10, baseTileSolarWeight: 10, thumbIconVAlignment: "center"})
		registry.registerWidget("screen", pumpSwitchConfigScreenUrl, this, "pumpSwitchConfigScreen")
		registry.registerWidget("screen", pumpSwitchScreenUrl, this, "pumpSwitchScreen")
	}
	
	function parseBillingInfo(msg) {
		if (msg) {
			var newBillingInfos = {};
			var infoChild = msg.getChild("info", 0);
			while (infoChild) {
				var billingInfo = {};
				var childChild = infoChild.child;
				while (childChild) {
						if (childChild.name === "type" || childChild.name === "error")
								billingInfo[childChild.name] = childChild.text;
						else
								billingInfo[childChild.name] = parseFloat(childChild.text);
						childChild = childChild.sibling;
				}
				billingInfo.haveSJV = billingInfo.error !== "notSet" && billingInfo.usage !== 0;
				newBillingInfos[billingInfo.type] = billingInfo;
				infoChild = infoChild.next;
			}
			billingInfos = newBillingInfos;
			if (debugOutput) console.log("*********pumpSwitch JSON.stringify(billingInfos) : " + JSON.stringify(billingInfos));
			if (billingInfos.elec.price> 0.05){priceKWH = billingInfos.elec.price}
			if (debugOutput) console.log("*********pumpSwitch priceKWH : " + priceKWH);
		}
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
		    //pump switch to on
			runPump = true
			intervalTimer.stop()
			timerRunning = false
			lastOnTimeUnix = thishour.getTime()/1000
			
			// Reset power readings for new run period
			powerReadings = []
			avgPowerDuringRun = 0
			powerReadingStartTime = lastOnTimeUnix
			
			if (debugOutput) console.log("*********pumpSwitch pump ON - lastOnTimeUnix : " + lastOnTimeUnix)
			if (debugOutput) console.log("*********pumpSwitch started power monitoring")			
			if(tasmotaMode){
				// Only calculate euro savings with valid time difference and power data
				if (tasmotaHasPower && lastOffTimeUnix > 0 && (lastOnTimeUnix - lastOffTimeUnix) < 86400) {
					savedEuros = savedEuros + (parseFloat((lastOnTimeUnix - lastOffTimeUnix)/3600) * lastCurrentUsage) * (priceKWH/1000)
				}
				url = "http://" + selectedtasmotaIP + "/cm?cmnd=Power%20On"
				var http = new XMLHttpRequest()
				http.open("GET", url, true);
				http.send();
			} else if(shellyMode){
				// Only calculate euro savings with valid time difference and power data
				if (shellyHasPower && lastOffTimeUnix > 0 && (lastOnTimeUnix - lastOffTimeUnix) < 86400) {
					savedEuros = savedEuros + (parseFloat((lastOnTimeUnix - lastOffTimeUnix)/3600) * lastCurrentUsage) * (priceKWH/1000)
				}
				url = "http://" + selectedShellyIP + "/rpc/Switch.Set?id=0&on=true"
				var http = new XMLHttpRequest()
				http.open("GET", url, true);
				http.send();
				if (debugOutput) console.log("*********pumpSwitch Shelly ON URL: " + url)
			}else{
				// Only calculate euro savings with valid time difference
				if (lastOffTimeUnix > 0 && (lastOnTimeUnix - lastOffTimeUnix) < 86400) {
					savedEuros = savedEuros + (parseFloat((lastOnTimeUnix - lastOffTimeUnix)/3600) * lastCurrentUsage) * (priceKWH/1000)
				}
				if (debugOutput) console.log("*********pumpSwitch savedEuros : " + savedEuros)
				var msg = bxtFactory.newBxtMessage(BxtMessage.ACTION_INVOKE, selecteddeviceuuid , "SwitchPower", "SetTarget");
				msg.addArgument("NewTargetValue", "1");
				bxtClient.sendMsg(msg);
				bxtClient.sendMsg(msg); // do it twice because sometimes the plug does not respond
			}
		}else{
			//pump switch to off
			if (!manualOn){
				intervalTimer.restart()
				timerRunning = true
				calculateSwitchTime()
				runPump = false
				lastCurrentUsage = 0  // Reset power display when pump turns off
				lastOffTimeUnix = thishour.getTime()/1000
				
				// NOW CALCULATE THE SAVINGS (when pump goes OFF)
				if (lastOnTimeUnix > 0 && (lastOffTimeUnix - lastOnTimeUnix) > 0 && (lastOffTimeUnix - lastOnTimeUnix) < 86400) {
					var runtimeMinutes = parseInt((lastOffTimeUnix - lastOnTimeUnix)/60)
					savedMinutes = savedMinutes + runtimeMinutes
					
					// Calculate euro savings using average power during run
					if (avgPowerDuringRun > 0) {
						var runtimeHours = (lastOffTimeUnix - lastOnTimeUnix) / 3600
						var euroSavings = (runtimeHours * avgPowerDuringRun) * (priceKWH / 1000)
						savedEuros = savedEuros + euroSavings
						if (debugOutput) console.log("*********pumpSwitch SAVINGS - Runtime: " + runtimeMinutes + " min, Avg power: " + avgPowerDuringRun.toFixed(1) + "W, Euro savings: €" + euroSavings.toFixed(4))
					}
					
					if (debugOutput) console.log("*********pumpSwitch TOTAL SAVINGS - Minutes: " + savedMinutes + ", Euros: €" + savedEuros.toFixed(2))
				}
				
				if (debugOutput) console.log("*********pumpSwitch pump OFF - lastOffTimeUnix : " + lastOffTimeUnix)
				
				// Turn off the physical pump
				if(tasmotaMode){
					url = "http://" + selectedtasmotaIP + "/cm?cmnd=Power%20off"
					var http = new XMLHttpRequest()
					http.open("GET", url, true);
					http.send();
				} else if(shellyMode){
					url = "http://" + selectedShellyIP + "/rpc/Switch.Set?id=0&on=false"
					var http = new XMLHttpRequest()
					http.open("GET", url, true);
					http.send();
					if (debugOutput) console.log("*********pumpSwitch Shelly OFF URL: " + url)
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
		interval: runDuration*60*1000  //runDuration*60*1000
		repeat: false
		running: false
		triggeredOnStart: false
		onTriggered: {
		    if (debugOutput) console.log("*********pumpSwitch stopping pump from time mode : ")
			setPumpStatus(false)
			if (debugOutput) console.log("*********pumpSwitch stopping runtimer")
			runTimer.stop()
        }
    }
	
	Timer {
		id: intervalTimer   //time between running the pump
		interval: pumpInterval*60*60*1000 //pumpInterval*60*60*1000
		repeat: false
		running: false
		triggeredOnStart: false
		onTriggered: {
			pumpStatus = "Timer aan"
			if (debugOutput) console.log("*********pumpSwitch runPump switch on after ..hrs standstill : " + runPump)
			intervalTimer.restart()
			if (debugOutput) console.log("*********pumpSwitch starting runtimer : ")
			runTimer.restart()
			setPumpStatus(true)
        }
    }	

	Timer {
		id: shellyPollingTimer
		interval: 30000  // Poll every 30 seconds
		repeat: true
		running: shellyMode && !timerRunning
		onTriggered: {
			if (shellyMode) {
				getShellypower()
			}
		}
	}

	function addPowerReading(power) {
		var currentTime = (new Date().getTime()) / 1000
		
		// Skip first 30 seconds to avoid startup current
		if (powerReadingStartTime > 0 && (currentTime - powerReadingStartTime) < 30) {
			if (debugOutput) console.log("*********pumpSwitch skipping startup power reading: " + power + "W")
			return
		}
		
		// Filter extreme values (less than 5W or more than 500W for typical pumps)
		if (power < 5 || power > 500) {
			if (debugOutput) console.log("*********pumpSwitch filtering extreme power reading: " + power + "W")
			return
		}
		
		powerReadings.push(power)
		if (debugOutput) console.log("*********pumpSwitch added power reading: " + power + "W (total readings: " + powerReadings.length + ")")
		
		// Calculate running average
		if (powerReadings.length > 0) {
			var sum = 0
			for (var i = 0; i < powerReadings.length; i++) {
				sum += powerReadings[i]
			}
			avgPowerDuringRun = sum / powerReadings.length
			if (debugOutput) console.log("*********pumpSwitch average power during run: " + avgPowerDuringRun.toFixed(1) + "W")
		}
	}

	function resetSavings() {
		savedMinutes = 0
		savedEuros = 0.00
		var pumpSwitchSavingsJson = {
			"savedMinutes" : savedMinutes,
			"savedEuros" : savedEuros
		}
		pumpSwitchSavings.write(JSON.stringify(pumpSwitchSavingsJson))
		if (debugOutput) console.log("*********pumpSwitch savings reset")
	}

	function saveSettings() {
		var temptasmotaMode = ""
		var tempshellyMode = ""
		
		if (tasmotaMode){
			temptasmotaMode = "Tasmota"
		}else{
			temptasmotaMode = "Fibaro"
		}
		
		if (shellyMode){
			tempshellyMode = "Shelly"
		}else{
			tempshellyMode = "Toon"
		}
		
 		var pumpSwitchSettingsJson = {
			"tasmotaMode" : temptasmotaMode,
			"shellyMode" : tempshellyMode,
			"deviceType" : deviceType,
			"offDelay" : offDelay,
			"runDuration" : runDuration,
			"pumpInterval" : pumpInterval,
			"selectedtasmotaIP" : selectedtasmotaIP,
			"selectedShellyIP" : selectedShellyIP,
			"selecteddevicename" : selecteddevicename,
			"selecteddeviceuuid" : selecteddeviceuuid
		}
  		pumpSwitchSettingsFile.write(JSON.stringify(pumpSwitchSettingsJson))
		calculateSwitchTime()
		intervalTimer.restart()
	}
	
	
	function calculateSwitchTime(){
		var nextSwitch = new Date();
		nextSwitch.setMinutes (nextSwitch.getMinutes() + (60*pumpInterval));  //60*pumpInterval minutes extra
		var minutes = Qt.formatDateTime(nextSwitch,"mm")
		if (minutes.length == 1){minutes = "0" + minutes}
		var hours = Qt.formatDateTime(nextSwitch,"hh")
		if (hours.length == 1){hours = "0" + hours}
		nextSwitchTime = parseInt(Qt.formatDateTime(nextSwitch,"dd")) + "-" +parseInt(Qt.formatDateTime(nextSwitch,"MM")) + " " + hours + ":" +  minutes
		if (debugOutput) console.log("*********pumpSwitch nextSwitchTime : " + nextSwitchTime)
	}
	
	
	function getTasmotapower(){
		var http = new XMLHttpRequest()
		var url = "http://" + switchIP + "/?m=1";
		http.open("GET", url, true)
		http.onreadystatechange = function() { // Call a function when the state changes.
			if (http.readyState == XMLHttpRequest.DONE) {
				if (http.status === 200 || http.status === 300  || http.status === 302) {
					var response = http.responseText
					if (debugOutput) console.log("*********pumpSwitch response : " + response)
					if (response.indexOf('Power{m}')>0){
						tasmotaHasPower = true
						var n13 = response.indexOf('Power{m}') + 'Power{m}'.length
						var n14 = response.indexOf('W{e}',n13)
						var foundWatts = response.substring(n13, n14).trim()
						if (debugOutput) console.log("*********pumpSwitch foundWatts : " + foundWatts)
						lastCurrentUsage = parseFloat(foundWatts);
						
						// Add to power readings if pump is running
						if (runPump) {
							addPowerReading(lastCurrentUsage)
						}
					}else{
						tasmotaHasPower = false
					}
				}
			}
		}
        http.send();
	}
	
	function getShellypower(){
		var http = new XMLHttpRequest()
		var url = "http://" + selectedShellyIP + "/rpc/Shelly.GetStatus";
		http.open("GET", url, true)
		http.onreadystatechange = function() { // Call a function when the state changes.
			if (http.readyState == XMLHttpRequest.DONE) {
				if (http.status === 200 || http.status === 300  || http.status === 302) {
					var response = http.responseText
					if (debugOutput) console.log("*********pumpSwitch Shelly response : " + response)
					try {
						var jsonResponse = JSON.parse(response)
						if (jsonResponse["switch:0"]) {
							shellyHasPower = true
							var apower = jsonResponse["switch:0"].apower || 0
							if (debugOutput) console.log("*********pumpSwitch Shelly foundWatts : " + apower)
							lastCurrentUsage = parseFloat(apower);
							
							// Add to power readings if pump is running
							if (runPump) {
								addPowerReading(lastCurrentUsage)
							}
						} else {
							shellyHasPower = false
						}
					} catch (e) {
						if (debugOutput) console.log("*********pumpSwitch Shelly JSON parse error: " + e)
						shellyHasPower = false
					}
				}
			}
		}
        http.send();
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
		if (!isNaN(deviceStatusInfo.CurrentUsage) && deviceStatusInfo.CurrentUsage > 0){
			lastCurrentUsage = parseFloat(deviceStatusInfo.CurrentUsage).toFixed(2)
			
			// Add to power readings if pump is running (for Z-wave devices)
			if (runPump && deviceType == "Toon") {
				addPowerReading(lastCurrentUsage)
			}
		}
		if (debugOutput) console.log("*********pumpSwitch lastCurrentUsage : " + lastCurrentUsage)
		
		if (debugOutput) console.log("*********pumpSwitch tasmotaMode : " + tasmotaMode)
		if (debugOutput) console.log("*********pumpSwitch deviceStatusInfo.CurrentState : " + deviceStatusInfo.CurrentState)
		if (debugOutput) console.log("*********pumpSwitch deviceStatusInfo.IsConnected : " + deviceStatusInfo.IsConnected)
		
		if (deviceType == "Toon" & ((runPump & deviceStatusInfo.CurrentState == 0) || (!runPump & deviceStatusInfo.CurrentState == 1) || deviceStatusInfo.IsConnected == 0 )){
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
	
	
	BxtDatasetHandler {
		id: billingInfoDsHandler
		dataset: "billingInfo"
		discoHandler: pwrusageDiscoHandler
		onDatasetUpdate:  parseBillingInfo(update) 
	}
	
	BxtDiscoveryHandler {
		id: pwrusageDiscoHandler
		deviceType: "happ_pwrusage"
		onDiscoReceived: pwrUsageUuid = deviceUuid
	}
}