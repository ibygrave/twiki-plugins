# FootNotePlugin for TWiki Collaboration Platform, http://TWiki.org/
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

# =========================
package TWiki::Plugins::FootNotePlugin;

use TWiki::Plugins::FootNotePlugin::Note;
use TWiki::Func;

# =========================
use vars qw(
        $web $topic $user $installWeb $VERSION $pluginName
        $debug @notes $header $footer $maintopic
    );

$VERSION = '1.021';
$pluginName = 'FootNotePlugin';  # Name of this Plugin

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

    # Get footnotes header
    $header = TWiki::Func::getPluginPreferencesValue( "HEADER" );
    TWiki::Func::writeDebug( "- ${pluginName} header = ${header}" ) if $debug;

    # Get footnotes footer
    $footer = TWiki::Func::getPluginPreferencesValue( "FOOTER" );
    TWiki::Func::writeDebug( "- ${pluginName} footer = ${footer}" ) if $debug;

    $maintopic = "$web.$topic";
    @notes = ();
    TWiki::Plugins::FootNotePlugin::Note::reset();

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}

# =========================
# Store a footnote, returning the note placeholder.
sub storeNote
{
    my ( $page, %params ) = @_;
    my $note = new TWiki::Plugins::FootNotePlugin::Note( $page, %params );
    push( @notes, $note );
    return $note->text();
}

# =========================
# Print a table of footnotes for the given page.
sub printNotes
{
    my ( $page, %params ) = @_;
    return "" if ($page ne $maintopic);
    my $result = "";

    foreach $note (@notes) {
        if (($params{"LIST"} eq "ALL") || ($params{"LIST"} eq $note->{"page"})) {
            $result .= $note->note();
        }
    }

    return "" if ($result eq "");

    return "\n\n$header\n\n$result\n\n$footer\n\n";
}

# =========================
sub noteHandler
{
    TWiki::Func::writeDebug( "- ${pluginName}::noteHandler( $_[0], $_[1] )" ) if $debug;

    my %params = TWiki::Func::extractParameters( $_[1] );

    $params{"_DEFAULT"} = $_[2] if ( $_[2] );

    return storeNote($_[0],%params) if (exists $params{"_DEFAULT"});

    return printNotes($_[0],%params) if (exists $params{"LIST"});

    return "";
}

# =========================
sub commonTagsHandler
{
### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead

    TWiki::Func::writeDebug( "- ${pluginName}::commonTagsHandler( $_[1], $_[2] )" ) if $debug;
    my $thistopic = "$_[2].$_[1]";

    # Translate all markup into the %FOOTNOTE{...}% form
    $_[0] =~ s/%FOOTNOTELIST%/%STARTFOOTNOTE{LIST="$web.$topic"}%%ENDFOOTNOTE%/g;
    $_[0] =~ s/%FOOTNOTE{(.*?)}%/%STARTFOOTNOTE{$1}%%ENDFOOTNOTE%/sg;
    $_[0] =~ s/{{/%STARTFOOTNOTE{}%/g;
    $_[0] =~ s/}}/%ENDFOOTNOTE%/g;
    # Process all footnotes and footnote lists in page order.
    $_[0] =~ s/%STARTFOOTNOTE{(.*?)}%(.*?)%ENDFOOTNOTE%/&noteHandler("$_[2].$_[1]",$1,$2)/sge;
    # Print remaining footnotes
    $_[0] = $_[0] . printNotes($thistopic, ("LIST" => "ALL"));
}

# =========================

1;
