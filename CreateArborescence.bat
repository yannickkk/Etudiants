REM "Programme de création des répertoires de base conformément à la démarche qualité"
REM " Ce programme devra être exécuté au niveau ou se situera la racine du projet (l'ensemble des répertoires)"
echo off
cls
REM "On demande le nom du projet qui sera le nom de la racine du projet"
set /p rep= Nom du nouveau projet :
REM "Creation du répertoire racine"
mkdir "%rep%"
cd "%rep%"
REM "Création des répertoires de nécessaires à tout traitement suivant (les noms peuvent être adaptés à chacun ci-dessous)"
mkdir "DonneesBrutes"
mkdir "DonneesTravaillees"
mkdir "Programmes"
mkdir "Docs"
mkdir "Outputs"
REM " Un fichier portant la date de création est généré"
set Auto=Creation-%Date:~-4%-%Date:~-7,-5%-%Date:~-10,-8%.txt
echo Création de l'arborescence de ce projet %rep% le %Date:~-4%-%Date:~-7,-5%-%Date:~-10,-8%> %Auto%
cd ..