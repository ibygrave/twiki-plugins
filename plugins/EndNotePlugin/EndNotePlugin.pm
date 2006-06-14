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

use TWiki::Plugins::EndNotePlugin::PageNotes;
use TWiki::Func;

# =========================
use vars qw(
        $web $topic $user $installWeb $VERSION $pluginName
        $debug $notes
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
    my $heading = TWiki::Func::getPluginPreferencesValue( "HEADING" );
    TWiki::Func::writeDebug( "- ${pluginName} heading = ${heading}" ) if $debug;

    $notes = new TWiki::Plugins::EndNotePlugin::PageNotes( "$web.$topic", $heading );

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}

# =========================
sub noteHandler
{
    TWiki::Func::writeDebug( "- ${pluginName}::noteHandler( $_[0], $_[1] )" ) if $debug;

    my %params = TWiki::Func::extractParameters( $_[1] );

    return $notes->store($_[0],%params) if (exists $params{"_DEFAULT"});

    return $notes->print($_[0],%params) if (exists $params{"LIST"});
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
    $_[0] = $_[0] . $notes->print($thistopic,("LIST" => "yes"));
}

# =========================

1;
