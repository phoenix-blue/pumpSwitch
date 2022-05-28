import QtQuick 2.1
import qb.components 1.0

Tile {
	id: pumpSwitchTile
	property var idArray : []
	property bool debugOutput: app.debugOutput
	property bool dimState: screenStateController.dimmedColors
	property bool runPump:app.runPump
	property int currentFrame: 1
	
	
	Component.onCompleted: {
		app.pumpUpdated.connect(updateTile);
	}

	function updateTile() {
		runPump = app.runPump
	}


	onClicked: {
		stage.openFullscreen(app.pumpSwitchScreenUrl)
	}
	
	Text {
		id: txtTitle
		anchors {
			baseline: parent.top
			baselineOffset: 30
			horizontalCenter: parent.horizontalCenter
		}
		font {
			family: qfont.regular.name
			pixelSize: qfont.tileTitle
		}
		color: !dimState? "black" : "white"
		text: "switchPump"
	}

	Image {
		id: waterIcon
		anchors.centerIn: parent
		source: runPump? "file:///qmf/qml/apps/pumpSwitch/drawables/" + "pump_" + currentFrame + (dimState ? "-dim" : "") + ".png" : "file:///qmf/qml/apps/pumpSwitch/drawables/" + "img_pump_stop" + (dimState ? "-dim" : "") + ".png"
		width: isNxt ? 150:120
		height: isNxt ? 150:120
		fillMode: Image.PreserveAspectFit
	}

	Text {
		id: txtPumpStatus
		text: app.pumpStatus
		//text: runPump? "Aan" : "Uit"
		color: dimmableColors.tileTextColor
		anchors {
			horizontalCenter: parent.horizontalCenter
			baseline: parent.bottom
			baselineOffset: designElements.vMarginNeg16
		}
		font.pixelSize: qfont.tileText
		font.family: qfont.regular.name
	}


	Timer {
		id: animationTimer
		interval: 400
		running:runPump
		repeat: true
		onTriggered: 
			if(currentFrame==4){currentFrame=1}else{currentFrame++}
	}

}
