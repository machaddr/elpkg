package Elpkg::Version;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(cmp_version);

sub cmp_version {
    my ($a, $b) = @_;
    return 0 if !defined $a && !defined $b;
    return -1 if !defined $a;
    return 1 if !defined $b;

    my @as = _split($a);
    my @bs = _split($b);
    my $len = @as > @bs ? @as : @bs;
    for (my $i = 0; $i < $len; $i++) {
        my $x = $as[$i] // '';
        my $y = $bs[$i] // '';
        if ($x =~ /^\d+$/ && $y =~ /^\d+$/) {
            my $cmp = $x <=> $y;
            return $cmp if $cmp != 0;
        } else {
            my $cmp = $x cmp $y;
            return $cmp if $cmp != 0;
        }
    }
    return 0;
}

sub _split {
    my ($v) = @_;
    my @parts;
    for my $seg (split /[\.-]/, $v) {
        next if $seg eq '';
        if ($seg =~ /(\d+|[A-Za-z]+)/g) {
            push @parts, $1 while $seg =~ /(\d+|[A-Za-z]+)/g;
        } else {
            push @parts, $seg;
        }
    }
    return @parts;
}

1;
