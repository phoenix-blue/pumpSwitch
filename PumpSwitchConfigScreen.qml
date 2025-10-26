import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: pumpSwitchConfigScreen
	screenTitle: 		"Pomp schakeling instellingen"
	property bool 		plugsfound: false
	property bool 		temptasmotaMode: app.tasmotaMode
	property bool 		tempshellyMode: app.shellyMode
	property string 	tempdeviceType: app.deviceType
	property bool 		debugOutput: app.debugOutput
	property string  	tempselecteddeviceuuid:app.selecteddeviceuuid
	property string  	tempselecteddevicename:app.selecteddevicename
	property string  	tempselectedtasmotaIP:app.selectedtasmotaIP
	property string  	tempselectedShellyIP:app.selectedShellyIP
	property variant    plugsArray : []
	property variant    uuidArray : []
	property bool 		firstShown: true;
	
	onShown: {
		if (firstShown) {
			intervalLabel.inputText = app.pumpInterval
			runTimeLabel.inputText = app.runDuration
			offDelayLabel.inputText = app.offDelay
			firstShown = false;
		}
		getPlugNames()
		addCustomTopRightButton("Opslaan")
		tasmotaIPlabel.inputText = tempselectedtasmotaIP
		shellyIPlabel.inputText = tempselectedShellyIP
		// Set initial device type if not set
		if (!tempdeviceType) {
			if (temptasmotaMode) {
				tempdeviceType = "tasmota"
			} else if (tempshellyMode) {
				tempdeviceType = "shelly"
			} else {
				tempdeviceType = "toon"
			}
		}
	}
	
	onCustomButtonClicked: {
		app.selecteddeviceuuid = tempselecteddeviceuuid
		app.selecteddevicename = tempselecteddevicename
		app.selectedtasmotaIP = tempselectedtasmotaIP
		app.selectedShellyIP = tempselectedShellyIP
		app.tasmotaMode = temptasmotaMode
		app.shellyMode = tempshellyMode
		app.deviceType = tempdeviceType
		
		app.pumpInterval =intervalLabel.inputText
		app.runDuration =	runTimeLabel.inputText 
		app.offDelay = offDelayLabel.inputText
		app.saveSettings()
		hide()
	}
	
	function saveTasmotaIP(text) {
		if (text) {
			tempselectedtasmotaIP = text;
		}
	}

	function saveShellyIP(text) {
		if (text) {
			tempselectedShellyIP = text;
		}
	}

	function getPlugNames(){
		model.clear()	
		plugsfound=false
		var doc = new XMLHttpRequest();
			doc.onreadystatechange = function() {
					if (doc.readyState == XMLHttpRequest.DONE) {
						var devicesfile = doc.responseText;
						var devices = devicesfile.split('<device>')
						for(var x0 = 0;x0 < devices.length;x0++){
							if((devices[x0].toUpperCase().indexOf('PUMP')>0 & devices[x0].toUpperCase().indexOf('SWITCH')>0) || devices[x0].indexOf('FGWPF102')>0 || devices[x0].indexOf('ZMNHYD1')>0 ||devices[x0].indexOf('FGWP011')>0 ||devices[x0].indexOf('NAS_WR01Z')>0 ||devices[x0].indexOf('NAS_WR01ZE')>0 ||devices[x0].indexOf('NAS_WR02ZE')>0 ||devices[x0].indexOf('EMPOWER')>0 ||devices[x0].indexOf('EM6550_v1')>0)
							{
								var n20 = devices[x0].indexOf('<uuid>') + 6
								var n21 = devices[x0].indexOf('</uuid>',n21)
								var devicesuuid = devices[x0].substring(n20, n21)
								if (debugOutput) console.log("*********pumpSwitch devicesuuid found: " + devicesuuid)
								
								var n30 = devices[x0].indexOf('<type>') + 6
								var n31 = devices[x0].indexOf('</type>',n21)
								var devicetype = devices[x0].substring(n30, n31)
								if (debugOutput) console.log("*********pumpSwitch devicetype found: " + devicetype)
								
								var n40 = devices[x0].indexOf('<name>') + 6
								var n41 = devices[x0].indexOf('</name>',n41)
								var devicesname = devices[x0].substring(n40, n41)
								if (debugOutput) console.log("*********pumpSwitch devicesname found: " + devicesname)

								listview1.model.append({name: devicesname.trim()})
								plugsArray.push(devicesname.trim())
								uuidArray.push(devicesuuid.trim())
								
								if (debugOutput) console.log("Found Plug : "  + devicesuuid.trim())
								if (devicesuuid.length>5){// plugs found
									plugsfound=true
								}
								break
							}	
						}
					}
			}
		doc.open("GET", "file:////qmf/config/config_happ_smartplug.xml", true);
		doc.setRequestHeader("Content-Encoding", "UTF-8");
		doc.send();
	}
	
	EditTextLabel {
		id: intervalLabel
		width: parent.width - 100
		height: 40		
		labelFontSize: isNxt ? 18:14
		labelFontFamily: qfont.semiBold.name
		leftTextAvailableWidth:  isNxt ? 600:480
		leftText: "Minimale interval voor de pomp (bij niet verwarmen) (uren): "
		inputHints: Qt.ImhDigitsOnly
		anchors {
			top:parent.top
			left:parent.left
			topMargin: isNxt ? 10:8
			leftMargin: isNxt ? 20:16
		}
	}
	
	EditTextLabel {
		id: runTimeLabel
		width: parent.width - 100
		height: 40		
		labelFontSize: isNxt ? 18:14
		labelFontFamily: qfont.semiBold.name
		leftTextAvailableWidth:  isNxt ? 600:480
		leftText: "Tijd dat de pomp dan moet draaien (bij niet verwarmen)(minuten): "
		inputHints: Qt.ImhDigitsOnly
		anchors {
			top:intervalLabel.bottom
			left:intervalLabel.left
			topMargin: isNxt ? 10:8
		}
	}
	

	EditTextLabel {
		id: offDelayLabel
		width: parent.width - 100
		height: 40		
		labelFontSize: isNxt ? 18:14
		labelFontFamily: qfont.semiBold.name
		leftTextAvailableWidth:  isNxt ? 600:480
		leftText: "Uitschakelvertraging na verwarmen (minuten): "
		inputHints: Qt.ImhDigitsOnly
		anchors {
			top:runTimeLabel.bottom
			left:intervalLabel.left
			topMargin: isNxt ? 10:8
		}
	}

	Text {
		id: savingsText
		text: "Besparingen "
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 18:14
		}
		anchors {
			top:offDelayLabel.bottom
			left:offDelayLabel.left
			topMargin: isNxt ? 10:8
		}
	}
	
	Text {
		id: resetLabel
		text: "terug naar 0:"
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 18:14
		}
		anchors {
			top:savingsText.top
			left:savingsText.right
			leftMargin: isNxt ? 20:16
		}
	}

	Rectangle {
		id: resetButton
		width: isNxt ? 80 : 64
		height: isNxt ? 30 : 24
		color: "orange"
		border.color: "black"
		border.width: 1
		radius: 4
		anchors {
			top: savingsText.top
			left: resetLabel.right
			leftMargin: isNxt ? 20:16
		}

		Text {
			text: "Reset"
			font.pixelSize: isNxt ? 14 : 11
			anchors.centerIn: parent
		}

		MouseArea {
			anchors.fill: parent
			onClicked: {
				app.resetSavings()
			}
		}
	}

	Text {
		id: text1
		text: "Pomp stekker "
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 18:14
		}
		anchors {
			top:savingsText.bottom
			left:offDelayLabel.left
			topMargin: isNxt ? 10:8
		}
	}
	
	Text {
		id: deviceTypeLabel
		text: "Apparaat type:"
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 18:14
		}
		anchors {
			top:text1.top
			left:text1.right
			leftMargin: isNxt ? 20:16
		}
	}

	Row {
		id: deviceTypeButtons
		spacing: isNxt ? 10 : 8
		anchors {
			top: text1.top
			left: deviceTypeLabel.right
			leftMargin: isNxt ? 20:16
		}

		Rectangle {
			id: toonButton
			width: isNxt ? 80 : 64
			height: isNxt ? 30 : 24
			color: tempdeviceType == "Toon" ? "lightgreen" : "lightgray"
			border.color: "black"
			border.width: 1
			radius: 4

			Text {
				text: "Toon"
				font.pixelSize: isNxt ? 14 : 11
				anchors.centerIn: parent
			}

			MouseArea {
				anchors.fill: parent
				onClicked: {
					tempdeviceType = "Toon"
					temptasmotaMode = false
					tempshellyMode = false
				}
			}
		}

		Rectangle {
			id: tasmotaButton
			width: isNxt ? 80 : 64
			height: isNxt ? 30 : 24
			color: tempdeviceType == "Tasmota" ? "lightgreen" : "lightgray"
			border.color: "black"
			border.width: 1
			radius: 4

			Text {
				text: "Tasmota"
				font.pixelSize: isNxt ? 14 : 11
				anchors.centerIn: parent
			}

			MouseArea {
				anchors.fill: parent
				onClicked: {
					tempdeviceType = "Tasmota"
					temptasmotaMode = true
					tempshellyMode = false
				}
			}
		}

		Rectangle {
			id: shellyButton
			width: isNxt ? 80 : 64
			height: isNxt ? 30 : 24
			color: tempdeviceType == "Shelly" ? "lightgreen" : "lightgray"
			border.color: "black"
			border.width: 1
			radius: 4

			Text {
				text: "Shelly"
				font.pixelSize: isNxt ? 14 : 11
				anchors.centerIn: parent
			}

			MouseArea {
				anchors.fill: parent
				onClicked: {
					tempdeviceType = "Shelly"
					temptasmotaMode = false
					tempshellyMode = true
				}
			}
		}
	}
	

	EditTextLabel4421 {
		id: tasmotaIPlabel
		width: (parent.width*0.4) - 40		
		leftTextAvailableWidth:  isNxt ? 200:160
		leftText: "Tasmota IP adres"
		height: 40		
		labelFontSize: isNxt ? 18:14
		labelFontFamily: qfont.semiBold.name
		anchors {
			left: text1.left
			top: resetSavingsButton.bottom
			topMargin: isNxt ? 10:8
		}
		onClicked: {
			qkeyboard.open("Tasmota IP adres", tasmotaIPlabel.inputText, saveTasmotaIP)
		}
		visible: tempdeviceType == "Tasmota"
	}

	EditTextLabel4421 {
		id: shellyIPlabel
		width: (parent.width*0.4) - 40		
		leftTextAvailableWidth:  isNxt ? 200:160
		leftText: "Shelly IP adres"
		height: 40		
		labelFontSize: isNxt ? 18:14
		labelFontFamily: qfont.semiBold.name
		anchors {
			left: text1.left
			top: deviceTypeButtons.bottom
			topMargin: isNxt ? 10:8
		}
		onClicked: {
			qkeyboard.open("Shelly IP adres", shellyIPlabel.inputText, saveShellyIP)
		}
		visible: tempdeviceType == "Shelly"
	}


	Rectangle{
		id: listviewContainer1
		width: isNxt ? parent.width/2 -100 : parent.width/2 - 80
		height: isNxt ? 140 : 112
		color: "white"
		radius: isNxt ? 5 : 4
		border.color: "black"
			border.width: isNxt ? 3 : 2
		anchors {
			left: text1.left
			top: resetSavingsButton.bottom
			topMargin: isNxt ?10:8
		}

		Component {
			id: aniDelegate
			Item {
				width: isNxt ? (parent.width-20) : (parent.width-16)
				height: isNxt ? 22 : 18
				Text {
					id: tst
					text: name
					font.pixelSize: isNxt ? 18:14
				}
			}
		}

		ListModel {
				id: model
		}
		ListView {
			id: listview1
			anchors {
				top: parent.top
				topMargin:isNxt ? 20 : 16
				leftMargin: isNxt ? 12 : 9
				left: parent.left
			}
			width: parent.width
			height: isNxt ? (parent.height-50) : (parent.height-40)
			model:model
			delegate: aniDelegate
			highlight: Rectangle { 
				color: "lightsteelblue"; 
				radius: isNxt ? 5 : 4
			}
			focus: true
		}
		visible: tempdeviceType == "Toon"
	}
	
	IconButton {
		id: upButton
		anchors {
			top: listviewContainer1.top
			left:  listviewContainer1.right
			leftMargin : isNxt? 3 : 2
		}

		iconSource: "qrc:/tsc/up.png"
		onClicked: {
		    if (listview1.currentIndex>0){
                        listview1.currentIndex  = listview1.currentIndex -1
            }
		}
		visible: tempdeviceType == "Toon"		
	}

	IconButton {
		id: downButton
		anchors {
			bottom: listviewContainer1.bottom
			left:  listviewContainer1.right
			leftMargin : isNxt? 3 : 2

		}
		iconSource: "qrc:/tsc/down.png"
		onClicked: {
		    if (numberofItems2>listview1.currentIndex +1){
                        listview1.currentIndex  = listview1.currentIndex +1
            }
		}
		visible: tempdeviceType == "Toon"		
	}


	NewTextLabel {
		id: addFibaro
		width: isNxt ? 250 : 200;  
		height: isNxt ? 40:32
		buttonActiveColor: "lightgreen"
		buttonHoverColor: "blue"
		enabled : true
		textColor : "black"
		buttonText:  "Selecteer deze stekker"
		anchors {
			top: listviewContainer1.bottom
			topMargin:isNxt ? 10:8
			left: text1.left
			}
		onClicked: {
			if (plugsArray[listview1.currentIndex].length>1){
				tempselecteddevicename = plugsArray[listview1.currentIndex]
				tempselecteddeviceuuid = uuidArray[listview1.currentIndex]
				if (debugOutput) console.log("*********pumpSwitch Selected Plug : "  + tempselecteddevicename)
				if (debugOutput) console.log("*********pumpSwitch Selected Plug : "  + tempselecteddeviceuuid)
			}
		}
		visible: tempdeviceType == "Toon"
	}

	Text {
		id: text10
		text: "Geselecteerd (naam): " + tempselecteddevicename
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 18:14
		}
		anchors {
			top:addFibaro.bottom
			topMargin:isNxt ? 10:8
			left: text1.left
		}
		visible: tempdeviceType == "Toon"
	}
	
	Text {
		id: text11
		text: "Geselecteerd (uuid): " + tempselecteddeviceuuid
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 18:14
		}
		anchors {
			top:text10.bottom
			topMargin:isNxt ? 10:8
			left: text1.left
		}
		visible: tempdeviceType == "Toon"
	}
	
	Text {
		id: text12
		text: "Stekker niet zichtbaar in de lijst? Hernoem hem naar Pump Switch en probeer opnieuw."
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 18:14
		}
		anchors {
			top:text11.bottom
			topMargin:isNxt ? 10:8
			left: text1.left
		}
		visible: tempdeviceType == "Toon"
	}



}




