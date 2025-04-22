# time
function real_time() {
    local color="%{$fg_no_bold[cyan]%}";                    # color in PROMPT need format in %{XXX%} which is not same with echo
    local time="[$(date +%H:%M:%S)]";
    local color_reset="%{$reset_color%}";
    echo "${color}${time}${color_reset}";
}

# login_info
function login_info() {
    local color="%{$fg_no_bold[cyan]%}";                    # color in PROMPT need format in %{XXX%} which is not same with echo
    local ip
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        # Linux
        ip="$(ifconfig | grep ^eth1 -A 1 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)";
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        ip="$(ifconfig | grep ^en1 -A 4 | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | head -1)";
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
    elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
    elif [[ "$OSTYPE" == "win32" ]]; then
        # I'm not sure this can happen.
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        # ...
    else
        # Unknown.
    fi
    local color_reset="%{$reset_color%}";
    echo "${color}[%n@${ip}]${color_reset}";
}


# directory
function directory() {
    local color="%{$fg_bold[cyan]%}";
    # REF: https://stackoverflow.com/questions/25944006/bash-current-working-directory-with-replacing-path-to-home-folder
    local directory="${PWD/#$HOME/~}";
    local color_reset="%{$reset_color%}";
    #echo "%F{87}%1~%f%b";  # brighter;
		echo "${color}%1~${color_reset}";
}


# git
ZSH_THEME_GIT_PROMPT_PREFIX="%B%F{203}git(%F{161}";
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} ";
ZSH_THEME_GIT_PROMPT_DIRTY="%F{203}) 🔥";
ZSH_THEME_GIT_PROMPT_CLEAN="%F{203})";

# command
function update_command_status() {
    local arrow="";
    local color_reset="%{$reset_color%}";
    local reset_font="%{$fg_no_bold[white]%}";
    COMMAND_RESULT=$1;
    export COMMAND_RESULT=$COMMAND_RESULT
    if $COMMAND_RESULT;
    then
        # arrow="%B%F{009}❱%F{227}❱%F{046}❱";  # brighter
				arrow="%{$fg_bold[red]%}❱%{$fg_bold[yellow]%}❱%{$fg_bold[green]%}❱";
    else
        #arrow="%B%F{009}❱❱❱";  # brighter
				arrow="%{$fg_bold[red]%}❱❱❱";
    fi
    COMMAND_STATUS="${arrow}${reset_font}${color_reset}";
}
update_command_status true;

function command_status() {
    echo "${COMMAND_STATUS}"
}


# output command execute after
output_command_execute_after() {
		if [ "$COMMAND_TIME_BEGIN" = "-20200325" ] || [ "$COMMAND_TIME_BEGIN" = "" ];
    then
        return 1;
    fi

    # cmd
    local cmd="${$(fc -ln | tail -1)#*  }";
    local color_cmd="";
    if $1;
    then
        color_cmd="$fg_no_bold[green]";
    else
        color_cmd="$fg_bold[red]";
    fi
    local color_reset="$reset_color";
    cmd="${color_cmd}${cmd}${color_reset}"

    # time
    local time="[$(date +%H:%M:%S)]"
    local color_time="$fg_no_bold[yellow]";
    time="${color_time}${time}${color_reset}";

		# cost
    local time_end="$(current_time_seconds)";
    local cost=`bc <<< "${time_end}-${COMMAND_TIME_BEGIN}"`;
    COMMAND_TIME_BEGIN="-20200325"

		# if cost is 0 don't print
		if [ "${cost}" = "0" ]; then
       return 1
		fi

    local color_cost="$fg_no_bold[cyan]";

    # format cost
    local cost_days=$(( cost / (60 * 60 * 24) ));
    local cost_hours=$(( (cost-cost_days*60*60*24)/(60*60) ));
    local cost_minutes=$(( (cost-cost_days*60*60*24-cost_hours*60*60)/60 ));
    local cost_seconds=$(( (cost-cost_days*60*60*24-cost_hours*60*60-cost_minutes*60) ));

    if [ "${cost_days}" != "0" ]; then # Days
      cost="${cost_days}d ${cost_hours}h ${cost_minutes}m ${cost_seconds}s";
    elif [ "${cost_hours}" != "0" ]; then # Hours
      cost="${cost_hours}h ${cost_minutes}m ${cost_seconds}s";
    elif [ "${cost_minutes}" != "0" ]; then # Minutes
       cost="${cost_minutes}m ${cost_seconds}s";
    else; # Seconds
      cost="${cost}s"
    fi
    cost="${color_cost}${cost}${color_reset}";

		# print
		echo -e "${time} ${cost} ${cmd}";
}

# command execute before
# REF: http://zsh.sourceforge.net/Doc/Release/Functions.html
preexec() {
    COMMAND_TIME_BEGIN="$(current_time_seconds)";
}

current_time_seconds() {
    local time_millis;
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        # Linux
        time_s="$(date +%s)";
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        time_s="$(date +%s)";
    fi
    echo $time_s;
}

# command execute after
# REF: http://zsh.sourceforge.net/Doc/Release/Functions.html
precmd() {
    # last_cmd
    local last_cmd_return_code=$?;
    local last_cmd_result=true;
    if [ "$last_cmd_return_code" = "0" ];
    then
        last_cmd_result=true;
    else
        last_cmd_result=false;
    fi

    # update_command_status
    update_command_status $last_cmd_result;

    # output command execute after
    output_command_execute_after $last_cmd_result;
}


# set option
setopt PROMPT_SUBST;


# timer
#REF: https://stackoverflow.com/questions/26526175/zsh-menu-completion-causes-problems-after-zle-reset-prompt
TMOUT=1;
TRAPALRM() {
    # $(git_prompt_info) cost too much time which will raise stutters when inputting. so we need to disable it in this occurence.
    # if [ "$WIDGET" != "expand-or-complete" ] && [ "$WIDGET" != "self-insert" ] && [ "$WIDGET" != "backward-delete-char" ]; then
    # black list will not enum it completely. even some pipe broken will appear.
    # so we just put a white list here.
    if [ "$WIDGET" = "" ] || [ "$WIDGET" = "accept-line" ] ; then
        zle reset-prompt;
    fi
}


# prompt
# PROMPT='$(real_time) $(login_info) $(directory) $(git_status)$(command_status) ';
if command -v kube_ps1 > /dev/null; then
	PROMPT='$(kube_ps1) $(git_prompt_info)$(directory) $(command_status) ';
else
	PROMPT='$(git_status) $(directory) $(command_status) ';
fi
RPROMPT='$(real_time)'

echo "\e[38;5;196mH\e[38;5;50ma\e[38;5;99mp\e[38;5;82mp\e[38;5;226my \e[38;5;49mC\e[38;5;21mo\e[38;5;203md\e[38;5;11mi\e[38;5;48mn\e[38;5;161mg\e[0m"
