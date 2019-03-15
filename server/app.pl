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
use File::Path;
use Mojolicious::Lite;
use Text::CSV_XS;
use Try::Tiny;
use strict;
use warnings;

$Data::Dumper::Indent = 1;
our $VERSION = '0.6';

my $queue_dir  = getcwd() . '/queue';
my $queue_file = $queue_dir . '/later.queue';

any '/' => sub {
    my $c = shift;

    $c->redirect_to('/queue');
};

get '/queue' => sub {
    my $c = shift;

    my $later_data = {};

    $later_data->{status} = 0;

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

post '/queue' => sub {
    my $c = shift;

    my $later_hash = $c->req->json();
    if (($later_hash) && (exists($later_hash->{tweet}))) {
        if (! -d $queue_dir) {
            try {
                mkpath($queue_dir);
            } catch {
                print $_, "\n";
            };
        }
        $c->render(text => 'yes');
    } else {
        $c->render(text => 'nope');
    }
};

app->start();
