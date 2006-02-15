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
# Embed protected content in public pages.
#
# TBD:
#   1. handle edit restrictions.

# =========================
package TWiki::Plugins::SnibPlugin;

# =========================
use vars qw(
        $web $topic $user $installWeb $VERSION $pluginName
        $debug
    );

$VERSION = '1.001';
$pluginName = 'SnibPlugin';  # Name of this Plugin

# =========================
sub initPlugin
{
    ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if( $TWiki::Plugins::VERSION < 1.021 ) {
        TWiki::Func::writeWarning( "Version mismatch between $pluginName and Plugins.pm" );
        return 0;
    }

    # Get plugin debug flag
    $debug = TWiki::Func::getPluginPreferencesFlag( "DEBUG" );

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- TWiki::Plugins::${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}


# =========================
sub handleSnibCommonTag
{
    my ( $snibParams, $snibText ) = @_;
    my %params = TWiki::Func::extractParameters( $snibParams );
    my $permsText = "";
    my $user = TWiki::Func::getWikiUserName();

    TWiki::Func::writeDebug( "- ${pluginName}::handleSnibCommonTag( $snibParams )" ) if $debug;
    TWiki::Func::writeDebug( "- \$user = ${user}" ) if $debug;

    my $perm = $params{"ALLOWVIEW"};
    if (defined($perm)) {
        $permsText = $permsText."   * Set ALLOWTOPICVIEW = ${perm}\n";
    }

    $perm = $params{"DENYVIEW"};
    if (defined($perm)) {
        $permsText = $permsText."   * Set DENYTOPICVIEW = ${perm}\n";
    }

    TWiki::Func::writeDebug( "- \$permsText = \"${permsText}\"" ) if $debug;
    if (TWiki::Func::checkAccessPermission( "VIEW",
                                            $user,
                                            $permsText,
                                            $topic,
                                            $web )) {
        return $2;
    }

    return $params{"ALT"};
}

sub commonTagsHandler
{
### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead

    TWiki::Func::writeDebug( "- ${pluginName}::commonTagsHandler( $_[2].$_[1] )" ) if $debug;

    # This is the place to define customized tags and variables
    # Called by TWiki::handleCommonTags, after %INCLUDE:"..."%

    $_[0] =~ s/%STARTSNIB{(.*?)}%(.*?)%ENDSNIB%/&handleSnibCommonTag($1,$2)/sge;
}

# =========================
sub DISABLE_beforeEditHandler
{
### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead

    TWiki::Func::writeDebug( "- ${pluginName}::beforeEditHandler( $_[2].$_[1] )" ) if $debug;

    # This handler is called by the edit script just before presenting the edit text
    # in the edit box. Use it to process the text before editing.
    # New hook in TWiki::Plugins $VERSION = '1.010'

    # TBD: Replace SNIB tags which the user isn't authorized
    #   to edit with opaque placeholders, storing their contents.
}

# =========================
sub afterEditHandler
{
### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead

    TWiki::Func::writeDebug( "- ${pluginName}::afterEditHandler( $_[2].$_[1] )" ) if $debug;

    # This handler is called by the preview script just before presenting the text.
    # New hook in TWiki::Plugins $VERSION = '1.010'

    # TBD: Replace opaque placeholders with their stored contents.
    #   Throw an oops if any placeholders have been deleted, (or reordered?)

    # Text can get into the topic without being seen by this function.
    # For example, via CommentPlugin.
}

# =========================

1;
