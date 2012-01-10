#!/usr/bin/perl -w

use Getopt::Long;
use File::Basename;

use Stockholm;
use Stockholm::Database;
use Newick;

my ($progname) = fileparse($0);

my $usage = "";
$usage .= "$progname -- convert a Stockholm MCMC trace to MPD format\n";
$usage .= "\n";
$usage .= "Usage: $progname [Stockholm file(s)]\n";
$usage .= "\n";

GetOptions() or die $usage;

unless (@ARGV) { @ARGV = ("-"); warn "[waiting for Stockholm file(s) on standard input]\n" }
my @db;
for my $filename (@ARGV) {
    push @db, @{Stockholm::Database->from_file($filename)};
}

my $sample = 0;
for my $stock (@db) {
    next if $stock->gf_TYPE eq 'Refined';  # skip Viterbi local-refinement alignments generated by handalign
    my $tree;
    if (defined $stock->gf->{'NH'}) {
	$tree = Newick->from_string (@{$stock->gf_NH});
    }
    for my $seqname (@{$stock->seqname}) {
	if (defined $tree) {
	    # drop internal nodes
	    my @node = $tree->find_nodes ($seqname);
	    next if @node == 1 && $tree->children($node[0]) > 0;
	}
	print "Sample ", $sample, "\tAlignment:\t>", $seqname, "\n";
	print "Sample ", $sample, "\tAlignment:\t", $stock->seqdata->{$seqname}, "\n";
    }
    ++$sample;
}