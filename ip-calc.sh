#!/bin/bash
# Kalkulator IP
# wersja: 0.1

PARAMS=(
    "--batch" "-B" "Dodanie nazwy opcji przed wynikiem"
    "--netmask" "-nm" "Maska sieciowa"
    "--cidr" "-c" "Długość prefisku CIDR"
    "--count" "-ct" "Ilość adresów w podsieci"
    "--count-host" "-cth" "Ilość adresów w podsieci do wykorzystania jako adresacja dla hostów"
    "--network" "-nw" "Adres sieci"
    "--broadcast" "-b" "Adres rozgłoszeniowy"
    "--range" "-r" "Zakres dostepnych do użycia adresów IP w podsieci"
    "--wildcard" "-w" "Konwersja maski sieciowej na maskę typu Wildcard (konwencja Cisco)"
    "--next" "-N" "Określenie kolejnego (dostepnego) adresu IP dla danej podsieci"
    "--prev" "-P" "Określenie poprzedniego (dostepnego) adresu IP dla danej podsieci"
    "--first" "-F" "Podanie pierwszego dostepnego adresu IP dla danej podsieci"
    "--last" "-L" "Podanie ostatniego dostepnego adresu IP dla danej podsieci"
    "--split" "-S" "Podział sieci na podsieci na podstawie podanej długości maski"
    "--all" "-A" "Prezentacja wszystkich możliwych informacji o adresie IP"
    "--compress" "-co" "Kompresja (uproszczenie) adresu IPv6"
    "--expand" "-ex" "Rozszerzenie adresu IPv6"
    )
KINDS=(
    "none"
    "IPv4"
    "IPv6"
    "LongNetMask"
    "ShortNetMask"
)
DEFAULTMASK=(
    "255.255.255.0"
    "24"
)
# ==========
# usage() -> funkcja wyświetlająca zawartość pomocy/skróconej obsługi skryptu
# ----
function usage {
    echo "========================================"
    echo "Kalkulator IP - jak korzystać?"
    echo "========================================"
    echo "Wersja rozwojowa ip-calc.sh"
    echo "Skrypt jest w wersji rozwojowej, na chwilę obecną nie została ukończona jeszcze cała wymagana funkcjonalność"
    echo "Poniżej znajduje się tabela z opisem możliwych parametrów i statusem ich realizacji."
    echo " ----------------------------------------------------------------------------------------------------------- "
    echo "| Status        |      Parametr       | Opis                                                                |"
    echo " ----------------------------------------------------------------------------------------------------------- "
    echo "| ukończony     | --batch      | -B   | Dodanie nazwy opcji przed wynikiem                                  |"
    echo "| ukończony     | --netmask    | -nm  | Maska sieciowa                                                      |"
    echo "| ukończony     | --cidr       | -c   | Długość prefisku CIDR                                               |"
    echo "| ukończony     | --count      | -ct  | Ilość adresów w podsieci                                            |"
    echo "| ukończony     | --count-host | -cth | Ilość adresów w podsieci do wykorzystania jako adresacja dla hostów |"
    echo "| ukończony     | --network    | -nw  | Adres sieci                                                         |"
    echo "| ukończony     | --broadcast  | -b   | Adres rozgłoszeniowy                                                |"
    echo "| ukończony     | --range      | -r   | Zakres dostepnych do użycia adresów IP w podsieci                   |"
    echo "| ukończony     | --wildcard   | -w   | Konwersja maski sieciowej na maskę typu Wildcard (konwencja Cisco)  |"
    echo "| w realizacji  | --next       | -N   | Określenie kolejnego (dostepnego) adresu IP dla danej podsieci      |"
    echo "| w realizacji  | --prev       | -P   | Określenie poprzedniego (dostepnego) adresu IP dla danej podsieci   |"
    echo "| ukończony     | --first      | -F   | Podanie pierwszego dostepnego adresu IP dla danej podsieci          |"
    echo "| ukończony     | --last       |  L   | Podanie ostatniego dostepnego adresu IP dla danej podsieci          |"
    echo "| w realizacji  | --split      | -S   | Podział sieci na podsieci na podstawie podanej długości maski       |"
    echo "| ukończony     | --all        | -A   | Prezentacja wszystkich możliwych informacji o adresie IP            |"
    echo "| nierozpoczęty | --compress   | -co  | Kompresja (uproszczenie) adresu IPv6                                |"
    echo "| nierozpoczęty | --expand     | -ex  | Rozszerzenie adresu IPv6                                            |"
    echo " ----------------------------------------------------------------------------------------------------------- "
}

# ==========
# error() -> funkcja zwracająca komunikat błędu
# ----
function error {
    echo "Błąd: "$@
    exit 1
}

# ==========
# validateFlags() -> funkcja walidująca flagi podane podczas uruchamiania skryptu
# Zwraca true, gdy flaga jest prawidłowa
# ----
function validateFlag {
    local arr=("$@")
    for param in "${arr[@]:1}"; do
        if [[ "$param" = "${arr[0]}" ]]; then
            return 0
            break
        fi
    done
    return 1
}

# ==========
# validateAddress() -> funkcja walidująca argumenty podane podczas uruchamiania skryptu
# https://regexr.com/
# IPv4: ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$
# Netmask_IPv4: ^(((255\.){3}(255|254|252|248|240|224|192|128+))|((255\.){2}(255|254|252|248|240|224|192|128|0+)\.0)|((255\.)(255|254|252|248|240|224|192|128|0+)(\.0+){2})|((255|254|252|248|240|224|192|128|0+)(\.0+){3}))$
# 
# ----
function validateAddress {
    local arr=("$@")
    local patternIPv4="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    local patternIPv6=""
    local patternLongNetMask="^(((255\.){3}(255|254|252|248|240|224|192|128+))|((255\.){2}(255|254|252|248|240|224|192|128|0+)\.0+)|((255\.)(255|254|252|248|240|224|192|128|0+)(\.0+){2})|((255|254|252|248|240|224|192|128|0+)(\.0+){3}))$"
    local patternShortNetMask="^(([0-9])|([1-2][0-9])|(3[0-2]))$"
    local pattern=""
    case ${arr[0]} in
        ${KINDS[1]} )
            pattern=$patternIPv4
            ;;
        ${KINDS[2]} )
            pattern=$patternIPv6
            ;;
        ${KINDS[3]} )
            pattern=$patternLongNetMask
            ;;
        ${KINDS[4]} )
            pattern=$patternShortNetMask
            ;;
    esac
    if [[ ${arr[1]} =~ $pattern ]]; then
        return 0
        break
    fi
    return 1
}

function determineArgumentsKind {
    local arr=("$@")
    if [[ ${#args[@]} -gt 2 ]]; then
        error "Za dużo argumentów:" ${args[@]}
    elif [[ ${#args[@]} -eq 2 ]] && [[ ${args[0]} == *"."* ]] && [[ ${args[1]} == *"."* ]] && [[ ${args[@]} == *" "* ]]; then
        addressKind=${KINDS[1]}
        netmaskKind=${KINDS[3]}
    elif [[ ${#args[@]} -eq 1 ]] && [[ ${args[0]} == *"."* ]] && [[ ${args[0]} == *"/"* ]]; then
        addressKind=${KINDS[1]}
        netmaskKind=${KINDS[4]}
    elif [[ ${#args[@]} -eq 1 ]] && [[ ${args[0]} == *"."* ]]; then
        addressKind=${KINDS[1]}
        netmaskKind=${KINDS[0]}
    fi
}

# ==========
# parseParametrs() -> funkcja parsująca parametry wejściowe skryptu, 
# zwraca parametry w dwóch tablicach: 
# flags -> dla parametrów będących flagą ("--AAAA", "-a")
# address -> dla parametrów będących argumentem (adres ip)
# ----
function parseParameters {
    declare -a PARAMETERS=("$@")
    declare -i j=0
    declare -i k=0
    declare -i l=0
    local -a args=()
    declare -a badFlags=()
    declare -a badAddress=()
    for i in "${!PARAMETERS[@]}"; do
        if [[ ${PARAMETERS[$(($i-1))]} == "--split" ]] || [[ ${PARAMETERS[$(($i-1))]} == "-S" ]]; then
            splitArgument="${PARAMETERS[$i]}"
        elif [[ ${PARAMETERS[i]} == *"--"* ]] || [[ ${PARAMETERS[i]} == *"-"* ]]; then
            if validateFlag "${PARAMETERS[i]}" "${PARAMS[@]}"; then
                flags[$(($k))]="${PARAMETERS[$i]}"
                k=$(($k+1));
            else
                badFlags[$(($l))]=${PARAMETERS[i]}
                l=$(($l+1));
            fi
        else
            if [[ ${PARAMETERS[i]} == *" "* ]] || [[ ${PARAMETERS[i]} == *"/"* ]] || [[ ${PARAMETERS[i]} == *"."* ]] || [[ ${PARAMETERS[i]} == *":"* ]]; then
                args[$(($j))]="${PARAMETERS[$i]}"
                j=$(($j+1))
            else
                error "Nie poprawny argument:" ${PARAMETERS[i]}
            fi
        fi
    done
    determineArgumentsKind "${args[0]}"
    #echo "${args[@]}"
    if [[ $splitArgument ]]; then
        validateAddress ${KINDS[4]} "${splitArgument}" || error "Nie poprawna maska sieciowa do podziału na podsieci:" ${splitArgument}
    fi
    if [[ -z  $args ]]; then
        error "Brak argumentów" 
    fi
    if [[ $addressKind == ${KINDS[1]} ]] && [[ $netmaskKind == ${KINDS[3]} ]]; then
        validateAddress ${KINDS[1]} "${args[0]}" && address="${args[0]}" || error "Nie poprawny adres IPv4:" ${args[0]};
        validateAddress ${KINDS[3]} "${args[1]}" && netmask="${args[1]}" || error "Nie poprawna maska sieciowa:" ${args[1]};
    fi
    if [[ $addressKind == ${KINDS[1]} ]] && [[ $netmaskKind == ${KINDS[4]} ]]; then
        validateAddress ${KINDS[1]} "${args[0]%"/"*}" && address="${args[0]%"/"*}" || error "Nie poprawny adres IPv4:" ${args[0]%"/"*};
        validateAddress ${KINDS[4]} "${args[0]#*"/"}" && cidr="${args[0]#*"/"}" || error "Nie poprawna maska sieciowa:" ${args[0]#*"/"};
    fi
    if [[ $addressKind == ${KINDS[1]} ]] && [[ $netmaskKind == ${KINDS[0]} ]]; then
        validateAddress ${KINDS[1]} "${args[0]}" && address="${args[0]}" netmask=${DEFAULTMASK[0]} cidr=${DEFAULTMASK[1]} || error "Nie poprawny adres IPv4:" ${args[0]};
    fi
    if [[ ${#badFlags[@]} -gt 0 ]]; then
        error "Nie poprawny parametr:" "${badFlags[@]}"
    fi
}

# ==========
# bin2dec() -> 
# ----
function bin2dec {
    local -a bin=("$@")
    local dec=0
    for item in ${bin[@]}; do
        dec=$(( 2 * $dec + $item ))
    done
    echo $dec
}

# ==========
# dec2bin() -> 
# ----
function dec2bin {
    local dec=$1
    local reminder=""
    declare -a bin=(0 0 0 0 0 0 0 0)
    local i=0
    while [ $dec -gt 0 ]; do
        reminder=$(($dec%2))
        dec=$(($dec/2))
        bin[$((7-$i))]=${reminder}
        i=$(($i+"1"))
    done
    echo ${bin[@]}
}

# ==========
# netmask() -> 
# ----
function netmask {
    if [[ $netmaskKind == "ShortNetMask" ]]; then
        local -a octetBinA=()
        local -a octetBinB=()
        local -a octetBinC=()
        local -a octetBinD=()
        for (( i=1; i<=32; i++ )) do
            if [[ $i -le 8 ]]; then
                if [[ $i -le $cidr ]]; then
                    octetBinA[$i]=1
                else
                    octetBinA[$i]=0
                fi
            elif [[ $i -le 16 ]] && [[ $i -gt 8 ]]; then
                if [[ $i -le $cidr ]]; then
                    octetBinB[$i]=1
                else
                    octetBinB[$i]=0
                fi
            elif [[ $i -le 24 ]] && [[ $i -gt 16 ]]; then
                if [[ $i -le $cidr ]]; then
                    octetBinC[$i]=1
                else
                    octetBinC[$i]=0
                fi
            elif [[ $i -le 32 ]] && [[ $i -gt 24 ]]; then
                if [[ $i -le $cidr ]]; then
                    octetBinD[$i]=1
                else
                    octetBinD[$i]=0
                fi
            fi
        done
        local octetDecA=$(bin2dec ${octetBinA[@]})
        local octetDecB=$(bin2dec ${octetBinB[@]})
        local octetDecC=$(bin2dec ${octetBinC[@]})
        local octetDecD=$(bin2dec ${octetBinD[@]})
        netmask=$octetDecA"."$octetDecB"."$octetDecC"."$octetDecD
    fi
}

# ==========
# cidr() -> 
# ----
function cidr {
    if [[ $netmaskKind == "LongNetMask" ]]; then
        local rest=""
        declare -a octetBinA=($(dec2bin ${netmask%%"."*}))
        rest=${netmask#*"."}
        declare -a octetBinB=($(dec2bin ${rest%%"."*}))
        rest=${rest#*"."}
        declare -a octetBinC=($(dec2bin ${rest%%"."*}))
        rest=${rest#*"."}
        declare -a octetBinD=($(dec2bin $rest))
        local counter=0
        for (( i=0; i<8; i++ )) do
            if [[ ${octetBinA[$i]} == 1 ]]; then
                counter=$(($counter+1))
            fi
        done
        for (( i=0; i<8; i++ )) do
            if [[ ${octetBinB[$i]} == 1 ]]; then
                counter=$(($counter+1))
            fi
        done
        for (( i=0; i<8; i++ )) do
            if [[ ${octetBinC[$i]} == 1 ]]; then
                counter=$(($counter+1))
            fi
        done
        for (( i=0; i<8; i++ )) do
            if [[ ${octetBinD[$i]} == 1 ]]; then
                counter=$(($counter+1))
            fi
        done
        cidr=$counter
    fi
}

# ==========
# count() -> 
# ----
function count {
    if [[ -z  $cidr ]]; then
        cidr
    fi
    local zeros=$((32-$cidr))
    count=$((2 ** $zeros))
}

# ==========
# countHost() -> 
# ----
function countHost {
    if [[ -z  $count ]]; then
        count
    fi
    if [[ $(($count - 2)) -le 0 ]]; then 
        countHost=0
    else
        countHost=$(($count - 2))
    fi
}

# ==========
# network() -> 
# ----
function network {
    if [[ -z  $netmask ]]; then
        netmask
    fi
    local rest=""
    declare -i octetAddressDecA=${address%%"."*}
    rest=${address#*"."}
    declare -i octetAddressDecB=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetAddressDecC=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetAddressDecD=$rest
    declare -i octetNetmaskDecA=${netmask%%"."*}
    rest=${netmask#*"."}
    declare -i octetNetmaskDecB=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetNetmaskDecC=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetNetmaskDecD=$rest
    local octetNetworkDecA=$(( $octetAddressDecA & $octetNetmaskDecA ))
    local octetNetworkDecB=$(( $octetAddressDecB & $octetNetmaskDecB ))
    local octetNetworkDecC=$(( $octetAddressDecC & $octetNetmaskDecC ))
    local octetNetworkDecD=$(( $octetAddressDecD & $octetNetmaskDecD ))
    network=$octetNetworkDecA"."$octetNetworkDecB"."$octetNetworkDecC"."$octetNetworkDecD
}

# ==========
# broadcast() -> 
# ----
function broadcast {
    if [[ -z  $wildcard ]]; then
        wildcard
    fi
    local rest=""
    declare -i octetAddressDecA=${address%%"."*}
    rest=${address#*"."}
    declare -i octetAddressDecB=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetAddressDecC=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetAddressDecD=$rest
    declare -i octetWildcardDecA=${wildcard%%"."*}
    rest=${wildcard#*"."}
    declare -i octetWildcardDecB=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetWildcardDecC=${rest%%"."*}
    rest=${rest#*"."}
    declare -i local octetWildcardDecD=$rest
    local octetBroadcastDecA=$(( $octetAddressDecA | $octetWildcardDecA ))
    local octetBroadcastDecB=$(( $octetAddressDecB | $octetWildcardDecB ))
    local octetBroadcastDecC=$(( $octetAddressDecC | $octetWildcardDecC ))
    local octetBroadcastDecD=$(( $octetAddressDecD | $octetWildcardDecD ))
    broadcast=$octetBroadcastDecA"."$octetBroadcastDecB"."$octetBroadcastDecC"."$octetBroadcastDecD
}

# ==========
# range() -> 
# ----
function range {
    if [[ -z  $first ]]; then
        first
    fi
    if [[ -z  $last ]]; then
        last
    fi
    range=$first"-"$last
}

# ==========
# wildcard() -> 
# ----
function wildcard {
    if [[ -z  $netmask ]]; then
        netmask
    fi
    local rest=""
    declare -i octetNetmaskDecA=${netmask%%"."*}
    rest=${netmask#*"."}
    declare -i octetNetmaskDecB=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetNetmaskDecC=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetNetmaskDecD=$rest
    local octetWildcardDecA=$((~ $octetNetmaskDecA & 0xFF))
    local octetWildcardDecB=$((~ $octetNetmaskDecB & 0xFF))
    local octetWildcardDecC=$((~ $octetNetmaskDecC & 0xFF))
    local octetWildcardDecD=$((~ $octetNetmaskDecD & 0xFF))
    wildcard=$octetWildcardDecA"."$octetWildcardDecB"."$octetWildcardDecC"."$octetWildcardDecD
}

# ==========
# next() -> 
# ----
function next {
    if [[ -z  $network ]]; then
        network
    fi
    if [[ -z  $broadcast ]]; then
        broadcast
    fi
    local rest=""
    declare -i octetAddressDecA=${address%%"."*}
    rest=${address#*"."}
    declare -i octetAddressDecB=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetAddressDecC=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetAddressDecD=$rest
    
    declare -i octetNetworkDecA=${network%%"."*}
    rest=${network#*"."}
    declare -i octetNetworkDecB=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetNetworkDecC=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetNetworkDecD=$rest

    declare -i octetBroadcastDecA=${broadcast%%"."*}
    rest=${broadcast#*"."}
    declare -i octetBroadcastDecB=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetBroadcastDecC=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetBroadcastDecD=$rest

    local octetNextDecA=""
    local octetNextDecB=""
    local octetNextDecC=""
    local octetNextDecD=""
    
    echo "  NETWORK:" $octetNetworkDecA"."$octetNetworkDecB"."$octetNetworkDecC"."$octetNetworkDecD
    echo "  ADDRESS:" $octetAddressDecA"."$octetAddressDecB"."$octetAddressDecC"."$octetAddressDecD
    echo "BROADCAST:" $octetBroadcastDecA"."$octetBroadcastDecB"."$octetBroadcastDecC"."$octetBroadcastDecD
    
    #if [[ $(($octetAddressDecA +1)) -gt $octetNetworkDecA ]] && [[ $(($octetAddressDecA +1)) -lt $octetBroadcastDecA ]]; then
    #    octetNextDecA=$(($octetAddressDecA +1))
    #else
    #    octetNextDecA=$octetAddressDecA
    #fi
    #if [[ $(($octetAddressDecB +1)) -gt $octetNetworkDecB ]] && [[ $(($octetAddressDecB +1)) -lt $octetBroadcastDecB ]]; then
    #    octetNextDecB=$(($octetAddressDecB +1))
    #else
    #    octetNextDecB=$octetAddressDecB
    #fi
    #if [[ $(($octetAddressDecC +1)) -gt $octetNetworkDecC ]] && [[ $(($octetAddressDecC +1)) -lt $octetBroadcastDecC ]]; then
    #    octetNextDecC=$(($octetAddressDecC +1))
    #else
    #    octetNextDecC=$octetAddressDecC
    #fi
    #if [[ $(($octetAddressDecD +1)) -gt $octetNetworkDecD ]] && [[ $(($octetAddressDecD +1)) -lt $octetBroadcastDecD ]]; then
    #    octetNextDecD=$(($octetAddressDecD +1))
    #    if 
    #else
    #    octetNextDecD=$octetAddressDecD
    #fi
#    echo $octetNextDecA"."$octetNextDecB"."$octetNextDecC"."$octetNextDecD
    #next=$octetNextDecA"."$octetNextDecB"."$octetNextDecC"."$octetNextDecD
    #if [[ $(($octetAddressDecD +1)) -lt $octetBroadcastDecD ]]; then
    #    next=${address%"."*}"."$(( ${address##*"."} + 1))
    #else
    #    echo""
    #fi

}

# ==========
# prev() -> 
# ----
function prev {
    prev=${address%"."*}"."$(( ${address##*"."} - 1))
}

# ==========
# first() -> 
# ----
function first {
    if [[ -z  $network ]]; then
        network
    fi
    first=${network%"."*}"."$(( ${network##*"."} + 1))
}

# ==========
# last() -> 
# ----
function last {
    if [[ -z  $broadcast ]]; then
        broadcast
    fi
    last=${broadcast%"."*}"."$(( ${broadcast##*"."} - 1))
}

# ==========
# split() -> 
# ----
function split {
    # http://admintools.com.ua/ipcalc/split/?process=1&network=192.168.23.15%2F25&split_by=28
    if [[ -z  $network ]]; then
        network
    fi
    if [[ -z  $broadcast ]]; then
        broadcast
    fi
    if [[ -z  $cidr ]]; then
        cidr
    fi
    beforeSplit=$((2 ** $((32-$cidr))))
    afterSplit=$((2 ** $((32-$splitArgument))))
    echo $splitArgument
    echo $network
    declare -i octetAddressDecA=${address%%"."*}
    rest=${address#*"."}
    declare -i octetAddressDecB=${rest%%"."*}
    rest=${rest#*"."}
    declare -i octetAddressDecC=${rest%%"."*}
    echo $broadcast
    echo $cidr
    echo $beforeSplit
    echo $afterSplit
    echo "-----"
    for (( d=0; d<$beforeSplit; d += $afterSplit )) do
        echo $octetAddressDecA"."$octetAddressDecB"."$octetAddressDecC"."$d"/"$splitArgument
    done
    echo "-----"
    return 0
}

# ==========
# compress() -> 
# ----
function compress {
    return 0
}

# ==========
# expand() -> 
# ----
function expand {
    return 0
}

# ==========
# batch() -> jeżeli flaga: --batch, lub -B została wprowadzona, funkcja wyświeli również nazwę dla zwracanego wyniku
# ----
function batch {
    if [[ "${flags[@]}" =~ "${PARAMS[0]}" ]] || [[ "${flags[@]}" =~ "${PARAMS[1]}" ]]; then
        echo ${PARAMS[(($1))]}":" $2
    else
        echo $2
    fi
}

# ==========
# all() -> jeżeli flaga: --all, lub -A została wprowadzona, funkcja wyświeli wszystkie możliwe informacje o adresie ip
# ----
function all {
    network
    cidr
    broadcast
    range
    wildcard
    count
    echo "Kind:" $addressKind
    echo "Host address:" $address
    echo "Network address:" $network
    echo "CIDR:" $cidr
    echo "Broadcast:" $broadcast
    echo "Usable range:" $range
    echo "Wildcard:" $wildcard
    echo "Addresses in network:" $count
}

# ==========
# execute() -> funkcja uruchamiająca funkcje w zależności od zadanych w poleceniu flag na wejściu, 
# zwraca wyniki działania wywoływanych funkcji
# ----
function execute {
    declare -i l=0
    while [ ${#flags[@]} -ne $(($l)) ]; do
        case ${flags[$(($l))]} in
        "${PARAMS[3]}"|"${PARAMS[4]}" )
            # "--netmask" "-nm" "Maska sieciowa"
            netmask
            batch "5" $netmask
            ;;
        "${PARAMS[6]}"|"${PARAMS[7]}" )
            # "--cidr" "-c" "Długość prefisku CIDR"
            cidr
            batch "8" "/"$cidr
            ;;
        "${PARAMS[9]}"|"${PARAMS[10]}" )
            # "--count" "-ct" "Ilość adresów w podsieci"
            count
            batch "11" $count
            ;;
        "${PARAMS[12]}"|"${PARAMS[13]}" )
            # "--count-host" "-cth" "Ilość adresów w podsieci do wykorzystania jako adresacja dla hostów"
            echo "Wyświetla niepoprawne wyniki dla masek /31 /32 -> do przemyślenia i poprawy. Obecnie zwraca jedynie dostępną do wykorzystania ilość hostów dla danej podsieci, która dla masek /31 /32 wynosi 0."
            countHost
            batch "14" $countHost
            ;;
        "${PARAMS[15]}"|"${PARAMS[16]}" )
            # "--network" "-nw" "Adres sieci"
            network
            batch "17" $network
            ;;
        "${PARAMS[18]}"|"${PARAMS[19]}" )
            # "--broadcast" "-b" "Adres rozgłoszeniowy"
            broadcast
            batch "20" $broadcast
            ;;
        "${PARAMS[21]}"|"${PARAMS[22]}" )
            # "--range" "-r" "Zakres dostepnych do użycia adresów IP w podsieci"
            range
            batch "23" $range
            ;;
        "${PARAMS[24]}"|"${PARAMS[25]}" )
            # "--wildcard" "-w" "Konwersja maski sieciowej na maskę typu Wildcard (konwencja Cisco)"
            wildcard
            batch "26" $wildcard
            ;;
        "${PARAMS[27]}"|"${PARAMS[28]}" )
            # "--next" "-N" "Określenie kolejnego (dostepnego) adresu IP dla danej podsieci"
            echo "Funkcjonalność w trakcie realizacji. Nie została jeszcze ukończona. Nie zwraca jeszcze poprawnych wyników."
            next
            batch "29" $next
            ;;
        "${PARAMS[30]}"|"${PARAMS[31]}" )
            # "--prev" "-P" "Określenie poprzedniego (dostepnego) adresu IP dla danej podsieci"
            echo "Funkcjonalność w trakcie realizacji. Nie została jeszcze ukończona. Nie zwraca jeszcze poprawnych wyników."
            prev
            batch "32" $prev
            ;;
        "${PARAMS[33]}"|"${PARAMS[34]}" )
            # "--first" "-F" "Podanie pierwszego dostepnego adresu IP dla danej podsieci"
            first
            batch "35" $first
            ;;
        "${PARAMS[36]}"|"${PARAMS[37]}" )
            # "--last" "-L" "Podanie ostatniego dostepnego adresu IP dla danej podsieci"
            last
            batch "38" $last
            ;;
        "${PARAMS[39]}"|"${PARAMS[40]}" )
            # "--split" "-S" "Podział sieci na podsieci na podstawie podanej długości maski"
            echo "Funkcjonalność w trakcie realizacji. Nie została jeszcze ukończona. Nie zwraca jeszcze poprawnych wyników."
            split
            batch "41" $split
            ;;
        "${PARAMS[42]}"|"${PARAMS[43]}" )
            # "--all" "-A" "Prezentacja wszystkich możliwych informacji o adresie IP"
            batch "44"
            all
            ;;
        "${PARAMS[45]}"|"${PARAMS[46]}" )
            # "--compress" "-co" "Kompresja (uproszczenie) adresu IPv6"
            echo "Ta funkcjonalność nie została jeszcze zrealizowana."
            batch "47" $compress
            ;;
        "${PARAMS[48]}"|"${PARAMS[49]}" )
            # "--expand" "-ex" "Rozszerzenie adresu IPv6"
            echo "Ta funkcjonalność nie została jeszcze zrealizowana."
            batch "50" $expand
            ;;
        "-?"|"--help")
            echo "Pomoc"
            ;;
        esac
        l=$(($l+1))
    done
}

# ==========
# run() -> funkcja główna polecenia, 
# sprawdza istnienie parametrów na wejściu polecenia, i steruje jego wykonaniem 
# ----
function run {
    if [ ${#@} -gt 0 ]; then
        declare -a flags=()
        local splitArgument=""
        local addressKind=""
        local netmaskKind=""
        local address=""
        local netmask=""
        local cidr=""
        local count=""
        local countHost=""
        local network=""
        local broadcast=""
        local range=""
        local wildcard=""
        local next=""
        local prev=""
        local first=""
        local last=""
        parseParameters $@
        execute
    else
        usage
    fi
}


# ==================================================
run ${@}