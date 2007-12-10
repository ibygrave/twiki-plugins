# Plugin for TWiki Collaboration Platform, http://TWiki.org/
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
#
# =========================
#
# This plugin adds metadata to pages

# =========================
package TWiki::Plugins::KeyWordPlugin;

# =========================
use vars qw(
        $web $topic $user $installWeb $VERSION $pluginName
        $debug $disable
    );

$VERSION = '$Revision: 198 $';
$pluginName = 'KeyWordPlugin';  # Name of this Plugin

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

    # Get disable flag
    $disable = TWiki::Func::getPreferencesFlag( "KEYWORDPLUGIN_DISABLEKEYWORDPLUGIN" ) || TWiki::Func::getPreferencesFlag( "DISABLEKEYWORDPLUGIN" );
    TWiki::Func::writeDebug( "- ${pluginName} disable = ${disable}" ) if $debug;
    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- TWiki::Plugins::${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}

# =========================

$TWikiCompatibility{endRenderingHandler} = 1.1;
sub endRenderingHandler
{
    &postRenderingHandler;
}

sub postRenderingHandler {
### my ( $text ) = @_;   # do not uncomment, use $_[0] instead
    my @metas = ("description", "keywords");
    my $content;

    if ( $disable ) {
        TWiki::Func::writeDebug( "- ${pluginName}::endRenderingHandler(disabled by DISABLEKEYWORDPLUGIN)" ) if $debug;
        return;
    }
    TWiki::Func::writeDebug( "- ${pluginName}::endRenderingHandler( $web.$topic )" ) if $debug;

    $content = $web . ', ' . $topic;
    $content =~ s/([a-z])([A-Z])/$1 $2/g;

    foreach my $meta (@metas) {
        TWiki::Func::addToHEAD( "KeyWordPlugin.${meta}",
                                "\n<meta name=\"${meta}\" " .
                                "content=\"${content}\" />\n" );
    }
}

# =========================

1;
