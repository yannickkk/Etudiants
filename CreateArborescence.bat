REM "Programme de cr�ation des r�pertoires de base conform�ment � la d�marche qualit�"
REM " Ce programme devra �tre ex�cut� au niveau ou se situera la racine du projet (l'ensemble des r�pertoires)"
echo off
cls
REM "On demande le nom du projet qui sera le nom de la racine du projet"
set /p rep= Nom du nouveau projet :
REM "Creation du r�pertoire racine"
mkdir "%rep%"
cd "%rep%"
REM "Cr�ation des r�pertoires de n�cessaires � tout traitement suivant (les noms peuvent �tre adapt�s � chacun ci-dessous)"
mkdir "DonneesBrutes"
mkdir "DonneesTravaillees"
mkdir "Programmes"
mkdir "Docs"
mkdir "Outputs"
REM " Un fichier portant la date de cr�ation est g�n�r�"
set Auto=Creation-%Date:~-4%-%Date:~-7,-5%-%Date:~-10,-8%.txt
echo Cr�ation de l'arborescence de ce projet %rep% le %Date:~-4%-%Date:~-7,-5%-%Date:~-10,-8%> %Auto%
cd ..