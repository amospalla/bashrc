#!/usr/bin/env perl

# FileVersion=1

use open qw(:std :utf8);
use Encode qw(decode);

while (my $line = <STDIN>) {
        print decode("MIME-Header", $line);
}
