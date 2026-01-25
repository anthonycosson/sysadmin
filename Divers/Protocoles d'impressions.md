# Les protocoles de découverte :

- mDSN / Bonjour : (5353) > Standard ouvert, multi-OS. Sert uniquement à la découverte.
- WSD : (3702/5357/5358) >
    - 3702 : Pour la découverte
    - 5537/5538 : Communication  Bidirectionnel pour l’état et/ou l’impression. Peut aussi passer en RAW.
- SMB / CIFS : 445 (138/139 anciennement) > Pour les imprimantes partagées

# Les protocoles d’impression :

- IPP : 631 > moderne, ouvert, utilisé par macOS, Linux, AirPrint. Souvent associé à mDNS
- RAW / JetDirecte : 9100 > Impression socket directe, rapide mais sans gestion avancée.
- LPD / LPR  : 515 > Ancien protocole Unix

# Les protocoles de supervision :

- SNMP : 161
- **SNMP Traps** : 162