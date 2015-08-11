use warnings;
use strict;

my $natives_file = "natives.txt";
my $synonymy_file = "synonymy.txt";

#check that parameters were input correctly
unless ($ARGV[0]) {
	die "no input file declared\nproper script usage is \$native_getter.pl datafile.txt 6" unless $ARGV[0];
}
unless ($ARGV[1]) {
	die "please indicate the number of the column containing scientific name\ni.e. \$native_getter.pl datafile.txt 6\n";
}
unless ($ARGV[1] =~ /^[1-9][0-9]*$/) {
	die "please indicate the number of the column containing scientific name\ni.e. \$native_getter.pl datafile.txt 6\n";
}

#process natives.txt into an array
my @native_taxa;
open(IN, "$natives_file") || die "script requires a native taxa file natives.txt\nrefer to natives_template.txt";
while(my $line = <IN>){
	next if $.==1; #skips the first line
	chomp $line;
	push @native_taxa, "$line";
}
close(IN);
#die;

#process synonymy.txt into %accepted_names and %binomials ####is binomials necessary?
my %accepted_names;
my %binomials;
my @fields;
open(IN, "$synonymy_file") || die "script required a synonymy file synonymy.txt\nrefer to synonymy_template.txt";
while(my $line = <IN>){
	next if $.==1; #skips the first line
	chomp $line;
	@fields = split(/\t/,$line,5); #fields are synonym_name, accepted_name, accepted_name_binomial
	$accepted_names{$fields[0]} = $fields[1];
	$binomials{$fields[1]} = $fields[2];
}

#assign parameters to variables
my $input_file = $ARGV[0]; #"CCH_records.txt";
my $name_field_number = $ARGV[1];

#make name for output file
my $output_file = $input_file;
$output_file =~ s/(.*)(\..*)/$1_clipped$2/;

#open input and output files
open(IN, $input_file) || die "could not find input file $input_file\nproper script usage is \$native_getter.pl datafile.txt 6";
open(OUT,">$output_file") || die;

#process the main file
Record: while(<IN>){
	chomp;
	next if $.==1; #skips the first line --> it should print out the first line with new field headings appended
	my @fields=split(/\t/,$_,150);

	#the field input number is the scientific name field
	my $original_name = $fields[$name_field_number];
	
	#need to remove infra rank for matching to the synonymy hash
	my $name_for_matching = $original_name;
	$name_for_matching =~ s/subsp\. //;
	$name_for_matching =~ s/var\. //;
	$name_for_matching =~ s/f\. //;

	#declare the variables that will be printed out
	my $current_name;
	my $current_binomial;

	#check if the name is in the native_taxa array
	if ( grep( /^\Q$original_name\E/, @native_taxa ) ) { #if the name is in the native_taxa array (only match beginning on the string because we are using binomials
		$current_name = $original_name;
		$current_binomial = $current_name;
		$current_binomial =~ s/(.*) (.*) (.*)/$1 $2/;
	}
	elsif (exists($accepted_names{$name_for_matching})) { #if the name is a synonym of an accepted name
		$current_name = $accepted_names{$name_for_matching};
		$current_binomial = $binomials{$current_name};
	}
	else { #else the name is not a native taxon, do not print it
		next;
	}
	
	print OUT "$fields[0]\t$original_name\t$current_name\t$current_binomial\n";

}

