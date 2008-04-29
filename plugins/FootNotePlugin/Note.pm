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

# A single footnote.
{
  package TWiki::Plugins::FootNotePlugin::Note;

  my %notes = ();
  my $next_num = 1;

  sub reset
  {
    %notes = ();
    $next_num = 1;
  }

  sub new
  {
    my ( $class, $page, %params ) = @_;
    my $text = $params{"_DEFAULT"};
    my $safetext;

    # encode HTML special characters
    $safetext = $text;
    $safetext =~ s/[^\w\t ]/'&#'.ord($&).';'/goe;

    my $this = {
      n => $next_num,
      label => " *${next_num}* ",
      page => $page,
      text => $text, 
      safetext => $safetext,
      anchored => 0,
      printed => 0,
    };

    bless( $this, $class );
    
    if (!exists $notes{$text}) {
      $notes{$text} = {
        anchors => [],
        first => $next_num,
        printed => 0,
      };
    }

    push(@{$notes{$text}->{"anchors"}}, $this);

    $next_num += 1;

    return $this;
  }

  sub anchor
  {
    my ( $this ) = @_;
    return "" if ( $this->{"anchored"} );
    $this->{"anchored"} = 1;
    return "<a name=\"FootNote" . $this->{"n"} . "text\"></a>";
  }

  sub text
  {
    my ( $this ) = @_;
    my $n = $this->{"n"};
    my $safetext = $this->{"safetext"};
    return $this->anchor() . "<sup>[[#FootNote${n}note][<span title=\"${safetext}\">(${n})</span>]]</sup>";
  }

  sub note
  {
    my ( $this ) = @_;
    return "" if ( $this->{"printed"} );
    $this->{"printed"} = 1;
    my $n = $this->{"n"};
    my $label = $this->{"label"};
    return "<a name=\"FootNote${n}note\"></a> [[#FootNote${n}text][${label}]]";
  }

  sub printNotes
  { 
    my ( $page ) = @_;
    my $result = "";
    my @anchors;

    foreach $note (sort { $a->{"first"} <=> $b->{"first"} } values(%notes)) {
      next if $note->{"printed"};
      if ($page eq "ALL") {
        @anchors = @{$note->{"anchors"}};
      } else {
        @anchors = grep {
          $page eq $_->{"page"}
        } @{$note->{"anchors"}};
      }
      next if $#anchors == -1;
      $result .= join( ',' , map( $_->note(), @anchors ) );
      $result .= ": " . $anchors[0]->{"text"} . " \n\n";
      $note->{"printed"} = 1;
    }

    return $result;
  }


} # end of class Note

1;
