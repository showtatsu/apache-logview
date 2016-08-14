#!/usr/bin/perl
use strict;
use warnings;
use 5.010; # Perl 5.10.x or later versions are required.
use HTML::Entities qw(encode_entities);
use utf8;
use Encode;
use FindBin;
use lib $FindBin::Bin;
use FancyLog;
use Data::Dumper;

my $self_ip = $ENV{HTTP_CLIENT_IP}
        || $ENV{HTTP_X_FORWARDED_FOR}
        || $ENV{REMOTE_ADDR}
        || "";
my $tracelog = "";

# NCSA extended/combined
my $ncsa_combined_pattern = join(' ',(
    '(\S+)',         # remote_addr   $1
    '(\S+)',         # ident_name    $2
    '(\S+)',         # remote_user   $3
    '\[([^\]]+?)\]', # timestamp     $4
    '"([^"]+)"',     # request_line  $5
    '([0-9]{3})',    # status_code   $6
    '([0-9-]+)',     # response_size $7
    '"([^"]+)"',     # referer       $8
    '"([^"]+)"',     # user_agent    $9
));

my $fancy_output = FancyLog->new(
    title => sprintf('fancyview: %s (NCSA combined style access log)',
        ($ENV{DOCUMENT_URI} || "-")),
    headers => [qw(client ident remote_user timestamp
        request_line status ressize referer useragent)],
    options => +{
        status => +{
            classes => sub{
                my $s = shift;
                return unless defined $s;
                return sprintf('status%sxx', substr($s, 0, 1));
            },
        },
        client => +{
            classes => sub{
                my $s = shift;
                return unless defined $s;
                return 'self_ip' if($s eq $self_ip);
            },
        },
    },
    regexp => $ncsa_combined_pattern,
    autoclass => 1,
);
binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
$fancy_output->auto_print(*STDIN, *STDOUT);

__END__

Named regexp mode is much slower than normal mode.
The fetch phase ($+{XXXX}) is high cost.

At Perl v5.16.3 / CentOS7.0 on ESXi 5.5 / Core i5-3570T CPU @ 2.30GHz

* Named  @2000 lines, (match 18.0ms + fetch 35.1ms) * 2000

my $apache_combined_pattern = join(' ',(
    '(?<remote_addr>\S+)',
    '(?<ident>\S+)',
    '(?<remote_user>\S+)',
    '(?<timestamp>\[[^\]]+?\])',
    '"(?<request_line>[^"]+)"',
    '(?<status_code>[0-9]{3})',
    '(?<response_size>[0-9-]+)',
    '"(?<referer>[^"]+)"',
    '"(?<user_agent>[^"]+)"',
));
my $line = join("\t", $+{remote_addr}, $+{timestamp},
     $+{request_line}, $+{status_code}, $+{referer});


* Normal @2000 lines, (match 15.2ms + fetch  2.2ms) * 2000
my $apache_combined_pattern = join(' ',(
    '(\S+)',         # remote_addr   $1
    '(\S+)',         # ident_name    $2
    '(\S+)',         # remote_user   $3
    '(\[[^\]]+?\])', # timestamp     $4
    '"([^"]+)"',     # request_line  $5
    '([0-9]{3})',    # status_code   $6
    '([0-9-]+)',     # response_size $7
    '"([^"]+)"',     # referer       $8
    '"([^"]+)"',     # user_agent    $9
));
my $line = join("\t", $1, $4, $5, $6, $8);

