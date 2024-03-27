#!/bin/bash


# overriding the built in cd, in order to save history
function cd {
    local escapedPWD="${PWD// /__SPACE__}"

    # Initiate MOJIR_DIR_STACK to current directory if not defined
    MOJIR_DIR_STACK=${MOJIR_DIR_STACK:-$escapedPWD};

    # Calculate position in stack if not defined
    MOJIR_DIR_STACK_POS=${MOJIR_DIR_STACK_POS:-$(( ${#MOJIR_DIR_STACK[@]} - 1 ))}

    # avoid recursion by using builtin
    builtin cd "$@"
    escapedPWD="${PWD// /__SPACE__}"
    if [ "${MOJIR_DIR_STACK[$MOJIR_DIR_STACK_POS]}" == "$escapedPWD" ]; then
        return
    fi

    # truncate stack if MOJIR_DIR_STACK_POS somewhere in the middle.
    # You can jump back and forth in stack with cd- and cd+ bu
    # as soon as you cd to a new directory, the forward history
    # is lost.
    MOJIR_DIR_STACK=(${MOJIR_DIR_STACK[@]:0:$(( $MOJIR_DIR_STACK_POS + 1 ))} )

    # Push current dir to stack
    MOJIR_DIR_STACK=("${MOJIR_DIR_STACK[@]}" "$escapedPWD")

    # Restrict the size to 200 elements
    if [ ${#MOJIR_DIR_STACK[@]} -gt 200 ]; then
        MOJIR_DIR_STACK=(${MOJIR_DIR_STACK[@]:1} );
    fi

    # set position to the last element
    MOJIR_DIR_STACK_POS=$(( ${#MOJIR_DIR_STACK[@]} - 1 ))
}

function pushd {
    local escapedPWD="${PWD// /__SPACE__}"

    # Initiate MOJIR_DIR_STACK to current directory if not defined
    MOJIR_DIR_STACK=${MOJIR_DIR_STACK:-$escapedPWD};

    # Calculate position in stack if not defined
    MOJIR_DIR_STACK_POS=${MOJIR_DIR_STACK_POS:-$(( ${#MOJIR_DIR_STACK[@]} - 1 ))}

    # avoid recursion by using builtin
    builtin pushd "$@"
    escapedPWD="${PWD// /__SPACE__}"
    if [ "${MOJIR_DIR_STACK[$MOJIR_DIR_STACK_POS]}" == "$escapedPWD" ]; then
        return
    fi

    # truncate stack if MOJIR_DIR_STACK_POS somewhere in the middle.
    # You can jump back and forth in stack with cd- and cd+ bu
    # as soon as you cd to a new directory, the forward history
    # is lost.
    MOJIR_DIR_STACK=(${MOJIR_DIR_STACK[@]:0:$(( $MOJIR_DIR_STACK_POS + 1 ))} )

    # Push current dir to stack
    MOJIR_DIR_STACK=("${MOJIR_DIR_STACK[@]}" "$escapedPWD")

    # Restrict the size to 200 elements
    if [ ${#MOJIR_DIR_STACK[@]} -gt 200 ]; then
        MOJIR_DIR_STACK=(${MOJIR_DIR_STACK[@]:1} );
    fi

    # set position to the last element
    MOJIR_DIR_STACK_POS=$(( ${#MOJIR_DIR_STACK[@]} - 1 ))
}

function popd {
    local escapedPWD="${PWD// /__SPACE__}"

    # Initiate MOJIR_DIR_STACK to current directory if not defined
    MOJIR_DIR_STACK=${MOJIR_DIR_STACK:-$escapedPWD};

    # Calculate position in stack if not defined
    MOJIR_DIR_STACK_POS=${MOJIR_DIR_STACK_POS:-$(( ${#MOJIR_DIR_STACK[@]} - 1 ))}

    # avoid recursion by using builtin
    builtin popd "$@"
    escapedPWD="${PWD// /__SPACE__}"
    if [ "${MOJIR_DIR_STACK[$MOJIR_DIR_STACK_POS]}" == "$escapedPWD" ]; then
        return
    fi

    # truncate stack if MOJIR_DIR_STACK_POS somewhere in the middle.
    # You can jump back and forth in stack with cd- and cd+ bu
    # as soon as you cd to a new directory, the forward history
    # is lost.
    MOJIR_DIR_STACK=(${MOJIR_DIR_STACK[@]:0:$(( $MOJIR_DIR_STACK_POS + 1 ))} )

    # Push current dir to stack
    MOJIR_DIR_STACK=("${MOJIR_DIR_STACK[@]}" "$escapedPWD")

    # Restrict the size to 200 elements
    if [ ${#MOJIR_DIR_STACK[@]} -gt 200 ]; then
        MOJIR_DIR_STACK=(${MOJIR_DIR_STACK[@]:1} );
    fi

    # set position to the last element
    MOJIR_DIR_STACK_POS=$(( ${#MOJIR_DIR_STACK[@]} - 1 ))
}

# move backward in history
function cd- {
    # Set position to last element if not defined
    MOJIR_DIR_STACK_POS=${MOJIR_DIR_STACK_POS:-$(( ${#MOJIR_DIR_STACK[@]} - 1 ))}

    # decrease position
    MOJIR_DIR_STACK_POS=$(( MOJIR_DIR_STACK_POS - 1 ))

    # Guard, don't cross element boundaries
    if [ $MOJIR_DIR_STACK_POS -lt 0 ]; then
        MOJIR_DIR_STACK_POS=0
        return
    fi

    # avoid recursion by using builtin
    local path=${MOJIR_DIR_STACK[$MOJIR_DIR_STACK_POS]}
    builtin cd "${path//__SPACE__/ }"
}

# move forward in history
function cd+ {
    # Set position to last element if not defined
    MOJIR_DIR_STACK_POS=${MOJIR_DIR_STACK_POS:-$(( ${#MOJIR_DIR_STACK[@]} - 1 ))}

    # increase position
    MOJIR_DIR_STACK_POS=$(( MOJIR_DIR_STACK_POS + 1 ))

    # Guard, don't cross element boundaries
    if [ $MOJIR_DIR_STACK_POS -ge ${#MOJIR_DIR_STACK[@]} ]; then
        MOJIR_DIR_STACK_POS=$(( ${#MOJIR_DIR_STACK[@]} - 1 ))
        return
    fi

    # avoid recursion by using builtin
    local path=${MOJIR_DIR_STACK[$MOJIR_DIR_STACK_POS]}
    builtin cd "${path//__SPACE__/ }"
}

# list directory history, mark current position with an asterisk
# Ask user to enter numer of directory to go there
function cd? {

    # number of elements in history
    local count=${#MOJIR_DIR_STACK[@]}
    if [ $count -eq 0 ]; then return; fi
    
    local input
    if [ ! -z $1 ]; then
        input=$1
    else
        # column width for sequence number
        local width=2
        if [ $count -ge 10 ]; then width=$(( width + 1 )); fi
        if [ $count -ge 100 ]; then width=$(( width + 1 )); fi

        local i
        local empty=1
        for i in $(seq $count -1 1); do
            # substitute home folder to ~
            local path="${MOJIR_DIR_STACK[ $(( count - i )) ]/#$HOME/~}"
            path="${path//__SPACE__/ }"
            local marker
            [ $MOJIR_DIR_STACK_POS -eq $(( count - i )) ] && marker="* " || marker="  "
            printf "%-${width}d%s%s\n" "$i" "$marker" "$path"
            empty=0
        done
        if [ $empty -eq 1 ]; then return; fi

        echo -n "Directory number: "
        read input
    fi

    # Empty input cancels
    if [ -z $input ]; then return; fi

    # match digits
    if [[ $input = *[![:digit:]]* ]]; then echo "Invalid number"; return; fi
    if [ $input -lt 1 ]; then echo "Invalid number"; return; fi
    if [ $input -gt $count ]; then echo "Invalid number"; return; fi

    MOJIR_DIR_STACK_POS=$((${#MOJIR_DIR_STACK[@]} - $input))

    # avoid recursion by using builtin
    local path=${MOJIR_DIR_STACK[$MOJIR_DIR_STACK_POS]}
    builtin cd "${path//__SPACE__/ }"
}

# Go to specific directory in favorites.
function cd: {
    local dir=~/.config/cd
    local file=$dir/cd.conf

    # Create directory and file if not existing
    mojir_create_configfile

    # save favorite file in array
    local favs=( $( cat $file | sed 's/ /__SPACE__/g' ) )
    local count=${#favs[@]}

    # column width for sequense number
    local width=1
    if [ $count -ge 10 ]; then width=$(( width + 1 )); fi
    if [ $count -ge 100 ]; then width=$(( width + 1 )); fi

    local i=1
    local fav
    for fav in ${favs[@]}; do
        # substitute home folder to ~
        fav=${fav/#$HOME/~}
        fav=${fav//__SPACE__/ }
        printf "%-${width}d %s\n" "$i" "$fav"
        i=$(( i + 1 ))
    done

    # no favorites?
    if [ $i -eq 1 ]; then return; fi

    echo -n "Directory number: "
    local input
    read input

    # Empty input cancels
    if [ -z $input ]; then return; fi

    # match digits
    if [[ $input = *[![:digit:]]* ]]; then echo "Invalid number"; return; fi

    if [ $input -lt 1 ]; then echo "Invalid number"; return; fi
    if [ $input -gt $count ]; then echo "Invalid number"; return; fi

    local pos=$(( input - 1 ))
    cd "${favs[$pos]//__SPACE__/ }"

}

# Add current directory ($PWD) to favorites
function cd++ {
    local dir=~/.config/cd
    local file=$dir/cd.conf

    # Create directory and file if not existing
    mojir_create_configfile

    # path to save
    local path="$PWD"

    # load favorites file in to array
    local favs=( $( cat $file | sed 's/ /__SPACE__/g' ) )
    local fav
    for fav in ${favs[@]}; do
        # Avoid duplicates
        if [ "$fav" = "${path// /__SPACE__}" ]; then return; fi
    done

    # Append to file
    echo $path >> $file
}

# If no agument, remove either current directory.
# If numeric argument supplied, remove that from number from history file.
function cd-- {
    local dir=~/.config/cd
    local file=$dir/cd.conf

    # Create directory and file if not existing
    mojir_create_configfile

    # load favorites file in to array
    local favs=( $( cat $file | sed 's/ /__SPACE__/g' ) )

    # Remove and create new empty favorite file
    rm $file
    touch $file

    # if no argument, remove current directory from history
    if [ -z $1 ]; then
        local path="$PWD"
        local fav
        for fav in ${favs[@]}; do
            if [ ! "$fav" = "${path// /__SPACE__}" ]; then echo $fav >> $file; fi
        done
    else # use argument to decide what dir. to remove
        local fav
        local i=1
        for fav in ${favs[@]}; do
            if [ ! $i = $1 ]; then echo $fav >> $file; fi
            i=$(( i + 1 ))
        done
    fi
}

function mojir_create_configfile {
    local dir=~/.config/cd
    local file=$dir/cd.conf
    if [ ! -d $dir ]; then
        echo creating directory $dir
        mkdir $dir
    fi
    if [ ! -f $file ]; then
        echo creating file $file
        touch $file
    fi
}

function cd_dump
{
    local i
    for i in ${MOJIR_DIR_STACK[@]}; do
        echo $i
    done
    echo "MOJIR_DIR_STACK_POS: $MOJIR_DIR_STACK_POS"
}

function cdunset {
    unset cd
    unset pushd
    unset popd
}

function cdreset {
    unset MOJIR_DIR_STACK
    unset MOJIR_DIR_STACK_POS
}