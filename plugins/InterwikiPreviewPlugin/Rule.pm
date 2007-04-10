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

# A single rule.

package TWiki::Plugins::InterwikiPreviewPlugin::Rule;

use TWiki::Func;

my $pluginName = "InterwikiPreviewPlugin::Rule";
my $debug = 1;
my %rules = ();

sub reset
{
    TWiki::Func::writeDebug( "- ${pluginName}::reset" ) if $debug;
    %rules = ();
};

sub new
{
    my ( $class, $alias, $url, $info, $reload ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::new( $alias, $url, $info, $reload )" ) if $debug;

    my ( $user, $pass, $host, $port, $path ) = ('', '', '', 80, '');

    if( $url =~ /http\:\/\/(.+)\:(.+)\@([^\:]+)\:([0-9]+)(\/.*)/ ) {
        ( $user, $pass, $host, $port, $path ) = ( $1, $2, $3, $4, $5 );
    } elsif( $url =~ /http\:\/\/(.+)\:(.+)\@([^\/]+)(\/.*)/ ) {
        ( $user, $pass, $host, $path ) = ( $1, $2, $3, $4 );
    } elsif( $url =~ /http\:\/\/([^\:]+)\:([0-9]+)(\/.*)/ ) {
        ( $host, $port, $path ) = ( $1, $2, $3 );
    } elsif( $url =~ /http\:\/\/([^\/]+)(\/.*)/ ) {
        ( $host, $path ) = ( $1, $2 );
    } else {
        # Write to warning log
        return undef();
    }

    my $this = {
        alias => $alias,
        user => $user,
        pass => $pass,
        host => $host,
        port => $port,
        path => $path,
        info => $info,
        reload => $reload,
    };

    $rules{$alias} = bless( $this, $class );

    return $this;
}

sub get
{
    my ( $class, $alias ) = @_;
    TWiki::Func::writeDebug( "- ${pluginName}::get( $alias )" ) if $debug;
    return $rules{$alias};
}

sub restHandler
{
    my ($this, $session, $subject, $verb) = @_;
    TWiki::Func::writeDebug( "- ${pluginName}::restHandler()" ) if $debug;
    return $session->{net}->getUrl( $this->{host},
                                    $this->{port},
                                    $this->{path} . $session->{cgiQuery}->param('page'),
                                    $this->{user},
                                    $this->{pass} );
}

# end of class Rule

1;
