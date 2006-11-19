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
        $debug @editStore
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
    $debug = 1;

    # Create an empty edit store.
    @editStore = ();

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- TWiki::Plugins::${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}


# =========================
sub permsText
{
    my ( %snibArgs ) = @_;
    my %permsMap =
        (
         "ALLOWVIEW" => "ALLOWTOPICVIEW",
         "DENYVIEW" => "DENYTOPICVIEW",
         "ALLOWCHANGE" => "ALLOWTOPICCHANGE",
         "DENYCHANGE" => "DENYTOPICCHANGE",
         );
    my $text = "";
    foreach my $snibArg (keys(%snibArgs))
    {
        if (defined($permsMap{$snibArg}))
        {
            $text = $text."   * Set ${permsMap{$snibArg}} = ${snibArgs{$snibArg}}\n";
        }
    }
    TWiki::Func::writeDebug( "- \$text = \"${text}\"" ) if $debug;
    return $text;
}

# =========================
sub handleSnibCommonTag
{
    my ( $snibParams, $snibText ) = @_;
    my %params = TWiki::Func::extractParameters( $snibParams );
    my $user = TWiki::Func::getWikiUserName();

    TWiki::Func::writeDebug( "- ${pluginName}::handleSnibCommonTag( $snibParams )" ) if $debug;
    TWiki::Func::writeDebug( "- \$user = ${user}" ) if $debug;

    if (TWiki::Func::checkAccessPermission( "VIEW",
                                            $user,
                                            permsText(%params),
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
sub storeAddSnib
{
    my ( $args, $text ) = @_;
    TWiki::Func::writeDebug( "- ${pluginName}::storeAddSnib( ${args}, ${text} )" ) if $debug;

    my $rec = {
        'args' => $args,
        'text' => $text,
    };
    @editStore = (@editStore, $rec);
    return $#editStore;
}

sub storeRetrieveSnib
{
    TWiki::Func::writeDebug( "- ${pluginName}::storeRetrieveSnib( $_[0] )" ) if $debug;

    my $rec = $editStore[$_[0]];
    # TBD: Mark retrieval, and fail on duplicate retrieval.
    return ($rec{'args'},$rec{'text'});
}

# TBD: function to check all snibs have been retrived from editStore.

# =========================
sub handleSnibPreEdit
{
    my ( $snibParams, $snibText ) = @_;
    my %params = TWiki::Func::extractParameters( $snibParams );
    my $user = TWiki::Func::getWikiUserName();

    TWiki::Func::writeDebug( "- ${pluginName}::handleSnibPreEdit( $snibParams )" ) if $debug;
    TWiki::Func::writeDebug( "- \$user = ${user}" ) if $debug;

    my $editPermsText = permsText( %params );

    if (!TWiki::Func::checkAccessPermission( "VIEW",
                                             $user,
                                             $editPermsText,
                                             $topic,
                                             $web ) &&
        !TWiki::Func::checkAccessPermission( "CHANGE",
                                             $user,
                                             $editPermsText,
                                             $topic,
                                             $web )) {
        return "%STOREDSNIB{${storeAddSnib($snibParams, $snibText )}}%";
    }
    return "%STARTSNIB{${snibParams}}${snibText}%ENDSNIB%";
}

sub beforeEditHandler
{
### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead

    TWiki::Func::writeDebug( "- ${pluginName}::beforeEditHandler( $_[2].$_[1] )" ) if $debug;

    # This handler is called by the edit script just before presenting the edit text
    # in the edit box. Use it to process the text before editing.
    # New hook in TWiki::Plugins $VERSION = '1.010'

    # Replace SNIB tags which the user isn't authorized
    # to edit with opaque placeholders, storing their contents.
    $_[0] =~ s/%STARTSNIB{(.*?)}%(.*?)%ENDSNIB%/&handleSnibPreEdit($1,$2)/sge;
}

# =========================
sub handleSnibPostEdit
{
    my ( $args, $text ) = storeRetrieveSnib($_[0]);
    return "%STARTSNIB{${args}}%${text}%ENDSNIB%";
}

sub afterEditHandler
{
### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead

    TWiki::Func::writeDebug( "- ${pluginName}::afterEditHandler( $_[2].$_[1] )" ) if $debug;

    # This handler is called by the preview script just before presenting the text.
    # New hook in TWiki::Plugins $VERSION = '1.010'

    # Replace opaque placeholders with their stored contents.
    $_[0] =~ s/%STOREDSNIB{(.*?)}%/&handleSnibPostEdit($1)/sge;

    # Text can get into the topic without being seen by this function.
    # For example, via CommentPlugin.
}

# =========================
sub DISABLE_beforeSaveHandler
{
### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead

    TWiki::Func::writeDebug( "- ${pluginName}::beforeSaveHandler( $_[2].$_[1] )" ) if $debug;

    # This handler is called by TWiki::Store::saveTopic just before the save action.
    # New hook in TWiki::Plugins $VERSION = '1.010'

    # TBD: Throw an oops if any placeholders have been deleted, (or reordered?)
}

# =========================

1;
