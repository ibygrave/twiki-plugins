# Plugin for TWiki Collaboration Platform, http://TWiki.org/
#
# Copyright (C) 2006 Ian Bygrave, ian@bygrave.me.uk
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
#
# =========================
#
# This plugin redirects links to external sites via a page of your choice.

# =========================
package TWiki::Plugins::ExitPlugin;

use URI::URL;

# =========================
use vars qw(
        $web $topic $user $installWeb $VERSION $pluginName
        $debug $redirectVia $noExit
    );

$VERSION = '1.001';
$pluginName = 'ExitPlugin';  # Name of this Plugin

# =========================
sub initPlugin
{
    ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if( $TWiki::Plugins::VERSION < 1.001 ) {
        TWiki::Func::writeWarning( "Version mismatch between $pluginName and Plugins.pm" );
        return 0;
    }

    # Get plugin debug flag
    $debug = TWiki::Func::getPluginPreferencesFlag( "DEBUG" );

    # Get redirect page
    $redirectVia = TWiki::Func::getPluginPreferencesValue( "REDIRECTVIA" );
    TWiki::Func::writeDebug( "- ${pluginName} redirectVia = ${redirectVia}" ) if $debug;

    # Get exempt link targets
    $noExit = TWiki::Func::getPluginPreferencesValue( "NOEXIT" );
    TWiki::Func::writeDebug( "- ${pluginName} noExit = ${noExit}" ) if $debug;

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- TWiki::Plugins::${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}

# =========================
sub linkreplace
{
    my $url = new URI::URL( $_[0] );
    # Only redirect http urls
    if ( $url->scheme() =~ /http[s]?/ ) {
        if ( !( $url->host() =~ /$noExit$/ ) ) {
            return "<a href=\"${redirectVia}${url}\""
        }
    }
    return "<a href=\"${url}\"";
}

sub endRenderingHandler
{
### my ( $text ) = @_;   # do not uncomment, use $_[0] instead

    TWiki::Func::writeDebug( "- ${pluginName}::endRenderingHandler( $web.$topic )" ) if $debug;

    # This handler is called by getRenderedVersion just after the line loop, that is,
    # after almost all XHTML rendering of a topic. <nop> tags are removed after this.
    $_[0] =~ s/<a\s*href="([^"]*)"/linkreplace $1/ge;
}

# =========================

1;
