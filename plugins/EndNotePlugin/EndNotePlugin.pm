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

# =========================
use vars qw(
        $web $topic $user $installWeb $VERSION $pluginName
        $debug @endnotes %endnote_nums $heading $firstnote $maintopic
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
    $firstnote = 1;
    @endnotes = ();
    %endnote_nums = ();

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}


# =========================
sub storeEndNote
{
    my ( $topic, %params ) = @_;
    my $text = $params{"_DEFAULT"};
    my $i;
    my $anchor = "";
    if (exists $endnote_nums{$text}) {
        $i = $endnote_nums{$text};
        TWiki::Func::writeDebug( "- ${pluginName}::storeEndNote( $topic, $text ) exists as $i" ) if $debug;
    } else {
        $i = @endnotes + $firstnote;
        @endnotes = (@endnotes, $text);
        $endnote_nums{$_[0]} = $i;
        $anchor = "<a name=\"EndNote${i}text\"></a>";
        TWiki::Func::writeDebug( "- ${pluginName}::storeEndNote( $topic, $text ) stored as $i" ) if $debug;
    }
    return "${anchor}<sup>[[#EndNote${i}note][${i}]]</sup>";
}

# =========================
sub printEndNotes
{
    my ( $topic, %params ) = @_;
    my $c = @endnotes;
    TWiki::Func::writeDebug( "- ${pluginName}::printEndNotes( $topic ) endnotes = $c" ) if $debug;
    return "" if ($c == 0);
    return "" if !($topic eq $maintopic);
    my $result = "\n---\n\n";
    my $i = 0;
    my $n;
    if ($result) {
        $result = $result . "---+ $heading $topic\n";
    }
    while ($i < $c) {
        $n = $i + $firstnote;
        $result = $result . "\n#EndNote${n}note [[#EndNote${n}text][ *${n}:* ]] ${endnotes[$i]}\n\n"; 
        $i = $i + 1;
    }
    $result = $result . "---\n\n";
    $firstnote = $firstnote + @endnotes;
    @endnotes = ();
    return $result;
}

sub noteHandler
{
    TWiki::Func::writeDebug( "- ${pluginName}::noteHandler( $_[0], $_[1] )" ) if $debug;

    my %params = TWiki::Func::extractParameters( $_[1] );

    return storeEndNote($_[0],%params) if (exists $params{"_DEFAULT"});

    return printEndNotes($_[0],%params) if (exists $params{"LIST"});
}

# =========================
sub commonTagsHandler
{
### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead

    TWiki::Func::writeDebug( "- ${pluginName}::commonTagsHandler( $_[1], $_[2] )" ) if $debug;
    my $thistopic = "$_[2].$_[1]";

    # Translate all markup into the %FOOTNOTE{...}% form
    $_[0] =~ s/%(?:END|FOOT)NOTELIST%/%FOOTNOTE{LIST="yes"}%/g;
    $_[0] =~ s/{{(.*?)}}/%FOOTNOTE{"$1"}%/g;
    # Process all footnotes and footnote lists in page order.
    $_[0] =~ s/%(?:END|FOOT)NOTE{(.*?)}%/&noteHandler("$_[2].$_[1]",$1)/ge;
    # Print remaining footnotes
    $_[0] = $_[0] . printEndNotes($thistopic,("LIST" => "yes"));
}

# =========================

1;
