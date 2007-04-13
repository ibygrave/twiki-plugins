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

# A single rule.

package TWiki::Plugins::InterwikiPreviewPlugin::Rule;

use TWiki::Func;

my $pluginName = "InterwikiPreviewPlugin::Rule";
my $debug = 0;
my %rules = ();

sub enableDebug
{
    TWiki::Func::writeDebug( "- ${pluginName}::enableDebug" );
    $debug = 1;
}

sub reset
{
    TWiki::Func::writeDebug( "- ${pluginName}::reset" ) if $debug;
    %rules = ();
};

sub new
{
    my ( $class, $alias, $url, $format, $info, $reload ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::new( $alias, $url, $info, $reload )" ) if $debug;

    my $this = {
        alias => $alias,
        format => $format,
        info => $info,
        reload => $reload,
    };

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
            TWiki::Func::writeDebug( "- ${pluginName}::new failed to parse url $url" ) if $debug;
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

    $rules{$alias} = bless( $this, $class );

    return $this;
}

sub get
{
    my ( $class, $alias ) = @_;
    TWiki::Func::writeDebug( "- ${pluginName}::get( $alias )" ) if $debug;
    return $rules{$alias};
}

sub restHandler
{
    my ($this, $session, $subject, $verb) = @_;
    TWiki::Func::writeDebug( "- ${pluginName}::restHandler($subject,$verb)" ) if $debug;
    my $page = $session->{cgiQuery}->param('page');
    my $path = "";
    my $url = "";
    if( $TWiki::Plugins::VERSION < 1.12 ) {
        # TWiki 4.0 - 4.1
        $path = $this->{path};
        if ( ! ($path =~ s/\$page/$page/go) ) {
            $path = $path . $page;
        }
    } else {
        # TWiki 4.2
        $url = $this->{url};
        if ( ! ($url =~ s/\$page/$page/go) ) {
            $url = $url . $page;
        }
    }
    # This conditional code c'n'h from BlackListPlugin,
    # and untested except on TWiki 4.0
    # TODO: extract URL scheme for TWiki 4.1
    # TODO: check Content-Type header processing for TWiki 4.2
    my $text = '';
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
            TWiki::Func::writeDebug( "- $pluginName ERROR: Can't read $url ($msg)" );
            return "#ERROR: Can't read $url ($msg)";
        } else {
            $text = $response->content();
            $headerAndContent = 0;
        }
    }
    return $text;
}

# end of class Rule

1;
