#!/usr/bin/env perl
use strict;
use warnings;

while (<STDIN>) {
    s{/\*!\d+\s+DEFINER=`[^`]+`@`[^`]+`\*/\s*}{}g;
    s{\bDEFINER=`[^`]+`@`[^`]+`\s+}{}g;
    s{\bSQL\s+SECURITY\s+DEFINER\b}{SQL SECURITY INVOKER}g;
    print;
}

