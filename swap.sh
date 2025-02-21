#!/bin/bash

# Script per creare un file di swap su Ubuntu 22.04
# Uso: sudo ./swap.sh <dimensione_in_GB>, es. sudo ./swap.sh 32

# Controlla se è stato passato un argomento
if [ $# -ne 1 ]; then
    echo "Errore: Specifica la dimensione in GB. Esempio: sudo ./swap.sh 32"
    exit 1
fi

# Verifica che l'argomento sia un numero intero positivo
if ! [[ "$1" =~ ^[0-9]+$ ]] || [ "$1" -le 0 ]; then
    echo "Errore: Inserisci un numero intero positivo per la dimensione in GB."
    exit 1
fi

# Verifica se lo script è eseguito come root
if [ "$EUID" -ne 0 ]; then
    echo "Errore: Questo script deve essere eseguito come root (usa sudo)."
    exit 1
fi

# Variabili
SIZE=$1  # Dimensione in GB
SWAP_FILE="/swap.img"
BLOCK_SIZE=1M
COUNT=$((SIZE * 1024))  # Converti GB in MB (1 GB = 1024 MB)

# Verifica spazio disponibile su disco
AVAILABLE_SPACE=$(df -m / | tail -1 | awk '{print $4}')  # Spazio disponibile in MB
if [ "$AVAILABLE_SPACE" -lt "$COUNT" ]; then
    echo "Errore: Spazio su disco insufficiente. Richiesti ${SIZE}GB (${COUNT}MB), disponibili ${AVAILABLE_SPACE}MB."
    exit 1
fi

# Disattiva lo swap esistente
echo "Disattivazione dello swap corrente..."
swapoff "$SWAP_FILE" 2>/dev/null || echo "Nessuno swap attivo da disattivare."

# Rimuove il vecchio file di swap (se esiste)
if [ -f "$SWAP_FILE" ]; then
    echo "Rimozione del vecchio file di swap..."
    rm -f "$SWAP_FILE"
fi

# Crea un nuovo file di swap
echo "Creazione di un nuovo file di swap da ${SIZE}GB..."
dd if=/dev/zero of="$SWAP_FILE" bs="$BLOCK_SIZE" count="$COUNT" status=progress

# Imposta i permessi corretti
echo "Impostazione dei permessi..."
chmod 600 "$SWAP_FILE"

# Formatta il file come swap
echo "Formattazione del file come swap..."
mkswap "$SWAP_FILE"

# Attiva il nuovo swap
echo "Attivazione del nuovo swap..."
swapon "$SWAP_FILE"

# Verifica il risultato
echo "Verifica dello swap attivo:"
swapon --show

# Controlla se il file è già in /etc/fstab, altrimenti lo aggiunge
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "Aggiunta di $SWAP_FILE a /etc/fstab per persistenza al riavvio..."
    echo "$SWAP_FILE none swap sw 0 0" | tee -a /etc/fstab
else
    echo "$SWAP_FILE già presente in /etc/fstab."
fi

echo "Swap da ${SIZE}GB creato e attivato con successo!"
