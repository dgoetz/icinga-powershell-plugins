<#
.SYNOPSIS
    Checks a given path / unc path and determines the size of the volume including free space
.DESCRIPTION
    Invoke-IcingaCheckUNCPath uses a path or unc path to fetch information about the volume this
    path is set to. This includes the total and free space of the share but also the total free share size.

    You can monitor the share size itself by using % and byte values, while the total free share size only supports byte values.

    In case you are checking very long path entries, you can short them with a display name alias.
.ROLE
    ### Path Permissions

    The user running this plugin requires read access to the given path. In case authentication is required, it has to be mapped to a user
    who can authenticate without a prompt
.PARAMETER Path
    The path to a volume or network share you want to monitor, like "\\example.com\Home" or "C:\ClusterSharedVolume\Volume1"
.PARAMETER DisplayAlias
    Modifies the plugin output to not display the value provided within the `-Path` argument but to use this string value
    instead of shorten the output and make it more visual appealing.
.PARAMETER Warning
    A warning threshold for the shares free space in either % or byte units, like "20%:" or "50GB:"
    Please note that this value is decreasing over time, therefor you will have to use the plugin handler and add ":" at the end
    of your input to check for "current value < threshold" like in the previous example

    Allowed units: %, B, KB, MB, GB, TB, PB, KiB, MiB, GiB, TiB, PiB
.PARAMETER Critical
    A critical threshold for the shares free space in either % or byte units, like "20%:" or "50GB:"
    Please note that this value is decreasing over time, therefor you will have to use the plugin handler and add ":" at the end
    of your input to check for "current value < threshold" like in the previous example

    Allowed units: %, B, KB, MB, GB, TB, PB, KiB, MiB, GiB, TiB, PiB
.PARAMETER WarningTotal
    A warning threshold for the shares total free space in byte units, like "50GB:"
    Please note that this value is decreasing over time, therefor you will have to use the plugin handler and add ":" at the end
    of your input to check for "current value < threshold" like in the previous example

    Allowed units: B, KB, MB, GB, TB, PB, KiB, MiB, GiB, TiB, PiB
.PARAMETER CriticalTotal
    A warning threshold for the shares total free space in byte units, like "50GB:"
    Please note that this value is decreasing over time, therefor you will have to use the plugin handler and add ":" at the end
    of your input to check for "current value < threshold" like in the previous example

    Allowed units: B, KB, MB, GB, TB, PB, KiB, MiB, GiB, TiB, PiB
.PARAMETER NoPerfData
    Disables the performance data output of this plugin. Default to FALSE.
.PARAMETER Verbosity
    Changes the behavior of the plugin output which check states are printed:
    0 (default): Only service checks/packages with state not OK will be printed
    1: Only services with not OK will be printed including OK checks of affected check packages including Package config
    2: Everything will be printed regardless of the check state
.EXAMPLE
    icinga { Invoke-IcingaCheckUNCPath -Path '\\example.com\Shares\Icinga' -Critical '20TB:' }

    [CRITICAL] Check package "\\example.com\Shares\Icinga Share" (Match All) - [CRITICAL] Free Space
        \_ [CRITICAL] Free Space: Value "5105899364352B" is lower than threshold "20000000000000B"
    | 'share_free_bytes'=5105899364352B;;20000000000000: 'total_free_bytes'=5105899364352B;; 'share_size'=23016091746304B;; 'share_free_percent'=22.18%;;;0;100
.EXAMPLE
    icinga { Invoke-IcingaCheckUNCPath -Path '\\example.com\Shares\Icinga' -Critical '40%:' }

    [CRITICAL] Check package "\\example.com\Shares\Icinga Share" - [CRITICAL] Free %
        \_ [CRITICAL] Free %: Value "22.18%" is lower than threshold "40%"
    | 'share_free_bytes'=5105899343872B;; 'total_free_bytes'=5105899343872B;; 'share_size'=23016091746304B;; 'share_free_percent'=22.18%;;40:;0;100
.EXAMPLE
    icinga { Invoke-IcingaCheckUNCPath -Path '\\example.com\Shares\Icinga' -CriticalTotal '20TB:' }

    [CRITICAL] Check package "\\example.com\Shares\Icinga Share" - [CRITICAL] Total Free
        \_ [CRITICAL] Total Free: Value "5105899315200B" is lower than threshold "20000000000000B"
    | 'share_free_bytes'=5105899315200B;; 'total_free_bytes'=5105899315200B;;20000000000000: 'share_size'=23016091746304B;; 'share_free_percent'=22.18%;;;0;100
.EXAMPLE
    icinga { Invoke-IcingaCheckUNCPath -Path '\\example.com\Shares\Icinga' -DisplayAlias 'IcingaExample' -CriticalTotal '20TB:' }

    [CRITICAL] Check package "IcingaExample Share" - [CRITICAL] Total Free
        \_ [CRITICAL] Total Free: Value "5105899069440B" is lower than threshold "20000000000000B"
    | 'share_free_bytes'=5105899069440B;; 'total_free_bytes'=5105899069440B;;20000000000000: 'share_size'=23016091746304B;; 'share_free_percent'=22.18%;;;0;100
.LINK
    https://github.com/Icinga/icinga-powershell-framework
    https://github.com/Icinga/icinga-powershell-plugins
#>

function Invoke-IcingaCheckUNCPath()
{
    param (
        [string]$Path         = '',
        [string]$DisplayAlias = '',
        $Warning              = $null,
        $Critical             = $null,
        $WarningTotal         = $null,
        $CriticalTotal        = $null,
        [switch]$NoPerfData   = $FALSE,
        [ValidateSet(0, 1, 2)]
        $Verbosity            = 0
    );

    [string]$DisplayName = $Path;

    if ([string]::IsNullOrEmpty($DisplayAlias) -eq $FALSE) {
        $DisplayName = $DisplayAlias;
    }

    $Warning       = Convert-IcingaPluginThresholds $Warning;
    $Critical      = Convert-IcingaPluginThresholds $Critical;
    $WarningTotal  = Convert-IcingaPluginThresholds $WarningTotal;
    $CriticalTotal = Convert-IcingaPluginThresholds $CriticalTotal;
    $PathData      = Get-IcingaUNCPathSize -Path $Path;
    $CheckPackage  = New-IcingaCheckPackage -Name ([string]::Format('{0} Share', $DisplayName)) -OperatorAnd -Verbose $Verbosity;

    $ShareFree = New-IcingaCheck `
        -Name ([string]::Format('Free Space', $DisplayName)) `
        -Value $PathData.ShareFree `
        -Unit 'B' `
        -LabelName ([string]::Format('share_free_bytes', $PathData.ShareFree));

    $ShareSize = New-IcingaCheck `
        -Name ([string]::Format('Size', $DisplayName)) `
        -Value $PathData.ShareSize `
        -Unit 'B' `
        -LabelName ([string]::Format('share_size', $PathData.ShareSize));

    if ($Warning.Unit -ne '%') {
        $ShareFree.WarnOutOfRange($Warning.Value) | Out-Null;
    }
    if ($Critical.Unit -ne '%') {
        $ShareFree.CritOutOfRange($Critical.Value) | Out-Null;
    }

    $ShareFreePercent = New-IcingaCheck `
        -Name ([string]::Format('Free %', $DisplayName)) `
        -Value $PathData.ShareFreePercent `
        -Unit '%' `
        -LabelName ([string]::Format('share_free_percent', $PathData.ShareFreePercent));

    if ($Warning.Unit -eq '%') {
        $ShareFreePercent.WarnOutOfRange($Warning.Value) | Out-Null;
    }
    if ($Critical.Unit -eq '%') {
        $ShareFreePercent.CritOutOfRange($Critical.Value) | Out-Null;
    }

    $TotalFree = New-IcingaCheck `
        -Name ([string]::Format('Total Free', $DisplayName)) `
        -Value $PathData.TotalFree `
        -Unit 'B' `
        -LabelName ([string]::Format('total_free_bytes', $PathData.TotalFree));

    $TotalFree.WarnOutOfRange($WarningTotal.Value).CritOutOfRange($CriticalTotal.Value) | Out-Null;

    $CheckPackage.AddCheck($ShareFree);
    $CheckPackage.AddCheck($ShareSize);
    $CheckPackage.AddCheck($ShareFreePercent);
    $CheckPackage.AddCheck($TotalFree);

    return (New-IcingaCheckResult -Name ([string]::Format('{0} Share', $DisplayName)) -Check $CheckPackage -NoPerfData $NoPerfData -Compile);
}
