#!/usr/bin/perl
# BCLtoFastq_conv_HISEQ_V7.pl by Matthew Brooks
# Written and tested Dec 3rd, 2015
# Last modified Aug 7th, 2019 by MB
# This uses the bcl2fastq v2.20.0.422 with executable in PATH
# Execute this perl script from the base Run directory

use strict; use warnings;

my $reExp = 0; #Set to '1' for re-exporting the data without running the demultiplexing (default = '0')


#########################################
#Change destination folder every 6 months
my $destFolder = "2019Jun-2019Dec/";
#my $destFolder = "Fastqs/";
#
#Change for different FASTQ paths
my $FastqPath = "/home/sbsuser/NAS2/Master_FASTQs/"."$destFolder";
#my $FastqPath = "/data/pipeline_in/Runs/"."$destFolder";
#my $FastqPath = "/Volumes/PEGASUS/Projects/BioInf_Scripts/ScriptTesting/BCL2Fq_HISEQ_Test/Bcl2FQ_v2.20/"."$destFolder"; #Testing
#########################################



########################################################
##### Check for SampleSheets and extract names, descriptions, and check for illegal characters
########################################################

#Define sample sheets for index type
#LT: single 6-base, LT8: single 8-base, HT: dual 8-base)

my (%LTSampleInfo, %LT8SampleInfo, %HTSampleInfo);
my $LTsamp = "SampleSheet_LT.csv";
my $LT8samp = "SampleSheet_LT8.csv";
my $HTsamp = "SampleSheet_HT.csv";

#Check for presence of any sample sheet
if (! -e $LTsamp && ! -e $LT8samp && ! -e $HTsamp)
{
    die "\n\n********ERROR*********\n
    \nSampleSheets DO NOT EXIST!\n
    \nUsage: perl BCLtoFastq_conv_HISEQ_V5.pl\n
    \nSampleSheet_LT.csv, SampleSheet_LT8.csv, or SampleSheet_HT.csv must be present in the current folder.\n\n";
}


############################
#Single Index 6-base sample name acquisition

if (-e $LTsamp)
{

    #Check for illegal characters in SampleSheet_LT.csv
    my $countSpace = 0;
    my $countIllChar = 0;
    open(my $LTsheet, "<", "SampleSheet_LT.csv") or die "\n\n********ERROR*********\n
    \nCould not open SampleSheet_LT.csv. Please check SampleSheet_LT.csv.\n\n";

    while (<$LTsheet>)
    {
        next if 1 .. /^\[Data\]/; #Skip until [Data] section
        next if /^L/; #Skip header

        #Count spaces and illegal characters
        $countSpace++ if /\h/;
        $countIllChar++ if /[?()=+<>:;"'*^|&.#_]/;
    }
     #Report and die if SampleSheet contains spaces or illegal characters
    if ($countSpace > 0 || $countIllChar > 0)
    {
        die "\n\n********ERROR*********\n
        \nNumber of lines with spaces or tabs in SampleSheet_LT.csv: $countSpace\n
        \nNumber of lines with illegal characters in SampleSheet_LT.csv: $countIllChar\n\n";
    }
    close $LTsheet;


    # Get LT sample names and descriptions from SampleSheet_LT.csv
    my (@LTIDs, @LTdescs);
    open($LTsheet, "<", "SampleSheet_LT.csv");
    print "\nGetting LT Project IDs and Descriptions\n\n";

    while (<$LTsheet>)
    {
        next if 1 .. /^\[Data\]/; #Skip until [Data] section
        next if /^L/; #Skip header

        my @LTcells = split(",", $_);

        push(@LTIDs, $LTcells[1]);
        push(@LTdescs, $LTcells[2]);
    }
    close $LTsheet;

    @LTSampleInfo{@LTIDs} = @LTdescs;

    print "Got LT IDs: \n@LTIDs\n";
    print "Got LT Descriptions: \n@LTdescs\n\n";

}
############################


############################
#Single Index 8-base sample name acquisition

if (-e $LT8samp)
{

    #Check for illegal characters in SampleSheet_LT.csv
    my $countSpace = 0;
    my $countIllChar = 0;
    open(my $LT8sheet, "<", "SampleSheet_LT8.csv") or die "\n\n********ERROR*********\n
    \nCould not open SampleSheet_LT8.csv. Please check SampleSheet_LT8.csv.\n\n";

    while (<$LT8sheet>)
    {
        next if 1 .. /^\[Data\]/; #Skip until [Data] section
        next if /^L/; #Skip header

        #Count spaces and illegal characters
        $countSpace++ if /\h/;
        $countIllChar++ if /[?()=+<>:;"'*^|&.#_]/;
    }
     #Report and die if SampleSheet contains spaces or illegal characters
    if ($countSpace > 0 || $countIllChar > 0)
    {
        die "\n\n********ERROR*********\n
        \nNumber of lines with spaces or tabs in SampleSheet_LT8.csv: $countSpace\n
        \nNumber of lines with illegal characters in SampleSheet_LT8.csv: $countIllChar\n\n";
    }
    close $LT8sheet;


    # Get LT sample names and descriptions from SampleSheet_LT.csv
    my (@LT8IDs, @LT8descs);
    open($LT8sheet, "<", "SampleSheet_LT8.csv");
    print "\nGetting LT8 Project IDs and Descriptions\n\n";

    while (<$LT8sheet>)
    {
        next if 1 .. /^\[Data\]/; #Skip until [Data] section
        next if /^L/; #Skip header

        my @LT8cells = split(",", $_);

        push(@LT8IDs, $LT8cells[1]);
        push(@LT8descs, $LT8cells[2]);
    }
    close $LT8sheet;

    @LT8SampleInfo{@LT8IDs} = @LT8descs;

    print "Got LT8 IDs: \n@LT8IDs\n";
    print "Got LT8 Descriptions: \n@LT8descs\n\n";

}
############################


############################
#Dual Index sample name acquisition

if (-e $HTsamp)
{

    #Check for illegal characters in SampleSheet_LT.csv
    my $countSpace = 0;
    my $countIllChar = 0;
    open(my $HTsheet, "<", "SampleSheet_HT.csv") or die "\n\n********ERROR*********\n
    \nCould not open SampleSheet_HT.csv. Please check SampleSheet_HT.csv.\n\n";

    while (<$HTsheet>)
    {
        next if 1 .. /^\[Data\]/; #Skip until [Data] section
        next if /^L/; #Skip header

        #Count spaces and illegal characters
        $countSpace++ if /\h/;
        $countIllChar++ if /[?()=+<>:;"'*^|&.#_]/;
    }
     #Report and die if SampleSheet contains spaces or illegal characters
    if ($countSpace > 0 || $countIllChar > 0)
    {
        die "\n\n********ERROR*********\n
        \nNumber of lines with spaces or tabs in SampleSheet_HT.csv: $countSpace\n
        \nNumber of lines with illegal characters in SampleSheet_HT.csv: $countIllChar\n\n";
    }
    close $HTsheet;


    # Get HT sample names and descriptions from SampleSheet_HT.csv
    my (@HTIDs, @HTdescs);
    open($HTsheet, "<", "SampleSheet_HT.csv");

    print "\nGetting HT Project IDs and Descriptions\n\n";

    while (<$HTsheet>)
    {
        next if 1 .. /^\[Data\]/; #Skip until [Data] section
        next if /^L/; #Skip header

        my @HTcells = split(",", $_);

        push(@HTIDs, $HTcells[1]);
        push(@HTdescs, $HTcells[2]);
    }

    @HTSampleInfo{@HTIDs} = @HTdescs;

    print "Got HT IDs: \n@HTIDs\n";
    print "Got HT Descriptions: \n@HTdescs\n\n";
    close $HTsheet;
}
############################



########################################################
##### Get Run Read and Index Info for --use-bases-mask
########################################################

my $countRead = 0;
my $countIndex = 0;
my $read2length6 = 0;
my $read2length7 = 0;
my $read2length8 = 0;
my $baseMask;

open(my $info, "<", "RunInfo.xml") or die "\n\n********ERROR*********\n
\nCould not open RunInfo.xml for Read and Index info!\n\n";

#Acquire read and index quantities
while (<$info>)
{
    $countRead++ if /.+IsIndexedRead=\"N\".+/;
    $countIndex++ if /.+IsIndexedRead=\"Y\".+/;
    $read2length6++ if /.+Number=\"2\".NumCycles=\"6\".+/;
    $read2length7++ if /.+Number=\"2\".NumCycles=\"7\".+/;
    $read2length8++ if /.+Number=\"2\".NumCycles=\"8\".+/;
}

if ($countRead == 0 && $countIndex == 0)
{
    die "\n\n********ERROR*********\n
    \nRunInfo.xml file is missing Read Number information!!!\n\n";
}

print "Read number: $countRead\n";
print "Index number: $countIndex\n";
print "Read2Length6: $read2length6\n";
print "Read2Length6: $read2length7\n";
print "Read2Length8: $read2length8\n";



########################################################
##### Demultiplex and BCL-to-Fastq Conversion
########################################################

############################
#Get LT basemask and perform demultiplexing/BCL2FQ

if (-e $LTsamp && !$reExp)
{

    #Determine base mask
    if ($countRead == 1)
    {
        if ($countIndex == 1 && $read2length6 == 1)
        {
            $baseMask = "Y*,I*";
        } elsif ($countIndex == 1 && $read2length7 == 1)
        {
            $baseMask = "Y*,I6n1";
        } elsif ($countIndex == 1 && $read2length8 == 1)
        {
            $baseMask = "Y*,I6n2";
        } elsif ($countIndex == 2)
        {
            $baseMask = "Y*,I6n2,n8";
        }
    } elsif ($countRead == 2)
    {
        if ($countIndex == 1 && $read2length6 == 1)
        {
            $baseMask = "Y*,I6n1,Y*";
        } elsif ($countIndex == 1 && $read2length7 == 1)
        {
            $baseMask = "Y*,I6n1,Y*";
        } elsif ($countIndex == 1 && $read2length8 == 1)
        {
            $baseMask = "Y*,I6n2,Y*";
        } elsif ($countIndex == 2)
        {
            $baseMask = "Y*,I6n2,n8,Y*";
        }
    } else
    {
        die "\n\n********ERROR*********\n
        \nRunInfo.xml file has additional Read Number information!!!\n\n";
    }
    print "LT Base mask: $baseMask\n";

    #LT processes
    print "\nConfiguring for LT conversion and creating folders.\n";
    my $LTconfig = "nohup /usr/local/bin/bcl2fastq -p 12 -o ./Data/Intensities/BaseCalls/FastqLT --sample-sheet SampleSheet_LT.csv --ignore-missing-bcls --use-bases-mask ".$baseMask;
    print "LT Config:  $LTconfig\n";
    print "\nPerforming LT demultiplex and conversion…\n";
    system("$LTconfig");
    print "\nLT Demultiplexing and BCL to Fastq conversion successful!\n\n";

}
############################


############################
#Get LT8 basemask and perform demultiplexing/BCL2FQ

if (-e $LT8samp && !$reExp)
{

    #Determine base mask
    if ($countRead == 1)
    {
        if ($countIndex == 1 && $read2length6 == 1)
        {
            die "\n\n********ERROR*********\n
            \nIndex sequence length of 8 required!!!\n\n";
        } elsif ($countIndex == 1 && $read2length8 == 1)
        {
            $baseMask = "Y*,I*";
        } elsif ($countIndex == 2)
        {
            $baseMask = "Y*,I*,n8";
        }
    } elsif ($countRead == 2)
    {
        if ($countIndex == 1 && $read2length6 == 1)
        {
            die "\n\n********ERROR*********\n
            \nIndex sequence length of 8 required!!!\n\n";
        } elsif ($countIndex == 1 && $read2length8 == 1)
        {
            $baseMask = "Y*,I*,Y*";
        } elsif ($countIndex == 2)
        {
            $baseMask = "Y*,I*,n8,Y*";
        }
    } else
    {
        die "\n\n********ERROR*********\n
        \nRunInfo.xml file has additional Read Number information!!!\n\n";
    }
    print "LT8 Base mask: $baseMask\n";

    #LT8 processes
    print "\nConfiguring for LT8 conversion and creating folders.\n";
    my $LT8config = "nohup /usr/local/bin/bcl2fastq -p 12 -o ./Data/Intensities/BaseCalls/FastqLT8 --sample-sheet SampleSheet_LT8.csv --ignore-missing-bcls --use-bases-mask ".$baseMask;
    print "LT8 Config:  $LT8config\n";
    print "\nPerforming LT8 demultiplex and conversion…\n";
    system("$LT8config");
    print "\nLT8 Demultiplexing and BCL to Fastq conversion successful!\n\n";

}
############################


############################
#Get HT basemask and perform demultiplexing/BCL2FQ

if (-e $HTsamp && !$reExp)
{

    #Determine base mask
    if ($countRead == 1)
    {
        $baseMask = "Y*,I*,I*";
    } elsif ($countRead == 2)
    {
        $baseMask = "Y*,I*,I*,Y*";
    } else
    {
        die "\nRunInfo.xml file has additional Read Number information!!!\n\n";
    }
    print "HT Base mask: $baseMask\n";

    #HT processes
    print "\nConfiguring for HT conversion and creating folders.\n";

    my $HTconfig = "nohup /usr/local/bin/bcl2fastq -p 12 -o ./Data/Intensities/BaseCalls/FastqHT --sample-sheet SampleSheet_HT.csv --ignore-missing-bcls --barcode-mismatches 1 --use-bases-mask ".$baseMask;
    print "HT Config:  $HTconfig\n";
    print "\nPerforming HT demultiplex and conversion…\n";
    system("$HTconfig");
    print "\nHT Demultiplexing and BCL to Fastq conversion successful!\n\n";

}

print "Demultiplex and Conversion Complete!\n\n";
############################



########################################################
##### Copy SAV docs and Prepare MASTER_FASTQ folder on NAS2
########################################################

# Get Run Date Info
open($info, "<", "RunInfo.xml") or die "Could not open RunInfo.xml for Run Date\n";
my $date;

while (my $line = <$info>)
{
    next if $line !~ m/.+Run\sId.+$/;
    ($date) = $line =~ /^\s*<Run\sId="(.+)_.+_.+_.+$/;
}
close $info;

# Get Run Number Info
open($info, "<", "RunInfo.xml") or die "Could not open RunInfo.xml for Run Number\n";
my $runNum;

while (my $line2 = <$info>)
{
    next if $line2 !~ m/.+Run\sId.+$/;
    ($runNum) = $line2 =~ /.+Number=\"(.+)\".+/;
}
close $info;

# Copy SAV Files
print "Copying SAV Documents.\n";
my $SAVfolder = "mkdir -p ../SAV/$date"."_"."$runNum";
system("$SAVfolder");
my $SAVxml = "cp *.xml ../SAV/$date"."_"."$runNum";
system("$SAVxml");
my $SAVinterop = "cp -r InterOp ../SAV/$date"."_"."$runNum";
system("$SAVinterop");
print "SAV Copying Complete.\n\n";

# Prepare Fastq Destination Folder in NAS2
my $FastqFolder = "$date"."_"."$runNum"."/";
print "Making folder for Fastq destination.\n";
print "Fastq path: $FastqPath\n";
print "Fastq Folder: $FastqFolder\n";
system("mkdir "."$FastqPath"."$FastqFolder");
print "Fastq destination ready.\n\n";



########################################################
##### Copy and Rename Fastq Files
########################################################

############################
#Single Index 6-base Samples
if (-e $LTsamp)
{

    # Copy SampleSheet and Demultiplex Stats
    print "\nCopying LT SampleSheet and Demultiplex_Stats…\n";
    my $LTSampSheet = "cp SampleSheet_LT.csv "."$FastqPath"."$FastqFolder";
    system("$LTSampSheet");
    my $LTDemultStats = "cp Data/Intensities/BaseCalls/FastqLT/Stats/DemultiplexingStats.xml "."$FastqPath"."$FastqFolder"."$date"."_"."$runNum"."_Demultiplex_StatsLT.htm";
    system("$LTDemultStats");
    print "$LTDemultStats\n\n";

    chdir("Data/Intensities/BaseCalls/FastqLT");

    # Project Loop
    my @projPaths = <*-*>;
    foreach my $path (@projPaths)
    {

        chdir("$path");

        # Get Sample IDs from folders
        print "Copying $path Fastq files.\n\n";
        my @samples = <*>;
        my @LTsampIDs;

        foreach my $sample (@samples)
        {

            my ($ids) = $sample =~ /^(.+)$/;
            push (@LTsampIDs, $ids);

        }

        # Sample Loop
        print "Copying LT Fastqs…\n\n";
        foreach my $name (@LTsampIDs)
        {
            chdir("$name");

            # Get the description and lane numbers incase the sample was sequenced over multiple lanes
            my (@lanes, @uniq, @desc, %seen);
            my @fastqs = <*fastq.gz>;

            foreach my $fastq (@fastqs)
            {
                my ($lane) = $fastq =~ /.+L00(.+)_R.+/;
                push (@lanes, $lane);
            }

            @uniq = grep { !$seen{$_}++} @lanes;

            # Copy fastq files
            foreach my $uniq (@uniq)
            {
                my $FastqCopyR1 = "cp "."$LTSampleInfo{$name}"."*L00"."$uniq"."*R1* "."$FastqPath"."$FastqFolder"."$name"."pf_"."$LTSampleInfo{$name}"."_L"."$uniq".".R1.fastq.gz";
                system ("$FastqCopyR1");
                print "$FastqCopyR1\n";
                my $FastqCopyR2 = "cp "."$LTSampleInfo{$name}"."*L00"."$uniq"."*R2* "."$FastqPath"."$FastqFolder"."$name"."pf_"."$LTSampleInfo{$name}"."_L"."$uniq".".R2.fastq.gz";
                system ("$FastqCopyR2");
            }

            chdir("../"); #Out of Sample Folder

        }

        chdir("../"); #Out of Project Folder

        print "\nCopying of $path Fastq files complete!\n\n";
    }

    chdir("../../../../"); #Out of FastqLT Folder

}
############################


############################
#Single Index 8-base Samples
if (-e $LT8samp)
{


    # Copy SampleSheet and Demultiplex Stats
    print "\nCopying LT8 SampleSheet and Demultiplex_Stats…\n";
    my $LT8SampSheet = "cp SampleSheet_LT8.csv "."$FastqPath"."$FastqFolder";
    system("$LT8SampSheet");
    my $LT8DemultStats = "cp Data/Intensities/BaseCalls/FastqLT8/Stats/DemultiplexingStats.xml "."$FastqPath"."$FastqFolder"."$date"."_"."$runNum"."_Demultiplex_StatsLT8.htm";
    system("$LT8DemultStats");
    print "$LT8DemultStats\n\n";

    chdir("Data/Intensities/BaseCalls/FastqLT8");

    # Project Loop
    my @projPaths = <*-*>;
    foreach my $path (@projPaths)
    {

        chdir("$path");

        # Get Sample IDs from folders
        print "Copying $path Fastq files.\n\n";
        my @samples = <*>;
        my @LT8sampIDs;

        foreach my $sample (@samples)
        {

            my ($ids) = $sample =~ /^(.+)$/;
            push (@LT8sampIDs, $ids);

        }

        # Sample Loop
        print "Copying LT8 Fastqs…\n\n";
        foreach my $name (@LT8sampIDs)
        {
            chdir("$name");

            # Get the lane numbers incase the sample was sequenced over multiple lanes
            my (@lanes, @uniq, %seen);
            my @fastqs = <*fastq.gz>;

            foreach my $fastq (@fastqs)
            {
                my ($lane) = $fastq =~ /.+L00(.+)_R.+/;
                push (@lanes, $lane);
            }

            @uniq = grep { !$seen{$_}++} @lanes;

            # Copy fastq files
            foreach my $uniq (@uniq)
            {
                my $FastqCopyR1 = "cp "."$LT8SampleInfo{$name}"."*L00"."$uniq"."*R1* "."$FastqPath"."$FastqFolder"."$name"."pf_"."$LT8SampleInfo{$name}"."_L"."$uniq".".R1.fastq.gz";
                system ("$FastqCopyR1");
                print "$FastqCopyR1\n";
                my $FastqCopyR2 = "cp "."$LT8SampleInfo{$name}"."*L00"."$uniq"."*R2* "."$FastqPath"."$FastqFolder"."$name"."pf_"."$LT8SampleInfo{$name}"."_L"."$uniq".".R2.fastq.gz";
                system ("$FastqCopyR2");
            }

            chdir("../"); #Out of Sample Folder

        }

        chdir("../"); #Out of Project Folder

        print "\nCopying of $path Fastq files complete!\n\n";
    }

    chdir("../../../../"); #Out of FastqLT Folder

}
############################


############################
#Dual Index Samples
if (-e $HTsamp)
{


    # Copy SampleSheet and Demultiplex Stats
    print "\nCopying HT SampleSheet and Demultiplex_Stats…\n";
    my $HTSampSheet = "cp SampleSheet_HT.csv "."$FastqPath"."$FastqFolder";
    system("$HTSampSheet");
    my $HTDemultStats = "cp Data/Intensities/BaseCalls/FastqHT/Stats/DemultiplexingStats.xml "."$FastqPath"."$FastqFolder"."$date"."_"."$runNum"."_Demultiplex_StatsHT.htm";
    system("$HTDemultStats");
    print "$HTDemultStats\n\n";

    chdir("Data/Intensities/BaseCalls/FastqHT");

    # Project Loop
    my @projPaths = <*-*>;
    foreach my $path (@projPaths)
    {

        chdir("$path");

        # Get Sample IDs from folders
        print "Copying $path Fastq files.\n\n";
        my @samples = <*>;
        my @HTsampIDs;

        foreach my $sample (@samples)
        {
            my ($ids) = $sample =~ /^(.+)$/;
            push (@HTsampIDs, $ids);
        }

        # Sample Loop
        print "Copying HT Fastqs…\n\n";
        foreach my $name (@HTsampIDs)
        {
            chdir("$name");

            # Get the lane numbers incase the sample was sequenced over multiple lanes
            my (@lanes, @uniq, %seen);
            my @fastqs = <*fastq.gz>;

            foreach my $fastq (@fastqs)
            {
                my ($lane) = $fastq =~ /.+L00(.+)_R.+/;
                push (@lanes, $lane);
            }

            @uniq = grep { !$seen{$_}++} @lanes;

            # Copy fastq files
            foreach my $uniq (@uniq)
            {
                my $FastqCopyR1 = "cp "."$HTSampleInfo{$name}"."*L00"."$uniq"."*R1* "."$FastqPath"."$FastqFolder"."$name"."pf_"."$HTSampleInfo{$name}"."_L"."$uniq".".R1.fastq.gz";
                system ("$FastqCopyR1");
                print "$FastqCopyR1\n";
                my $FastqCopyR2 = "cp "."$HTSampleInfo{$name}"."*L00"."$uniq"."*R2* "."$FastqPath"."$FastqFolder"."$name"."pf_"."$HTSampleInfo{$name}"."_L"."$uniq".".R2.fastq.gz";
                system ("$FastqCopyR2");
            }

            chdir("../"); #Out of Sample Folder

        }

        chdir("../"); #Out of Project Folder

        print "\nCopying of $path Fastq files complete!\n\n";
    }

}
############################



########################################################
##### Merge Fastq files for samples run on multiple lanes
########################################################
chdir("$FastqPath"."$FastqFolder");
print "\nPerforming Fastq Merge!\n";

my @files = <*pf_*R1.fastq.gz>;
my @libID;
foreach my $files (@files)
{
	my ($lib) = $files =~ /(.+)_L.+/;
	push(@libID, $lib);
}

my @dups = dups(@libID);
#my @uniqdups = uniq @dups;
my @uniqdups = do { my %seen; grep { !$seen{$_}++ } @dups };
print "\nDups:\n@uniqdups\n\n";

foreach my $dup (@uniqdups)
{
	my @dupfileR1 = <$dup*R1.fastq.gz>;
	my $mergeR1 = "cat @dupfileR1 > "."$dup"."_merge.R1.fastq.gz";
	print "Merging files: @dupfileR1\n";
	system ("$mergeR1");
	#print "$mergeR1\n";

	my @dupfileR2 = <$dup*R2.fastq.gz>;
	if (@dupfileR2)
	{
		my $mergeR2 = "cat @dupfileR2 > "."$dup"."_merge.R2.fastq.gz";
		print "Merging files: @dupfileR2\n";
		system ("$mergeR2");
		#print "$mergeR2\n";

	}

}


sub dups {
	my %seen;
	grep $seen{$_}++, @_;
}



########################################################
##### Perform md5 checksum on the transfered Fastq files
########################################################

# Get Fastq sample names
#chdir("$FastqPath"."$FastqFolder");
print "\nPerforming md5 checksum!\n";
my @fqsamps = <*fastq.gz>;

foreach my $fq (@fqsamps)
{
    # Perform md5 on each sample in folder
    my $md5 = ("md5sum $fq >> md5.txt ");
    system ("$md5");
}

print "\nmd5 checksum complete!\n";

print "\nAll processes completed!!!\n\n";
