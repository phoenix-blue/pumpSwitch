import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: pumpSwitchConfigScreen
	screenTitle: 		"Pomp schakeling instellingen"
	property bool 		plugsfound: false
	property bool 		temptasmotaMode: app.tasmotaMode
	property bool 		debugOutput: app.debugOutput
	property string  	tempselecteddeviceuuid:app.selecteddeviceuuid
	property string  	tempselecteddevicename:app.selecteddevicename
	property string  	tempselectedtasmotaIP:app.selectedtasmotaIP
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
		enableTasmotaToggle.isSwitchedOn = temptasmotaMode;
	}
	
	onCustomButtonClicked: {
		app.selecteddeviceuuid = tempselecteddeviceuuid
		app.selecteddevicename = tempselecteddevicename
		app.selectedtasmotaIP = tempselectedtasmotaIP
		app.tasmotaMode = temptasmotaMode
		
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
		id: text1
		text: "Z-wave stekker "
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
	
	OnOffToggle {
		id: enableTasmotaToggle
		height:  30
		anchors {
			top:text1.top
			left:text1.right
			leftMargin: isNxt ? 20:16
		}
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			if (isSwitchedOn) {
				temptasmotaMode = true;
			} else {
				temptasmotaMode = false;
			}
		}
	}
	
	Text {
		id: text2
		text: "Tasmota"
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 18:14
		}
		anchors {
			top:text1.top
			left:enableTasmotaToggle.right
			leftMargin: isNxt ? 20:16
		}
	}
	

	EditTextLabel4421 {
		id: tasmotaIPlabel
		width: (parent.width*0.4) - 40		
		leftTextAvailableWidth:  isNxt ? 200:160
		leftText: "Tasmota IP adress"
		height: 40		
		labelFontSize: isNxt ? 18:14
		labelFontFamily: qfont.semiBold.name
		anchors {
			left: text1.left
			top: text1.bottom
			topMargin: isNxt ? 10:8
		}
		onClicked: {
			qkeyboard.open("Tasmota IP adress", tasmotaIPlabel.inputText, saveTasmotaIP)
		}
		visible: temptasmotaMode
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
			top: text1.bottom
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
		visible: !temptasmotaMode
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
		visible: !temptasmotaMode		
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
		visible: !temptasmotaMode		
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
		visible: !temptasmotaMode
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
		visible: !temptasmotaMode
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
		visible: !temptasmotaMode
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
		visible: !temptasmotaMode
	}
	
	

}




