# InterwikiPreviewPlugin for TWiki Collaboration Platform, http://TWiki.org/
#
# Copyright (C) 2007 Ian Bygrave, ian@bygrave.me.uk
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at 
# http://www.gnu.org/copyleft/gpl.html

# A single AJAX query.

package TWiki::Plugins::InterwikiPreviewPlugin::Query;

use TWiki::Func;
use XML::Parser;

my $pluginName = "InterwikiPreviewPlugin";
my %queries = ();
my $next_field = 1;
my $debug = 0;

my %extractors = ( XML => sub {
    my ($text, @fields)=@_;
    my %result = ();

    # Discard leading HTTP headers
    $text =~ /.*?(<\?xml.*)$/s;
    $text = $1;

    my $p = new XML::Parser();

    $p->setHandlers(Char => sub {
        my ($p, $s) = @_;
        my $e = $p->current_element();
        if ( grep {/^$e$/} @fields ) {
            $result{$e} .= $s;
        }
    }, End => sub {
        my ($p, $e) = @_;
        @fields = grep {!/^$e$/} @fields;
        if ($#fields == -1) {
            $p->finish();
        }
    } );

    # Catch XML parsing errors.
    eval {
        $p->parse($text);
    };
    if ($@) {
        TWiki::Func::writeDebug( "- ${pluginName}::Query::extractors{XML} parsing failed: $@" );
        return ();
    }

    return %result;
} );

sub enableDebug
{
    TWiki::Func::writeDebug( "- ${pluginName}::Query::enableDebug" );
    $debug = 1;
}

sub reset
{
    TWiki::Func::writeDebug( "- ${pluginName}::Query::reset()" ) if $debug;
    %queries = ();
    $next_field = 1;
}

sub new
{
    my ( $class, $rule, $page ) = @_;

    my $queryid = $rule->{alias} . ":" . $page;

    TWiki::Func::writeDebug( "- ${pluginName}::Query::new($queryid)" ) if $debug;

    if (exists $queries{$queryid}) {
        TWiki::Func::writeDebug( "- ${pluginName}::Query::new reusing '$queryid')" ) if $debug;
        return $queries{$queryid};
    }

    my $this = {
        rule => $rule,
        page => $page,
        fields => {},
        loaddelay => 0,
    };

    # Prepare cache if we can extract fields from it
    if ( exists $extractors{$this->{rule}->{format}} ) {
        TWiki::Func::writeDebug( "- ${pluginName}::Query::new extractable" ) if $debug;
        my $cache = $rule->{cache}->get_object( $page );
        if ( defined $cache ) {
            $this->{cache} = $cache->get_data();
            # Delay this query until the cache expires.
            $this->{loaddelay} = $cache->get_expires_at() - time();
            TWiki::Func::writeDebug( "- ${pluginName}::Query::new cached" ) if $debug;
        }
    }

    $queries{$queryid} = bless( $this, $class );

    return $this;
}

sub field
{
    my ( $this, $args ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::Query::field($args)" ) if $debug;

    my %params = TWiki::Func::extractParameters( $args );

    my $filler = $params{"_DEFAULT"} || '-';
    if ( exists $params{"width"} ) {
        $filler = $filler x $params{"width"};
    }

    if ( exists $params{"source"} ) {
        my $cssclass = "iwppFieldEmpty";
        my $field_id = "iwppf${next_field}";
        $next_field = $next_field + 1;
        $this->{"fields"}->{$field_id} = $params{"source"};

        # Populate field with cache data
        if ( exists $this->{cache} ) {
            # Extract this field from the cached data
            my %extracted = &{$extractors{$this->{rule}->{format}}}( $this->{cache}, $params{"source"} );
            if ( exists $extracted{$params{"source"}} ) {
                $cssclass = "iwppFieldFull";
                $filler = $extracted{$params{"source"}};
                # encode HTML/TML special characters
                $filler =~ s/[[\x01-\x09\x0b\x0c\x0e-\x1f"%&'*<=>@[_\|]/'&#'.ord($&).';'/goe;
                TWiki::Func::writeDebug( "- ${pluginName}::Query::field '${filler}' extracted from cache" ) if $debug;
            } else {
                # Our extractor failed.
                # Give browser javascript a chance to extracting this field.
                $this->{loaddelay} = 0;
            }
        }

        return "<span id=\"${field_id}\" class=\"${cssclass}\">${filler}</span>";
    }
    return $filler;
}

sub script
{
    my ( $this ) = @_;

    my $format = $this->{"rule"}->{"format"};
    my $url = TWiki::Func::getScriptUrl($pluginName,
                                        $this->{"rule"}->{"alias"},
                                        'rest')
        . "?page=" . $this->{"page"};
    my $reload = $this->{"rule"}->{"reload"};

    TWiki::Func::writeDebug( "- ${pluginName}::Query::script $format $url $reload" ) if $debug;

    my $text = "new iwppq_${format}('${url}', ${reload}, [" .
        join( ',' ,
              map( "['" . $_ . "','" . $this->{"fields"}->{$_} . "']" ,
                   keys %{$this->{"fields"}} ) ) . "]).go();\n";

    if ($this->{loaddelay} > 0) {
        $text = "callLater(" . $this->{loaddelay} . ", function() {\n" . $text . "} );\n"
    }

    return $text;
}

sub scripts
{
    my ( $class ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::Query::scripts" ) if $debug;

    my $text = "";

    foreach (values %queries) {
        $text = $text . $_->script();
    }

    if ($text) {
        $text = "<script type=\"text/javascript\">\n<!--<noautolink><pre>InterwikiPreviewPlugin fill fields\n" .
            $text .
            "//InterwikiPreviewPlugin fill fields</pre></noautolink>-->;\n</script>\n";
    }

    %queries = ();

    return $text;
}

# end of class Query

1;
