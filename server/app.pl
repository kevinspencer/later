#!/usr/bin/env perl
# Copyright 2019-2021 Kevin Spencer <kevin@kevinspencer.org>
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
use File::Path;
use Mojolicious::Lite;
use Text::CSV_XS;
use Try::Tiny;
use strict;
use utf8;
use warnings;

$Data::Dumper::Indent = 1;
our $VERSION = '0.12';

my $queue_dir  = dirname(getcwd()) . '/queue';
my $queue_file = $queue_dir . '/later.queue';

any '/' => sub {
    my $c = shift;

    $c->redirect_to('/queue');
};

# GET /queue
# Testing: curl http://localhost:3000/queue/

get '/queue' => sub {
    my $c = shift;

    my $later_response_data = {};
    $later_response_data->{status} = 0;

    # if we've got no queue file, we got nothing to do
    if (! -e $queue_file) {
        return $c->render(
            json   => $later_response_data,
            status => 200
        );
    }

    open(my $fh, '<', $queue_file) || do {
        return $c->render(
            json   => $later_response_data,
            status => 500
        );
    };
    my $parser = Text::CSV_XS->new();
    while(<$fh>) {
        chomp;
        $parser->parse($_);
        my @fields = $parser->fields();
        if ($fields[0] && $fields[1]) {
            $later_response_data->{status} = 1;
            push(@{$later_response_data->{queue}}, {id => $fields[0], tweet => $fields[1]});
        }
    }
    close($fh);
    
    $c->render(
        json   => $later_response_data,
        status => 200
    );
};

# POST /queue
# Testing: curl -XPOST http://localhost:3000/queue/ -d '{"tweet":"this is a tweet"}'

post '/queue' => sub {
    my $c = shift;

    my $later_data = {};
    $later_data->{status} = 0;
    my $later_hash = $c->req->json();
    if (($later_hash) && (exists($later_hash->{tweet}))) {
        if (! -d $queue_dir) {
            try {
                mkpath($queue_dir);
            } catch {
                return $c->render(
                    json   => $later_data,
                    status => 500
                );
            };
        }
        my $now = time();
        open(my $fh, '>>', $queue_file) || do {
            return $c->render(
                json   => $later_data,
                status => 500
            );
        };
        print $fh "$now,$later_hash->{tweet}\n";
        close($fh);

        $later_data->{status} = 1;
        $c->render(
            json   => $later_data,
            status => 200
        );
    } else {
        $c->render(
            json   => $later_data,
            status => 400
        );
    }
};

# DELETE /queue
# Testing: curl -XDELETE http://localhost:3000/queue/ -d '{"delete":$id"}'

del '/queue' => sub {
    my $c = shift;

    my $later_data = {};
    $later_data->{status} = 0;
    my $later_hash = $c->req->json();

    if (($later_hash) && (exists($later_hash->{delete}))) {
        if (-e $queue_file) {
            my $tmp_file = $queue_file . '.tmp';

            open(my $tmpfh, '>', $tmp_file) || do {
                return $c->render(
                    json   => $later_data,
                    status => 500
                );
            };

            open(my $fh, '<', $queue_file) || do {
                return $c->render(
                    json   => $later_data,
                    status => 500
                );
            };

            my $parser = Text::CSV_XS->new();

            while(<$fh>) {
                chomp;
                my $line = $_;
                $parser->parse($line);
                my @fields = $parser->fields();
                if ($fields[0] && ($fields[0] == $later_hash->{delete})) {
                    $later_data->{status} = 1;
                    next;
                }
                print $tmpfh $line, "\n"; 
            }
            close($fh);
            close($tmpfh);

            rename($tmpfh, $queue_file) || do {
                return $c->render(
                    json   => $later_data,
                    status => 500
                );
            };

           
            my $http_status = $later_data->{status} ? 200 : 404;

            $c->render(
                json   => $later_data,
                status => $later_data->{status} ? 200 : 404
            );

        } else {
            $c->render(
                json => $later_data,
                status => 404
            );
        }
    }
};

app->start();
