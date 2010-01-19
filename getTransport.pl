#!/usr/bin/perl -w
# a perl script interface to ratp.fr
# for getting transport time/lines in paris.
# zakaria.elqotbi zelqotbi@gmail.com
# TODO
#      : Porfiles
#      : errors management. 
#      : support of stations search 
#      : adresse/stations as arguments
#

BEGIN {
push @INC,"/home/zakaria/bin";
    }

use strict;
use MyParser;

# RATP Constants :
my $initURL = "http://www33.ratp.info/Pivi/piviweb.php?exec=piviweb&cmd=NouvelleRecherche&Profil=RATP";
my $requestURL = "http://www33.ratp.info/Pivi/piviweb.php?exec=piviweb&cmd=Lexico&Profil=RATP";
my $resultURL = "http://www33.ratp.info/Pivi/piviweb.php?exec=piviweb&cmd=FeuilleDeRoute&Profil=RATP";

my $DEPART = "14+Rue+Gaillon+PARIS-02EME";

# test of RER
#my $ARRIVEE = "Impasse+de+la+Chapelle+MONTLHERY";

# test of metro/bus
my $ARRIVEE = "40+Rue+d%27+Alesia+PARIS-14EME";
# test of Tramway
#my $DEPART="17+Boulevard+Jourdan+PARIS-14EME";
#my $ARRIVEE="1+Boulevard+Brune+PARIS-14EME";

my $Annee = "2009"; 
my $Mois = "10";
my $Jour = "6";

my $Heure = "18";
my $Minute = "00";

my $CRITERE = "PLUS_RAPIDE"; # available criteres : 
my $MODE = "TOUS_MODE";      # available modes:
my $TypeDate = "DATE_DEPART"; # available types:


my $numArgs = $#ARGV + 1;
# if no arguement is given, we try to get localtime
if ( $numArgs < 1 )
{
    my @timeData = localtime(time);
    $Annee = $timeData[5] + 1900; 
    $Mois = $timeData[4] + 1;
    $Jour = $timeData[3];

    $Heure = $timeData[2];
    $Minute = $timeData[1];
}


# else we take the time gived as an arguments
else {
    my @token = split(/h/,$ARGV[0]);
    
    $Heure = $token[0];
    $Minute = $token[1];
}

#my $REQUEST = "Depart%5BType%5D=RUE&Depart%5BSaisie%5D=14+Rue+Gaillon+PARIS-02EME&listePersoDepart=0&Arrivee%5BType%5D=RUE&Arrivee%5BSaisie%5D=40+Rue+d%27+Alesia+PARIS-14EME&listePersoArrivee=0&ModeTransport%5BModeTransportSelectionne%5D=TOUS_MODE&ModeTransport%5BCritereSelectionne%5D=PLUS_RAPIDE&Date%5BJourSelectionne%5D=8&Date%5BMoisSelectionne%5D=9&Date%5BAnneeSelectionne%5D=2009&Date%5BTypeDateSelectionne%5D=DATE_DEPART&Date%5BHeureSelectionne%5D=13&Date%5BMinuteSelectionne%5D=45" ;

my $REQUEST = "Depart%5BType%5D=RUE&Depart%5BSaisie%5D=" . $DEPART . "&listePersoDepart=0&Arrivee%5BType%5D=RUE&Arrivee%5BSaisie%5D=" . $ARRIVEE . 
              "&listePersoArrivee=0&ModeTransport%5BModeTransportSelectionne%5D=" . $MODE . "&ModeTransport%5BCritereSelectionne%5D=" . $CRITERE .
              "&Date%5BJourSelectionne%5D=" . $Jour . "&Date%5BMoisSelectionne%5D=" . $Mois . "&Date%5BAnneeSelectionne%5D=" . $Annee . 
              "&Date%5BTypeDateSelectionne%5D=" . $TypeDate . "&Date%5BHeureSelectionne%5D=" . $Heure . "&Date%5BMinuteSelectionne%5D=" . $Minute
              ;

# initialising the connection to ratp.fr and getting the php session id.
my @curlinit = ('/usr/bin/curl','-#', "$initURL", '-o', "/tmp/initcurl.html" , '-m' , "5" );
system @curlinit;

my $PHPSESSID = MyParser::phpsession("/tmp/initcurl.html");

my $requestPage = $requestURL . "&PHPSESSID=" . $PHPSESSID ;

#print "$requestPage\n" ;

# submitting the request :

#curl -d "Depart%5BType%5D=RUE&Depart%5BSaisie%5D=14+Rue+Gaillon+PARIS-02EME&listePersoDepart=0&Arrivee%5BType%5D=RUE&Arrivee%5BSaisie%5D=40+Rue+d%27+Alesia+PARIS-14EME&listePersoArrivee=0&ModeTransport%5BModeTransportSelectionne%5D=TOUS_MODE&ModeTransport%5BCritereSelectionne%5D=PLUS_RAPIDE&Date%5BJourSelectionne%5D=8&Date%5BMoisSelectionne%5D=9&Date%5BAnneeSelectionne%5D=2009&Date%5BTypeDateSelectionne%5D=DATE_DEPART&Date%5BHeureSelectionne%5D=13&Date%5BMinuteSelectionne%5D=45"  'http://www33.ratp.info/Pivi/piviweb.php?exec=piviweb&cmd=Lexico&Profil=RATP&PHPSESSID=2beec3e8a699edaf95f5f8dec023a267'
#curl -d $REQUEST $requestPage

my @curlreq = ('/usr/bin/curl', '-#', '-d', "$REQUEST", "$requestPage", '-o', "/tmp/requestcurl.html" , '-m' , "5");
system @curlreq;

my $resultPage = MyParser::get_resultlink("/tmp/requestcurl.html");

# getting the result :
#
#curl 'http://www33.ratp.info/Pivi/piviweb.php?exec=piviweb&cmd=FeuilleDeRoute&Profil=RATP&PHPSESSID=2beec3e8a699edaf95f5f8dec023a267' > ratp.result.html

my @curlres = ('/usr/bin/curl', '-#', "$resultPage", '-o', "/tmp/resultcurl.html" , '-m' , "5");
system @curlres;

# parsing the result : 

my %data = MyParser::result("/tmp/resultcurl.html");
print "RATP info JOB->Home : ";
while ( my ($key, $value) = each(%data) )
{
        print "$key => $value ";
}

print "\n";

