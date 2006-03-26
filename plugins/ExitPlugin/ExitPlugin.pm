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

# =========================
use vars qw(
        $web $topic $user $installWeb $VERSION $pluginName
        $debug $initStage $redirectVia $noExit $preMark $postMark $marksInLink
    );

$VERSION = '$Revision$';
$pluginName = 'ExitPlugin';  # Name of this Plugin

# =========================

sub partInit
{
# Partial initialization
# stage 0:
#  uninitialized
# stage 1:
#  enough for endRenderingHandler
#  set $debug
# stage 2:
#  enough for linkreplace without link rewriting
#  load URI::URL
#  set $noExit
# stage 3:
#  enough for link rewriting
#  load URI::Escape
#  set $redirectVia, $preMark, $postMark, $marksInLink

    return if ($_[0] > 3);

    while ( $initStage < $_[0] ) {

        if ( $initStage == 0 ) {

            # Get plugin debug flag
            $debug = TWiki::Func::getPluginPreferencesFlag( "DEBUG" );

            $initStage = 1;

        } elsif ( $initStage == 1 ) {

            # Get exempt link targets
            $noExit = "(\Q".join("\E|\Q", split(/\s+/, TWiki::Func::getPluginPreferencesValue( "NOEXIT" )) )."\E)\$";
            TWiki::Func::writeDebug( "- ${pluginName} noExit = ${noExit}" ) if $debug;

            eval { require URI::URL };

            $initStage = 2;

        } elsif ( $initStage == 2 ) {

            # Get redirect page
            $redirectVia = TWiki::Func::getPluginPreferencesValue( "REDIRECTVIA" );
            $redirectVia = TWiki::Func::expandCommonVariables( $redirectVia, $topic, $web );
            TWiki::Func::writeDebug( "- ${pluginName} redirectVia = ${redirectVia}" ) if $debug;

            # Get pre- and post- marks
            $preMark = TWiki::Func::getPluginPreferencesValue( "PREMARK" ) || "";
            $preMark = TWiki::Func::expandCommonVariables( $preMark, $topic, $web );
            TWiki::Func::writeDebug( "- ${pluginName} preMark = ${preMark}" ) if $debug;
            $postMark = TWiki::Func::getPluginPreferencesValue( "POSTMARK" ) || "";
            $postMark = TWiki::Func::expandCommonVariables( $postMark, $topic, $web );
            TWiki::Func::writeDebug( "- ${pluginName} postMark = ${postMark}" ) if $debug;

            # Get marksInLink flag
            $marksInLink = TWiki::Func::getPluginPreferencesFlag( "MARKSINLINK" );

            eval { require URI::Escape };

            $initStage = 3;

        }

    }
    return;
}

# =========================
sub initPlugin
{
    ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if( $TWiki::Plugins::VERSION < 1.001 ) {
        TWiki::Func::writeWarning( "Version mismatch between $pluginName and Plugins.pm" );
        return 0;
    }

    $initStage = 0;
    partInit(1);

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- TWiki::Plugins::${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}

# =========================
sub linkexits
{
    my $url = new URI::URL( $_[0] );

    TWiki::Func::writeDebug( "- ${pluginName}::linkexits( ${url} )" ) if $debug;

    return !( $url->host() =~ /$noExit/ );
}

sub linkreplace
{
    my ( $pretags, $url, $posttags, $text, $close ) = @_;
    partInit(2);
    if ( linkexits($url) ) {
        partInit(3);
	$url = URI::Escape::uri_escape($url);
        if ( $marksInLink ) {
            return $pretags.$redirectVia.$url.$posttags.$preMark.$text.$postMark.$close;
        } else {
            return $preMark.$pretags.$redirectVia.$url.$posttags.$text.$close.$postMark;
        }
    }
    return $pretags.$url.$posttags.$text.$close;
}

sub endRenderingHandler
{
### my ( $text ) = @_;   # do not uncomment, use $_[0] instead

    TWiki::Func::writeDebug( "- ${pluginName}::endRenderingHandler( $web.$topic )" ) if $debug;

    # This handler is called by getRenderedVersion just after the line loop, that is,
    # after almost all XHTML rendering of a topic. <nop> tags are removed after this.
    $_[0] =~ s/(<a\s+[^>]*?href=")(http[s]?:\/\/[^"]+)("[^>]*>)(.*?)(<\/a>)/&linkreplace($1,$2,$3,$4,$5)/isge;
}

# =========================

1;
