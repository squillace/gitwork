
$langlinkregex=".*/[a-z]{2}-[a-z]{2}/.*"
foreach ($link in $input) {
	if($link -match $langlinkregex) { 
		write-output $link
	}
}
