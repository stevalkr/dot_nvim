plugins=(git vi-mode zsh-autosuggestions zsh-syntax-highlighting conda-zsh-completion)


export PATH="/usr/local/go/bin:$PATH"

alias scmpt='ssh ubuntu@cmpt.swangel.cn'
alias sntwk='ssh walker-ntwk@ntwk.swangel.cn -p 59'

alias refresh='source /home/walker/.zshrc'

alias cp='cp -i'
alias ws='cd /home/walker/Documents/carto_ws; ls src;'

alias v='nvim'
alias rviz='ros2 run rviz2 rviz2'

source /opt/ros/humble/setup.zsh
source /home/walker/Documents/carto_ws/install/setup.zsh
source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.zsh
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
export FASTRTPS_DEFAULT_PROFILES_FILE=/home/walker/Documents/network_interface.xml

function ef(){
    cd "${1}";
    ls;
}

function mkd(){
    mkdir "${1}";
    cd "${1}";
}


function proxy() {
    export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
    export http_proxy="http://127.0.0.1:7890"
    export https_proxy=$http_proxy
    export all_proxy="socks5://127.0.0.1:7890"
    echo -e "已开启代理"
}
function unproxy(){
    unset http_proxy
    unset https_proxy
    unset all_proxy
    echo -e "已关闭代理"
}

alias saysth='figlet F Society | lolcat; fortune | cowsay | lolcat'

