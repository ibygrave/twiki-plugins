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
my $debug = 0;

sub reset
{
    TWiki::Func::writeDebug( "- ${pluginName}::reset()" ) if $debug;
    %queries = ();
    $next_field = 1;
}

sub new
{
    my ( $class, $rule, $page ) = @_;

    my $queryid = $rule->{alias} . ":" . $page;

    TWiki::Func::writeDebug( "- ${pluginName}::new($queryid)" ) if $debug;

    if (exists $queries{$queryid}) {
        TWiki::Func::writeDebug( "- ${pluginName}::new reusing '$queryid')" ) if $debug;
        return $queries{$queryid};
    }

    my $this = {
        rule => $rule,
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

    return "<span id=\"${field_id}\" class=\"iwppFieldEmpty\"></span>";
}

sub script
{
    my ( $this ) = @_;

    my $alias = $this->{"rule"}->{"alias"};
    my $reload = $this->{"rule"}->{"reload"};
    my $page = $this->{"page"};

    TWiki::Func::writeDebug( "- ${pluginName}::script $alias\:$page $reload" ) if $debug;

    my $text = "new iwppq_new('${alias}', ${reload}, '${page}',[";

    foreach (keys %{$this->{"fields"}}) {
        my $info = $this->{"fields"}->{$_};
        $text = $text . "['${_}', '${info}'],";
    }

    $text = $text . "]);\n";

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

    if ($text) {
        $text = "<!-- InterwikiPreviewPlugin fill fields-->\n<script type=\"text/javascript\">\n" .
            $text .
            "</script>\n<!-- /InterwikiPreviewPlugin fill fields-->\n";
    }

    %queries = ();

    return $text;
}

# end of class Query

1;
