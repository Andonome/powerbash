#!/usr/bin/env bash

if [ -z "$POWERLINE_ORG_PS1" ]; then POWERLINE_ORG_PS1=$PS1; fi
POWERLINE_SHORT_NUM=20

powerline-bash() {
    case "$@" in
        "on")
          export PROMPT_COMMAND=__powerline_ps1-on
          ;;
        "off")
          export PROMPT_COMMAND=__powerline_ps1-off
          ;;
        "system")
          export PROMPT_COMMAND=__powerline_ps1-system
          ;;
        "reload")
          source ~/.bashrc
          source /etc/bash_completion.d/powerline-completion.sh
          ;;
        "path on")
          export POWERLINE_PATH=pwd
          ;;
        "path off")
          export POWERLINE_PATH=off
          ;;
        "path short-path")
          export POWERLINE_PATH=shortpath
          ;;
        "path short-path add"*)
          __powerline_short_num_change add $4
          ;;
        "path short-path subtract"*)
          __powerline_short_num_change subtract $4
          ;;
        "path short-directory")
          export POWERLINE_PATH=shortdir
          ;;
        *)
          echo "invalid option"
    esac
}

__powerline() {

    # unicode symbols
    ICONS=( "⚑" "»" "♆" "☀" "♞" "☯" "☢" "❄" )
    ARROWS=( "⇠" "⇡" "⇢" "⇣" )
    SYMBOL_USER='$'
    SYMBOL_ROOT='#'
    GIT_BRANCH_SYMBOL=${ICONS[1]}
    GIT_BRANCH_CHANGED_SYMBOL='+'
    GIT_NEED_PUSH_SYMBOL=${ARROWS[1]}
    GIT_NEED_PULL_SYMBOL=${ARROWS[3]}

    # color specials
    DIM="\[$(tput dim)\]"
    REVERSE="\[$(tput rev)\]"
    RESET="\[$(tput sgr0)\]"
    BOLD="\[$(tput bold)\]"

    # color definitions
    COLOR_USER="\[$(tput setaf 15)\]\[$(tput setab 8)\]"
    COLOR_SUDO="\[$(tput setaf 3)\]\[$(tput setab 8)\]"
    COLOR_SSH="\[$(tput setaf 3)\]\[$(tput setab 8)\]"
    COLOR_DIR="\[$(tput setaf 7)\]\[$(tput setab 8)\]"
    COLOR_GIT="\[$(tput setaf 15)\]\[$(tput setab 4)\]"
    COLOR_RC="\[$(tput setaf 15)\]\[$(tput setab 9)\]"
    COLOR_JOBS="\[$(tput setaf 15)\]\[$(tput setab 5)\]"
    COLOR_SYMBOL_USER="\[$(tput setaf 15)\]\[$(tput setab 2)\]"
    COLOR_SYMBOL_ROOT="\[$(tput setaf 15)\]\[$(tput setab 1)\]"

    # solarized colorscheme
    #FG_BASE03="\[$(tput setaf 8)\]"
    #FG_BASE02="\[$(tput setaf 0)\]"
    #FG_BASE01="\[$(tput setaf 10)\]"
    #FG_BASE00="\[$(tput setaf 11)\]"
    #FG_BASE0="\[$(tput setaf 12)\]"
    #FG_BASE1="\[$(tput setaf 14)\]"
    #FG_BASE2="\[$(tput setaf 7)\]"
    #FG_BASE3="\[$(tput setaf 15)\]"

    #BG_BASE03="\[$(tput setab 8)\]"
    #BG_BASE02="\[$(tput setab 0)\]"
    #BG_BASE01="\[$(tput setab 10)\]"
    #BG_BASE00="\[$(tput setab 11)\]"
    #BG_BASE0="\[$(tput setab 12)\]"
    #BG_BASE1="\[$(tput setab 14)\]"
    #BG_BASE2="\[$(tput setab 7)\]"
    #BG_BASE3="\[$(tput setab 15)\]"

    #FG_YELLOW="\[$(tput setaf 3)\]"
    #FG_ORANGE="\[$(tput setaf 9)\]"
    #FG_RED="\[$(tput setaf 1)\]"
    #FG_MAGENTA="\[$(tput setaf 5)\]"
    #FG_VIOLET="\[$(tput setaf 13)\]"
    #FG_BLUE="\[$(tput setaf 4)\]"
    #FG_CYAN="\[$(tput setaf 6)\]"
    #FG_GREEN="\[$(tput setaf 2)\]"

    #BG_YELLOW="\[$(tput setab 3)\]"
    #BG_ORANGE="\[$(tput setab 9)\]"
    #BG_RED="\[$(tput setab 1)\]"
    #BG_MAGENTA="\[$(tput setab 5)\]"
    #BG_VIOLET="\[$(tput setab 13)\]"
    #BG_BLUE="\[$(tput setab 4)\]"
    #BG_CYAN="\[$(tput setab 6)\]"
    #BG_GREEN="\[$(tput setab 2)\]"

    __powerline_git_info() { 
        [ -x "$(which git)" ] || return    # git not found

        # get current branch name or short SHA1 hash for detached head
        local branch="$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --always 2>/dev/null)"
        [ -n "$branch" ] || return  # git branch not found

        local marks

        # branch is modified?
        [ -n "$(git status --porcelain)" ] && marks+=" $GIT_BRANCH_CHANGED_SYMBOL"

        # how many commits local branch is ahead/behind of remote?
        local stat="$(git status --porcelain --branch | head -n1)"
        local aheadN="$(echo $stat | grep -o 'ahead [0-9]*' | grep -o '[0-9]')"
        local behindN="$(echo $stat | grep -o 'behind [0-9]*' | grep -o '[0-9]')"
        [ -n "$aheadN" ] && marks+=" $GIT_NEED_PUSH_SYMBOL$aheadN"
        [ -n "$behindN" ] && marks+=" $GIT_NEED_PULL_SYMBOL$behindN"

        # print the git branch segment without a trailing newline
        printf "$COLOR_GIT $GIT_BRANCH_SYMBOL$branch$marks $RESET"
    }

    __powerline_user_display() {
        # check if running sudo
        if [ -z "$SUDO_USER" ]; then
            local IS_SUDO=""
        else
            local IS_SUDO="$COLOR_SUDO"
        fi

        # check if ssh session
        if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
            local IS_SSH="$COLOR_SSH@$HOSTNAME"
        else
            local IS_SSH=""
        fi
        printf "$COLOR_USER$IS_SUDO $USER$IS_SSH $RESET"
    }

    __powerline_short_dir() {
        local DIR_SPLIT_COUNT=4
        IFS='/' read -a DIR_ARRAY <<< "$PWD"
        if [ ${#DIR_ARRAY[@]} -gt $DIR_SPLIT_COUNT ]; then
            local SHORT_DIR="/${DIR_ARRAY[1]}/.../${DIR_ARRAY[${#DIR_ARRAY[@]}-2]}/${DIR_ARRAY[${#DIR_ARRAY[@]}-1]}"
        else
            local SHORT_DIR="$PWD"
        fi
        if [ "$HOME" == "$PWD" ]; then
            local SHORT_DIR="~"
        fi
        printf "$SHORT_DIR"
    }

    __powerline_short_path() {
        local SHORT_NUM="$POWERLINE_SHORT_NUM"
        if (( ${#PWD} > $SHORT_NUM )); then
            local SHORT_PATH="..${PWD: -$SHORT_NUM}"
        else
            local SHORT_PATH=$PWD
        fi
        if [ "$HOME" == "$PWD" ]; then
            local SHORT_PATH="~"
        fi
        printf "$SHORT_PATH"
   }
   __powerline_short_num_change() {
        local NUMBER_DEFAULT=1
        if [ -z "$2" ];then
            NUMBER=$NUMBER_DEFAULT
        else
            NUMBER=$2
        fi
        if [ "$1" == "add" ]; then
            ((POWERLINE_SHORT_NUM+=$NUMBER))
        fi
        if [ "$1" == "subtract" ]; then
            ((POWERLINE_SHORT_NUM-=$NUMBER))
        fi
   }

   __powerline_dir_display() {
        if [ "$POWERLINE_PATH" == "shortdir" ]; then
          local DIR_DISPLAY=$(__powerline_short_dir)
        elif [ "$POWERLINE_PATH" == "shortpath" ]; then
          local DIR_DISPLAY=$(__powerline_short_path)
        elif [ "$POWERLINE_PATH" == "pwd" ]; then
          local DIR_DISPLAY=$PWD
        elif [ "$POWERLINE_PATH" == "off" ]; then
          local DIR_DISPLAY=""
        else
          local DIR_DISPLAY=$(__powerline_short_dir)
        fi
        printf "$COLOR_DIR $DIR_DISPLAY $RESET"
   }

   __powerline_jobs_display() {
        local JOBS="$(jobs | wc -l)"
        if [ "$JOBS" -ne "0" ]; then
            local JOBS_DISPLAY="$COLOR_JOBS $JOBS $RESET"
        else
            local JOBS_DISPLAY=""
        fi
        printf "$JOBS_DISPLAY"
   }

   __powerline_symbol_display() {
        # check if root or regular user
        if [ $EUID -ne 0 ]; then
            local SYMBOL_BG=$COLOR_SYMBOL_USER
            local SYMBOL=$SYMBOL_USER
        else
            local SYMBOL_BG=$COLOR_SYMBOL_ROOT
            local SYMBOL=$SYMBOL_ROOT
        fi
        printf "$SYMBOL_BG $SYMBOL $RESET"
   }

   __powerline_rc_display() {
        # check the exit code of the previous command and display different
        local rc=$1
        if [ $rc -ne 0 ]; then
            local RC_DISPLAY="$COLOR_RC $rc $RESET"
        else
            local RC_DISPLAY=""
        fi
        printf "$RC_DISPLAY"
   }

    __powerline_ps1-system() {
        # set prompt
        PS1=$POWERLINE_ORG_PS1 
    }

    __powerline_ps1-off() {
        # set prompt
        PS1="$ "
    }

    __powerline_ps1-on() {
        # capture latest return code
        local RETURN_CODE=$?

        # set prompt
        PS1=""
        PS1+="$(__powerline_user_display)"
        PS1+="$(__powerline_dir_display)"
        PS1+="$(__powerline_git_info)"
        PS1+="$(__powerline_jobs_display)"
        PS1+="$(__powerline_symbol_display)"
        PS1+="$(__powerline_rc_display ${RETURN_CODE})"
        PS1+=" "
    }

    PROMPT_COMMAND=__powerline_ps1-on
}

__powerline
unset __powerline
