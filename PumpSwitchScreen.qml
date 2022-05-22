import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Screen {
	id: pumpSwitchScreen
	screenTitle: "PumpSwitch"
	
	onShown: {
		addCustomTopRightButton("Instellingen")
	}

	onCustomButtonClicked: {
		stage.openFullscreen(app.pumpSwitchConfigScreenUrl)
	}

	Text {
		id: text1
		text: "Deze app is in staat een slimme stekker met de verwarming mee te schakelen. Dit is bijvoorbeeld handig om de vloerverwarmingspomp te schakelen. De pomp zal draaien als het systeem verwarmd plus een nadraaitijd na het verwarmen (instelbaar). Als de pomp 24 uur (instelbaar) niet heeft gedraaid dan zal de pomp 10 minuten (instelbaar) draaien om lange stailstand en vastlopen te voorkomen."
		wrapMode: Text.WordWrap
		width : isNxt? parent.width - 24 : parent.width - 18

		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 24:20
		}
		anchors {
			top:parent.top
			left:parent.left
			topMargin: isNxt ? 20:16
			leftMargin: isNxt ? 20:16
		}
	}

	Text {
		id: text2
		text: "Selecteer onder instellingen de slimme stekker. Hieruit is de keuze tussen de zwave plus stekkers die je hebt aangemeld in de Toon of een Tasmota stekker (bijvoorbeeld een Sonoff die je geflashed hebt)."
		wrapMode: Text.WordWrap
		width : isNxt? parent.width - 24 : parent.width - 18

		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 24:20
		}
		anchors {
			top:text1.bottom
			left:text1.left
			topMargin: isNxt ? 20:16
		}
	}
}




