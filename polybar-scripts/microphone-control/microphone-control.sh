#!/bin/env sh

# Variables
MICROPHONE_ICON_MUTED=""
MICROPHONE_ICON_UNMUTED=""
MICROPHONE_SOURCE_NAME="\*"
MICROPHONE_MUTE="false"
MICROPHONE_STATUS="false"
MICROPHONE_VOLUME_UP="false"
MICROPHONE_VOLUME_DOWN="false"
MICROPHONE_VOLUME_INCREMENT="7"

SOURCE=""
SOURCE_INDEX=""
SOURCE_NAME=""
SOURCE_VOLUMES=""
SOURCE_VOLUME=""
SOURCE_MUTED=""


# Arguments
for ARG in "${@}"; do
    case $ARG in
        -n|--name)
        MICROPHONE_SOURCE_NAME="<${2}>"
        shift; shift
        ;;
        -m|--mute)
        MICROPHONE_MUTE="true"
        MICROPHONE_VOLUME_UP="false"
        MICROPHONE_VOLUME_DOWN="false"
        shift
        ;;
        -s|--status)
        MICROPHONE_STATUS="true"
        shift
        ;;
        -i|--volume-increment)
        MICROPHONE_VOLUME_INCREMENT="${2}"
        shift; shift
        ;;
        -u|--volume-up)
        MICROPHONE_MUTE="false"
        MICROPHONE_VOLUME_UP="true"
        MICROPHONE_VOLUME_DOWN="false"
        shift
        ;;
        -d|--volume-down)
        MICROPHONE_MUTE="false"
        MICROPHONE_VOLUME_UP="false"
        MICROPHONE_VOLUME_DOWN="true"
        shift
        ;;
    esac
done


# Functions
function source_status(){
    SOURCE="$(pacmd list-sources | grep -e 'index\:' -e 'name\:' -e 'volume\:' -e 'muted\:' -e 'card\:' | grep -B 1 -A 4 "${1}")"
    SOURCE_INDEX="$(grep -e 'index' <<< "${SOURCE}" | awk -F ' ' '{ print $3 }')"
    SOURCE_NAME="$(grep -e 'name' <<< "${SOURCE}" | awk -F '[<>]' '{ print $2 }')"
    SOURCE_VOLUMES="$(grep -e 'volume' <<< "${SOURCE}" | head -n 1 | grep -o '[[:digit:]]*\%' | grep -o '[[:digit:]]*')"
    SOURCE_VOLUME="$(bc <<< "scale=0; $(awk '{ n += $1 }; END{ print n }' <<< ${SOURCE_VOLUMES})/$(wc -l <<< ${SOURCE_VOLUMES})")"
    SOURCE_MUTED="$(grep -e 'muted' <<< "${SOURCE}" | awk -F ' ' '{ print $2 }')"

    if [[ -z "${2}" ]]; then

        if [[ "${MICROPHONE_STATUS}" == "true" || "${MICROPHONE_MUTE}" == "true" ]]; then
            if [[ "${SOURCE_MUTED}" == "yes" ]]; then
                microphone_icon ${SOURCE_MUTED}
            else
                printf '%s %s%%' $(microphone_icon ${SOURCE_MUTED}) ${SOURCE_VOLUME}
            fi
        fi
        
        if [[ "${MICROPHONE_VOLUME_UP}" == "true" && "${MICROPHONE_VOLUME_DOWN}" == "false" ]]; then printf '%s %s%%' $(microphone_icon ${SOURCE_MUTED}) ${SOURCE_VOLUME}; fi
        if [[ "${MICROPHONE_VOLUME_UP}" == "false" && "${MICROPHONE_VOLUME_DOWN}" == "true" ]]; then printf '%s %s%%' $(microphone_icon ${SOURCE_MUTED}) ${SOURCE_VOLUME}; fi
    fi
}

volume_up(){
    pactl set-source-volume ${1} +${MICROPHONE_VOLUME_INCREMENT}%

    source_status ${MICROPHONE_SOURCE_NAME}
}

volume_down(){
    pactl set-source-volume ${1} -${MICROPHONE_VOLUME_INCREMENT}%

    source_status ${MICROPHONE_SOURCE_NAME}
}

mute(){
    pactl set-source-mute ${1} toggle

    source_status ${MICROPHONE_SOURCE_NAME}
}

microphone_icon(){
    if [[ "${1}" == "yes" ]]; then
        printf '%s' ${MICROPHONE_ICON_MUTED}
    else
        printf '%s' ${MICROPHONE_ICON_UNMUTED}
    fi
}


# Main
source_status ${MICROPHONE_SOURCE_NAME} false

if [[ ! -z "${SOURCE_INDEX}" ]]; then

    if [[ "${SOURCE_MUTED}" == "no" ]]; then
        if [[ "${MICROPHONE_VOLUME_UP}" == "true" && "${MICROPHONE_VOLUME_DOWN}" == "false" ]]; then volume_up ${SOURCE_INDEX}; fi

        if [[ "${MICROPHONE_VOLUME_UP}" == "false" && "${MICROPHONE_VOLUME_DOWN}" == "true" ]]; then volume_down ${SOURCE_INDEX}; fi
    fi

    if [[ "${MICROPHONE_MUTE}" == "true" ]]; then mute ${SOURCE_INDEX}; fi

    if [[ "${MICROPHONE_STATUS}" == "true" ]]; then source_status ${MICROPHONE_SOURCE_NAME}; fi

else

    printf 'Source %s[%s] not found ...\n' ${SOURCE_NAME} ${SOURCE_INDEX}
    return 1
fi