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
        $debug @endnotes %endnote_nums $heading $firstnote
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

    $firstnote = 1;

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- TWiki::Plugins::${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}


# =========================
sub storeEndNote
{
    my ( %params ) = @_;
    my $text = $params{"_DEFAULT"};
    my $i;
    my $anchor = "";
    if (exists $endnote_nums{$text}) {
        $i = $endnote_nums{$text};
    } else {
        $i = @endnotes + $firstnote;
        @endnotes = (@endnotes, $text);
        $endnote_nums{$_[0]} = $i;
        $anchor = "<a name=\"EndNote${i}text\"></a>"
    }
    return "${anchor}<sup>[[#EndNote${i}note][${i}]]</sup>";
}

# =========================
sub printEndNotes
{
    my ( %params ) = @_;
    my $c = @endnotes;
    return "" if ($c == 0);
    my $result = "\n---\n\n";
    my $i = 0;
    my $n;
    if ($result) {
        $result = $result . "---+ $heading $params{LISTTOPIC}\n";
    }
    while ($i < $c) {
        $n = $i + $firstnote;
        $result = $result . "\n#EndNote${n}note [[#EndNote${n}text][ *${n}:* ]] ${endnotes[$i]}\n\n"; 
        $i = $i + 1;
    }
    $result = $result . "---\n\n";
    $firstnote = @endnotes + 1;
    @endnotes = ();
    %endnote_nums = ();
    return $result;
}

sub noteHandler
{
    TWiki::Func::writeDebug( "- ${pluginName}::noteHandler( $_[0] )" ) if $debug;

    my %params = TWiki::Func::extractParameters( $_[0] );

    return storeEndNote(%params) if (exists $params{"_DEFAULT"});

    return printEndNotes(%params) if (exists $params{"LISTTOPIC"});
}

# =========================
sub commonTagsHandler
{
### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead

    TWiki::Func::writeDebug( "- ${pluginName}::commonTagsHandler( $_[1], $_[2] )" ) if $debug;
    @endnotes = ();
    %endnote_nums = ();
    # Translate all markup into the %FOOTNOTE{...}% form
    $_[0] =~ s/%(?:END|FOOT)NOTELIST%/%FOOTNOTE{LISTTOPIC="$_[2].$_[1]"}%/g;
    $_[0] =~ s/{{(.*?)}}/%FOOTNOTE{"$1"}%/g;
    # Process all footnotes and footnote lists in page order.
    $_[0] =~ s/%(?:END|FOOT)NOTE{(.*?)}%/&noteHandler($1)/ge;
    # Print remaining footnotes
    $_[0] = $_[0] . printEndNotes(("LISTTOPIC" => "$_[2].$_[1]"));
}

# =========================

1;
