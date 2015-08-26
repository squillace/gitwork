# Find HTTP/S URLs within a document
param(
[String]$azureArticle
)

# Unused for now, may be used in the future to find Markdown formatted links,
#  vs. just links within content
$markdownLinks="\[.*\]\(.*\)"
# Used to find http/s links
$linkRegex="[a-zA-Z]{3,}://[a-zA-Z0-9\.]+/*[a-zA-Z0-9/\\%_.\-]*[:0-9]*\?*[a-zA-Z0-9/\\%_.=&amp;]*"

# Select all matches, then the unique values to eliminate duplicates
Select-String -Pattern $linkRegex -Path	$azureArticle -AllMatches `
			| select-object -expandproperty Matches `
			| select-object -expandproperty Value -Unique
