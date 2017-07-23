function Clear-DbaSqlConnectionPool {
<#
	.SYNOPSIS
		Resets (or empties) the connection pool.

	.DESCRIPTION
		This command resets (or empties) the connection pool.

		If there are connections in use at the time of the call, they are marked appropriately and will be discarded (instead of being returned to the pool) when Close() is called on them.

		Ref: https://msdn.microsoft.com/en-us/library/system.data.sqlclient.sqlconnection.clearallpools(v=vs.110).aspx

	.PARAMETER ComputerName
		Target computer(s). If no computer name is specified, the local computer is targeted

	.PARAMETER Credential
		Alternate credential object to use for accessing the target computer(s).

	.PARAMETER Silent
		Use this switch to disable any kind of verbose messages

	.NOTES
		Tags: Connection

		Website: https://dbatools.io
		Copyright: (C) Chrissy LeMaire, clemaire@gmail.com
		License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0

	.LINK
		https://dbatools.io/Clear-DbaSqlConnectionPool

	.EXAMPLE
		Clear-DbaSqlConnectionPool

		Clears all local connection pools.

	.EXAMPLE
		Clear-DbaSqlConnectionPool -ComputerName workstation27

		Clears all connection pools on workstation27.
#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[Alias("cn", "host", "Server")]
		[DbaInstanceParameter[]]$ComputerName = $env:COMPUTERNAME,
		[PSCredential]$Credential,
		[switch]$Silent
	)

	process
	{
		# TODO: https://jamessdixon.wordpress.com/2013/01/22/ado-net-and-connection-pooling

		foreach ($Computer in $ComputerName)
		{
			if ($Computer -ne $env:COMPUTERNAME -and $Computer -ne "localhost" -and $Computer -ne "." -and $Computer -ne "127.0.0.1")
			{
				Write-Message -Level Verbose -Message "Clearing all pools on remote computer $Computer"
				if (Test-Bound 'Credential')
				{
					Invoke-Command2 -ComputerName $Computer -Credential $Credential -ScriptBlock { [System.Data.SqlClient.SqlConnection]::ClearAllPools() }
				}
				else
				{
					Invoke-Command2 -ComputerName $Computer -ScriptBlock { [System.Data.SqlClient.SqlConnection]::ClearAllPools() }
				}
			}
			else
			{
				Write-Verbose "Clearing all local pools"
				if (Test-Bound 'Credential')
				{
					Invoke-Command2 -Credential $Credential -ScriptBlock { [System.Data.SqlClient.SqlConnection]::ClearAllPools() }
				}
				else
				{
					Invoke-Command2 -ScriptBlock { [System.Data.SqlClient.SqlConnection]::ClearAllPools() }
				}
			}
		}
	}
}
