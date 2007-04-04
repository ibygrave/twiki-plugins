<script type="text/javascript" src="/mochikit/MochiKit/MochiKit.js"></script>
<script type="text/javascript">
function gotdata(s) {
  log("Entered gotdata", this.url, this.show);
  forEach( this.show, function (d) {
    log("gotdata show", d);
    swapDOM( d[0], SPAN( { 'id': d[0] }, s.responseXML.getElementsByTagName(d[1])[0] ) );
  });
  if ( this.reload > 0 ) {
    callLater(this.reload, bind(this.go, this));
  };
  log("Leaving gotdata", this.url);
};

function go() {
  log("Entered go", this.url);
  this.d = doSimpleXMLHttpRequest(this.url);
  this.d.addCallback(bind(this.gotdata, this));
  log("Leaving go", this.url);
};

function bq(alias, page, show) {
  log("Creating", page);
  this.url = "http://wisp.bygrave.me.uk/cgi-bin/twiki/rest/InterwikiAjaxInfoPlugin/"+alias+"?page="+page;
  this.url = "http://wisp.bygrave.me.uk/cgi-bin/bug.cgi?"+page;
  this.reload = 0;
  this.show = show;
  this.go = go;
  this.gotdata = gotdata;
  this.go();
  log("Created", this.url);
};

</script>
