# ip-calc

## IP calc - how to use?
The script is in a development version, at the moment not all the required functionality has been completed

Below is a table with a description of the possible parameters and the status of their implementation.
| Status        | Parameter    | Flag  | Description                                                          |
| --------------| ------------ | ----- | -------------------------------------------------------------------- |
| finished      | --batch      | -B    | Add the option name before the result                                |
| finished      | --netmask    | -nm   | Network mask                                                         |
| finished      | --cidr       | -c    | CIDR prefix length                                                   |
| finished      | --count      | -ct   | Number of addresses in the subnet                                    |
| finished      | --count-host | -cth  | Number of addresses on the subnet to be used as addressing for hosts |
| finished      | --network    | -nw   | Network address                                                      |
| finished      | --broadcast  | -b    | Broadcast address                                                    |
| finished      | --range      | -r    | The range of IP addresses available for use in the subnet            |
| finished      | --wildcard   | -w    | Converting a Netmask to a Wildcard Mask (Cisco Convention)           |
| in progress   | --next       | -N    | Determining the next (available) IP address for this subnet          |
| in progress   | --prev       | -P    | Determining the previous (available) IP address for this subnet      |
| finished      | --first      | -F    | Provide the first available IP address for a given subnet            |
| finished      | --last       | -L    | Provide the last available IP address for a given subnet             |
| in progress   | --split      | -S    | Divide a network into subnets based on a given mask length           |
| finished      | --all        | -A    | Presentation of all possible information about the IP address        |
| not begun     | --compress   | -co   | Compression (simplification) of an IPv6 address                      |
| not begun     | --expand     | -ex   | IPv6 address extension                                               |

## What's the best way to learn shell scripts?
*Writing a script that does something useful ;)*
