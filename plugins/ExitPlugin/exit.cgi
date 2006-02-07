#!/usr/bin/env python

answer = """
<html>
<head>
  <title>You Are Exiting The TWiki Web Server</title>
  <meta http-equiv="refresh" content="0; URL=%(url)s"></head>

<body>

<b>
Thank you for visiting.
Click on the following link to go to:
</b>
</p>
<a href="%(url)s">%(url)s</a>

<b>
(or you will be taken there immediately)
<hr>
</b>

</body>
</html>
"""

import cgi

form = cgi.FieldStorage()
try:
  print "Content-type: text/html"
  print ""
  print answer % {'url':form['url'].value}

except KeyError:
  print "Content-type: text/plain"
  print ""
  print "Bad call to exit.cgi"
