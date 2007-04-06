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

# =========================
package TWiki::Plugins::InterwikiAjaxInfoPlugin;

use TWiki::Plugins::InterwikiAjaxInfoPlugin::Rule;
use TWiki::Plugins::InterwikiAjaxInfoPlugin::Query;
use TWiki::Func;

# =========================
use vars qw(
        $web $topic $user $installWeb $VERSION $pluginName
        $prefixPattern $upperAlpha $mixedAlphaNum $sitePattern $pagePattern $postfixPattern
        $debug $defaultRulesTopic %rulesTable
    );

$VERSION = '1.021';
$pluginName = 'InterwikiAjaxInfoPlugin';  # Name of this Plugin
$defaultRulesTopic = "InterWikisAjaxInfo";

# 'Use locale' for internationalisation of Perl sorting and searching - 
# main locale settings are done in TWiki::setupLocale
BEGIN {
    # Do a dynamic 'use locale' for this module
    if( $TWiki::useLocale ) {
        require locale;
	import locale ();
    }
}

# Regexes for the Site:page format InterWiki reference - updated to support
# 8-bit characters in both parts - see Codev.InternationalisationEnhancements
$prefixPattern  = '(^|[\s\-\*\(])';
$upperAlpha    = TWiki::Func::getRegularExpression("upperAlpha");
$mixedAlphaNum = TWiki::Func::getRegularExpression("mixedAlphaNum");
$sitePattern    = "([${upperAlpha}][${mixedAlphaNum}]+)";
$pagePattern    = "([${mixedAlphaNum}_\/][${mixedAlphaNum}" . '\+\_\.\,\;\:\!\?\/\%\#-]+?)';
$postfixPattern = '(?=[\s\.\,\;\:\!\?\)]*(\s|$))';

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
    $debug = 1;

    # Get rules topic
    my $rulesTopic = &TWiki::Func::getPluginPreferencesValue( "RULESTOPIC" ) 
        || "$installWeb.$defaultRulesTopic";

    $rulesTopic = TWiki::Func::expandCommonVariables( $rulesTopic, $topic, $web );
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin, rules topic: ${rulesTopic}" ) if $debug;

    TWiki::Plugins::InterwikiAjaxInfoPlugin::Rule::reset();
    TWiki::Plugins::InterwikiAjaxInfoPlugin::Query::reset();

    my $data = TWiki::Func::readTopicText( "", $rulesTopic );
    $data =~ s/^\|\s*$sitePattern\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|/TWiki::Plugins::InterwikiAjaxInfoPlugin::Rule->new($1,$2,$3)/geom;

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}

# =========================
sub handleInterwiki
{
    my ( $pre, $alias, $page, $post ) = @_;
    &TWiki::Func::writeDebug( "- ${pluginName}::handleInterwiki( $pre, $alias, $page, $post )" ) if $debug;

    my $text = "";

    my $rule = TWiki::Plugins::InterwikiAjaxInfoPlugin::Rule->get($alias);

    if (defined $rule) {
        my $query = TWiki::Plugins::InterwikiAjaxInfoPlugin::Query->new($alias,$page);
        $text = " " . $rule->{"info"};
        $text =~ s/%(\w+)%/$query->field($1)/geo;
    }
    return "$pre$alias\:$page$text$post";
}

# =========================
sub startRenderingHandler
{
### my ( $text, $web ) = @_;   # do not uncomment, use $_[0], $_[1] instead
    &TWiki::Func::writeDebug( "- ${pluginName}::startRenderingHandler( $_[1] )" ) if $debug;

    $_[0] =~ s/(\[\[)$sitePattern:$pagePattern(\]\]|\]\[| )/&handleInterwiki($1,$2,$3,$4)/geo;
    $_[0] =~ s/$prefixPattern$sitePattern:$pagePattern$postfixPattern/&handleInterwiki($1,$2,$3,"")/geo;
}

# =========================
sub endRenderingHandler
{
    $_[0] = $_[0] . TWiki::Plugins::InterwikiAjaxInfoPlugin::Query->scripts();
}

# =========================

1;
