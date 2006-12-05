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

# A single footnote.
{
  package TWiki::Plugins::EndNotePlugin::Note;

  my %notes = ();
  my $next_num = 1;

  sub new
  {
    my ( $class, $page, %params ) = @_;
    my $text = $params{"_DEFAULT"};

    if (exists $notes{$text}) {
      return $notes{$text};
    }

    my $this = {
      n => $next_num,
      page => $page,
      text => $params{"_DEFAULT"},
      anchored => 0,
      printed => 0,
    };

    $notes{$text} = bless( $this, $class );

    $next_num += 1;

    return $this;
  }

  sub anchor
  {
    my ( $this ) = @_;
    return "" if ( $this->{"anchored"} );
    $this->{"anchored"} = 1;
    return "<a name=\"EndNote" . $this->{"n"} . "text\"></a>";
  }

  sub text
  {
    my ( $this ) = @_;
    my $n = $this->{"n"};
    return $this->anchor() . "<sup>[[#EndNote${n}note][${n}]]</sup>";
  }

  sub note
  {
    my ( $this ) = @_;
    return "" if ( $this->{"printed"} );
    $this->{"printed"} = 1;
    my $n = $this->{"n"};
    return "#EndNote${n}note [[#EndNote${n}text][ *${n}:* ]] " . $this->{"text"} . " \n\n";
  }

} # end of class Note

1;
