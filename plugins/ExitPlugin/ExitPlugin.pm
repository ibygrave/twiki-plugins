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
use URI::Escape;

# =========================
use vars qw(
        $web $topic $user $installWeb $VERSION $pluginName
        $debug $redirectVia @noExit $preMark $postMark
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
    $redirectVia = TWiki::Func::expandCommonVariables( $redirectVia, $topic, $web );
    TWiki::Func::writeDebug( "- ${pluginName} redirectVia = ${redirectVia}" ) if $debug;

    # Get exempt link targets
    @noExit = split(/\s+/, TWiki::Func::getPluginPreferencesValue( "NOEXIT" ));
    TWiki::Func::writeDebug( "- ${pluginName} noExit = @{noExit}" ) if $debug;

    # Get pre- and post- marks
    $preMark = TWiki::Func::getPluginPreferencesValue( "PREMARK" ) || "";
    $preMark = TWiki::Func::expandCommonVariables( $preMark, $topic, $web );
    TWiki::Func::writeDebug( "- ${pluginName} preMark = ${preMark}" ) if $debug;
    $postMark = TWiki::Func::getPluginPreferencesValue( "POSTMARK" ) || "";
    $postMark = TWiki::Func::expandCommonVariables( $postMark, $topic, $web );
    TWiki::Func::writeDebug( "- ${pluginName} postMark = ${postMark}" ) if $debug;

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- TWiki::Plugins::${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}

# =========================
sub linkexits
{
    my $url = new URI::URL( $_[0] );

    TWiki::Func::writeDebug( "- ${pluginName}::linkexits( ${url} )" ) if $debug;
    # Only redirect http urls
    if ( !($url->scheme()) or !($url->scheme() =~ /http[s]?/) ) {
        TWiki::Func::writeDebug( "    No redirect for scheme." ) if $debug;
        return 0;
    }

    for my $h (@noExit) {
        if ( $url->host() =~ /$h$/ ) {
            TWiki::Func::writeDebug( "    No redirect for host ${h}." ) if $debug;
            return 0;
        }
    }

    TWiki::Func::writeDebug( "    Redirect." ) if $debug;
    return 1;
}

sub linkreplace
{
    my ( $url, $xtags, $text ) = @_;
    if ( linkexits($url) ) {
	$url = URI::Escape::uri_escape($url);
	return "${preMark}<a href=\"${redirectVia}${url}\" ${xtags}>${text}</a>${postMark}"
    }
    return "<a href=\"${url}\" ${xtags}>${text}</a>";
}

sub endRenderingHandler
{
### my ( $text ) = @_;   # do not uncomment, use $_[0] instead

    TWiki::Func::writeDebug( "- ${pluginName}::endRenderingHandler( $web.$topic )" ) if $debug;

    # This handler is called by getRenderedVersion just after the line loop, that is,
    # after almost all XHTML rendering of a topic. <nop> tags are removed after this.
    $_[0] =~ s/<a\s*href="([^"]*)"\s*([^>]*)>(.*)<\/a>/&linkreplace($1,$2,$3)/ge;
}

# =========================

1;
