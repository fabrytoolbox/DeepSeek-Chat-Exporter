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