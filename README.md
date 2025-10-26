# PumpSwitch v1.0.8 - Enhanced Multi-Device Support

Een geavanceerde pompschakel-app voor Toon thermostaten met ondersteuning voor meerdere apparaat types en intelligente stroomverbruikmonitoring.

## 🆕 Nieuwe Features in v1.0.8

### Multi-Device Ondersteuning
- **Toon (Z-wave)**: Originele ondersteuning voor Toon ingebouwde schakelaars
- **Tasmota**: HTTP API ondersteuning voor Tasmota-gebaseerde schakelaars
- **Shelly Plug-S Gen3**: Volledige RPC API integratie voor nieuwste Shelly devices

### Intelligente Stroomverbruikmonitoring
- **Opstroom Filtering**: Negeert hoge opstroom gedurende eerste 30 seconden
- **Extreme Waarde Filtering**: Filtert onrealistische waarden (5-500W bereik)
- **Gemiddelde Berekening**: Gebruikt gemiddeld verbruik voor nauwkeurige besparingsberekeningen
- **Accurate Timing**: Berekent besparingen wanneer pomp uitschakelt (niet inschakelt)

### Verbeterde Gebruikersinterface
- **Elegant Keuzemenu**: Mooie button-gebaseerde apparaat selectie
- **Consistente Styling**: Uniforme look-and-feel door hele applicatie
- **Reset Functionaliteit**: Eenvoudig besparingen resetten met één klik
- **Dynamic Display**: Toont 0W wanneer pomp uitstaat

## 🔧 Installatie

1. **Upload naar Toon**: Kopieer alle bestanden naar `/mnt/data/tsc/`
2. **Configureer Apparaat**: Kies je apparaat type in instellingen
3. **Stel IP in**: Voor Tasmota/Shelly, voer het juiste IP adres in
4. **Test Verbinding**: Controleer of de pomp correct wordt geschakeld

## ⚙️ Configuratie

### Toon (Z-wave)
- Selecteer "Toon" als apparaat type
- Kies je pomp schakelaar uit de lijst
- Geen aanvullende configuratie nodig

### Tasmota 
- Selecteer "Tasmota" als apparaat type
- Voer IP adres van je Tasmota device in (bijv. 192.168.1.100)
- Zorg dat HTTP API toegankelijk is

### Shelly Plug-S Gen3
- Selecteer "Shelly" als apparaat type
- Voer IP adres van je Shelly device in (bijv. 192.168.1.200)
- Gebruikt moderne RPC API voor betrouwbare communicatie

## 📊 Monitoring & Besparingen

### Power Monitoring
- Realtime stroomverbruik monitoring
- Automatische filtering van opstroom pieken
- Gemiddelde berekening over volledige looptijd
- Nauwkeurige euro besparingen op basis van werkelijk verbruik

### Reset Functionaliteit
- **Besparingen terug naar 0**: Reset alle opgeslagen besparingen
- **Behoud Instellingen**: Apparaat configuratie blijft behouden
- **Instant Update**: Onmiddellijke visuele bevestiging

## 🔄 API Endpoints

### Tasmota
- **Status**: `http://[IP]/?m=1`
- **Aan**: `http://[IP]/cm?cmnd=Power%20On`
- **Uit**: `http://[IP]/cm?cmnd=Power%20Off`

### Shelly Gen3 RPC
- **Status**: `http://[IP]/rpc/Shelly.GetStatus`
- **Aan**: `http://[IP]/rpc/Switch.Set?id=0&on=true`
- **Uit**: `http://[IP]/rpc/Switch.Set?id=0&on=false`

## 🐛 Troubleshooting

### Geen Verbinding
1. Controleer IP adres en netwerkconnectiviteit
2. Zorg dat firewall HTTP toegang toestaat
3. Test API endpoints handmatig in browser

### Onjuiste Power Readings
1. Controleer of apparaat power monitoring ondersteunt
2. Wacht 30 seconden na opstarten voor stabiele metingen
3. Reset besparingen en start nieuwe meetperiode

### Schakelaar Niet Gevonden (Toon)
1. Hernoem je schakelaar naar "Pump Switch"
2. Restart Toon app
3. Controleer in device lijst

## 📝 Changelog v1.0.8

- ✅ Shelly Plug-S Gen3 ondersteuning toegevoegd
- ✅ Intelligente power averaging geïmplementeerd
- ✅ Startup current filtering (30 sec delay)
- ✅ Extreme value filtering (5-500W)
- ✅ Besparingen logica gecorrigeerd
- ✅ UI consistentie verbeterd
- ✅ Reset functionaliteit toegevoegd
- ✅ 0W display wanneer pomp uit is
- ✅ Backward compatibility behouden

## 🤝 Bijdragen

Contributions zijn welkom! Open een issue of pull request op GitHub.

## 📄 Licentie

Open source project voor de Toon community.

---

**Ontwikkeld door phoenix-blue** | **Enhanced by GitHub Copilot**