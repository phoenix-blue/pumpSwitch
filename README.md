# PumpSwitch

Intelligente pompschakel-app voor Toon thermostaten met ondersteuning voor verschillende apparaat types.

## Overzicht

PumpSwitch is een Toon app die automatisch je CV-pomp kan schakelen op basis van verwarmingspatronen. Dit helpt energie te besparen en verlengt de levensduur van je CV-pomp.

## Installatie

1. Upload alle bestanden naar `/mnt/data/tsc/` op je Toon
2. Herstart de Toon interface  
3. De app verschijnt als nieuwe tile op je Toon

## Configuratie

### Apparaat Types

**Toon (Z-wave)** - Originele functionaliteit
- Selecteer "Toon" als apparaat type
- Kies je pomp schakelaar uit de lijst
- Hernoem je schakelaar naar "Pump Switch" indien nodig

**Tasmota** 
- Selecteer "Tasmota" als apparaat type
- Voer IP adres van je Tasmota device in
- Zorg dat HTTP API toegankelijk is

**Shelly Plug-S Gen3** *(Nieuw in v1.0.8-enhanced)*
- Selecteer "Shelly" als apparaat type  
- Voer IP adres van je Shelly device in
- Gebruikt moderne RPC API voor betrouwbare communicatie

### Instellingen
- **Minimale interval**: Tijd tussen pomploops wanneer verwarming uit is
- **Looptijd**: Hoe lang de pomp draait per cyclus  
- **Uitschakelvertraging**: Vertraging na verwarming uitschakelt

## Enhanced Features (v1.0.8)

Deze versie bevat uitgebreide verbeteringen voor moderne smart home setups:

### 🔌 Multi-Device Ondersteuning
- **Shelly Gen3 RPC API**: Volledige ondersteuning voor nieuwste Shelly hardware
- **Elegant Device Menu**: Verbeterde UI met button-gebaseerde selectie
- **100% Backward Compatible**: Alle bestaande Toon/Tasmota functionaliteit behouden

### ⚡ Intelligente Power Monitoring  
- **Opstroom Filtering**: Negeert hoge startstroom (eerste 30 seconden)
- **Extreme Value Filtering**: Filtert onrealistische waarden (5-500W)
- **Power Averaging**: Nauwkeurige gemiddelde berekening over pomprun
- **Accurate Savings**: Gecorrigeerde timing - berekent bij uitschakelen

### 🎨 UI/UX Verbeteringen
- **Consistente Styling**: Uniforme button design door hele app
- **Reset Functionaliteit**: "Besparingen terug naar 0" met één klik  
- **Dynamic Display**: Toont 0W wanneer pomp uit (ipv laatste waarde)
- **Improved Layout**: Logische volgorde configuratie elementen

## API Endpoints

### Shelly Gen3 RPC *(Nieuw)*
```
Status: GET http://[IP]/rpc/Shelly.GetStatus
Aan:    GET http://[IP]/rpc/Switch.Set?id=0&on=true  
Uit:    GET http://[IP]/rpc/Switch.Set?id=0&on=false
```

### Tasmota HTTP
```  
Status: GET http://[IP]/?m=1
Aan:    GET http://[IP]/cm?cmnd=Power%20On
Uit:    GET http://[IP]/cm?cmnd=Power%20Off
```

## Troubleshooting

**Geen verbinding (Tasmota/Shelly)**
- Controleer IP adres en netwerkconnectiviteit
- Test API endpoints handmatig in browser
- Zorg dat firewall HTTP toegang toestaat

**Schakelaar niet gevonden (Toon)**  
- Hernoem schakelaar naar "Pump Switch"
- Restart Toon app en controleer device lijst

**Onjuiste power readings**
- Wacht 30 seconden na pomp start voor stabiele metingen  
- Reset besparingen voor nieuwe meetperiode
- Controleer of device power monitoring ondersteunt

## Changelog

Zie `Changelog.txt` voor volledige versiegeschiedenis.

## Bijdragen

Contributions welkom! Open een issue of pull request.

---

**Origineel door oepi-loepi** | **Enhanced door phoenix-blue**