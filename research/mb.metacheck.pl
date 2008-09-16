#!/usr/bin/perl

use warnings;
use strict;

use File::Fu;
my $tree = shift(@ARGV) or die "need tree";
$tree = File::Fu->dir($tree);

my @matchers;
my $match = shift(@ARGV); # TODO as a list?
if($match) {
  my ($where, $what) = split(/=/, $match, 2);
  push(@matchers, [$what, File::Fu->file($where)->open('>')]);
}

my $pkd = $tree + '/modules/02packages.details.txt';

my $fh = $pkd->open;
while(my $x = <$fh>) { $x eq "\n" and last; } # cue-up

my $auth_tree = ($tree / 'authors/id')->stringify;

my $d_total = 0;
my $m_total = 0;
my $g_total = 0;
my %generators;
my %seen;
while(my $line = <$fh>) {
  chomp($line);
  $line =~ s/.* //;

  my $dist = $line;
  $seen{$dist} and next; $seen{$dist} = 1;

  $d_total++;
  print "$d_total\n" unless($d_total % 1000);

  $line =~ s/(?:\.tar\.gz|\.tgz|\.zip|\.pm\.gz)$/.meta/ or die $line;

  if(-e (my $meta = "$auth_tree/$line")) {
    $m_total++;
    my $meta_fh = File::Fu->file($meta)->open;
    while(my $line = <$meta_fh>) {
      if($line =~ m/^generated_by: *(.*)/) {
        $g_total++;
        my $gen = $1;
        # cleanup some junk - this ain't a yaml parser
        $gen =~ s/^'//; $gen =~ s/'$//; $gen =~ s/\s+$//;
        foreach my $m (@matchers) {
          my ($e, $fh) = @$m;
          if($gen =~ m/$e/) {
            print $fh $dist, "\n";
            last; # only matching once better be okay
          }
        }
        ($generators{$gen} ||= 0)++;
        last;
      }
    }
  }
}

print "$g_total tagged in $m_total meta of $d_total dists\n";
foreach my $gen (sort({$generators{$b} <=> $generators{$a}} keys %generators)) {
  print "$gen: $generators{$gen}\n";
}

# vim:ts=2:sw=2:et:sta
