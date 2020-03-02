<#
.SYNOPSIS
   Check whether a certificate is still trusted and when it runs out or starts.
.DESCRIPTION
   Invoke-IcingaCheckCertificate returns either 'OK', 'WARNING' or 'CRITICAL', based on the thresholds set.
   e.g a certificate will run out in 30 days, WARNING is set to @20d:50d, CRITICAL is set to @0d:50d. In this case the check will return 'WARNING'.
   
   More Information on https://github.com/Icinga/icinga-powershell-plugins
.FUNCTIONALITY
   This module is intended to be used to check if a certificate is still valid or about to become valid.
.EXAMPLE
   PS> Invoke-IcingaCheckCertificate -CertStore 'LocalMachine' -CertStorePath 'My' -CertThumbprint '*' -WarningEnd '@10d:365d' -CriticalEnd '@0d:10d' -Verbosity 3
   [OK] Check package "Certificates" (Match All)
   \_ [OK] Check package "Certificate End" (Match All)
      \_ [OK] Certificate CN=Cloudbase-Init WinRM(ACACBAC2A29ADC68D710C715DA20B036407BA3A8): 313784201.23
   | 'certificate_cncloudbaseinit_winrmacacbac2a29adc68d710c715da20b036407ba3a8'=313784201.23;@864000:31536000;@0:864000
   0
.EXAMPLE
   PS> Invoke-IcingaCheckCertificate -CertStore 'LocalMachine' -CertStorePath 'My' -CertThumbprint '*' -WarningStart '@0d:10d' -Verbosity 3
   [OK] Check package "Certificates" (Match All)
   \_ [OK] Check package "Certificate Start" (Match All)
      \_ [OK] Certificate CN=Cloudbase-Init WinRM(ACACBAC2A29ADC68D710C715DA20B036407BA3A8): -1662338.9726846
   | 'certificate_cncloudbaseinit_winrmacacbac2a29adc68d710c715da20b036407ba3a8'=-1662338.9726846;@0:864000;
   0
.EXAMPLE
   PS> Invoke-IcingaCheckCertificate -CertStore 'LocalMachine' -CertStorePath 'My' -CertThumbprint '*' -WarningEnd '@10d:365d' -CriticalEnd '@0d:10d' -Verbosity 3;
   [CRITICAL] Check package "Certificates" (Match All) - [CRITICAL] Certificate CN=Cloudbase-Init WinRM(ACACBAC2A29ADC68D710C715DA20B036407BA3A8)
   \_ [CRITICAL] Certificate CN=Cloudbase-Init WinRM(ACACBAC2A29ADC68D710C715DA20B036407BA3A8): Value "False" is not matching threshold "True"
   \_ [OK] Check package "Certificate End" (Match All)
      \_ [OK] Certificate CN=Cloudbase-Init WinRM(ACACBAC2A29ADC68D710C715DA20B036407BA3A8): 313783999.12
   | 'certificate_cncloudbaseinit_winrmacacbac2a29adc68d710c715da20b036407ba3a8'=313783999.12;@864000:31536000;@0:864000 'certificate_cncloudbaseinit_winrmacacbac2a29adc68d710c715da20b036407ba3a8'=False;;True
   2
.PARAMETER Trusted
   Used to switch on trusted behavior. Whether to check, If the certificate is trusted by the system root.
   Will return Critical in case of untrust.

.PARAMETER WarningStart
   Used to specify a Warning range for the start date of an certificate. In this case a string.
   Allowed units include: ms, s, m, h, d, w, M, y

.PARAMETER CriticalStart
   Used to specify a Critical range for the start date of an certificate. In this case a string.
   Allowed units include: ms, s, m, h, d, w, M, y
   
.PARAMETER WarningEnd
   Used to specify a Warning range for the end date of an certificate. In this case a string.
   Allowed units include: ms, s, m, h, d, w, M, y

.PARAMETER CriticalEnd
   Used to specify a Critical range for the end date of an certificate. In this case a string.
   Allowed units include: ms, s, m, h, d, w, M, y
   
.PARAMETER CertStore
   Used to specify which CertStore to check. Valid choices are '*', 'LocalMachine', 'CurrentUser', ''
   
 .PARAMETER CertThumbprint
   Used to specify an array of Thumbprints, which are used to determine what certificate to check, within the CertStore.

.PARAMETER CertSubject
   Used to specify an array of Subjects, which are used to determine what certificate to check, within the CertStore.
   
.PARAMETER CertStorePath
   Used to specify which path within the CertStore should be checked.
   
.PARAMETER CertPaths
   Used to specify an array of paths on your system, where certificate files are. Use with CertName.
   
.PARAMETER CertName
   Used to specify an array of certificate names of certificate files to check. Use with CertPaths.
   
.INPUTS
   System.String
.OUTPUTS
   System.String
.LINK
   https://github.com/Icinga/icinga-powershell-plugins
.NOTES
#>


function Invoke-IcingaCheckCertificate()
{
   param(
    #Checking
	  [switch]$Trusted,
	  $WarningStart          = $null,
	  $CriticalStart         = $null,
	  $WarningEnd            = $null,
	  $CriticalEnd           = $null,
    #CertStore-Related Param
	  [ValidateSet('*', 'LocalMachine', 'CurrentUser')]
	  [string]$CertStore     = '*',
	  [array]$CertThumbprint = $null,
	  [array]$CertSubject    = $null,
	  $CertStorePath         = '*',
	#Local Certs
      [array]$CertPaths      = $null,
	  [array]$CertName		 = $null,
	#Other
      [ValidateSet(0, 1, 2, 3)]
      [int]$Verbosity        = 0,
      [switch]$NoPerfData
   );

   $CertData    = (Get-IcingaCertificateData -CertStore $CertStore -CertThumbprint $CertThumbprint -CertSubject $CertSubject -CertPaths $CertPaths -CertName $CertName -CertStorePath $CertStorePath);
   $CertPackage = New-IcingaCheckPackage -Name 'Certificates' -OperatorAnd -Verbose $Verbosity;
   $Date        = Get-Date; 

   if($Trusted) {
      foreach($Cert in $CertData.CertStore) {
	     if ($Cert.Thumbprint -eq $CompareThumbprint) {
		    continue;
		 }
		 $CompareThumbprint = $Cert.Thumbprint;
         $IcingaCheck = New-IcingaCheck -Name ([string]::Format('Certificate {0}({1})', $Cert.Subject, $Cert.Thumbprint)) -Value (Test-Certificate $Cert -ErrorAction silentlycontinue);
		 $IcingaCheck.CritIfNotMatch($TRUE) | Out-Null;
 		 $CertPackage.AddCheck($IcingaCheck);
      }
      foreach($Cert in $CertData.CertFile) {
	  	 if ($Cert.Thumbprint -eq $CompareThumbprint) {
		    continue;
		 }
		 $CompareThumbprint = $Cert.Thumbprint;
         $IcingaCheck = New-IcingaCheck -Name ([string]::Format('Certificate {0}({1})', $Cert.Subject, $Cert.Thumbprint)) -Value (Test-Certificate $Cert -ErrorAction silentlycontinue);
		 $IcingaCheck.CritIfNotMatch($TRUE) | Out-Null;
		 $CertPackage.AddCheck($IcingaCheck);
      }
   }

# Check for Start of Cert
   if(($null -ne $WarningStart) -Or ($null -ne $CriticalStart)) {
      $CompareThumbprint = $null
      $CertPackageStart = New-IcingaCheckPackage -Name 'Certificate Start' -OperatorAnd -Verbose $Verbosity;
      foreach($Cert in $CertData.CertStore) {
	  	 if ($Cert.Thumbprint -eq $CompareThumbprint) {
		    continue;
		 }
		 $CompareThumbprint = $Cert.Thumbprint;
         $IcingaCheck = New-IcingaCheck -Name ([string]::Format('Certificate {0}({1})', $Cert.Subject, $Cert.Thumbprint)) -Value (New-TimeSpan -End $Cert.NotBefore.DateTime).TotalSeconds;
         $IcingaCheck.WarnOutOfRange((ConvertTo-SecondsFromIcingaThresholds -Threshold $WarningStart)).CritOutOfRange((ConvertTo-SecondsFromIcingaThresholds -Threshold $CriticalStart)) | Out-Null;
	     $CertPackageStart.AddCheck($IcingaCheck);
	  }
	  foreach($Cert in $CertData.CertFile) {
	  	 if ($Cert.Thumbprint -eq $CompareThumbprint) {
		    continue;
		 }
		 $CompareThumbprint = $Cert.Thumbprint;
         $IcingaCheck = New-IcingaCheck -Name ([string]::Format('Certificate {0}({1})', $Cert.Subject, $Cert.Thumbprint)) -Value (New-TimeSpan -End $Cert.NotAfter.DateTime).TotalSeconds;
         $IcingaCheck.WarnOutOfRange((ConvertTo-SecondsFromIcingaThresholds -Threshold $WarningStart)).CritOutOfRange((ConvertTo-SecondsFromIcingaThresholds -Threshold $CriticalStart)) | Out-Null;
		 $CertPackageStart.AddCheck($IcingaCheck);
      }
   }
# Check for End of Cert
   if(($null -ne $WarningEnd) -Or ($null -ne $CriticalEnd)) {
      $CompareThumbprint = $null
      $CertPackageEnd = New-IcingaCheckPackage -Name 'Certificate End' -OperatorAnd -Verbose $Verbosity;
      foreach($Cert in $CertData.CertStore) {
	  	 if ($Cert.Thumbprint -eq $CompareThumbprint) {
		    continue;
		 }
		 $CompareThumbprint = $Cert.Thumbprint;
         $IcingaCheck = New-IcingaCheck -Name ([string]::Format('Certificate {0}({1})', $Cert.Subject, $Cert.Thumbprint)) -Value (New-TimeSpan -End $Cert.NotAfter.DateTime).TotalSeconds;
		 $IcingaCheck.WarnOutOfRange((ConvertTo-SecondsFromIcingaThresholds -Threshold $WarningEnd)).CritOutOfRange((ConvertTo-SecondsFromIcingaThresholds -Threshold $CriticalEnd)) | Out-Null;
		 $CertPackageEnd.AddCheck($IcingaCheck);

	  }
	  foreach($Cert in $CertData.CertFile) {
	  	 if ($Cert.Thumbprint -eq $CompareThumbprint) {
		    continue;
		 }
		 $CompareThumbprint = $Cert.Thumbprint;
         $IcingaCheck = New-IcingaCheck -Name ([string]::Format('Certificate {0}({1})', $Cert.Subject, $Cert.Thumbprint)) -Value (New-TimeSpan -End $Cert.NotAfter.DateTime).TotalSeconds;
         $IcingaCheck.WarnOutOfRange((ConvertTo-SecondsFromIcingaThresholds -Threshold $WarningEnd)).CritOutOfRange((ConvertTo-SecondsFromIcingaThresholds -Threshold $CriticalEnd)) | Out-Null;
		 $CertPackageEnd.AddCheck($IcingaCheck);
     }
   }

   $CertPackage.AddCheck($CertPackageStart);
   $CertPackage.AddCheck($CertPackageEnd);
   
   return (New-IcingaCheckResult -Name 'Certificates' -Check $CertPackage -NoPerfData $NoPerfData -Compile);
}
