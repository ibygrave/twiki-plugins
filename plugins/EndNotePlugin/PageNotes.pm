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

# A set of footnotes on a page.
{
  package TWiki::Plugins::EndNotePlugin::PageNotes;

  # Make an empty set of footnotes
  sub new
  {
    my ( $class, $page, $heading ) = @_;
    my $this = {};

    $this->{"page"} = $page;
    $this->{"notes"} = [];
    $this->{"first_note"} = 1;
    $this->{"note_num"} = {};
    $this->{"heading"} = $heading;

    return bless( $this, $class );
  }

  # Store a footnote, returning the the note placeholder.
  sub store
  {
    my ( $this, $page, %params ) = @_;
    my $text = $params{"_DEFAULT"};
    my $i;
    my $anchor = "";
    if (exists $this->{"note_num"}->{$text}) {
      $i = $this->{"note_num"}->{$text};
    } else {
      $i = @{$this->{"notes"}} + $this->{"first_note"};
      push( @{$this->{"notes"}}, $text );
      $this->{"note_num"}->{$text} = $i;
      $anchor = "<a name=\"EndNote${i}text\"></a>";
    }
    return "${anchor}<sup>[[#EndNote${i}note][${i}]]</sup>";
  }

  # Print a table of footnotes.
  sub print
  {
    my ( $this, $page, %params ) = @_;
    my $c = @{$this->{"notes"}};
    return "" if ($c == 0);
    return "" if !($page eq $this->{"page"});
    my $result = "\n---\n\n";
    my $i = 0;
    my $n;
    if ($this->{"heading"}) {
        $result .= "---+ $heading $page\n";
    }
    while ($i < $c) {
        $n = $i + $this->{"first_note"};
        $result .= "\n#EndNote${n}note [[#EndNote${n}text][ *${n}:* ]]";
        $result .= ${$this->{"notes"}}[$i];
        $result .= "\n\n";
        $i = $i + 1;
    }
    $result .= "---\n\n";
    $this->{"first_note"} += $c;
    $this->{"notes"} = [];
    return $result;
  }

} # end of class PageNotes

1;
