#!/usr/bin/env perl
# Copyright 2019 Kevin Spencer <kevin@kevinspencer.org>
#
# Permission to use, copy, modify, distribute, and sell this software and its
# documentation for any purpose is hereby granted without fee, provided that
# the above copyright notice appear in all copies and that both that
# copyright notice and this permission notice appear in supporting
# documentation. No representations are made about the suitability of this
# software for any purpose. It is provided "as is" without express or
# implied warranty.
#
################################################################################

use Cwd;
use Data::Dumper;
use File::Basename;
use Text::CSV_XS;
use utf8;
use strict;
use warnings;

$Data::Dumper::Indent = 1;

our $VERSION = '0.2';

my $queue_dir  = dirname(getcwd()) . '/queue';
my $queue_file = $queue_dir . '/later.queue';

exit() if (! -e $queue_file);

open(my $fh, '<', $queue_file) || die "Could not open $queue_file - $!\n";
my $parser = Text::CSV_XS->new();
while(<$fh>) {
    chomp;
    $parser->parse($_);
    my @fields = $parser->fields();
    print $fields[1], "\n";
}
close($fh);

