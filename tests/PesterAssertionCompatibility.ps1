$loadedPester = Get-Module Pester
if ($null -ne $loadedPester -and $loadedPester.Version.Major -eq 3) {
    $script:Pester3Should = (Get-Command Should -CommandType Function).ScriptBlock

    function Should {
        begin {
            $legacyArguments = @($args)
            if ($legacyArguments.Count -gt 0 -and $legacyArguments[0] -eq '-Not') {
                $legacyArguments[0] = 'Not'
                if ($legacyArguments.Count -gt 1 -and $legacyArguments[1] -is [string] -and $legacyArguments[1].StartsWith('-')) {
                    $legacyArguments[1] = $legacyArguments[1].Substring(1)
                }
            }
            elseif ($legacyArguments.Count -gt 0 -and $legacyArguments[0] -is [string] -and $legacyArguments[0].StartsWith('-')) {
                $legacyArguments[0] = $legacyArguments[0].Substring(1)
            }
            $actualValues = @()
        }

        process {
            $actualValues += ,$_
        }

        end {
            $actualValues | & $script:Pester3Should @legacyArguments
        }
    }
}
