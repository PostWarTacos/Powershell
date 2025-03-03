<#
#   Intent: Creates a scheduled task that will run a script. Script is used to check the health of the SCCM client.
#   Author: Matthew Wurtz
#   Date: 28-Feb-25
#>

# Uses Base64 encoded string of the script for ease of use 
# Updated Base64 as of 3-Mar-25
$encodedCommand = "PAAjAA0ACgAjACAAIAAgAEkAbgB0AGUAbgB0ADoAIABSAGEAbgAgAGYAcgBvAG0AIABDAG8AbABsAGUAYwB0AGkAbwBuACAAQwBvAG0AbQBhAG4AZABlAHIALgAgAFcAaQBsAGwAIABjAGgAZQBjAGsAIAA3ACAAZABpAGYAZgBlAHIAZQBuAHQAIABwAG8AaQBuAHQAcwAgAHQAbwAgAHYAZQByAGkAZgB5ACAAdABoAGUAIABoAGUAYQBsAHQAaAAgAG8AZgAgAFMAQwBDAE0AIABjAGwAaQBlAG4AdAANAAoAIwAgACAAIABEAGEAdABlADoAIAAyADQALQBGAGUAYgAtADIANQANAAoAIwAgACAAIABBAHUAdABoAG8AcgA6ACAATQBhAHQAdABoAGUAdwAgAFcAdQByAHQAegANAAoAIwA+AD4ADQAKAA0ACgAjACAAQwByAGUAYQB0AGUAcwAgAGEAbgAgAEEAcgByAGEAeQBsAGkAcwB0ACAAdwBoAGkAYwBoACAAaQBzACAAbQB1AHQAYQBiAGwAZQAgAGEAbgBkACAAZQBhAHMAaQBlAHIAIAB0AG8AIABtAGEAbgBpAHAAdQBsAGEAdABlACAAdABoAGEAbgAgAGEAbgAgAGEAcgByAGEAeQAuAA0ACgAkAGgAZQBhAGwAdABoAEwAbwBnACAAPQAgAFsAUwB5AHMAdABlAG0ALgBDAG8AbABsAGUAYwB0AGkAbwBuAHMALgBBAHIAcgBhAHkATABpAHMAdABdAEAAKAApAA0ACgAkAGgAZQBhAGwAdABoAEwAbwBnAFAAYQB0AGgAIAA9ACAAIgBDADoAXABkAHIAaQB2AGUAcgBzAFwAQwBDAE0AXABMAG8AZwBzAFwAIgANAAoAJABjAG8AcgByAHUAcAB0AGkAbwBuACAAPQAgADAADQAKAA0ACgBJAGYAKAAgAC0AbgBvAHQAIAAoACAAVABlAHMAdAAtAFAAYQB0AGgAIAAkAGgAZQBhAGwAdABoAEwAbwBnAFAAYQB0AGgAIAApACkAIAB7AA0ACgAgACAAIAAgAG0AawBkAGkAcgAgACQAaABlAGEAbAB0AGgATABvAGcAUABhAHQAaAANAAoAfQANAAoADQAKACMAIABDAGgAZQBjAGsAIABpAGYAIABTAEMAQwBNACAAQwBsAGkAZQBuAHQAIABpAHMAIABpAG4AcwB0AGEAbABsAGUAZAANAAoAJABjAGwAaQBlAG4AdABQAGEAdABoACAAPQAgACIAQwA6AFwAVwBpAG4AZABvAHcAcwBcAEMAQwBNAFwAQwBjAG0ARQB4AGUAYwAuAGUAeABlACIADQAKAGkAZgAgACgAIABUAGUAcwB0AC0AUABhAHQAaAAgACQAYwBsAGkAZQBuAHQAUABhAHQAaAAgACkAewANAAoAIAAgACAAIAAkAGgAZQBhAGwAdABoAEwAbwBnAC4AQQBkAGQAKAAgACIAWwAkACgAZwBlAHQALQBkAGEAdABlACAALQBGAG8AcgBtAGEAdAAgACIAZABkAC0ATQBNAE0ALQB5AHkAIABIAEgAOgBtAG0AOgBzAHMAIgApAF0AIABNAGUAcwBzAGEAZwBlADoAIABGAG8AdQBuAGQAIABDAGMAbQBFAHgAZQBjAC4AZQB4AGUALgAgAFMAQwBDAE0AIABpAG4AcwB0AGEAbABsAGUAZAAuACIAIAApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAANAAoAfQAgAEUAbABzAGUAIAB7AA0ACgAJACQAaABlAGEAbAB0AGgATABvAGcALgBBAGQAZAAoACAAIgBbACQAKABnAGUAdAAtAGQAYQB0AGUAIAAtAEYAbwByAG0AYQB0ACAAIgBkAGQALQBNAE0ATQAtAHkAeQAgAEgASAA6AG0AbQA6AHMAcwAiACkAXQAgAE0AZQBzAHMAYQBnAGUAOgAgAEMAYQBuAG4AbwB0ACAAZgBpAG4AZAAgAEMAYwBtAEUAeABlAGMALgBlAHgAZQAuACAAUwBDAEMATQAgAEMAbABpAGUAbgB0ACAAaQBzACAAbgBvAHQAIABpAG4AcwB0AGEAbABsAGUAZAAuACIAIAApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAANAAoAIAAgACAAIAAkAGMAbwByAHIAdQBwAHQAaQBvAG4AIAArAD0AIAAxAA0ACgB9AA0ACgAJAAkACQAJAA0ACgAjACAAQwBoAGUAYwBrACAAaQBmACAAUwBDAEMATQAgAEMAbABpAGUAbgB0ACAAUwBlAHIAdgBpAGMAZQAgAGkAcwAgAHIAdQBuAG4AaQBuAGcADQAKACQAcwBlAHIAdgBpAGMAZQAgAD0AIABHAGUAdAAtAFMAZQByAHYAaQBjAGUAIAAtAE4AYQBtAGUAIABDAGMAbQBFAHgAZQBjACAALQBFAHIAcgBvAHIAQQBjAHQAaQBvAG4AIABTAGkAbABlAG4AdABsAHkAQwBvAG4AdABpAG4AdQBlAA0ACgBpAGYAIAAoACAAJABzAGUAcgB2AGkAYwBlAC4AUwB0AGEAdAB1AHMAIAAtAGUAcQAgACcAUgB1AG4AbgBpAG4AZwAnACAAKQB7AA0ACgAgACAAIAAgACQAaABlAGEAbAB0AGgATABvAGcALgBBAGQAZAAoACAAIgBbACQAKABnAGUAdAAtAGQAYQB0AGUAIAAtAEYAbwByAG0AYQB0ACAAIgBkAGQALQBNAE0ATQAtAHkAeQAgAEgASAA6AG0AbQA6AHMAcwAiACkAXQAgAE0AZQBzAHMAYQBnAGUAOgAgAEYAbwB1AG4AZAAgAEMAYwBtAEUAeABlAGMAIABzAGUAcgB2AGkAYwBlACAAYQBuAGQAIABpAHQAIABpAHMAIAByAHUAbgBuAGkAbgBnAC4AIgAgACkAIAB8ACAATwB1AHQALQBOAHUAbABsAA0ACgB9ACAARQBsAHMAZQBpAGYAIAAoACAAJABzAGUAcgB2AGkAYwBlAC4AUwB0AGEAdAB1AHMAIAAtAG4AZQAgACcAUgB1AG4AbgBpAG4AZwAnACAAKQAgAHsADQAKACAAIAAgACAAJABoAGUAYQBsAHQAaABMAG8AZwAuAEEAZABkACgAIAAiAFsAJAAoAGcAZQB0AC0AZABhAHQAZQAgAC0ARgBvAHIAbQBhAHQAIAAiAGQAZAAtAE0ATQBNAC0AeQB5ACAASABIADoAbQBtADoAcwBzACIAKQBdACAATQBlAHMAcwBhAGcAZQA6ACAARgBvAHUAbgBkACAAQwBjAG0ARQB4AGUAYwAgAHMAZQByAHYAaQBjAGUAIABiAHUAdAAgAGkAdAAgAGkAcwAgAE4ATwBUACAAcgB1AG4AbgBpAG4AZwAuACIAIAApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAANAAoAIAAgACAAIAAkAGMAbwByAHIAdQBwAHQAaQBvAG4AIAArAD0AIAAxAA0ACgB9ACAARQBsAHMAZQAgAHsADQAKAAkAJABoAGUAYQBsAHQAaABMAG8AZwAuAEEAZABkACgAIAAiAFsAJAAoAGcAZQB0AC0AZABhAHQAZQAgAC0ARgBvAHIAbQBhAHQAIAAiAGQAZAAtAE0ATQBNAC0AeQB5ACAASABIADoAbQBtADoAcwBzACIAKQBdACAATQBlAHMAcwBhAGcAZQA6ACAAQwBjAG0ARQB4AGUAYwAgAHMAZQByAHYAaQBjAGUAIABjAG8AdQBsAGQAIABuAG8AdAAgAGIAZQAgAGYAbwB1AG4AZAAuACAAUwBDAEMATQAgAEMAbABpAGUAbgB0ACAAbQBhAHkAIABuAG8AdAAgAGIAZQAgAGkAbgBzAHQAYQBsAGwAZQBkAC4AIgAgACkAIAB8ACAATwB1AHQALQBOAHUAbABsAA0ACgAgACAAIAAgACQAYwBvAHIAcgB1AHAAdABpAG8AbgAgACsAPQAgADEADQAKAH0ADQAKAA0ACgAjACAAQwBoAGUAYwBrACAAQwBsAGkAZQBuAHQAIABWAGUAcgBzAGkAbwBuAA0ACgAkAHMAbQBzAEMAbABpAGUAbgB0ACAAPQAgAEcAZQB0AC0AVwBtAGkATwBiAGoAZQBjAHQAIAAtAE4AYQBtAGUAcwBwAGEAYwBlACAAIgByAG8AbwB0AFwAYwBjAG0AIgAgAC0AQwBsAGEAcwBzACAAUwBNAFMAXwBDAGwAaQBlAG4AdAAgAC0ARQByAHIAbwByAEEAYwB0AGkAbwBuACAAUwBpAGwAZQBuAHQAbAB5AEMAbwBuAHQAaQBuAHUAZQANAAoAaQBmACAAKAAgACQAcwBtAHMAQwBsAGkAZQBuAHQALgBDAGwAaQBlAG4AdABWAGUAcgBzAGkAbwBuACAAKQAgAHsADQAKACAAIAAgACAAJABoAGUAYQBsAHQAaABMAG8AZwAuAEEAZABkACgAIAAiAFsAJAAoAGcAZQB0AC0AZABhAHQAZQAgAC0ARgBvAHIAbQBhAHQAIAAiAGQAZAAtAE0ATQBNAC0AeQB5ACAASABIADoAbQBtADoAcwBzACIAKQBdACAATQBlAHMAcwBhAGcAZQA6ACAAUwBDAEMATQAgAEMAbABpAGUAbgB0ACAAVgBlAHIAcwBpAG8AbgA6ACAAJAAoACAAJABzAG0AcwBDAGwAaQBlAG4AdAAuAEMAbABpAGUAbgB0AFYAZQByAHMAaQBvAG4AIAApACIAIAApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAANAAoAfQAgAGUAbABzAGUAIAB7AA0ACgAgACAAIAAgACQAaABlAGEAbAB0AGgATABvAGcALgBBAGQAZAAoACAAIgBbACQAKABnAGUAdAAtAGQAYQB0AGUAIAAtAEYAbwByAG0AYQB0ACAAIgBkAGQALQBNAE0ATQAtAHkAeQAgAEgASAA6AG0AbQA6AHMAcwAiACkAXQAgAE0AZQBzAHMAYQBnAGUAOgAgAFMATQBTAF8AQwBsAGkAZQBuAHQALgBDAGwAaQBlAG4AdABWAGUAcgBzAGkAbwBuACAAYwBsAGEAcwBzACAAbgBvAHQAIABmAG8AdQBuAGQALgAgAFMAQwBDAE0AIABDAGwAaQBlAG4AdAAgAG0AYQB5ACAAbgBvAHQAIABiAGUAIABpAG4AcwB0AGEAbABsAGUAZAAuACIAIAApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAANAAoAIAAgACAAIAAkAGMAbwByAHIAdQBwAHQAaQBvAG4AIAArAD0AIAAxAA0ACgB9ACAAIAAgACAADQAKAA0ACgAjACAAQwBoAGUAYwBrACAATQBhAG4AYQBnAGUAbQBlAG4AdAAgAFAAbwBpAG4AdAAgAEMAbwBtAG0AdQBuAGkAYwBhAHQAaQBvAG4ADQAKACQAbQBwACAAPQAgAEcAZQB0AC0AVwBtAGkATwBiAGoAZQBjAHQAIAAtAE4AYQBtAGUAcwBwAGEAYwBlACAAIgByAG8AbwB0AFwAYwBjAG0AIgAgAC0AQwBsAGEAcwBzACAAUwBNAFMAXwBBAHUAdABoAG8AcgBpAHQAeQAgAC0ARQByAHIAbwByAEEAYwB0AGkAbwBuACAAUwBpAGwAZQBuAHQAbAB5AEMAbwBuAHQAaQBuAHUAZQANAAoAaQBmACAAKAAgACQAbQBwAC4ATgBhAG0AZQAgACkAIAB7AA0ACgAgACAAIAAgACQAaABlAGEAbAB0AGgATABvAGcALgBBAGQAZAAoACAAIgBbACQAKABnAGUAdAAtAGQAYQB0AGUAIAAtAEYAbwByAG0AYQB0ACAAIgBkAGQALQBNAE0ATQAtAHkAeQAgAEgASAA6AG0AbQA6AHMAcwAiACkAXQAgAE0AZQBzAHMAYQBnAGUAOgAgAFMAQwBDAE0AIABTAGkAdABlACAAZgBvAHUAbgBkADoAIAAkACgAIAAkAE0AUAAuAE4AYQBtAGUAIAApACIAIAApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAANAAoAfQAgAGUAbABzAGUAIAB7AA0ACgAgACAAIAAgACQAaABlAGEAbAB0AGgATABvAGcALgBBAGQAZAAoACAAIgBbACQAKABnAGUAdAAtAGQAYQB0AGUAIAAtAEYAbwByAG0AYQB0ACAAIgBkAGQALQBNAE0ATQAtAHkAeQAgAEgASAA6AG0AbQA6AHMAcwAiACkAXQAgAE0AZQBzAHMAYQBnAGUAOgAgAFMATQBTAF8AQQB1AHQAaABvAHIAaQB0AHkALgBOAGEAbQBlACAAcAByAG8AcABlAHIAdAB5ACAAbgBvAHQAIABmAG8AdQBuAGQALgAgAFMAQwBDAE0AIABDAGwAaQBlAG4AdAAgAG0AYQB5ACAAbgBvAHQAIABiAGUAIABpAG4AcwB0AGEAbABsAGUAZAAuACIAIAApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAANAAoAIAAgACAAIAAkAGMAbwByAHIAdQBwAHQAaQBvAG4AIAArAD0AIAAxAA0ACgB9AA0ACgANAAoAIwAgAEMAaABlAGMAawAgAEMAbABpAGUAbgB0ACAASQBEAA0ACgAkAGMAYwBtAEMAbABpAGUAbgB0ACAAPQAgAEcAZQB0AC0AVwBtAGkATwBiAGoAZQBjAHQAIAAtAE4AYQBtAGUAcwBwAGEAYwBlACAAIgByAG8AbwB0AFwAYwBjAG0AIgAgAC0AQwBsAGEAcwBzACAAQwBDAE0AXwBDAGwAaQBlAG4AdAAgAC0ARQByAHIAbwByAEEAYwB0AGkAbwBuACAAUwBpAGwAZQBuAHQAbAB5AEMAbwBuAHQAaQBuAHUAZQANAAoAaQBmACAAKAAgACQAYwBjAG0AQwBsAGkAZQBuAHQALgBDAGwAaQBlAG4AdABJAGQAIAApACAAewANAAoAIAAgACAAIAAkAGgAZQBhAGwAdABoAEwAbwBnAC4AQQBkAGQAKAAgACIAWwAkACgAZwBlAHQALQBkAGEAdABlACAALQBGAG8AcgBtAGEAdAAgACIAZABkAC0ATQBNAE0ALQB5AHkAIABIAEgAOgBtAG0AOgBzAHMAIgApAF0AIABNAGUAcwBzAGEAZwBlADoAIABTAEMAQwBNACAAQwBsAGkAZQBuAHQAIABDAGwAaQBlAG4AdAAgAEkARAAgAGYAbwB1AG4AZAA6ACAAJAAoACAAJABjAGMAbQBDAGwAaQBlAG4AdAAuAEMAbABpAGUAbgB0AEkAZAAgACkAIgAgACkAIAB8ACAATwB1AHQALQBOAHUAbABsAA0ACgB9ACAAZQBsAHMAZQAgAHsADQAKACAAIAAgACAAJABoAGUAYQBsAHQAaABMAG8AZwAuAEEAZABkACgAIAAiAFsAJAAoAGcAZQB0AC0AZABhAHQAZQAgAC0ARgBvAHIAbQBhAHQAIAAiAGQAZAAtAE0ATQBNAC0AeQB5ACAASABIADoAbQBtADoAcwBzACIAKQBdACAATQBlAHMAcwBhAGcAZQA6ACAAQwBDAE0AXwBDAGwAaQBlAG4AdAAuAEMAbABpAGUAbgB0AEkAZAAgAHAAcgBvAHAAZQByAHQAeQAgAG4AbwB0ACAAZgBvAHUAbgBkAC4AIABTAEMAQwBNACAAQwBsAGkAZQBuAHQAIABtAGEAeQAgAG4AbwB0ACAAYgBlACAAaQBuAHMAdABhAGwAbABlAGQALgAiACAAKQAgAHwAIABPAHUAdAAtAE4AdQBsAGwADQAKACAAIAAgACAAJABjAG8AcgByAHUAcAB0AGkAbwBuACAAKwA9ACAAMQANAAoAfQAgACAAIAANAAoAIAAgACAAIAANAAoAIwAgAEMAaABlAGMAawAgAE0AYQBuAGEAZwBlAG0AZQBuAHQAIABQAG8AaQBuAHQAIABDAG8AbQBtAHUAbgBpAGMAYQB0AGkAbwBuAA0ACgAkAG0AcAAgAD0AIABHAGUAdAAtAFcAbQBpAE8AYgBqAGUAYwB0ACAALQBOAGEAbQBlAHMAcABhAGMAZQAgACIAcgBvAG8AdABcAGMAYwBtACIAIAAtAEMAbABhAHMAcwAgAFMATQBTAF8AQQB1AHQAaABvAHIAaQB0AHkAIAAtAEUAcgByAG8AcgBBAGMAdABpAG8AbgAgAFMAaQBsAGUAbgB0AGwAeQBDAG8AbgB0AGkAbgB1AGUADQAKAGkAZgAgACgAIAAkAG0AcAAuAEMAdQByAHIAZQBuAHQATQBhAG4AYQBnAGUAbQBlAG4AdABQAG8AaQBuAHQAIAApACAAewANAAoAIAAgACAAIAAkAGgAZQBhAGwAdABoAEwAbwBnAC4AQQBkAGQAKAAgACIAWwAkACgAZwBlAHQALQBkAGEAdABlACAALQBGAG8AcgBtAGEAdAAgACIAZABkAC0ATQBNAE0ALQB5AHkAIABIAEgAOgBtAG0AOgBzAHMAIgApAF0AIABNAGUAcwBzAGEAZwBlADoAIABTAEMAQwBNACAATQBhAG4AYQBnAGUAbQBlAG4AdAAgAFAAbwBpAG4AdAAgAGYAbwB1AG4AZAA6ACAAJAAoACAAJABtAHAALgBDAHUAcgByAGUAbgB0AE0AYQBuAGEAZwBlAG0AZQBuAHQAUABvAGkAbgB0ACAAKQAiACAAKQAgAHwAIABPAHUAdAAtAE4AdQBsAGwADQAKAH0AIABlAGwAcwBlACAAewANAAoAIAAgACAAIAAkAGgAZQBhAGwAdABoAEwAbwBnAC4AQQBkAGQAKAAgACIAWwAkACgAZwBlAHQALQBkAGEAdABlACAALQBGAG8AcgBtAGEAdAAgACIAZABkAC0ATQBNAE0ALQB5AHkAIABIAEgAOgBtAG0AOgBzAHMAIgApAF0AIABNAGUAcwBzAGEAZwBlADoAIABTAE0AUwBfAEEAdQB0AGgAbwByAGkAdAB5AC4AQwB1AHIAcgBlAG4AdABNAGEAbgBhAGcAZQBtAGUAbgB0AFAAbwBpAG4AdAAgAHAAcgBvAHAAZQByAHQAeQAgAG4AbwB0ACAAZgBvAHUAbgBkAC4AIABTAEMAQwBNACAAQwBsAGkAZQBuAHQAIABtAGEAeQAgAG4AbwB0ACAAYgBlACAAaQBuAHMAdABhAGwAbABlAGQALgAiACAAKQAgAHwAIABPAHUAdAAtAE4AdQBsAGwADQAKACAAIAAgACAAJABjAG8AcgByAHUAcAB0AGkAbwBuACAAKwA9ACAAMQANAAoAfQANAAoADQAKACMAIABDAGgAZQBjAGsAIABTAEMAQwBNACAAQwBsAGkAZQBuAHQAIABIAGUAYQBsAHQAaAAgAEUAdgBhAGwAdQBhAHQAaQBvAG4AIAAoAFUAcwBpAG4AZwAgAEMAQwBNAEUAdgBhAGwAIABMAG8AZwBzACkADQAKACQAYwBjAG0ARQB2AGEAbABMAG8AZwBQAGEAdABoACAAPQAgACIAQwA6AFwAVwBpAG4AZABvAHcAcwBcAEMAQwBNAFwATABvAGcAcwBcAEMAQwBNAEUAdgBhAGwALgBsAG8AZwAiAA0ACgBpAGYAIAAoACAAVABlAHMAdAAtAFAAYQB0AGgAIAAkAGMAYwBtAEUAdgBhAGwATABvAGcAUABhAHQAaAAgACkAIAB7AA0ACgAgACAAIAAgACAAIAAgACAADQAKACAAIAAgACAAIwAgAEcAZQB0ACAAdABoAGUAIABjAHUAcgByAGUAbgB0ACAAZABhAHQAZQAgAGEAbgBkACAAYwBhAGwAYwB1AGwAYQB0AGUAIAB0AGgAZQAgAGQAYQB0AGUAIABhACAAdwBlAGUAawAgAGEAZwBvAA0ACgAgACAAIAAgACQAbABhAHMAdABXAGUAZQBrAEQAYQB0AGUAIAA9ACAAJAAoACAARwBlAHQALQBEAGEAdABlACAAKQAuAEEAZABkAEQAYQB5AHMAKAAgAC0ANwAgACkADQAKAA0ACgAgACAAIAAgACMAIABSAGUAZwBlAHgAIABwAGEAdAB0AGUAcgBuACAAdABvACAAbQBhAHQAYwBoACAAbABvAGcAIABlAG4AdAByAGkAZQBzACAAdwBpAHQAaAAgAGQAYQB0AGUAcwANAAoAIAAgACAAIAAkAHAAYQB0AHQAZQByAG4AIAA9ACAAJwA8AHQAaQBtAGUAPQAiAC4AKgA/ACIAIABkAGEAdABlAD0AIgAoAFwAZAB7ADIAfQApAC0AKABcAGQAewAyAH0AKQAtACgAXABkAHsANAB9ACkAIgAnAA0ACgANAAoAIAAgACAAIAAjACAAUgBlAGEAZAAgAHQAaABlACAAbABvAGcAIABmAGkAbABlACAAYQBuAGQAIABmAGkAbAB0AGUAcgAgAGwAbwBnAHMAIABmAHIAbwBtACAAdABoAGUAIABsAGEAcwB0ACAAdwBlAGUAawANAAoAIAAgACAAIAAkAGYAaQBsAHQAZQByAGUAZABMAG8AZwBzACAAPQAgAEcAZQB0AC0AQwBvAG4AdABlAG4AdAAgACQAYwBjAG0ARQB2AGEAbABMAG8AZwBQAGEAdABoACAALQBSAGEAdwAgAHwAIABXAGgAZQByAGUALQBPAGIAagBlAGMAdAAgAHsADQAKACAAIAAgACAAIAAgACAAIABpAGYAIAAoACAAJABfACAALQBtAGEAdABjAGgAIAAkAHAAYQB0AHQAZQByAG4AIAApACAAewANAAoAIAAgACAAIAAgACAAIAAgACAAIAAgACAAJABsAG8AZwBEAGEAdABlACAAPQAgAEcAZQB0AC0ARABhAHQAZQAgACIAJAAoACAAJABtAGEAdABjAGgAZQBzAFsAMQBdACAAKQAvACQAKAAgACQAbQBhAHQAYwBoAGUAcwBbADIAXQAgACkALwAkACgAIAAkAG0AYQB0AGMAaABlAHMAWwAzAF0AIAApACIAIAAtAEYAbwByAG0AYQB0ACAAIgBNAE0ALwBkAGQALwB5AHkAeQB5ACIADQAKACAAIAAgACAAIAAgACAAIAAgACAAIAAgAFsAZABhAHQAZQB0AGkAbQBlAF0AJABsAG8AZwBEAGEAdABlACAALQBnAGUAIAAkAGwAYQBzAHQAVwBlAGUAawBEAGEAdABlAA0ACgAgACAAIAAgACAAIAAgACAAfQANAAoAIAAgACAAIAB9AA0ACgANAAoAIAAgACAAIAAjACAAUwBlAGEAcgBjAGgAZQBzACAAZgBpAGwAdABlAHIAZQBkACAAbABvAGcAcwAgACgAbABhAHMAdAAgAHcAZQBlAGsAKQAgAGYAbwByACAAdABoAGUAIABzAHQAcgBpAG4AZwAgACIAZgBhAGkAbAAuACIADQAKACAAIAAgACAAJABjAGMAbQBFAHYAYQBsAFIAZQBzAHUAbAB0AHMAIAA9ACAAJABmAGkAbAB0AGUAcgBlAGQATABvAGcAcwAgAHwAIABmAGkAbgBkAHMAdAByACAALwBpACAAZgBhAGkAbAANAAoADQAKACAAIAAgACAAaQBmACAAKAAgACQAYwBjAG0ARQB2AGEAbABSAGUAcwB1AGwAdABzACAAKQAgAHsADQAKACAAIAAgACAAIAAgACAAIAAkAGgAZQBhAGwAdABoAEwAbwBnAC4AQQBkAGQAKAAgACIAWwAkACgAZwBlAHQALQBkAGEAdABlACAALQBGAG8AcgBtAGEAdAAgACIAZABkAC0ATQBNAE0ALQB5AHkAIABIAEgAOgBtAG0AOgBzAHMAIgApAF0AIABNAGUAcwBzAGEAZwBlADoAIABTAEMAQwBNACAAQwBsAGkAZQBuAHQAIABoAGUAYQBsAHQAaAAgAGMAaABlAGMAawAgAGYAYQBpAGwAZQBkACAAcABlAHIAIABDAEMATQBFAHYAYQBsACAAbABvAGcAcwAuACIAIAApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAANAAoAIAAgACAAIAAgACAAIAAgACQAbQBvAHMAdABSAGUAYwBlAG4AdABGAGEAaQBsACAAPQAgACIAJAAoACAAJABjAGMAbQBFAHYAYQBsAFIAZQBzAHUAbAB0AHMAIAB8ACAAcwBlAGwAZQBjAHQAIAAtAGwAYQBzAHQAIAAxACAAKQAuACIADQAKACAAIAAgACAAIAAgACAAIABpAGYAIAAoACQAbQBvAHMAdABSAGUAYwBlAG4AdABGAGEAaQBsACAALQBtAGEAdABjAGgAIAAnAEwATwBHAFwAWwAoAC4AKgA/ACkAXABdAEwATwBHACcAKQAgAHsADQAKACAAIAAgACAAIAAgACAAIAAgACAAIAAgACQAZgBhAGkAbABNAHMAZwAgAD0AIAAkAG0AYQB0AGMAaABlAHMAWwAxAF0ADQAKACAAIAAgACAAIAAgACAAIAAgACAAIAAgACQAaABlAGEAbAB0AGgATABvAGcALgBBAGQAZAAoACAAIgBbACQAKABnAGUAdAAtAGQAYQB0AGUAIAAtAEYAbwByAG0AYQB0ACAAIgBkAGQALQBNAE0ATQAtAHkAeQAgAEgASAA6AG0AbQA6AHMAcwAiACkAXQAgAE0AZQBzAHMAYQBnAGUAOgAgACQAKAAgACQAZgBhAGkAbABNAHMAZwAgACkALgAiACAAKQAgAHwAIABPAHUAdAAtAE4AdQBsAGwADQAKACAAIAAgACAAIAAgACAAIAB9AA0ACgAgACAAIAAgACAAIAAgACAAJABjAG8AcgByAHUAcAB0AGkAbwBuACAAKwA9ACAAMQANAAoAIAAgACAAIAB9ACAAZQBsAHMAZQAgAHsADQAKACAAIAAgACAAIAAgACAAIAAkAGgAZQBhAGwAdABoAEwAbwBnAC4AQQBkAGQAKAAgACIAWwAkACgAZwBlAHQALQBkAGEAdABlACAALQBGAG8AcgBtAGEAdAAgACIAZABkAC0ATQBNAE0ALQB5AHkAIABIAEgAOgBtAG0AOgBzAHMAIgApAF0AIABNAGUAcwBzAGEAZwBlADoAIABTAEMAQwBNACAAQwBsAGkAZQBuAHQAIABwAGEAcwBzAGUAZAAgAGgAZQBhAGwAdABoACAAYwBoAGUAYwBrACAAcABlAHIAIABDAEMATQBFAHYAYQBsACAAbABvAGcAcwAuACIAIAApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAANAAoAIAAgACAAIAB9AA0ACgB9ACAAZQBsAHMAZQAgAHsADQAKACAAIAAgACAAJABoAGUAYQBsAHQAaABMAG8AZwAuAEEAZABkACgAIAAiAFsAJAAoAGcAZQB0AC0AZABhAHQAZQAgAC0ARgBvAHIAbQBhAHQAIAAiAGQAZAAtAE0ATQBNAC0AeQB5ACAASABIADoAbQBtADoAcwBzACIAKQBdACAATQBlAHMAcwBhAGcAZQA6ACAAQwBDAE0ARQB2AGEAbAAgAGwAbwBnACAAbgBvAHQAIABmAG8AdQBuAGQALgAgAFUAbgBhAGIAbABlACAAdABvACAAdgBlAHIAaQBmAHkAIABTAEMAQwBNACAAQwBsAGkAZQBuAHQAIABoAGUAYQBsAHQAaAAuACIAIAApACAAfAAgAE8AdQB0AC0ATgB1AGwAbAANAAoAIAAgACAAIAAkAGMAbwByAHIAdQBwAHQAaQBvAG4AIAArAD0AIAAxAA0ACgB9AA0ACgANAAoAaQBmACAAKAAgACQAYwBvAHIAcgB1AHAAdABpAG8AbgAgAC0AZQBxACAAMAAgACkAewANAAoAIAAgACAAIAAkAHIAZQBzAHUAbAB0AHMAIAA9ACAAIgBIAGUAYQBsAHQAaAB5ACAAQwBsAGkAZQBuAHQAIgANAAoAfQAgAGUAbABzAGUAIAB7AA0ACgAgACAAIAAgACQAcgBlAHMAdQBsAHQAcwAgAD0AIAAiAEMAbwByAHIAdQBwAHQAIABDAGwAaQBlAG4AdAAsACAAJABmAGEAaQBsAE0AcwBnACIADQAKAH0ADQAKAA0ACgBpAGYAIAAoACAALQBuAG8AdAAgACgAIABUAGUAcwB0AC0AUABhAHQAaAAgACQAaABlAGEAbAB0AGgATABvAGcAUABhAHQAaAAgACkAKQB7AA0ACgAgACAAIAAgAG0AawBkAGkAcgAgACQAaABlAGEAbAB0AGgATABvAGcAUABhAHQAaAANAAoAfQANAAoADQAKACQAaABlAGEAbAB0AGgATABvAGcAIAA+AD4AIAAkAGgAZQBhAGwAdABoAEwAbwBnAFAAYQB0AGgAXABIAGUAYQBsAHQAaABDAGgAZQBjAGsALgB0AHgAdAANAAoAcgBlAHQAdQByAG4AIAAkAHIAZQBzAHUAbAB0AHMA"

# Compare hostname with API to determine timezone
$uri = "https://ssdcorpappsrvt1.dpos.loc/esper/Device/AllStores"
$header = @{"accept" = "text/plain"}
$web = Invoke-WebRequest -Uri $uri -Headers $header
$db = $web.content | ConvertFrom-Json
$site = $db | select storeNumber,siteCode,ipSubnet,timeZone | where sitecode -eq ($(hostname).substring(1,4))

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCommand"

# Set day and time based on even/odd store number
if (( $site.storeNumber % 2 ) -eq 0 ){
    $dayOfTheWeek = "Tuesday" # EVEN
}
else{
    $dayOfTheWeek = "Thursday" # ODD
}
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dayOfTheWeek -At 5am

$settings = New-ScheduledTaskSettingsSet -WakeToRun

$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount

$description = "Will download, store locally newest update to Check-SCCMHealth, and then run it. Output will be stored locally until retrieved by server."


Register-ScheduledTask -TaskName "Check-SCCMHealthTask" `
                       -Action $action `
                       -Trigger $trigger `
                       -settings $settings `
                       -Principal $principal `
                       -Description $description

if(Get-ScheduledTask -TaskName Check-SCCMHealthTask){
    $result = "Created task"
} else{
    $result = "Failed to create task"
}
return $result