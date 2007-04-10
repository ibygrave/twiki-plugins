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
        $web $topic $user $installWeb $VERSION $pluginName
        $prefixPattern $upperAlpha $mixedAlphaNum $sitePattern $pagePattern $postfixPattern
        $debug $defaultRulesTopic $queryContentType $pageHasQueries $mochikitSource
    );

$VERSION = '1.001';
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
    $debug = 1;

    $pageHasQueries = 0;
    TWiki::Plugins::InterwikiPreviewPlugin::Rule::reset();
    TWiki::Plugins::InterwikiPreviewPlugin::Query::reset();

    # Get rules topic
    my $rulesTopic = TWiki::Func::getPluginPreferencesValue( "RULESTOPIC" )
        || "$installWeb.$defaultRulesTopic";

    $rulesTopic = TWiki::Func::expandCommonVariables( $rulesTopic, $topic, $web );
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin, rules topic: ${rulesTopic}" ) if $debug;

    my $data = TWiki::Func::readTopicText( "", $rulesTopic );
    $data =~ s/^\|\s*$sitePattern\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(\d+)\s*|/newRule($1,$2,$3, $4)/geom;

    # Get mochikit library location
    $mochikitSource = TWiki::Func::getPluginPreferencesValue( "MOCHIKITJS" );
    $mochikitSource = TWiki::Func::expandCommonVariables( $mochikitSource, $topic, $web );
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin, mochikit: ${mochikitSource}" ) if $debug;

    # Plugin correctly initialized
    TWiki::Func::writeDebug( "- ${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;
    return 1;
}

# =========================
sub newRule
{
    my ( $alias, $url, $info, $reload ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::newRule( $alias, $url, $info, $reload )" ) if $debug;

    my $rule = TWiki::Plugins::InterwikiPreviewPlugin::Rule->new($alias,$url,$info, $reload);

    if (defined $rule) {
        # Proxy query via REST interface 
        TWiki::Func::registerRESTHandler($alias,
                                         sub {
                                             my $text = $rule->restHandler($_[0],$_[1],$_[2]);
                                             $text =~ s/\r\n/\n/gs;
                                             $text =~ s/\r/\n/gs;
                                             $text =~ s/^(.*?\n)\n(.*)/$2/s;
                                             my $httpHeader = $1;
                                             if( $httpHeader =~ /content\-type\:\s*([^\n]*)/ois ) {
                                                 $queryContentType = $1;
                                             }
                                             return $text;
                                         } );
    }
}    

# =========================
sub handleInterwiki
{
    my ( $pre, $alias, $page, $post ) = @_;
    TWiki::Func::writeDebug( "- ${pluginName}::handleInterwiki( $pre, $alias, $page, $post )" ) if $debug;

    my $text = "";

    my $rule = TWiki::Plugins::InterwikiPreviewPlugin::Rule->get($alias);

    if (defined $rule) {
        my $query = TWiki::Plugins::InterwikiPreviewPlugin::Query->new($rule,$page);
        $text = " " . $rule->{"info"};
        $text =~ s/%(\w+)%/$query->field($1)/geo;
        $pageHasQueries = 1;
    }
    return $pre . $alias . ":" . $page . $text . $post;
}

# =========================
sub addQueryScript
{
    TWiki::Func::writeDebug( "- ${pluginName}::addQueryScript" ) if $debug;
    my $head = <<HERE;
<!-- InterwikiPreviewPlugin iwppq-->
<script type="text/javascript" src="${mochikitSource}"></script>
<script type="text/javascript">
function iwppq_gotdata(s) {
  log("Entered iwppq_gotdata", this.id);
  forEach( this.show, function (d) {
    log("iwppq_gotdata show", d);
    swapDOM( d[0], SPAN( { 'id': d[0] }, s.responseXML.getElementsByTagName(d[1])[0] ) );
  });
  if ( this.reload > 0 ) {
    callLater(this.reload, bind(this.go, this));
  };
  log("Leaving iwppq_gotdata", this.id);
};

function iwppq_go() {
  log("Entered iwppq_go", this.id);
  this.d = doSimpleXMLHttpRequest(this.url);
  this.d.addCallback(bind(this.gotdata, this));
  log("Leaving iwppq_go", this.id);
};

function iwppq_new(alias, reload, page, show) {
  this.id = alias+":"+page;
  log("Creating iwppq", this.id);
  this.url = "%SCRIPTURL%/rest/${pluginName}/"+alias+"?page="+page;
  this.reload = reload;
  this.show = show;
  this.go = iwppq_go;
  this.gotdata = iwppq_gotdata;
  this.go();
  log("Created iwppq", this.id);
};
</script>
<!-- /InterwikiPreviewPlugin iwppq -->
HERE

    TWiki::Func::addToHEAD( 'INTERWIKIPREVIEWPLUGIN_QUERYJS', $head );
        
}

# =========================
sub startRenderingHandler
{
### my ( $text, $web ) = @_;   # do not uncomment, use $_[0], $_[1] instead
    TWiki::Func::writeDebug( "- ${pluginName}::startRenderingHandler( $_[1] )" ) if $debug;

    $_[0] =~ s/(\[\[)$sitePattern:$pagePattern(\]\]|\]\[| )/&handleInterwiki($1,$2,$3,$4)/geo;
    $_[0] =~ s/$prefixPattern$sitePattern:$pagePattern$postfixPattern/&handleInterwiki($1,$2,$3,"")/geo;

    addQueryScript() if $pageHasQueries;
}

# =========================
sub endRenderingHandler
{
### my ( $text ) = @_;   # do not uncomment, use $_[0] instead

    TWiki::Func::writeDebug( "- ${pluginName}::endRenderingHandler( $web.$topic )" ) if $debug;

    my $scripts = TWiki::Plugins::InterwikiPreviewPlugin::Query->scripts();

    if ($scripts) {
        $_[0] = $_[0] . '<!-- InterwikiPreviewPlugin fill fields--><script type="text/javascript">' . $scripts . '</script><!-- /InterwikiPreviewPlugin fill fields-->';
    }
}

# =========================
sub modifyHeaderHandler {
    my ( $headers, $query ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::modifyHeaderHandler()" ) if $debug;

    if( TWiki::Func::getContext()->{'rest'} && $queryContentType) {
        TWiki::Func::writeDebug( "- ${pluginName}::modifyHeaderHandler setting Content-Type to $queryContentType" ) if $debug;
        $headers->{'Content-Type'} = queryContentType;
    }
}

1;
