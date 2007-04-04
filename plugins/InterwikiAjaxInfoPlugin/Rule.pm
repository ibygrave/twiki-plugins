# InterwikiAjaxInfoPlugin for TWiki Collaboration Platform, http://TWiki.org/
#
# Copyright (C) 2007 Ian Bygrave, ian@bygrave.me.uk
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

# A single rule.

package TWiki::Plugins::InterwikiAjaxInfoPlugin::Rule;

my %rules = ();

sub reset
{
    %rules = ();
};

sub new
{
    my ( $class, $alias, $url, $info ) = @_;

    &TWiki::Func::writeDebug( "- ${pluginName} new Rule( $alias, $url, $info )" );

    my $this = {
        alias => $alias,
        url => $url,
        info => $info,
    };

    $rules{$alias} = bless( $this, $class );

    return $this;
}

sub get
{
    my ( $class, $alias ) = @_;
    return $rules{$alias};
}

# end of class Rule

1;
