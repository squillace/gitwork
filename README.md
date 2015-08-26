# gitwork
Scripts and programs to use with markdown files. This contains both scripts (the bash and powershell directories) and programs (forthcoming go and mono/.net directories) that perform basic tasks with markdown files.

## Bash
There are three files and two test files. The **links.sh** file extracts markdown links that contain internet reachable addresses (so that link examples in code or text are not extracted). These can be listed or piped to a file or piped to other programs. This script depends on a version of grep that takes the -o parameter to return only the selected text, and may require on Windows and Mac a newer version of grep.

```
╭─[~/Workspace/scripts/gitwork/bash]─[ralph@local]─[0]─[1487]
╰─[:)] % ./links.sh toolstest.md
http://msdn.microsoft.com/library/azure/gg981929.aspx
http://msdn.microsoft.com/library/windowsazure/jj193178.aspx
http://msdn.microsoft.com/library/windowsazure/jj860528.aspx
```

The **langlinks.sh** file takes a list of links and tests them to determine whether any contain a language code in a url, such as en-us, or de-de. This should work with any version of grep.

```
╭─[~/Workspace/scripts/gitwork/bash]─[ralph@local]─[0]─[1544]
╰─[:)] % ./langlinks.sh $(./links.sh testfile.md)
http://azure.microsoft.com/en-in/marketplace/partners/coreos/
http://azure.microsoft.com/en-in/marketplace/partners/OpenLogic/
```

The **404s** file takes a list of links and uses `curl` to make a header request (only) and follows redirects 3 deep in order to detect 404s. It has a progress indicator that lists out all responses. Obviously, requires an internet connection. Because some servers and pages do not return **precisely** the specified responses, there are some false positives, but they are rare. It's a good bulk checker, but not foolproof.

As an example, the third-from-last "bad" link (`https://support.microsoft.com/en-us/kb/2941892`) actually returns a page in the browser; but **curl** treats the underlying network responses as bad, becoming a 404. So, while this is a good test, remember to test them yourself just in case. It's 99.5% right.

```
╭─[~/Workspace/scripts/gitwork/bash]─[ralph@local]─[0]─[1553]
╰─[:)] % ./404s.sh $(./links.sh testfile.md)
There were 95 links passed.
95 of 95... (6 bad links so far)
404 http://azure.microsoft.com/en-us/marketplace/partners/msopentech/jdk6onwindowsserver2012/
404 http://azure.microsoft.com/en-us/marketplace/partners/msopentech/jdk7onwindowsserver2012/
404 http://azure.microsoft.com/en-us/marketplace/partners/msopentech/jdk8onwindowsserver2012r2/
404 https://support.microsoft.com/en-us/kb/2941892
404 http://wiki.hudson-ci.org/display/HUDSON/Azure
404 https://channel9.msdn.com/Shows/Cloud
```

##PowerShell

There are three scripts here:

- __find-links.ps1__ - Extracts links from a file and returns a list of them to stdout.

    Usage: `find-links <filename>`

    Example output:

    ```
    http://msdn.microsoft.com/library/azure/gg981929.aspx
    http://msdn.microsoft.com/library/windowsazure/jj193178.aspx
    http://msdn.microsoft.com/library/windowsazure/jj860528.aspx
    ```

- __find-langlinks.ps1__ - Expects a list of links through the pipeline. Each link is checked to see if it is language specific (/en-us/ for example.) The list of links, if any, are returned to stdout.

    Usage: `find-links <filename> | find-langlinks.ps1`

- __find-404.ps1__ - Expects a list of links through the pipeline. Each link is checked to see if it returns an HTTP 404 (not found) status. Any links that return a 404 are returned to stdout.

    Usage: `find-links <filename> | find-404.ps1`

    NOTE: Checking links can take a few minutes. Each link checked results in the full page being accessed, so large pages, or slow web servers, can significantly increase the amount of time it takes to process links.

There is an example __testfile.md__ in the __powershell__ directory, which contains links that will generate output for both __find-langlinks.ps1__ and __find-404.ps1__.
