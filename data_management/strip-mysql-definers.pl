#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp qw(tempfile);
use File::Copy qw(move);

sub process {
    my ($line) = @_;

    $line =~ s{/\*!\d+\s+DEFINER=`[^`]+`@`[^`]+`\*/\s*}{}g;
    $line =~ s{\bDEFINER=`[^`]+`@`[^`]+`\s+}{}g;
    $line =~ s{\bSQL\s+SECURITY\s+DEFINER\b}{SQL SECURITY INVOKER}g;

    return $line;
}

sub usage {
    die "Usage:\n"
      . "  $0                # read STDIN, write STDOUT\n"
      . "  $0 file           # read file, write STDOUT\n"
      . "  $0 -i file        # edit file in place\n"
      . "  $0 file -i        # edit file in place\n";
}

my ($inplace, $file);

if (@ARGV == 0) {
    # STDIN → STDOUT
    while (<STDIN>) {
        print process($_);
    }
    exit 0;
}
elsif (@ARGV == 1) {
    # file → STDOUT
    $file = $ARGV[0];
}
elsif (@ARGV == 2) {
    if ($ARGV[0] eq '-i') {
        ($inplace, $file) = (1, $ARGV[1]);
    }
    elsif ($ARGV[1] eq '-i') {
        ($file, $inplace) = ($ARGV[0], 1);
    }
    else {
        usage();
    }
}
else {
    usage();
}

# If we reach here and have no file, something went wrong
$file or usage();

# Not in-place: file → STDOUT
if (!$inplace) {
    open my $fh, '<', $file
        or die "Cannot open $file: $!";

    while (<$fh>) {
        print process($_);
    }
    close $fh;
    exit 0;
}

# In-place edit
open my $in, '<', $file
    or die "Cannot open $file for reading: $!";

my ($out, $tmp) = tempfile(
    DIR    => '.',
    UNLINK => 0,
);

while (<$in>) {
    print $out process($_);
}

close $in;
close $out;

move($tmp, $file)
    or die "Cannot replace $file: $!";
