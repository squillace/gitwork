# gitwork
Scripts and programs to use with markdown files.

## This contains both scripts (the bash and powershell directories) and programs (forthcoming go and mono/.net directories) that perform basic tasks with markdown files. 

### Bash
There are three files and two test files. The **links.sh** file extracts markdown links that contain internet reachable addresses (so that link examples in code or text are not extracted). These can be listed or piped to a file or piped to other programs. This script depends on a version of grep that takes the -o parameter to return only the selected text, and may require on Windows and Mac a newer version of grep.

The **langlinks.sh** file takes a list of links and tests them to determine whether any contain a language code in a url, such as en-us, or de-de. This should work with any version of grep.

The **404s** file takes a list of links and uses `curl` to make a header request (only) and follows redirects 3 deep in order to detect 404s. It has a progress indicator that lists out all responses. Obviously, requires an internet connection. Because some servers and pages do not return **precisely** the specified responses, there are some false positives, but they are rare. It's a good bulk checker, but not foolproof.
