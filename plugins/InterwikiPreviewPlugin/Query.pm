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

my $pluginName = "InterwikiPreviewPlugin";
my $debug = 0;

my %extractors = ();

eval {require XML::Parser};
unless ($@) {
    import XML::Parser;
    $extractors{XML} = sub {
        my ($text, @fields)=@_;
        my %result = ();

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
        eval {$p->parse($text)};
        if ($@) {
            return ();
        }

        return %result;
    };
}

eval {require JSON};
unless ($@) {
    import JSON;
    $extractors{JSON} = sub {
        my ($text, @fields)=@_;
        my %result = ();

        eval {
            my $json = new JSON(skipinvalid => 1);
            my $obj = $json->jsonToObj($text);

            while (($key,$value) = each(%$obj)) {
                if ( grep {/^$key$/} @fields ) {
                    $result{$key} = $value;
                }
            }
        };
        return %result;
    };
}

sub enableDebug
{
    $debug = 1;
}

sub reset
{
    my $cgi = TWiki::Func::getCgiQuery();
    return unless $cgi;
    $cgi->param( -name=>$pluginName.'Queries', -value=>{});
    $cgi->param( -name=>$pluginName.'NextField', -value=>1);
}

sub new
{
    my ( $class, $rule, $page ) = @_;

    my $queryid = $rule->{alias} . ":" . $page;
 
    my $cgi = TWiki::Func::getCgiQuery();
    return unless $cgi;

    my $queries = $cgi->param($pluginName.'Queries');
    if (exists $queries->{$queryid}) {
        TWiki::Func::writeDebug( "- ${pluginName}::Query::new reusing '$queryid')" ) if $debug;
        return $queries->{$queryid};
    }

    TWiki::Func::writeDebug( "- ${pluginName}::Query::new($queryid)" ) if $debug;

    my $this = {
        rule => $rule,
        page => $page,
        fields => {},
        loaddelay => 0,
    };

    # Check for 'Cache-control: no-cache' in the HTTP request.
    my $cachecontrol =
        !($cgi->http('Cache-control')  &&
          $cgi->http('Cache-control') =~ /no-cache/o &&
          TWiki::Func::getPreferencesFlag("INTERWIKIPREVIEWPLUGIN_HTTP_CACHE_CONTROL" ) );

    # Can we extract fields from cached data?
    my $extractable = ( exists $extractors{$this->{rule}->{format}} );

    # Prepare cache
    if ( $cachecontrol && $extractable ) {
        my $cache = $rule->{cache}->get_object( $page );
        if ( defined $cache ) {
            $this->{cache} = $cache->get_data();
            # Discard leading HTTP headers
            $this->{cache} =~ s/\r\n/\n/gos;
            $this->{cache} =~ s/\r/\n/gos;
            $this->{cache} =~ s/^(.*?\n)\n(.*)/$2/s;
            # Delay this query until the cache expires.
            $this->{loaddelay} = $cache->get_expires_at() - time();
        }
    }

    $queries->{$queryid} = bless( $this, $class );

    TWiki::Func::writeDebug( "- ${pluginName}::Query::new(${queryid}) cachecontrol=${cachecontrol} extractable=${extractable}" . ((defined $this->{cache}) ? " cached" : "") ) if $debug;

    return $this;
}

sub field
{
    my ( $this, $args ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::Query::field($args)" ) if $debug;

    my %params = TWiki::Func::extractParameters( $args );

    my $cgi = TWiki::Func::getCgiQuery();
    return unless $cgi;

    my $filler = $params{"_DEFAULT"} || '-';
    if ( exists $params{"width"} ) {
        $filler = $filler x $params{"width"};
    }

    if ( exists $params{"source"} ) {
        my $cssclass = "iwppFieldEmpty";
        my $next_field = $cgi->param($pluginName.'NextField');
        my $field_id = "iwppf${next_field}";
        $cgi->param( -name=>$pluginName.'NextField', -value=>$next_field+1 );
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

    my $cgi = TWiki::Func::getCgiQuery();
    return unless $cgi;

    foreach (values %{$cgi->param($pluginName.'Queries')}) {
        $text = $text . $_->script();
    }

    if ($text) {
        $text = "<script type=\"text/javascript\">\n<!--<noautolink><pre>InterwikiPreviewPlugin fill fields\n" .
            $text .
            "//InterwikiPreviewPlugin fill fields</pre></noautolink>-->;\n</script>\n";
    }

    $cgi->param( -name=>$pluginName.'Queries', -value=>{});

    return $text;
}

# end of class Query

1;
