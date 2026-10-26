# 📖 DeepSeek Chat Exporter

Esporta conversazioni DeepSeek (JSON) in storie HTML/TXT, con nomi personalizzati.

## ✨ Feature

- ✅ **Estrazione in ordine cronologico** (REQUEST + RESPONSE)
- ✅ **Personalizzazione nomi** (utente e assistente)
- ✅ **Salta ruoli** (lascia vuoto per non estrarre)
- ✅ **Validazione JSON** (controlla che il file sia valido)
- ✅ **Filtro messaggi vuoti** (solo simboli/spazi)
- ✅ **Output HTML** con tema scuro
- ✅ **Output TXT** per archivio
- ✅ **Log su file** con dettagli
- ✅ **Controllo PowerShell 7**
- ✅ **Apertura automatica** cartella output

## 📋 Requisiti

- **Windows 10 / 11**
- **PowerShell 7+** (scarica da https://aka.ms/powershell)

## 🚀 Quick start

```powershell
git clone https://github.com/fabrytoolbox/DeepSeek-Chat-Exporter.git
cd DeepSeek-Chat-Exporter
Unblock-File .\DeepSeek-Chat-Exporter.ps1
.\DeepSeek-Chat-Exporter.ps1

Oppure doppio click su avvia.bat .
📖
 Come si usa
1. Esporta la conversazione da DeepSeek in JSON (o altro formato)
2. Lancia lo script
3. Seleziona il file JSON
4. Inserisci i nomi (es. "Fabry" per USER, "Jarvis" per ASSISTANT)
5. Inserisci titolo, data, nome file
6. Lo script genera:
storie\<nome>.html (tema scuro)
storie\<nome>.txt (archivio)
storie\deepseek_exporter_*.log (log)
📂
 Struttura output
text
storie/
├── mia-storia.html          # Storia HTML con tema scuro
├── mia-storia.txt           # Storia TXT per archivio
└── deepseek_exporter_*.log  # Log dell'esportazione
🎯
 Casi d'uso
Archiviare conversazioni importanti con AI
Creare "storie" da chat AI (con nomi personalizzati)
Condividere dialoghi in formato leggibile
Backup di conversazioni con assistenti AI
🐛
 Problemi comuni
"JSON non valido"
Il file potrebbe essere corrotto o in un formato diverso. Lo script chiede se procedere
comunque.
"Nessun messaggio trovato"
Il JSON potrebbe non avere il formato atteso (fragments, type, content). Verifica che sia
un export di DeepSeek.
"PowerShell 7 non trovato"
Installa PowerShell 7 da 
�
�
 Licenza
MIT (vedi LICENSE ).
🙏
 Crediti
DeepSeek per l'AI
https://aka.ms/powershell
Fabry Toolbox per il tool
Jarvis (l'assistente) per la pazienza
