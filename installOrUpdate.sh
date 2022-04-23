#!/bin/bash

SETCOLOR_FAILURE="\\033[1;31m"
SETCOLOR_SUCCESS="\\033[1;32m"
SETCOLOR_WARNING="\\033[1;33m"
SETCOLOR_NORMAL="\\033[0;39m"
success() {
    echo -e "${SETCOLOR_SUCCESS}$*${SETCOLOR_NORMAL}"
}
error() {
    echo -e "${SETCOLOR_FAILURE}$*${SETCOLOR_NORMAL}"
    exit 1
}
warn() {
    echo -e "${SETCOLOR_WARNING}$*${SETCOLOR_NORMAL}"
}

INSTALLDIR=/var/www

if [ $# = 1 ]; then 
	if [ $1 = '-h' ] || [ $1 = '--help' ]; then
		warn "Usage: $0 [repertoire_d_installation]"
		echo "par défaut le répertoire d'installation est $INSTALLDIR"
    	exit 0
	else
		INSTALLDIR="$1"
	fi
fi   

echo
echo '+----------------------------------------------------------+'
echo "| Script d'installation et de mise à jour de la passerelle |"
echo '+----------------------------------------------------------+'
echo

if [ $USER != root ]; then
        error "merci de faire sudo $0"
fi

warn '   Attention, ce script est toujours en phase de test et donc fourni SANS garantie'

if $(which dpkg) -L apt  2>/dev/null | grep -q $(which apt-get); then
	echo ' -- Système Debian ou Ubuntu - compatible avec le script'
else
	error 'Désolé ce script est conçu pour une distribution Debian ou Ubuntu ! Vous pouvez vous inspirer du script et de la documentation pour installer sur un autre système'
fi

if [ -d "$INSTALLDIR/config" ]; then
	warn 'Une installation de Scodoc_Notes semble déjà présente, mise à jour des dossiers html, includes et lib'

else
	warn 'Nouvelle installation détectée, installation des packages'
	apt -yq update
	apt -yq install openssl apache2 wget unzip links
	apt -yq install php php-curl php-xml php-ldap
	a2enmod ssl
	phpenmod ldap
	systemctl restart apache2

	doinstall=1
fi

success "Récupération de l'archive sur git"
wget -q https://github.com/SebL68/Scodoc_Notes/archive/refs/heads/main.zip
mv main.zip "$INSTALLDIR"
cd "$INSTALLDIR"

success "Extraction de l'archive"
unzip -q main.zip
rm -rf html includes lib 
mv  Scodoc_Notes-main/html .
mv  Scodoc_Notes-main/includes .
mv  Scodoc_Notes-main/lib .

if [ $doinstall ]; then
	mv Scodoc_Notes-main/data .
	mv Scodoc_Notes-main/config .

	echo 'Changement des droits sur le répetoire data'
	chgrp -R www-data config data
	chmod -R o-rx config data
	chmod g+w data
	cat << FIN 
L'installation automatique est terminée, maintenant, à vous de jouer :
- modifiez les fichiers /config/config.php et /config/cas_config.php suivant vos paramètres,
- redémarrez le serveur web par : sudo systemctl restart apache2,
- pour vous aider, vous pouvez diagnostiquer le fonctionnement de la passerelle avec un navigateur https://votre_serveur/services/diagnostic.php ou en mode texte avec :  
FIN
     	success 'links https://localhost/services/diagnostic.php'
	echo
	warn 'ATTENTION Il est fortement conseillé de changer le certificat auto-signé pour un vrai! Contactez votre DSI'
else
	echo 'Mise à jour terminée'
fi

#Nettoyage
rm -rf Scodoc_Notes-main main.zip