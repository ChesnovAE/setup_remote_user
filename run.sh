#!/bin/bash


############# CONSTANTS  ############# 
BLACK='\033[30m'       # Black
RED='\033[31m'         # Red
GREEN='\033[32m'       # Green
YELLOW='\033[33m'      # Yellow
BLUE='\033[34m'        # Blue
PURPLE='\033[35m'      # Purple
CYAN='\033[36m'        # Cyan
WHITE='\033[37m'       # White
NC='\033[0m'             # No color
############# END CONST ##############

############################## FUNCTIONS BLOCK ############################## 
proof_state() {
    local yn=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    if [[ -z "$yn" ]]
    then
        yn="y"
    fi
    if [[ "$yn" = "y" || "$yn" = "yes" ]]
    then
        echo "true"
    else
        echo ""
    fi
}

install_prerequisites() {
    if ! command -v ansible &> /dev/null & ! command -v sshpass &> /dev/null
    then
        echo -e "${BLUE}Install prerequisites${NC}"
        echo "-----------"    

        sudo apt-get update &> /dev/null
        
        ######## Install ansible ########
        if ! command -v ansible &> /dev/null
        then
            echo -e "${BLUE}Install ansible${NC}"
            sudo apt install -y ansible
            echo -e "${CYAN}ansible ${GREEN}successfully installed${NC}"
        else
            echo -e "${CYAN}ansible ${GREEN}already installed${NC}"
        fi
        echo "-----------"    
        ######## Install sshpass #######
        if ! command -v sshpass &> /dev/null
        then
            echo -e "${BLUE}Install sshpass${NC}"
            sudo apt install -y sshpass &> /dev/null
            echo -e "${CYAN}sshpass ${GREEN}successfully installed${NC}"
        else
            echo -e "${CYAN}sshpass ${GREEN}already installed${NC}"
        fi
        echo "-----------"
    fi
}

create_ssh_key_pair() {
    echo -e "${BLUE}Generate ssh-keys${NC}"
    read -p "Enter file in which to save the key (default: id_rsa): " key_name
    if [[ -z "$key_name" ]]
    then
        key_name="id_rsa"
    fi
    echo "y" | ssh-keygen -t rsa -b 4096 -C "key for host" -f "$HOME/.ssh/${key_name}"
    export CURRENT_KEY_NAME="${HOME}/.ssh/${key_name}.pub"
    echo -e "${CYAN}SSH keys ${GREEN}successfully created${NC}" 
    echo "-----------"
}

run_ansible() {
    file="./vars/default.yml"
    
    echo -e "${BLUE}Start remote host(s) setup${NC}"
    read -p "Enter username: " remote_user_name
    pip3 install passlib &> /dev/null
    user_password=$(python3 -c "from passlib.hash import sha512_crypt; import getpass; print(sha512_crypt.using(rounds=5000).hash(getpass.getpass('Enter user password: ')))")
    export REMOTE_USER_PASSWORD="${user_password}"
    echo "---" > "$file"
    echo "user: ${remote_user_name}" >> "$file"
    echo "sys_packages: ['vim', 'curl', 'git', 'tmux', 'htop']" >> "$file"
    
    echo ""
    read -p "Dow you want to rewrite ./hosts file? [Y/n]: " yn
    if [[ ! -z "$(proof_state $yn)" ]]
    then
        echo -e "Enter all hosts. Type enter after ending"
        echo "[all]" > hosts
        read host
        while [[ ! -z "$host" ]]
        do
            echo "$host" >> hosts
            read host
        done
    fi
    echo -e  "${CYAN}Presetup ${GREEN}successfully ended${NC}"
    
    echo "-----------"
    echo -e "${BLUE}Start configure remote user${NC}"
    read -p "Enter existing remote user name with sudo root's: " existing_remote_user
    read -p "Enter password: " -s pass
    echo ""
    echo "Enter password again"
    ansible-playbook playbook.yml --extra-vars "ansible_user=$existing_remote_user ansible_password=$pass" --ask-become-pass
}
############################ END FUNCTIONS BLOCK ##########################

############################### MAIN BLOCK ################################ 
set -e

install_prerequisites
create_ssh_key_pair
run_ansible
