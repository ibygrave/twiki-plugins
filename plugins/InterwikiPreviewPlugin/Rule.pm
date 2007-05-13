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

# Rule objects store the InterWikiPreviews configuration.
# There is one rule object per rule alias.

package TWiki::Plugins::InterwikiPreviewPlugin::Rule;

use TWiki::Func;
use Cache::FileCache;

my $pluginName = "InterwikiPreviewPlugin";
my $debug = 0;

sub enableDebug
{
    $debug = 1;
}

# Forget all rules
sub reset
{
    TWiki::Func::setSessionValue($pluginName.'Rules',{});
};

# Create a new rule
sub new
{
    my ( $class, $alias, $url, $format, $info, $reload ) = @_;

    # alias: The part
    # url: The URL to retrieve data from, may contain $page
    # format: XML or JSON
    # info: The text of the information to be appended to Interwiki links,
    #       with the %INTERWIKIPREVIEWFIEL{}% fields not expanded
    # reload: Reload interval in seconds or 0

    TWiki::Func::writeDebug( "- ${pluginName}::Rule::new( $alias )" ) if $debug;

    my $cache = new Cache::FileCache( { 'cache_root' => TWiki::Func::getWorkArea( $pluginName )."/cache",
                                        'directory_umask' => '022',
                                        'namespace' => $alias } );

    my $this = {
        alias => $alias,
        format => $format,
        info => $info,
        reload => $reload,
        cache => $cache,
    };

    # Parse $url into ( $user, $pass, $host, $port, $path ) if needed by getUrl.
    if( $TWiki::Plugins::VERSION < 1.12 ) {
        # TWiki 4.0 - 4.1
        my ( $user, $pass, $host, $port, $path ) = ('', '', '', 80, '');

        if( $url =~ /http\:\/\/(.+)\:(.+)\@([^\:]+)\:([0-9]+)(\/.*)/ ) {
            ( $user, $pass, $host, $port, $path ) = ( $1, $2, $3, $4, $5 );
        } elsif( $url =~ /http\:\/\/(.+)\:(.+)\@([^\/]+)(\/.*)/ ) {
            ( $user, $pass, $host, $path ) = ( $1, $2, $3, $4 );
        } elsif( $url =~ /http\:\/\/([^\:]+)\:([0-9]+)(\/.*)/ ) {
            ( $host, $port, $path ) = ( $1, $2, $3 );
        } elsif( $url =~ /http\:\/\/([^\/]+)(\/.*)/ ) {
            ( $host, $path ) = ( $1, $2 );
        } else {
            TWiki::Func::writeDebug( "- ${pluginName}::Rule::new failed to parse url $url" ) if $debug;
            TWiki::Func::writeWarning( "Failed to parse url $url" );
            return undef();
        }

        $this->{user} = $user;
        $this->{pass} = $pass;
        $this->{host} = $host;
        $this->{port} = $port;
        $this->{path} = $path;
    } else {
        # TWiki 4.2
        $this->{url} = $url;
    }

    TWiki::Func::getSessionValue($pluginName.'Rules')->{$alias} = bless( $this, $class );

    return $this;
}

sub get
{
    # Find the Rule object for the give alias.
    my ( $class, $alias ) = @_;
    return TWiki::Func::getSessionValue($pluginName.'Rules')->{$alias};
}

sub restHandler
{
    # Handle a REST query of the form: rest/$pluginName/$alias?page=$page
    # Find the rule for $alias,
    # expand its URL for $page
    # and retrieve the contents of that URL
    my ($this, $session, $subject, $verb) = @_;

    my $query = TWiki::Func::getCgiQuery();
    return unless $query;

    my $httpCacheControl = TWiki::Func::getPreferencesFlag("INTERWIKIPREVIEWPLUGIN_HTTP_CACHE_CONTROL" );

    # Extract $page from cgiQuery
    my $page = $query->param('page');

    TWiki::Func::writeDebug( "- ${pluginName}::Rule::restHandler($subject,$verb,$page)" ) if $debug;

    # Check for 'Cache-control: no-cache' in the HTTP request
    unless ( $httpCacheControl &&
             $query->http('Cache-control') =~ /no-cache/o ) {
        # Look for cached response
        my $text = $this->{cache}->get( $page );
        if ( defined $text ) {
            if ( $debug ) {
                my $expiry = $this->{cache}->get_object( $page )->get_expires_at - time();
                TWiki::Func::writeDebug( "- ${pluginName}::Rule::restHandler ${page} cached for ${expiry}s" );
            }
            $text =~ s/^(.*?\n)\n(.*)/$2/s;
            if( $1 =~ /content\-type\:\s*([^\n]*)/ois ) {
                TWiki::Func::setSessionValue($pluginName.'ContentType',$1);
            }
            return $text;
        }
    }
    my $path = "";
    my $url = "";
    if( $TWiki::Plugins::VERSION < 1.12 ) {
        # TWiki 4.0 - 4.1
        $path = $this->{path};
        if ( ! ($path =~ s/\$page/$page/go) ) {
            # No $page in URL to expand, append $page instead
            $path = $path . $page;
        }
    } else {
        # TWiki 4.2
        $url = $this->{url};
        if ( ! ($url =~ s/\$page/$page/go) ) {
            # No $page in URL to expand, append $page instead
            $url = $url . $page;
        }
    }
    # This conditional code c'n'h from BlackListPlugin,
    # and untested except on TWiki 4.0
    # TODO: extract URL scheme for TWiki 4.1
    # TODO: check Content-Type header processing for TWiki 4.2
    $text = '';
    if( $TWiki::Plugins::VERSION < 1.11 ) {
        # TWiki 4.0
        $text = $session->{net}->getUrl( $this->{host},
                                         $this->{port},
                                         $path,
                                         $this->{user},
                                         $this->{pass} );
    } elsif( $TWiki::Plugins::VERSION < 1.12 ) {
        # TWiki 4.1
        $text = $session->{net}->getUrl( 'http',
                                         $this->{host},
                                         $this->{port},
                                         $path,
                                         $this->{user},
                                         $this->{pass} );
    } else {
        # TWiki 4.2
        my $response = TWiki::Func::getExternalResource( $url );
        if( $response->is_error() ) {
            my $msg = "Code " . $response->code() . ": " . $response->message();
            $msg =~ s/[\n\r]/ /gos;
            TWiki::Func::writeDebug( "- ${pluginName}::Rule ERROR: Can't read $url ($msg)" ) if $debug;
            return "#ERROR: Can't read $url ($msg)";
        } else {
            $text = $response->content();
            $headerAndContent = 0;
        }
    }
    my $expiry = $this->{reload};
    if ( $expiry == 0 ) {
        $expiry = TWiki::Func::getPreferencesValue("INTERWIKIPREVIEWPLUGIN_DEFAULT_CACHE_EXPIRY");
    }
    $text =~ s/\r\n/\n/gos;
    $text =~ s/\r/\n/gos;

    # Check for 'Cache-control: no-store' in the HTTP request
    unless ( $httpCacheControl &&
             $query->http('Cache-control') =~ /no-store/o ) {
        $this->{cache}->set( $page, $text, $expiry );
    }
    $text =~ s/^(.*?\n)\n(.*)/$2/s;
    if( $1 =~ /content\-type\:\s*([^\n]*)/ois ) {
        TWiki::Func::setSessionValue($pluginName.'ContentType',$1);
    }
    return $text;
}

# end of class Rule

1;
