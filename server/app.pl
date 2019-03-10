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
use Mojolicious::Lite;
use Text::CSV_XS;
use strict;
use warnings;

our $VERSION = '0.3';

get '/' => sub {
    my $c = shift;
    $c->redirect_to('/queue');
};

get '/queue' => sub {
    my $c = shift;

    my $later_data = {};

    $later_data->{status} = 0;

    my $queue_file = getcwd() . '/queue/later.queue';

    # if we've got no queue file, we got nothing to do
    return $c->render(json => $later_data) if (! -e $queue_file);

    open(my $fh, '<', $queue_file) || return $c->render(json => $later_data);
    my $parser = Text::CSV_XS->new();
    while(<$fh>) {
        chomp;
        $parser->parse($_);
        my @fields = $parser->fields();
        if ($fields[0] && $fields[1]) {
            $later_data->{status} = 1;
            push(@{$later_data->{queue}}, {timestamp => $fields[0], text => $fields[1]});
        }
    }
    close($fh);
    
    $c->render(json => $later_data);
};

app->start;
