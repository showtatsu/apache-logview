#!/usr/bin/perl
use strict;
use warnings;
use 5.010; # Perl 5.10.x or later versions are required.
use HTML::Entities qw(encode_entities);
use FindBin;
use lib $FindBin::Bin;
use FancyLog;
use Data::Dumper;

my $mode_html = 1;
my $self_ip = $ENV{HTTP_CLIENT_IP}
        || $ENV{HTTP_X_FORWARDED_FOR}
        || $ENV{REMOTE_ADDR}
        || "";
my $tracelog = "";

# apache errorlog pattern
my $errorlog_pattern = join(' ',(
    '\[([^\]]+)\]', # timestamp     $1
    '\[([^\]]+)\]', # loglevel      $2
    '\[([^\]]+)\]', # issuer        $3
    '(.+)',     # logmessage    $4
));

my $fancy_output = FancyLog->new(
    title => sprintf('fancyview: %s (apache style error log)',
        ($ENV{DOCUMENT_URI} || "-")),
    headers => [qw(timestamp loglevel issuer errorlog_message)],
    options => +{},
    regexp => $errorlog_pattern,
    autoclass => 1,
);

my $title = encode_entities(
        sprintf('fancyview: %s (apache style error log)',
            ($ENV{DOCUMENT_URI} || "-")
    ));

$fancy_output->auto_print(*STDIN, *STDOUT);
__END__

# Print HTML to STDOUT ...
print $fancy_output->html_start(title => $title);
print $fancy_output->table_start;
foreach (<STDIN>) {
    print $fancy_output->row_start;
    print $fancy_output->print_cells($_);
    print $fancy_output->row_end;
}
print $fancy_output->table_end;
print $fancy_output->html_end;

