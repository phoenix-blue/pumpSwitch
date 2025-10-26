# Enhanced PumpSwitch v1.0.8 - Multi-Device Support & Power Monitoring

## 🎯 **Samenvatting**
Deze pull request voegt uitgebreide ondersteuning toe voor **Shelly Plug-S Gen3** apparaten en implementeert een geavanceerd **power monitoring systeem** met intelligente filtering en nauwkeurige besparingsberekeningen.

## ✨ **Nieuwe Features**

### 🔌 **Multi-Device Ondersteuning**
- **Shelly Plug-S Gen3**: Volledige RPC API integratie (`/rpc/Switch.Set`, `/rpc/Shelly.GetStatus`)
- **Elegant Device Menu**: Button-gebaseerde apparaat selectie (Toon/Tasmota/Shelly)
- **Backward Compatible**: Behoudt volledige compatibiliteit met bestaande Toon/Tasmota setups

### ⚡ **Intelligente Power Monitoring**
- **Opstroom Filtering**: Negeert hoge startstroom gedurende eerste 30 seconden
- **Extreme Value Filtering**: Filtert onrealistische waarden (5-500W bereik)
- **Power Averaging**: Berekent gemiddeld verbruik over volledige pomprun
- **Accurate Savings**: Corrigeert timing - berekent besparingen bij uitschakelen (niet inschakelen)

### 🎨 **UI/UX Verbeteringen**
- **Consistente Button Styling**: Uniforme look-and-feel door hele applicatie
- **Reset Functionaliteit**: "Besparingen terug naar 0" met één klik
- **Dynamic Display**: Toont 0W wanneer pomp uitstaat (ipv laatste waarde)
- **Improved Layout**: Logische volgorde van configuratie elementen

## 🔧 **Technische Details**

### **Gewijzigde Bestanden:**
- `PumpSwitchApp.qml` - Hoofdlogica + Shelly integratie + power monitoring
- `PumpSwitchConfigScreen.qml` - Device selection menu + reset functionaliteit  
- `PumpSwitchScreen.qml` - Dynamic device type display
- `PumpSwitchTile.qml` - Correcte error handling voor non-Toon devices

### **Nieuwe Functionaliteit:**
```qml
// Power monitoring met filtering
function addPowerReading(powerValue) {
    var currentTime = new Date().getTime() / 1000
    
    // Skip first 30 seconds (startup current filtering)
    if (currentTime - powerReadingStartTime < 30) return
    
    // Filter extreme values
    if (powerValue < 5 || powerValue > 500) return
    
    powerReadings.push(powerValue)
    // Calculate average for savings
}

// Shelly Gen3 RPC API
function getShellypower() {
    var url = "http://" + selectedShellyIP + "/rpc/Shelly.GetStatus"
    // Parse switch:0 power data
}
```

### **API Endpoints:**
- **Shelly Status**: `GET /rpc/Shelly.GetStatus`
- **Shelly Switch On**: `GET /rpc/Switch.Set?id=0&on=true`  
- **Shelly Switch Off**: `GET /rpc/Switch.Set?id=0&on=false`

## 🐛 **Bug Fixes**
- ✅ **Tile Error Icon**: Fixed error display voor non-Toon devices
- ✅ **Case Sensitivity**: Gestandaardiseerde device type strings
- ✅ **Power Display**: Reset naar 0W wanneer pomp uitstaat
- ✅ **Savings Logic**: Corrigeert timing van besparingsberekeningen

## 🧪 **Testing**
- ✅ Getest met **Shelly Plug-S Gen3** (IP: 192.168.1.200)
- ✅ **Backward compatibility** gevalideerd met bestaande Toon/Tasmota setups
- ✅ **Power monitoring** accuracy geverifieerd met startup filtering
- ✅ **UI consistency** gecontroleerd op alle schermen

## 📊 **Performance Impact**
- **Minimal overhead**: Power monitoring voegt ~1KB geheugen toe
- **Network efficient**: Gebruikt bestaande polling intervals
- **Startup optimized**: 30-second delay voorkomt onnodige API calls

## 💡 **Gebruiker Ervaring**
```
Voor: Alleen Toon/Tasmota support, onnauwkeurige besparingen
Na:   Multi-device support, accurate power monitoring, elegante UI
```

## 🔄 **Migration Path**
- **Automatisch**: Bestaande instellingen blijven behouden
- **Opt-in**: Nieuwe features beschikbaar via device type selectie
- **Zero downtime**: Geen impact op huidige Toon/Tasmota gebruikers

## 📝 **Documentatie**
- ✅ **README.md**: Uitgebreide documentatie toegevoegd
- ✅ **Installation Guide**: Stap-voor-stap instructies
- ✅ **API Documentation**: Alle endpoints gedocumenteerd
- ✅ **Troubleshooting**: Veelvoorkomende problemen + oplossingen

---

**Ready for review!** 🚀 Deze PR voegt significant waarde toe voor de Toon community met moderne device support en professionele power monitoring.