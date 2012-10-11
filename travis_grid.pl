#!/usr/local/bin/perl
#
# travis_grid.pl
#
# Quickie script to print the Travis build status for individual
# Emacs runtimes across all of your libraries.
#
# How to use
#
#   1. Add your travis username where indicated in $travis_base
#
#   2. Add all desired repository names below __DATA__
#

###
### pragmas
###

use strict;
# use warnings;
# no  warnings qw/uninitialized numeric/;
# no  indirect;
# use criticism;
# ## no critic (SubroutinePrototypes MutatingListFunctions ExplicitReturnUndef ProhibitStringyEval)

use encoding::warnings 'FATAL';
use utf8;
use feature 'unicode_strings';  # perl 5.14+
use open ':utf8';               # not :encoding(utf8), which is currently incompatible with fork()
use open ':std';

###
### version
###

our $VERSION = '0.001_001';
    $VERSION = eval $VERSION;

###
### modules
###

use LWP::Simple;
use Term::ANSIColor;
use JSON;

###
### configurable file-scoped lexical variables
###

my $travis_base  = "https://travis-ci.org/YOUR_USER_NAME_HERE";

###
### argument processing
###

die "unknown arguments\n" if @ARGV;

###
### initialization
###

# unbuffered output
select STDERR; local $|=1;
select STDOUT; local $|=1;

my @repos;
my $longest_repo;
while (<DATA>) {
    s{#.*}{};
    next unless m{\S};
    s{\s+}{};
    push @repos, $_;
    $longest_repo = length $_ if length $_ > $longest_repo;
}

die "add your username to the \$travis_base variable\n"   if $travis_base =~ m/YOUR_USER_NAME/;
die "add some repository names below the __DATA__ line\n" unless @repos;

###
### main program
###

foreach my $repo (@repos) {
    my $json = get "${travis_base}/${repo}.json" or die "fetch failed in $repo\n";
       $json = from_json $json;
    my $status = $json->{last_build_status};
    print $repo;
    print ' ' x (1 + $longest_repo - (length $repo));
    if ($status eq "0") {
        print ((color "bold green"), "success", (color "reset"));
    } elsif ($status > 0) {
        print ((color "bold red"),   "failure", (color "reset"));
    } else {
        print ((color "white"),      "unknown", (color "reset"));
    }
    if (($status eq "0") or $status > 0) {
        my $build_id = $json->{last_build_id};
        $json = get "${travis_base}/${repo}/builds/${build_id}.json" or die "fetch failed in $repo\n";
        $json = from_json $json;
        print " |";
        foreach my $m (reverse @{$json->{matrix}}) {
            my $emacs = $m->{config}->{env};
            unless ($emacs =~ s{\A.*?EMACS=([^\s]+).*?\Z}{$1}) {
                die "failed to read JSON for repo $repo\n";
            }
            if ($m->{result} eq "0") {
                print ((color "bold green"), " ", $emacs, (color "reset"));
            } else {
                print ((color "bold red"), " ", $emacs, (color "reset"));
            }
            if ($status > 0) {
                print ((color "bold red"), " -- $travis_base/$repo", (color "reset"));
            }
        }
        print "\n";
    }
}

__DATA__
# list
# repository
# names
# one
# per
# line
