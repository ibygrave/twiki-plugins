# EndNotePlugin for TWiki Collaboration Platform, http://TWiki.org/
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
package TWiki::Plugins::EndNotePlugin;

use TWiki::Plugins::EndNotePlugin::Note;
use TWiki::Func;

# =========================
use vars qw(
        $web $topic $user $installWeb $VERSION $pluginName
        $debug @notes $heading $maintopic
    );

$VERSION = '1.021';
$pluginName = 'EndNotePlugin';  # Name of this Plugin

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

    # Get endnotes heading
    $heading = TWiki::Func::getPluginPreferencesValue( "HEADING" );
    TWiki::Func::writeDebug( "- ${pluginName} heading = ${heading}" ) if $debug;

    $maintopic = "$web.$topic";
    @notes = ();

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}

# =========================
# Store a footnote, returning the note placeholder.
sub storeNote
{
    my ( $page, %params ) = @_;
    my $note = new TWiki::Plugins::EndNotePlugin::Note( $page, %params );
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

    my $noteheading = "";
    if ($heading) {
        $noteheading = "---+ " . $heading;
        if ($params{"LIST"} ne "ALL") {
            $noteheading .= " to " . $params{"LIST"};
        }
    }
    return "\n---\n\n" . $noteheading . "\n\n" . $result . "---\n\n";
}

# =========================
sub noteHandler
{
    TWiki::Func::writeDebug( "- ${pluginName}::noteHandler( $_[0], $_[1] )" ) if $debug;

    my %params = TWiki::Func::extractParameters( $_[1] );

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
    $_[0] =~ s/%(?:END|FOOT)NOTELIST%/%FOOTNOTE{LIST="$web.$topic"}%/g;
    $_[0] =~ s/{{(.*?)}}/%FOOTNOTE{"$1"}%/g;
    # Process all footnotes and footnote lists in page order.
    $_[0] =~ s/%(?:END|FOOT)NOTE{(.*?)}%/&noteHandler("$_[2].$_[1]",$1)/ge;
    # Print remaining footnotes
    $_[0] = $_[0] . printNotes($thistopic, ("LIST" => "ALL"));
}

# =========================

1;
