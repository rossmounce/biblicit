#!/usr/bin/perl -CSD
use strict;
use FindBin;

use lib "$FindBin::Bin/FileConversionService/lib";
use lib "$FindBin::Bin/ParsCit/lib";
use lib "$FindBin::Bin/HeaderParseService/lib";

use ParsCit::Controller;
use HeaderParse::API::Parser;
use HeaderParse::Config::API_Config;

my $logDir = "$FindBin::Bin/log";

system("mkdir","-p","$logDir");

open (LOG, ">>$logDir/prep.log");
open (ERR, ">>$logDir/prep.err");

my $argc = scalar(@ARGV);

if ($argc != 2) {
  print "Usage: ./extract.pl path_to_input path_to_output\n";
  exit 1;
}

my $inputPath = $ARGV[0];
my $outputPath = $ARGV[1];

import($inputPath, $outputPath);

close LOG;
close ERR;

exit;

sub import {
    my ($filePath, $id) = @_;

    system("mkdir","-p","$id");
    
    my ($status, $msg) = prep($filePath, $id);
    if ($status == 0) {
	    print ERR "$id: $msg\n";
    }
    if ($status == 1) {
	    print LOG "$id\n";
    }
}


sub prep {
    my ($textFile, $id) = @_;

    my ($ecstatus, $msg) = extractCitations($textFile, $id);
    if ($ecstatus <= 0) {
	    return ($ecstatus, $msg);
    }
    
    my ($ehstatus, $msg) = extractHeader($textFile, $id);
    if ($ehstatus <= 0) {
	    return ($ehstatus, $msg);
    }    

    return (1, "");
}


sub extractCitations {
    my ($textFile, $id) = @_;

    my $rXML = ParsCit::Controller::extractCitations($textFile);

    unless(open(CITE, ">:utf8", "$outputPath/out.parscit")) {
	return (0, "Unable to open parscit file: $!");
    }

    print CITE $$rXML;
    close CITE;
    return (1);
}


sub extractHeader {
    my ($textFile, $id) = @_;

    my $jobID;
    while($jobID = rand(time)) {
	unless(-f $offlineD."$jobID") {
	    last;
	}
    }

    my ($status, $msg, $rXML) =
	HeaderParse::API::Parser::_parseHeader($textFile, $jobID);

    if ($status <= 0) {
	return ($status, $msg);
    }

    unless(open(HEAD, ">:utf8", "$outputPath/out.header")) {
	return (0, "Unable to open header file: $!");
    }

    print HEAD $$rXML;
    close HEAD;
    return (1);

}