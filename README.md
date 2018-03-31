# nimwhistle

An algorithmic url shortener based on the ideas in Whistle, with some additional enhancements (see http://tantek.pbworks.com/w/page/21743973/Whistle for more information) for dealing with non-standard "fixed" URLs.


Assumptions:
* files must have extensions
* shortened paths must be of the form: `/YYYY/mm/dd/filename.ext`
* only html/htm (prefix 'b'), text/txt (prefix 't'), png/gif/jpeg/jpg (prefix 'p') are currently supported


Usage:

* `nimwhistle c <url>` to compress a URL
* `nimwhistle x <url> <htdocs>` to expand a URL (using the base htdocs directory as specified to find the right file/path)
* `nimwhistle cgi <htdocs>` to provide CGI-based redirection of a compressed URL from the path /u/
* `nimwhistle a <path> <htdocs>` to add a relative URL path to the file `$htdocs/nimwhistle.urls`. Each line in the file results in the redirect `/u/f1`, `/u/f2`, `/u/f3`, etc


Example Apache2 configuration for CGI:

```
ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
<Directory "/usr/lib/cgi-bin">
    AllowOverride None
    Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
    Order allow,deny
    Allow from all
</Directory>

RewriteEngine On
RewriteRule /u/.* /cgi-bin/nimwhistle.cgi [NC,PT]
```

(obviously, in this example, install the nimwhistle executable and associated nimwhistle.cgi script in /usr/lib/cgi-bin)