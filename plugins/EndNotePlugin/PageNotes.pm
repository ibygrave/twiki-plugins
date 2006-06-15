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

use TWiki::Plugins::EndNotePlugin::Note;

# A set of footnotes on a page.
{
  package TWiki::Plugins::EndNotePlugin::PageNotes;

  # Make an empty set of footnotes
  sub new
  {
    my ( $class, $page, $heading ) = @_;
    my $this = {
      page => $page,
      notes => [],
      note_num => {},
      heading => $heading,
    };

    return bless( $this, $class );
  }

  # Store a footnote, returning the note placeholder.
  sub store
  {
    my ( $this, $page, %params ) = @_;
    my $note;
    my $text = $params{"_DEFAULT"};
    my $i;
    my $anchor = "";
    if (exists $this->{"note_num"}->{$text}) {
      $i = $this->{"note_num"}->{$text};
      $note = ${$this->{"notes"}}[$i-1];
    } else {
        $i = @{$this->{"notes"}} + 1;
      $note = new TWiki::Plugins::EndNotePlugin::Note( $i, $page, %params );
      push( @{$this->{"notes"}}, $note );
      $this->{"note_num"}->{$text} = $i;
    }
    return $note->text();
  }

  # Print a table of footnotes for the given page.
  sub print
  {
    my ( $this, $page, %params ) = @_;
    return "" if ($page ne $this->{"page"});
    my $result = "";

    foreach $note (@{$this->{"notes"}}) {
      if (($params{"LIST"} eq "ALL") || ($params{"LIST"} eq $note->{"page"})) {
        $result .= $note->note();
      }
    }

    return "" if ($result eq "");

    my $heading = "";
    if ($this->{"heading"}) {
      $heading = "---+ " . $this->{"heading"};
      if ($params{"LIST"} ne "ALL") {
        $heading .= " to " . $params{"LIST"};
      }
    }
    return "\n---\n\n" . $heading . "\n\n" . $result . "---\n\n";
  }

  # Print a table of all remaining footnotes
  sub printall
  {
      return $_[0]->print( $_[1], ("LIST" => "ALL") );
  }

} # end of class PageNotes

1;
