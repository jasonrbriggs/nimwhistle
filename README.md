# nimwhistle
Algorithmic url shortener

An algorithmic url shortener based on the ideas in Whistle with some additional enhancements (http://tantek.pbworks.com/w/page/21743973/Whistle).

Usage:

* `nimwhistle c <url>` to compress a URL
* `nimwhistle x <url> <htdocs>` to expand a URL (using the base htdocs directory as specified to find the right file/path)
* `nimwhistle cgi <htdocs>` to provide CGI-based redirection of a compressed URL from the path /u/

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