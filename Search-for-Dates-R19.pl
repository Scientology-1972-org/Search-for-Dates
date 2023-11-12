#!/usr/bin/perl
use strict;
use Getopt::Long;
Getopt::Long::Configure(qw{no_auto_abbrev no_ignore_case_always});
use List::Util qw(min max sum);

my $usage = <<'USAGE';

############ Search for dates #############
usage: Search-for-Dates.pl [options]
		--input|-i=list-of-all-files.csv
		--all|-a
		--outprefix|-o=outprefix
		--delim|-d="\t"
		--functdelim|-f=;
		--foldersToIgnore|-f
		--1date|-1
		--xtended|-x
		--link|-l
		--version|-v
		--debug
		--help|-h
#########################################

USAGE

my $inFile;
my $outprefix = "Out";
my $delim ="\t";
my $functdelim=";";
my $all;
my $debug;
my $silent;
my $version;
my $dupdate;
my $link;
my $xtended;
my $badrecord="BadRecord";
my $foldersToIgnore;
#my $cutbycount=0; 	"split=s" => \$cutbycount,

my $result = GetOptions(
	"input|i=s" => \$inFile,
	"OutPrefix|o=s" => \$outprefix,
	"all|a" => sub{$all='TRUE'},
	"delim|d=s" => \$delim,
	"functdelim|f=s" => \$functdelim,
	"debug" => sub{$debug='TRUE'},
	"1date|1" => sub{$dupdate='TRUE'},
	"link|l" => sub{$link='TRUE'},
	"foldersToIgnore|f=s" => \$foldersToIgnore,
	"xtended|x" => sub{$xtended='TRUE'},
	"silent|s" => sub{$silent='TRUE'},
	"version|v" => sub{$version='TRUE'},		
	"help|h|?" => sub{print $usage; exit}	
);

if($version)
{
print "Version 19\n";
}

die $usage unless($inFile);
if($all)
{
$dupdate=!$all;
$link=$all;
print "--all/-a will enable (--link|-l) and (--1date|1) options with default OutPrefix \n"; 
}
#print "--->$all\t$link\t$dupdate<----\n";
#print "$functdelim\n";
if($dupdate)
{
$dupdate=0;
}
else
{
$dupdate=1;
}
#print "-->$dupdate<---\n";
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
$year=1900+$year; 
$mon++;
$mon = "0".$mon if $mon < 10;
if(length($mday)==1)
{
	$mday="0".$mday;
}
print "start: date $year-$mon-$mday time $hour:$min:$sec \n";

my $lineCounter=-1;
my $lineCounter2=-1;
my $fileCounter=0;
my $DatesFound=0;
my $DatesNotFound=0;
my $linesInFile=0;
my $pathIndex=0;
my $filenameIndex=1;
my $header;
my $date = -1;
my $repeatdate = "";
		
#count lines in file 
open(INFILE,$inFile) or die "can-not find $inFile file\n";
while(my $line=<INFILE>)
{
$linesInFile++;
}
close(INFILE);

#################################################################################
my @ignore=();
if(defined $foldersToIgnore)
{
open(INFILE,$foldersToIgnore) or die "can-not find $foldersToIgnore file\n";
	while(my $line=<INFILE>)
	{
		$line=~s/\s$//g; 
		push(@ignore, $line);
	}
close(INFILE);
}
################################################################################
#open(BADRECORD, ">$badrecord-$inFile");

open(INFILE,$inFile) or die "can-not find $inFile file\n";
if(! $silent)
{
	print "Writing in $outprefix-$inFile file\n";
}
open(OUTFILE,">$outprefix-$inFile");
while(my $line=<INFILE>)
{
$lineCounter++;
#$lineCounter2++;
	my @array=split/$delim/,$line;
	my $path ="D $array[$pathIndex] D"; #adding dummy D to select digit only as script fails to determine between \d{8} and \d{6} 
	my $filename ="D $array[$filenameIndex] D"; 
		
	if($lineCounter==0)
	{	
		$header = $line;
		chomp($line); #print $header;
		my @array=split/$delim/,$line;
		for(my $index = 0; $index <=scalar(@array); $index++)
		{
			if(uc($array[$index]) eq "PATH")
			{
				$pathIndex = $index;
			}
			if(uc($array[$index]) eq "FILENAME")
			{
				$filenameIndex = $index;
			}
 	
		}
	print  OUTFILE "date-of-work\t";
		if($link)
		{
		print  OUTFILE "link\t";
		}
	print  OUTFILE "$header";
	
	}
	else
	{	
		my $flag=0;
		foreach my $ignorePath( @ignore)
		{#print "$ignorePath\n";
		
			if($array[$pathIndex]=~m/\Q$ignorePath\E/ && length($ignorePath) >0)
			{
				#print $line."1--->$ignorePath<----\n";
				$flag=1;
			}
		if(length($ignorePath)<10 && length($ignorePath) >0)
		{
			if($array[$filenameIndex]=~m/$ignorePath/ )
			{
				#print $line."2--->$ignorePath<----\n";
				$flag=1;
			}	
		}
		}

		if($flag==1)
		{
			next;
		}
		if(scalar(@array) < $pathIndex || scalar(@array) < $filenameIndex )
		{
		#print $line."\n";
		open(BADRECORD, ">>$badrecord-$inFile");
		print BADRECORD $line."\n";
		close(BADRECORD);
		next
		} 
		#print "3--->$line<---";
		#start date search in filename
		$repeatdate = "";
		$date = -1;
		my $index = 0;
		while($date == -1  && $index != -1)
		{
			if($date == -1)
			{	
				$date = SimpleDate($filename, $dupdate);
				if($date == -1)
				{
			    		$date = ComplexDate($filename, $dupdate);
					if($date == -1)	{ 
						$date = UnknownDate_Revision($filename, $xtended, $dupdate,);	
					}
				}
			}#print "--->$index\n$filename\n$date<----\n";
				#print "1--->index=$index<--->$filename<--->$date<---\n";
			if($date != -1)
			{
				
				#$date=~s/Rule\d+\s//g;
				my ($match, $validDay)=split/\t/,$date;
				$index = index($filename, $match);
				#$match=~s/^\//;
				#$match=~s/\D$//;
				#print $match;
				$filename=~s/\Q$match\E//ig;
				if($dupdate || $debug)
				{
                                	$repeatdate.=$validDay."\t";
				}
				else
				{
                               	 	$repeatdate.=$match."\t";
				}
				#print "2--->index=$index<--->$filename<--->$validDay<-->$match<--->$date<---\n";
				$date= -1;
			}
			else
			{
				last;	
			}
		}#print "RD--->$repeatdate\n$date<---\n";
		if(length($repeatdate) >0)
		{
			$date= $repeatdate;
		}#print "RD2--->$repeatdate\n$date<---\n";
		#start date search in path
		if($date == -1)
		{
			my @path=split(/\\|:|\//,$array[$pathIndex]);
			my $index= scalar(@path);
			#print "$array[0]@path\t$index\n";
			while($date == -1)
			{#print "$path[$index]\n";
				$date = SimpleDate("D $path[$index] D");
				if($date == -1)
				{
			    		$date = ComplexDate("D $path[$index] D");
					if($date == -1)	
					{ 
						$date = UnknownDate_Revision("D $path[$index] D",$xtended);		
					}
				}
			$index--;
				if($index <0)
				{
					last;	
				}
			}
		}
	}
	#print "RD3--->$repeatdate\n$date<---\n";
	#if($lineCounter % $cutbycount ==0) #1048560
			
		#open(OUTFILE, ">$outprefix-$fileCounter-$inFile");
		if($debug)
		{
			print  OUTFILE "MatchedRule\t";
		}

	
	if(! $silent)
	{
		if($lineCounter % 10000 ==0 && $lineCounter >1)
		{      
			my $percentage = int( ($lineCounter/ $linesInFile ) *100);
			print "\r"."Processed $lineCounter lines out of $linesInFile completed  ".$percentage." % ";
			#print int( ($lineCounter/ $linesInFile ) *100)." % ";
			
		}
	}
if($lineCounter > 0)
{
	if($debug && $date == -1 )
	{
	print  OUTFILE "No date Found\t";
	$DatesNotFound++;
	}	
	$DatesFound++;
	my @repeatdates=();	
	@repeatdates=split/\t/,$date;
	$path =$array[$pathIndex];
	$filename =$array[$filenameIndex];
	foreach my $date (@repeatdates)
	{
		if($date == -1)
		{
			$date="nix";
		}
	print OUTFILE "$date\t";
		if($link)
		{#file:////AGs
		my $path1=$path;
		$path1=~s/#/%23/g;
		$path1=~s/\"/%22/g;
		$path1=~s/\'/%27/g;
		$path1=~s/^\///;
		my $filename1=$filename;
		$filename1=~s/#/%23/g;
		$filename1=~s/\"/%22/g;
		$filename1=~s/\'/%27/g;
		
		print OUTFILE "=HYPERLINK(\"file:///$path1/$filename1\"$functdelim\"$filename\")\t";
		}
	print OUTFILE "$line";
		$lineCounter2++;
	}
}
#print "$date\t$line";
#my $path ="D $array[$pathIndex] D";
#my $filename ="D $array[$filenameIndex] D"; 
		
}
if(! $silent)
{
$lineCounter++;
my $percentage = int( ($lineCounter/ $linesInFile ) *100);
print "\r"."Processed $lineCounter lines out of $linesInFile completed  ".$percentage." % ";
print "\n";
}
close(INFILE);
close(OUTFILE);
if($debug)
{
	print "Summary stats\n";
	print "Total Data Processed = ";	
	print $DatesFound ;
	print "\r\nTotal Dates found = ";
	print $DatesFound - $DatesNotFound;
	print "\r\nTotal Dates Not found = ";
	print $DatesNotFound;
	print "\r\n";
	print 'Description about Rules for searching dates
RULE1: Date in DDMMYYYY with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE2: Date in DMMYYYY with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE3: Date in DDMYYYY with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE4: Date in DMMYYYY with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE5: Date in DMYYYY with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE6: Date in DDMMYY with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE7: Date in DMMYY with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE8: Date in DDMYY with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE9: Date in DMMYY with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE10: Date in DMYY with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE11: Date in YYYYMMDD with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE12: Date in YYYYMMD with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE13: Date in YYYYMDD with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE14: Date in YYYYMMD with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE15: Date in YYYYMD with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE16: Date in YYMMDD with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE17: Date in YYMMD with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE18: Date in YYMDD with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE19: Date in YYMMD with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE20: Date in YYMD with following Delim "space" ,"-", "_" or "." . Take care of Revision Marker R at end of date string and C before Year 
RULE21: Date in DD Month YY/YYYY with our without special charater and spaces. Look for charater month May , Mai  
RULE22: Date in YY/YYYY Month DD with our without special charater and spaces. Look for charater month May , Mai  
RULE23: Date in DD {st/nd/rd/th} MonthYY/YYYY with our without special charater and spaces. Look for charater month May , Mai  
RULE24: Date in DD {st/nd/rd/th} {of} Month YY/YYYY with our without special charater and spaces. Look for charater month May , Mai  
RULE25: Date in {mid/end/etc} {of} Month YY/YYYY with our without special charater and spaces. Look for charater month May , Mai  
RULE26: Date in Month DD YY/YYYY with our without special charater and spaces. Look for charater month May , Mai '; 

print "\r\n";
}

my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
$year=1900+$year; 
$mon++;
$mon = "0".$mon if $mon < 10;
if(length($mday)==1)
{
	$mday="0".$mday;
}
print "End: date $year-$mon-$mday time $hour:$min:$sec \n";
##### simple date Subroutine
sub SimpleDate {

my $dateString = $_[0];
my $dupdate = $_[1];
my $sep="|-|_|.";
#print $sep."\n";#
#print $dateString."\n";
# dates with space and "-" and . only single Non word charater between dates
if($dateString =~m/\D\d{4}[\sC$sep]{0,2}\d{1,2}\D{0,2}\d{1,2}\D/i ) # YYYY year at begning of string
	{
		my @matches = $dateString =~m/\D\d{4}[\sC$sep]{0,2}\d{1,2}\D{0,2}\d{1,2}\D/ig;
		#print "@matches\n";
		foreach my $match(@matches)
		{	
			if(!($match=~m/^\s/) && !($match=~m/\s$/))
			{
				#next;
			}
			#$match=~s/\D//g;
			my($year, $delimt1, $month, $delim2, $date) = $match =~ m/(\d{4})(\D{0,2})(\d{2})(\D{0,2})(\d{2})/; #YYYYMMDD
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule11 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	

				return("$validDay");
			}
			my($year, $delimt1, $month, $delim2, $date) = $match =~ m/(\d{4})(\D{1,2})(\d{1})(\D{1,2})(\d{2})/; #YYYYMDD
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule12 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	

				return("$validDay");
			}
			my($year, $delimt1, $month, $delim2, $date) = $match =~ m/(\d{4})(\D{1,2})(\d{2})(\D{1,2})(\d{1})/; #YYYYMMD
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule13 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($year, $delimt1, $month, $delim2, $date) = $match =~ m/(\d{4})(\D{1,2})(\d{1})(\D{1,2})(\d{1})/; #YYYYMD
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule14 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($year, $delimt1, $month, $delim2, $date) = $match =~ m/(\d{4})(\D{1,2})(\d{1})(\D{1,2})(\d{2})/; #YYYYMDD
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule15 $match\t$validDay");
				}	
				if($dupdate)
				{
					return("$match\t$validDay");
				}	


				return("$validDay");
			}
			# my($year, $delimt1, $month, $delim2, $date) = $match =~ m/(\d{4})(\D{0,2})(\d{1})(\D{0,2})(\d{1})/; #YYYYDM
			# my $validDay = validateDayInMonth($year, $month, $date);
			# #print "$validDay = validateDayInMonth($year, $month, $date)\n";
			# if($validDay != -1)
			# {	
				# if($debug)
				# {
					# return("Rule3\t$validDay");
				# }	

				# return("$validDay");
			# }
		}	
	}
	if($dateString =~m/\D\d{2}[\sC$sep]{0,2}\d{1,2}\D{0,2}\d{1,2}\D/i ) # YY year at begning of string
	{
		my @matches = $dateString =~m/\D\d{2}[\sC$sep]{0,2}\d{1,2}\D{0,2}\d{1,2}\D/ig;
		#print "@matches\n";
		foreach my $match(@matches)
		{	
			if(!($match=~m/^\s/) && !($match=~m/\s$/))
			{
				#next;
			}
			#$match=~s/\D//g;
			my($year, $delimt1, $month, $delim2, $date) = $match =~ m/(\d{2})(\D{0,2})(\d{2})(\D{0,2})(\d{2})/; #YYMMDD
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule16 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($year, $delimt1, $month, $delim2, $date) = $match =~ m/\D(\d{2})(\D{1,2})(\d{1})(\D{1,2})(\d{2})\D/; #YYMDD
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1 && length($match) > 6)
			{	
				if($debug)
				{
					return("Rule17 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($year, $delimt1, $month, $delim2, $date) = $match =~ m/(\d{2})(\D{1,2})(\d{2})(\D{1,2})(\d{1})/; #YYMMD
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule18 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	


				return("$validDay");
			}
			my($year, $delimt1, $month, $delim2, $date) = $match =~ m/\D(\d{2})(\D{1,2})(\d{1})(\D{1,2})(\d{1})\D/; #YYMD
			my $validDay = validateDayInMonth($year, $month, $date);
			#print " $dateString\n $validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1 && length($match) > 6)
			{	
				if($debug )
				{
					return("Rule19  $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($year, $delimt1, $month, $delim2, $date) = $match =~ m/(\d{2})(\D{1,2})(\d{1})(\D{1,2})(\d{2})/; #YYMDD
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule20 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			# my($year, $delimt1, $month, $delim2, $date) = $match =~ m/(\d{4})(\D{0,2})(\d{1})(\D{0,2})(\d{1})/; #YYYYDM
			# my $validDay = validateDayInMonth($year, $month, $date);
			# #print "$validDay = validateDayInMonth($year, $month, $date)\n";
			# if($validDay != -1)
			# {	
				# if($debug)
				# {
					# return("Rule3\t$validDay");
				# }	

				# return("$validDay");
			# }
		}	
	}
	if($dateString =~m/\d{1,2}\D{0,2}\d{1,2}[\sC$sep]{0,2}\d{4}\D/i ) #YYYY year at end of string
	{
		my @matches = $dateString =~m/\D\d{1,2}\D{0,2}\d{1,2}[\sC$sep]{0,2}\d{4}\D/ig;
		foreach my $match(@matches)
		{	#print $match;
		 if(!($match=~m/^\s/) && !($match=~m/\s$/))
		 {
			#next;
		 }
			#$match=~s/\D//g;
			#print "\n8D $match\n";
			my($date, $delimt1, $month, $delim2, $year) = $match =~ m/(\d{2})(\D{0,2})(\d{2})(\D{0,2})(\d{4})/; #DDMMYYYY
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule1 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($date, $d1, $month, $d2, $year) = $match =~ m/(\d{1})(\D{1,2})(\d{1})(\D{1,2})(\d{4})/; #DMYYYY
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug )
				{
					return("Rule2 $match\t$validDay");
				}	
				if($dupdate)
				{
					return("$match\t$validDay");
				}	


				return("$validDay");
			}
			# my($month, $d1, $date, $d2, $year) = $match =~ m/(\d{1})(\D{0,2})(\d{1})(\D{0,2})(\d{4})/; #MDYYYY
			# my $validDay = validateDayInMonth($year, $month, $date);
			# #print "$validDay = validateDayInMonth($year, $month, $date)\n";
			# if($validDay != -1)
			# {	
				# if($debug)
				# {
					# return("Rule3\t$validDay");
				# }	

				# return("$validDay");
			# }
			my($date, $d1, $month, $d2, $year) = $match =~ m/(\d{2})(\D{1,2})(\d{1})(\D{1,2})(\d{4})/; #DDMYYYY
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule3 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($date, $d1, $month, $d2, $year) = $match =~ m/(\d{1})(\D{1,2})(\d{2})(\D{1,2})(\d{4})/; #DMMYYYY
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug )
				{
					return("Rule4 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($date, $d1, $month, $d2, $year) = $match =~ m/(\d{1})(\D{1,2})(\d{1})(\D{1,2})(\d{4})/; #DMYYYY
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug )
				{
					return("Rule5 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			
		}	
	}#YYYY year at end of string END

	if($dateString =~m/\D\d{1,2}\D{0,2}\d{1,2}[\sC$sep]{0,2}\d{2}\D/i ) #YY year at end of string
	{#print "====>".$dateString."\n";
		my @matches = $dateString =~m/\D\d{1,2}\D{0,2}\d{1,2}[\sC$sep]{0,2}\d{2}\D/ig;
		#print "6D=@matches\n";
		foreach my $match(@matches)
		{	
		#print "1--->$match<---\n";
		#print "2--->$match<---\n";
			#$match=~s/\D//g; 
			my($date, $d1, $month, $d2, $year) = $match =~ m/(\d{2})(\D{0,2})(\d{2})(\D{0,2})(\d{2})/; #DDMMYY
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "Here --->$dateString\n$validDay = validateDayInMonth($date, $d1, $month, $d2, $year)\n";
			if($validDay != -1)
			{	
				if($debug )
				{
					return("Rule6 $match\t$validDay");
				}	
				if($dupdate)
				{
					return("$match\t$validDay");
				}	


				return("$validDay");
			}
			my($date, $d1,  $month, $d2, $year) = $match =~ m/\D(\d{1})(\D{1,2})(\d{1})(\D{1,2})(\d{2})\D/; #DMYY
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1 && length($match) > 6 )
			{	
				if($debug)
				{
					return("Rule7 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($date, $d1, $month, $d2, $year) = $match =~ m/(\d{2})(\D{1,2})(\d{1})(\D{1,2})(\d{2})/; #DDMYY
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "RULE8 $validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug )
				{
					return("Rule8 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($date, $d1, $month, $d1, $year) = $match =~ m/(\d{1})(\D{1,2})(\d{2})(\D{1,2})(\d{2})/; #DMMYY
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1)
			{	
				if($debug )
				{
					return("Rule9 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			my($date, $d1, $month, $d2, $year) = $match =~ m/\D(\d{1})(\D{1,2})(\d{1})(\D{1,2})(\d{2})\D/; #DMYY
			my $validDay = validateDayInMonth($year, $month, $date);
			#print "$validDay = validateDayInMonth($year, $month, $date)\n";
			if($validDay != -1 && length($match) > 6)
			{	
				if($debug )
				{
					return("Rule10 $match\t$validDay");
				}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
	

				return("$validDay");
			}
			
		}	
	}#YY year at end of string END
	
	
return(-1);	
}

##### Complex date Sunroutine 
sub ComplexDate{

my $dateString = $_[0];
my $dupdate = $_[1];
#print "F$dateString\n";
#removing any white spaces and spl charater 
#$dateString=~s/\W//g;
#$dateString=~s/\s//g;
#$dateString=~s/\.//g;
#print "F$dateString\n";
#For creating months lists use following format "listname" usually human readable name followed by months in order
#Example "list5SomeOtherLanguageAbv" => "Jan Febr Mär Aprl Mai Jun Jli Aug Sept Okt Novem Dezem"

my %months = ("listEnglish" => "January February March April May June July August September October November December",
	"listGerman" =>  "Januar Februar März April Mai Juni Juli August September Oktober November Dezember", 
        "list3GermanAbv" => "Jan Feb Mrz Apr Mai Jun Jul Aug Sep Okt Nov Dez", 
        "list4EnglishAbv" => "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", 
        "list5SomeOtherLanguageAbv" => "Jan Febr Mär Aprl Mai Jun Jli Aug Sept Okt Novem Dezem"
	 ) ;

	foreach my $key(keys %months)
	{
		my @months =split(/\s+/,$months{$key});#print "@months\n";
		my $monthdigit=0;
		foreach my $month (@months)
		{
			$monthdigit++;
		       #ddMONTHyyyy 			
			if( $dateString =~m/\D\d{1,2}\D{0,2}$month\D{0,2}\d{2,4}\D/i )
			{
				my @matches = $dateString =~m/\d{1,2}\D{0,2}$month\D{0,2}\d{2,4}/ig; 
				foreach my $match (@matches)
				{	#print "$match\n";
					my($date, $month, $thirdfourthAdd, $year) = $match =~ m/^(\d{1,2})\D{0,2}($month)(\D{0,2})(\d{2,4})$/i;
						my $validDay = validateDayInMonth($year, $monthdigit, $date);
						if($validDay != -1)
						{
							if($debug)
							{
								return("Rule21 $match\t$validDay");
							}	
							if($dupdate)
							{
								return("$match\t$validDay");
							}	

						
							return("$validDay");
						}
						
						#return("$year-$month-$date-Y6");
					
				}#end foreach
			}#end if
		       #yyyyMONTHdd 			
			if( $dateString =~m/\D\d{2,4}\D{0,2}$month\D{0,2}\d{1,2}\D/i )
			{
				my @matches = $dateString =~m/\d{2,4}\D{0,2}$month\D{0,2}\d{1,2}/ig; 
				foreach my $match (@matches)
				{	
					my($year, $month, $date) = $match =~ m/^(\d{2,4})\D{0,2}($month)(\d{1,2})$/i;
					
						my $validDay = validateDayInMonth($year, $monthdigit, $date);
						if($validDay != -1)
						{
							if($debug )
							{
								return("Rule22 $match\t$validDay");
							}	
							if($dupdate)
							{
								return("$match\t$validDay");
							}	

						
							return("$validDay");
						}
		
						#return("$year-$month-$date-Y7");
					
				}# end foreach
			}# end if
			#28th May 1972
			if( $dateString =~m/\D\d{1,2}\D{2,4}$month\D{0,2}\d{2,4}\D/i )
			{
				my @matches = $dateString =~m/\d{1,2}\D{2,4}$month\D{0,2}\d{2,4}/ig; 
				foreach my $match (@matches)
				{	
					my($date, $th_of, $month, $year) = $match =~ m/^(\d{1,2})(\D{2,4})($month)\D{0,2}(\d{2,4})$/i;
					
						my $validDay = validateDayInMonth($year, $monthdigit, $date);
						if($validDay != -1)
						{	
							if($debug )
							{
								return("Rule23 $match\t$validDay");
							}
							if($dupdate)
							{
								return("$match\t$validDay");
							}	
	

							return("$validDay");
						}
		
						#return("$year-$month-$date-Y7");
					
				}# end foreach
			}# end if
			#28th of May 1972
			if( $dateString =~m/\D\d{1,2}\D{4,8}$month\D{0,2}\d{2,4}\D/i )
			{
				my @matches = $dateString =~m/\d{1,2}\D{4,8}$month\D{0,2}\d{2,4}/ig; 
				foreach my $match (@matches)
				{	
					my($date, $th_of, $month, $year) = $match =~ m/^(\d{1,2})(\D{4,9})($month)\D{0,2}(\d{2,4})$/i;

						my $validDay = validateDayInMonth($year, $monthdigit, $date);
					#print "$dateString\n$validDay = validateDayInMonth $year, $monthdigit, $date)\n";
						if($validDay != -1)
						{
							if($debug )
							{
								return("Rule24 $match\t$validDay");
							}
							if($dupdate)
							{
								return("$match\t$validDay");
							}	
	
							return("$validDay");
						}
		
						#return("$year-$month-$date-Y7");
					
				}# end foreach
			}# end if
			# mid may 1966 , end of sept 78 etc only month and year in yy/YYYY format
			if( $dateString =~m/\D$month\d{2,4}\D/i )
			{
				my @matches = $dateString =~m/$month\D{0,2}\d{2,4}/ig; 
				foreach my $match (@matches)
				{	
					my $date = 1;
					my($month, $year) = $match =~ m/^($month)\D{0,2}(\d{2,4})$/i;
					
						my $validDay = validateDayInMonth($year, $monthdigit, $date);
						if($validDay != -1)
						{
							if($debug )
							{
								return("Rule25  $match\t$validDay");
							}
							if($dupdate)
							{
							return("$match\t$validDay");
							}	
	
							return("$validDay");
						}
		
						#return("$year-$month-$date-Y7");
					
				}# end foreach
			}# end if
				#Oct. 21 '05
			if( $dateString =~m/\D$month\D{0,2}\d{1,2}\D{0,2}\d{2,4}\D/i )
			{

				my @matches = $dateString =~m/\D$month\D{0,2}\d{1,2}\D{0,2}\d{2,4}\D/ig; 
				foreach my $match (@matches)
				{	#print $match."<---\n";
					#my $date = 1;
					my($month,$d1, $date, $d2 ,$year) = $match =~ m/($month)(\D{0,2})(\d{1,2})(\D{0,2})(\d{2,4})\D/i;

						my $validDay = validateDayInMonth($year, $monthdigit, $date);

						if($validDay != -1)
						{
							if($debug )
							{
								return("Rule26  $match\t$validDay");
							}
							if($dupdate)
							{
								return("$match\t$validDay");
							}	
	
							return("$validDay");
						}
		
						#return("$year-$month-$date-Y7");
					
				}# end foreach
			}# end if
		}#end foreach of months
	}#end foreach of lists 

return(-1);
}

sub UnknownDate_Revision {

my $dateString = $_[0];
my $xtended = $_[1];
my $dupdate = $_[2];
# since we agree on scrapping all dates which doesnt have date and year this function doesnt required much longer , if we need this function in future just comment out return bellow
if(!$xtended)
{
	return(-1);
}
#removing any white spaces and spl charater 
$dateString=~s/\W//g;
$dateString=~s/\s//g;
$dateString=~s/\.//g;
#yyyymmdd and ddmmyyyy
#print "F $dateString\n";

#yymmxx 7205xx
if( $dateString =~m/\D\d{4}xx\D/i )
{
	my @matches = $dateString =~m/\d{4}xx/ig; 
	foreach my $match (@matches)
	{
		my $date = 1;
		my($year, $month, $xx ) = $match =~ m/^(\d{2})(\d{2})(xx)$/i;
			my $validDay = validateDayInMonth($year, $month, $date);
			if($validDay != -1)
			{
							if($debug )
							{
								return("Rule26  $match\t$validDay");
							}
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
			
				return("$validDay");
			}

		
	}
}
#yymm00 720500
if( $dateString =~m/\D\d{4}00\D/ )
{
	my @matches = $dateString =~m/\d{4}00/ig; 
	foreach my $match (@matches)
	{
		my $date = 1;
		my($year, $month, $xx ) = $match =~ m/^(\d{2})(\d{2})(00)$/;
			my $validDay = validateDayInMonth($year, $month, $date);
			if($validDay != -1)
			{
				if($debug)
				{
					return("Rule23\t$validDay");
				}	
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
				return("$validDay");
			}

		
	}
}



#xx0571
if( $dateString =~m/\Dxx\d{4}\D/i )
{
	my @matches = $dateString =~m/xx\d{4}/ig; 
	foreach my $match (@matches)
	{
		my $date = 1;
		my($xx , $month, $year) = $match =~ m/^(xx)(\d{2})(\d{2})$/i;
			my $validDay = validateDayInMonth($year, $month, $date);
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule24b\t$validDay");
				}	
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
				return("$validDay");
			}

		
	}
}

#yymm00 000572
if( $dateString =~m/\D00\d{4}\D/ )
{
	my @matches = $dateString =~m/00\d{4}/ig; 
	foreach my $match (@matches)
	{
		my $date = 1;
		my($xx , $month, $year ) = $match =~ m/^(00)(\d{2})(\d{2})$/;
			my $validDay = validateDayInMonth($year, $month, $date);
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule25\t$validDay");
				}	
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
				return("$validDay");
			}

		
	}
}

##Revision 1966R 72r 88RA 88RB 88RC
if( $dateString =~m/\D\d{2,4}R/i )
{
	my @matches = $dateString =~m/\d{2,4}R/ig; 
	foreach my $match (@matches)
	{
		my $date = 1;
		my $month = 1;
		my($year, $R ) = $match =~ m/^(\d{2,4})(R)$/i;
			my $validDay = validateDayInMonth($year, $month, $date);
			if($validDay != -1)
			{
				if($dupdate)
				{
					return("Rule26\t$validDay");
				}	
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
				return("$validDay");
			}

		
	}
}
#yym


#7205??
$dateString= $_[0];
$dateString=~s/\s//g;
$dateString=~s/\.//g;

if( $dateString =~m/\D\d{4}\?\?/ )
{
	my @matches = $dateString =~m/\d{4}\?\?/ig; 
	foreach my $match (@matches)
	{
		my $date = 1;
		my($year, $month, $xx ) = $match =~ m/^(\d{2})(\d{2})(\?\?)$/;
			my $validDay = validateDayInMonth($year, $month, $date);
			if($validDay != -1)
			{	
				if($debug)
				{
					return("Rule27\t$validDay");
				}	
				if($dupdate)
				{
					return("$match\t$validDay");
				}	
				return("$validDay");
			}

		
	}
}
return(-1);
}




##################################################################
#validate day in month 
sub validateDayInMonth{
my($year, $month, $date)=@_;
#print "($year, $month, $date)\n";
my @DayInMonth=(0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
my($sec,$min,$hour,$mday,$mon,$Curyear,$wday,$yday,$isdst) = localtime();
#print "($sec,$min,$hour,$mday,$mon,$Curyear,$wday,$yday,$isdst) = localtime()\n";

if($year ==0 || $month ==0 || $date ==0)
{
	return(-1);
}

if(length($year) == 2)# 2 digit years
{
#print "$year\n"; 
	if($year <= $Curyear -100)	
	{
		$year = 2000 + $year
	}
	else
	{
		$year= 1900 + $year;
	}
#print "$year\n"; 	
}


if( $year < 1947 || $year > 1900 +$Curyear)
{
 return(-1);
}
#special case for leap year , 29 fed 

if($year%4 == 0)
{
	if($month ==2 && $date <= 29)
	{
		if(length($month) ==1)
		{
			$month="0".$month;
		}
		if(length($date) ==1)
		{
			$date="0".$date;
		}
		return("$year-$month-$date");
	}
}

if($date <=$DayInMonth[$month])
{
	if(length($month) ==1)
	{
		$month="0".$month;
	}
	if(length($date) ==1)
	{
		$date="0".$date;
	}
	return("$year-$month-$date");
}

return(-1);
}


