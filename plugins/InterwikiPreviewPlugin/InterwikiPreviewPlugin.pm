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

# =========================
package TWiki::Plugins::InterwikiPreviewPlugin;

use TWiki::Plugins::InterwikiPreviewPlugin::Rule;
use TWiki::Plugins::InterwikiPreviewPlugin::Query;
use TWiki::Func;

# =========================
use vars qw(
        $VERSION $pluginName $debug $web $topic $user $installWeb
        $prefixPattern $upperAlpha $mixedAlphaNum $sitePattern $pagePattern $postfixPattern
        $defaultRulesTopic $mochikitSource
    );

$VERSION = '1.009';
$pluginName = 'InterwikiPreviewPlugin';  # Name of this Plugin
$defaultRulesTopic = "InterWikiPreviews";

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
    if( $TWiki::Plugins::VERSION < 1.1 ) {
        TWiki::Func::writeWarning( "Version mismatch between $pluginName and Plugins.pm" );
        return 0;
    }

    # Get plugin debug flag
    $debug = TWiki::Func::getPluginPreferencesFlag( "DEBUG" );

    if ( $debug ) {
        TWiki::Plugins::InterwikiPreviewPlugin::Rule::enableDebug();
        TWiki::Plugins::InterwikiPreviewPlugin::Query::enableDebug();
    }
        
    TWiki::Plugins::InterwikiPreviewPlugin::Rule::reset();
    TWiki::Plugins::InterwikiPreviewPlugin::Query::reset();

    # Get rules topic
    my $rulesTopic = TWiki::Func::getPluginPreferencesValue( "RULESTOPIC" )
        || "$installWeb.$defaultRulesTopic";

    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin, rules topic: ${rulesTopic}" ) if $debug;

    my $data = TWiki::Func::readTopicText( "", $rulesTopic );
    $data =~ s/^\|\s*$sitePattern\s*\|\s*(.+?)\s*\|\s*([${mixedAlphaNum}]+)\s*\|\s*(.+?)\s*\|\s*(\d+)\s*\|$/newRule($1,$2,$3,$4,$5)/geom;

    # Get mochikit library location
    $mochikitSource = TWiki::Func::getPluginPreferencesValue( "MOCHIKITJS" );
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin, mochikit: ${mochikitSource}" ) if $debug;

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}

# =========================
sub newRule
{
#    my ( $alias, $url, $format, $info, $reload ) = @_;

    my $rule = TWiki::Plugins::InterwikiPreviewPlugin::Rule->new(@_);

    if (defined $rule) {
        # Proxy query via REST interface 
        TWiki::Func::registerRESTHandler($_[0],
            sub { return $rule->restHandler($_[0],$_[1],$_[2]); } );
    }
}    

# =========================
sub modifyHeaderHandler
{
    my ( $headers, $query ) = @_;

    my $queryContentType = TWiki::Func::getSessionValue($pluginName.'ContentType');
    if( TWiki::Func::getContext()->{'rest'} && $queryContentType ) {
        TWiki::Func::writeDebug( "- ${pluginName}::modifyHeaderHandler setting Content-Type to $queryContentType" ) if $debug;
        $headers->{'Content-Type'} = $queryContentType;
        TWiki::Func::clearSessionValue($pluginName.'ContentType');
    }
}

# =========================
sub handleInterwiki
{
#    my ( $pre, $alias, $page, $post ) = @_;
    TWiki::Func::writeDebug( "- ${pluginName}::handleInterwiki(${alias}:${page})" ) if $debug;

    my $text = "";

    my $rule = TWiki::Plugins::InterwikiPreviewPlugin::Rule->get($_[1]);

    if (defined $rule) {
        $text = " %INTERWIKIPREVIEWQUERY{alias=\"$_[1]\" page=\"$_[2]\"}% " .
            TWiki::Func::expandCommonVariables($rule->{"info"},$topic,$web);
    }
    return $_[0] . $_[1] . ":" . $_[2] . $_[3] . $text;
}

# =========================
sub preRenderingHandler
{
    # do not uncomment, use $_[0], $_[1]... instead
    #my( $text, $pMap ) = @_;
    TWiki::Func::writeDebug( "- ${pluginName}::preRenderingHandler()" ) if $debug;

    # The ...QUERY and ...FIELD tag handlers are local closures
    # which have the same $query in scope.
    my $query = undef();
    my %tagHandler = ( QUERY => sub {
        my %params = TWiki::Func::extractParameters($_[0]);
        my $rule = TWiki::Plugins::InterwikiPreviewPlugin::Rule->get($params{alias});
        if (defined $rule) {
            $query = TWiki::Plugins::InterwikiPreviewPlugin::Query->new($rule,$params{page});
        }
        return "";
    }, FIELD => sub {
        return $query->field($_[0]) if (defined $query);
        # Leave tag unexpanded if there was no query.
        return "%INTERWIKIPREVIEWFIELD{$_[0]}%";
    } );

    $_[0] =~ s/(\]\[)$sitePattern:$pagePattern(\]\]|\s)/&handleInterwiki($1,$2,$3,$4)/geo;
    $_[0] =~ s/$prefixPattern$sitePattern:$pagePattern$postfixPattern/&handleInterwiki($1,$2,$3,"")/geo;
    $_[0] =~ s/%INTERWIKIPREVIEW(\w+){(.*?)}%/&{$tagHandler{$1}}($2)/geo;
}

# =========================
sub postRenderingHandler {
    # do not uncomment, use $_[0], $_[1]... instead
    #my $text = shift;
    TWiki::Func::writeDebug( "- ${pluginName}::postRenderingHandler()" ) if $debug;
    my $queryScripts = TWiki::Plugins::InterwikiPreviewPlugin::Query->scripts();
    if ( $queryScripts ) {
        $_[0] = $_[0] . $queryScripts;
        my $head = <<HERE;
<script type="text/javascript" src="${mochikitSource}"></script>
<script type="text/javascript" src="%PUBURL%/%TWIKIWEB%/${pluginName}/query.js"></script>
HERE
        TWiki::Func::addToHEAD( 'INTERWIKIPREVIEWPLUGIN_QUERYJS', $head );
    }
}

1;
