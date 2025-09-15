#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#    Filename: StaleAccounts.ps1
#    Intent: Remove stale accounts and record accounts removed
#    Author: Matthew Wurtz
#    Date: 7/3/2024
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# change this value to equal the number of days that will define a stale account. Integers only.
$stale = 30

$staledate = $(get-date).AddDays(-$stale)
$removed = get-localuser | where { $_.lastlogon -le $staledate } | Remove-LocalUser

# the below will create a file within the documents folder of your home directory and then record what accounts are removed.
echo ""  >> ~\Documents\Accounts_Removed 
Get-Date  >> ~\Documents\Accounts_Removed 
$removed >> ~\Documents\Accounts_Removed 