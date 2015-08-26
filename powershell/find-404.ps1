# Grab links from the pipeline and iterate on them
foreach ($link in $input) {
	# Make a web request
	try {
		$request = Invoke-WebRequest -Uri $link
	}
	# Catch errors
	catch {
		$request = $_.Exception.Response
		$status = [int]$request.StatusCode
		# Write the status out if 404
		if($status -eq 404) {			
			write-output $link
		}
	}
}
