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
        $VERSION $pluginName $debug
        $prefixPattern $upperAlpha $mixedAlphaNum $sitePattern $pagePattern $postfixPattern
        $defaultRulesTopic $queryContentType $mochikitSource
    );

$VERSION = '1.005';
$pluginName = 'InterwikiPreviewPlugin';  # Name of this Plugin
$defaultRulesTopic = "InterWikiPreviews";
$queryContentType = "";

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
    my ( $topic, $web, $user, $installWeb ) = @_;

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

    TWiki::Func::writeDebug( "- ${pluginName}::newRule(@_)" ) if $debug;

    my $rule = TWiki::Plugins::InterwikiPreviewPlugin::Rule->new(@_);

    if (defined $rule) {
        # Proxy query via REST interface 
        TWiki::Func::registerRESTHandler($_[0],
                                         sub {
                                             my $text = $rule->restHandler($_[0],$_[1],$_[2]);
                                             $text =~ s/\r\n/\n/gos;
                                             $text =~ s/\r/\n/gos;
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
sub modifyHeaderHandler
{
    my ( $headers, $query ) = @_;

    TWiki::Func::writeDebug( "- ${pluginName}::modifyHeaderHandler()" ) if $debug;

    if( TWiki::Func::getContext()->{'rest'} && $queryContentType) {
        TWiki::Func::writeDebug( "- ${pluginName}::modifyHeaderHandler setting Content-Type to $queryContentType" ) if $debug;
        $headers->{'Content-Type'} = $queryContentType;
    }
}

# =========================
sub handleInterwiki
{
#    my ( $pre, $alias, $page, $post ) = @_;
    TWiki::Func::writeDebug( "- ${pluginName}::handleInterwiki(@_)" ) if $debug;

    my $text = "";

    my $rule = TWiki::Plugins::InterwikiPreviewPlugin::Rule->get($_[1]);

    if (defined $rule) {
        my $query = TWiki::Plugins::InterwikiPreviewPlugin::Query->new($rule,$_[2]);
        $text = " " . $rule->{"info"};
        $text =~ s/%INTERWIKIPREVIEWFIELD{(.*?)}%/$query->field($1)/geo;
    }
    return $_[0] . $_[1] . ":" . $_[2] . $_[3] . $text;
}

# =========================
sub addQueryScript
{
    TWiki::Func::writeDebug( "- ${pluginName}::addQueryScript" ) if $debug;
    my $head = <<HERE;
<!-- InterwikiPreviewPlugin iwppq-->
<script type="text/javascript" src="${mochikitSource}"></script>
<script type="text/javascript">
function iwppq(url, reload, show) {
  this.url = url;
  this.reload = reload;
  this.show = show;
  this.go = function() {
    this.d = this.doreq(this.url);
    this.d.addCallbacks(bind(this.gotdata, this), bind(this.err, this));
    log("IWPPQ requested", this.url); };
  this.gotdata = function(s) {
    log("IWPPQ got", this.url);
    extract = bind(this.extract, this);
    forEach( this.show, function(d) { swapDOM( d[0], SPAN( { 'id': d[0], 'class': 'iwppFieldFull' }, extract(s,d[1]) ) ); });
    if ( this.reload > 0 ) { callLater(this.reload, bind(this.go, this)); }; };
  this.err = function(err) {
    log("IWPPQ request failed", this.url, err);
    forEach( this.show, function(d) { swapDOM( d[0], SPAN( { 'id': d[0], 'class': 'iwppFieldFailed' }, '?' ) ); }); };
};

function iwppq_XML(url, reload, show) {
  log("Creating iwppq_XML", url);
  bind(iwppq,this)(url, reload, show);
  this.doreq = doSimpleXMLHttpRequest;
  this.extract = function(s,f) {
    try { return scrapeText( getFirstElementByTagAndClassName(f, null, s.responseXML) );
    } catch(e) { return s.responseXML.getElementsByTagName(f)[0]; } };
};

function iwppq_JSON(url, reload, show) {
  log("Creating iwppq_JSON", url);
  bind(iwppq,this)(url, reload, show);
  this.doreq = loadJSONDoc;
  this.extract = function(s,f) { return s[f]; };
};
</script>
<!-- /InterwikiPreviewPlugin iwppq -->
HERE
    TWiki::Func::addToHEAD( 'INTERWIKIPREVIEWPLUGIN_QUERYJS', $head );
}

# =========================
sub preRenderingHandler
{
    #my( $text, $pMap ) = @_;
    TWiki::Func::writeDebug( "- ${pluginName}::preRenderingHandler( )" ) if $debug;

    $_[0] =~ s/(\]\[)$sitePattern:$pagePattern(\]\]|\s)/&handleInterwiki($1,$2,$3,$4)/geo;
    $_[0] =~ s/$prefixPattern$sitePattern:$pagePattern$postfixPattern/&handleInterwiki($1,$2,$3,"")/geo;

    my $queryScripts = TWiki::Plugins::InterwikiPreviewPlugin::Query->scripts();
    if ( $queryScripts ) {
        $_[0] = $_[0] . $queryScripts;
        addQueryScript();
    }
}

1;
