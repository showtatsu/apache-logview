package FancyLog;
#
# * Fancy log script framework package.
#
# - Author: Tatsuya SHORIKI <show.tatsu.devel@gmail.com>
# - https://github.com/showtatsu/apache-logview
#
#  * new (header => arrayref, options => hashref, autoclass => 0/1)
#  * html_start (title => text)
#  * html_end ()
#  * table_start ()
#  * table_end ()
#  * row_start ()
#  * row_end ()
#  * print_cells ( STRING )
#
use strict;
use warnings;
use 5.010;
use HTML::Entities;
use Data::Dumper;
our $CSS_FILES = ['/logstorage/files/style.css'];

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless +{
        headers => (delete $args{headers} ||  []),
        options => (delete $args{options} || +{}),
        regexp  => delete $args{regexp},
        autoclass => delete $args{autoclass},
        title => delete $args{title} || "FancyLog View",
    }, $class;
    $self->_build;
    return $self;
}

sub _build {
    my $self = shift;

    my $headers = $self->{headers};
    my $options = $self->{options};
    foreach my $header (@$headers) {
        my $option = $options->{$header};
        $option->{title} = $header unless defined $option->{title};
        $option->{skip} = 0 unless defined $option->{skip};

        # set class builder...
        my $builder;
        if ($builder = $option->{classes}) {
            $builder = [ $builder ] if ref $builder ne "ARRAY";
        } else {
            $builder = [];
        }
        push(@$builder, $header) if $self->{autoclass};
        $option->{classes} = $builder;

        # Set updated option if undefined
        $options->{$header} = $option;
    }
    $self->{regexp} = qr/$self->{regexp}/ unless ref $self->{regexp};
}

sub auto_print {
    my $self = shift;
    my (%opts) = @_;
    my $input = $opts{input} || *STDIN;
    my $output = $opts{optput} || *STDOUT;

    print $self->html_start;
    print $self->table_start;
    foreach(<$input>) {
        print $self->row_start;
        print $self->print_cells($_);
        print $self->row_end;
    }
    print $self->table_end;
    print $self->html_end;
}

sub html_start {
    my $self = shift;
    my (%opts) = @_;
    my $title = delete $opts{title} || $self->{title};
    my $styles = delete $opts{styles} || $CSS_FILES;
    my $scripts = delete $opts{scripts} || [];

    my @buffer;
    push(@buffer, join("\n",
        '<!DOCTYPE html>',
        '<html>',
        '<head>',
        sprintf('<title>%s</title>', encode_entities($title)),
        '<meta http-equiv="content-type" content="text/html; charset=UTF-8">',
        ''));
    foreach (@$styles) {
        push(@buffer, sprintf('<link rel="stylesheet" type="text/css" href="%s">'."\n", $_));
    }
    foreach (@$scripts) {
       push(@buffer, sprintf('<script type="text/javascript" src="%s"></script>'."\n", $_));
    }
    push(@buffer, "</head>\n<body>\n");
    return join('', @buffer);
}

sub html_end {
    my $self = shift;
    my (%opts) = @_;
    return "</body>\n</html>\n";
}

sub table_start {
    my $self = shift;
    my $headers = $self->{headers};

    my @buffer;
    push(@buffer, "<table><thead>\n<tr>");
    foreach my $header (@$headers) {
        my $option = $self->{options}->{$header};
        next if $option->{skip};

        my %attrs = ();
        my @classes = _s_classgen($option->{classes}, $header, undef);
        $attrs{class} = join(' ', @classes) if (@classes);

        my @attributes;
        foreach my $key (keys %attrs) {
            my $value = $attrs{$key};
            next unless $value;
            push(@attributes, sprintf('%s="%s"', $key, $value));
        }
        my $title = $option->{title};
        push(@buffer, sprintf('<th %s>%s</th>', join(' ', @attributes), $title));
    }
    push(@buffer, "</tr>\n</thead><tbody>\n");
    return join('', @buffer);
}

sub table_end {
    my $self = shift;
    return "</tbody></table>";
}

sub row_start {
    my $self = shift;
    return "<tr>";
}
sub row_end {
    my $self = shift;
    return "</tr>\n";
}

sub print_cells {
    my $self = shift;
    my ($line) = @_;

    my @buffer;
    if(my @matches = ($line =~ /$self->{regexp}/)) {
        foreach my $header (@{$self->{headers}}) {
            my $text = shift @matches;
            my $cell = $self->_print_cell($header, $text);
            push(@buffer, $cell) if $cell;
        }
    } else {
        my $options = $self->{options};
        my $count = scalar(!grep{$options->{$_}->{skip}}(@{$self->{headers}}));
        push(@buffer, sprintf('<td colspan="%s"><strong>[UNMATCHED]</strong>%s</td>', $count, $line));
    }
    return join('', @buffer);
}

sub _print_cell {
    my $self = shift;
    my ($header, $text) = @_;

    my $option = $self->{options}->{$header};
    return if $option->{skip};

    my %attrs = ();
    my @classes = _s_classgen($option->{classes}, $header, $text);
    $attrs{class} = join(' ', @classes) if (@classes);

    my @attributes;
    foreach my $key (keys %attrs) {
        my $value = $attrs{$key};
        next unless $value;
        push(@attributes, sprintf('%s="%s"', $key, $value));
    }
    my $title = $option->{title};
    $text = encode_entities($text);
    return sprintf('<td %s>%s</td>', join(' ', @attributes), $text);
}

sub _s_classgen {
    my ($maker, $header, $text) = @_;
    my @classes;
    
    return unless $maker;
    return $maker unless ref $maker;

    if (ref $maker eq "ARRAY") {
        foreach my $sub_maker (@$maker) {
            my @products = _s_classgen($sub_maker, $header, $text);
            push(@classes, @products) if @products;
        }
    } elsif (ref $maker eq "CODE") {
        my $product = $maker->($text, $header);
        push(@classes, $product) if $product;
    }
    return @classes;
}

1;
