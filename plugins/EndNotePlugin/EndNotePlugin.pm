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
        $debug @endnotes %endnote_nums $heading $perblock
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

    # Get perblock flag
    $perblock = TWiki::Func::getPluginPreferencesFlag( "PERBLOCK" );
    TWiki::Func::writeDebug( "- ${pluginName} perblock = ${perblock}" ) if $debug;

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- TWiki::Plugins::${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}


# =========================
sub storeEndNote
{
    my $i;
    my $anchor = "";
    if (exists $endnote_nums{$_[0]}) {
        $i = $endnote_nums{$_[0]};
    } else {
        @endnotes = (@endnotes, $_[0]);
        $i = @endnotes;
        $endnote_nums{$_[0]} = $i;
        $anchor = "<a name=\"EndNote${i}text\"></a>"
    }
    return "${anchor}<sup>[[#EndNote${i}note][${i}]]</sup>";
}

# =========================
sub printEndNotes
{
    my $c = @endnotes;
    return "" if ($c == 0);
    my $result = "\n---\n\n";
    my $i = 0;
    my $n;
    if ($result) {
        $result = $result . "---+ $heading\n";
    }
    while ($i < $c) {
        $n = $i + 1;
        $result = $result . "\n#EndNote${n}note [[#EndNote${n}text][ *${n}:* ]] ${endnotes[$i]}\n\n"; 
        $i = $n;
    }
    $result = $result . "---\n\n";
    return $result;
}

sub noteHandler
{

    @endnotes = ();
    %endnote_nums = ();
    $_[0] =~ s/%(?:END|FOOT)NOTE{(.*?)}%/{{$1}}/g;
    $_[0] =~ s/{{(.*?)}}/&storeEndNote($1)/ge;
    $_[0] = $_[0] . printEndNotes();
}

# =========================
sub commonTagsHandler
{
### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead

    TWiki::Func::writeDebug( "- ${pluginName}::commonTagsHandler( $_[1], $_[2] )" ) if $debug;
    if ($perblock) {
        noteHandler( $_[0] );
    }
}

# =========================
sub startRenderingHandler
{
### my ( $text, $web ) = @_;   # do not uncomment, use $_[0], $_[1] instead

    TWiki::Func::writeDebug( "- ${pluginName}::startRenderingHandler( $_[1] )" ) if $debug;
    if (!$perblock) {
        noteHandler( $_[0] );
    }
}

# =========================

1;
