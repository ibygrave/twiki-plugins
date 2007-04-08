# InterwikiPreviewPlugin for TWiki Collaboration Platform, http://TWiki.org/
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

# A single AJAX query.

package TWiki::Plugins::InterwikiPreviewPlugin::Query;

my $pluginName = "InterwikiPreviewPlugin::Query";
my %queries = ();
my $next_field = 1;
my $debug = 1;

sub reset
{
    TWiki::Func::writeDebug( "- ${pluginName}::reset()" ) if $debug;
    %queries = ();
    $next_field = 1;
}

sub new
{
    my ( $class, $alias, $page ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::new($alias,$page)" ) if $debug;

    my $queryid = "$alias\:$page";

    if (exists $queries{$queryid}) {
        TWiki::Func::writeDebug( "- ${pluginName}::new reusing '$queryid')" ) if $debug;
        return $queries{$queryid};
    }

    my $this = {
        alias => $alias,
        page => $page,
        fields => {},
    };

    $queries{$queryid} = bless( $this, $class );

    return $this;
}

sub field
{
    my ( $this, $info ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::field($info)" ) if $debug;

    my $field_id = "f${next_field}";

    $next_field = $next_field + 1;

    $this->{"fields"}->{$field_id} = $info;

    return "<span id=\"${field_id}\"></span>";
}

sub script
{
    my ( $this ) = @_;

    my $alias = $this->{"alias"};
    my $page = $this->{"page"};

    TWiki::Func::writeDebug( "- ${pluginName}::script $alias\:$page" ) if $debug;

    my $text = "new bq('${alias}','${page}',[";

    foreach (keys %{$this->{"fields"}}) {
        my $info = $this->{"fields"}->{$_};
        $text = $text . "['${_}', '${info}'],";
    }

    $text = $text . "]);";

    return $text;
}

sub scripts
{
    my ( $class ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::scripts" ) if $debug;

    my $text = "";

    foreach (keys %queries) {
        $text = $text . $queries{$_}->script();
    }

    %queries = ();

    return $text;
}

# end of class Query

1;
