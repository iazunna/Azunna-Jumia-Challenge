#!/bin/sh

# Update Yum
yum update -y

# Install which
yum install -y which

# Install unzip
yum install -y unzip

# Install PostgreSQL client
amazon-linux-extras install postgresql14 -y
yum install -y postgresql-devel

# Install Git
yum install -y git

# Install jq
yum install -y jq

# Install Tinyproxy
yum install tinyproxy

# Install tmux
yum install -y tmux

# Configure tmux
tmuxconfig=$(cat <<EOF
set -g base-index 1

# Easy config reload
bind-key R source-file ~/.tmux.conf \; display-message "tmux.conf reloaded."

# vi is good
setw -g mode-keys vi
EOF
)
printf "%s\n" "$tmuxconfig" > /root/.tmux.conf  

# Update AWS CLI
rm -rf $(which aws)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install -i /usr/local/bin/aws -b /usr/bin

# Install kubectl 
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.22.0/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
ln -s /usr/local/bin/kubectl /usr/bin/kubectl

# Installing zsh
yum install -y zsh

# Install oh-my-zsh 
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install zsh-kubectl-prompt
git clone https://github.com/superbrothers/zsh-kubectl-prompt.git /root/.oh-my-zsh/custom/plugins/zsh-kubectl-prompt
line=$(sed -n '/^plugins=/=' /root/.zshrc)
sed -i -e $line's/.$/ zsh-kubectl-prompt)/' /root/.zshrc
echo -e "RPROMPT='%%{colored_cluster[cyan]%%}(zsh_kubectl_prompt)%%{coloring_reset%%}'" >> /root/.zshrc
sed -i 's/%%/%/g' /root/.zshrc 
sed -i 's/colored_cluster/$fg/g' /root/.zshrc
sed -i 's/zsh_kubectl_prompt/$ZSH_KUBECTL_PROMPT/g' /root/.zshrc
sed -i 's/coloring_reset/$reset_color/g' /root/.zshrc

# Add alias to ZSH
echo -e "alias k=kubectl" >> /root/.zshrc

# Install chsh and set zsh as default shell 
yum install -y util-linux-user 
chsh -s $(which zsh) $(whoami)