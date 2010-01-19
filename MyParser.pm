#!/usr/bin/perl -w
# get Result link 

package MyParser; 

use strict;
use Switch;
use HTML::Parser 3.00 ();
use Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(get_resultlink phpsession);
%EXPORT_TAGS = ( DEFAULT => [qw(&get_resultlink)],
                 Both    => [qw(&get_resultlink &phpsession)]);


my %inside;
my $URL;
my $resultURL;
my $pattern = "cliquez-ici";
my $datavar;
my $var;
my $ligne;

sub handle_resultlink
{
   my($tag,$attr, $num) = @_;
   $inside{$tag} += $num;
   $URL = $attr->{href};
}

sub text_resultlink
{
    return if $inside{script} || $inside{style};
    if (lc($_[0]) eq $pattern )
    {
      #print $_[0] . "\n";
#      print "$URL\n";
      $resultURL = $URL;
    }
}

sub handle_phpsession
{
    my($self, $tag, $attr) = @_;
    return unless $tag eq "form";
    return unless exists $attr->{action};
    $URL = "$attr->{action}" ;
}

sub get_resultlink
{
  HTML::Parser->new(api_version => 3,
		  handlers    => [start => [\&handle_resultlink, "tagname, attr,'+1'"],
				  end   => [\&handle_resultlink, "tagname, attr,'-1'"],
				  text  => [\&text_resultlink, "dtext"],
				 ],
		  marked_sections => 1,
	)->parse_file(shift) || die "Can't open file: $!\n";;
  return $resultURL;
}

sub phpsession
{

  my $p = HTML::Parser->new(api_version => 3,
        start_h => [\&handle_phpsession, "self,tagname,attr"],
        report_tags => [qw(form)],
        );

  $p->parse_file(shift || die) || die $!;

  my $iIndex = index($URL, "PHPSESSID"); 
  my $sNewString = substr($URL, $iIndex );
  my @words = split /=/, $sNewString;
  return "$words[1]";
}

# a start event for getting data
sub handler_data
{
    my($self, $tag, $attr) = @_;
    return if $tag ne "p";
    return unless exists $attr->{class};
    switch ( $datavar ){
        case "depart" { return if $attr->{class} ne "pdepart" }
        case "arrivee" { return if $attr->{class} ne "parrive" }
        case "date"   { return if $attr->{class} ne "pdate" }
    }

    $self->handler(text => sub { $var=shift }, "dtext");
    $self->handler(end  => sub { shift->eof if shift eq "p"; },
                           "tagname,self");
}

# handler for the metro line parser 
sub handle_ligne
{
    my($tag,$attr) = @_;
    return unless $tag eq "img";
    return unless exists $attr->{src};
    #  search for pattern : ex : /picts/moteur/ligne/b68.gif
    #  p_rer_c
    #  tram_t3
    #  b68
    #  m14
    if ( $attr->{src} =~ m/\/picts\/moteur\/ligne\/(((b|m)\d\d)|p_(rer_\D)|tram_(t\d))/ )
    {
        if ($2) {
            if ($ligne){
                $ligne = "$2,$ligne";
            }
            else{
                $ligne = $2 ;
            }

        }
        elsif ($4){
            if ($ligne){
                $ligne = "$4,$ligne";
            }
            else{
                $ligne =$4;
            }
        }
        elsif ($5){
            if ($ligne){
                $ligne = "$5,$ligne";
            }
            else{
                $ligne=$5
            }
            #print "$ligne: $attr->{src} \n";
            print "ligne: $ligne\n";
        }
    }
}

# internal function for getting metro/bus number line .
sub get_ligne
{
  HTML::Parser->new(api_version => 3,
                    start_h => [\&handle_ligne, "tagname, attr, "],
                    report_tags => [qw(img)],
                    marked_sections => 1,
  )->parse_file(shift) || die "Can't open file: $!\n";;
  return $ligne;
}

sub get_time
{
     my $filename = shift;
     my $key = shift;

     $datavar = $key;
  
     my $p = HTML::Parser->new(api_version => 3);
     $p->handler( start => \&handler_data, "self,tagname,attr");
     $p->parse_file($filename || die) || die $!;

     #format   xxhxx  xx/xx/xxxx 
     if ($var=~ m/(\d*h\d*|\d*\/\d*\/\d*)/)
     {
         return $1;
#         $data{$key}=$1;
     }
}


# function for return data result
sub result
{
  my $filename = shift;
  my %data=();
  
  $data{ 'date' } = '';
  $data{ 'depart' } = '';
  $data{ 'arrivee' } = '';
  $data{ 'ligne' } = '';
  
  for my $key qw( date depart arrivee ){
      $data{$key} = get_time($filename, $key);
  }
    # getting transport line separtely
  $data{ 'ligne' } = get_ligne($filename);
  
  return %data;
}

1;
