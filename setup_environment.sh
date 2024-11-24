#!/bin/bash

# Função para exibir texto em azul
blue_text() {
  echo -e "\033[1;34m$1\033[0m"
}

# Função para barra de progresso
progress_bar() {
  local progress=$1
  local total=100
  local done=$((progress * 50 / total))
  local left=$((50 - done))
  local bar=$(printf "%${done}s" | tr ' ' '#')
  local spaces=$(printf "%${left}s")
  printf "\r[%-50s] %d%%" "${bar}${spaces}" "${progress}"
}

# Atualização inicial
blue_text "Atualizando o sistema..."
sudo apt-get update -y && sudo apt-get upgrade -y --ignore-hold || {
  blue_text "Erro ao atualizar o sistema. Continuando..."
}
for i in {1..20}; do progress_bar $((i * 5)); sleep 0.1; done
echo -e "\n"

# Desmascarar e garantir que o Docker funcione
blue_text "Configurando o Docker (desmascarando, se necessário)..."
{
  sudo systemctl unmask docker.service || true
  sudo systemctl unmask docker.socket || true
  sudo systemctl start docker || true
  sudo systemctl enable docker || true
  sudo systemctl restart docker || true
} || {
  blue_text "Erro ao configurar o Docker. Verifique manualmente após a execução."
}

# Reinstalar Docker
blue_text "Verificando e reinstalando o Docker..."
{
  if command -v docker &>/dev/null; then
    blue_text "Docker detectado. Removendo versões antigas..."
    sudo apt-get remove -y docker docker-ce docker-ce-cli docker.io || true
    sudo apt-get autoremove --purge -y docker.io || true
    sudo rm -rf /var/lib/docker /etc/docker /usr/bin/docker /snap/bin/docker /usr/bin/dockerd || true
  fi

  blue_text "Instalando o Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
  for i in {1..20}; do progress_bar $((i * 5)); sleep 0.1; done
  echo -e "\n"
} || {
  blue_text "Erro ao instalar ou configurar o Docker. Continuando..."
}

# Configurar permissões do Docker
blue_text "Configurando permissões do Docker..."
{
  sudo groupadd docker || true
  sudo usermod -aG docker $USER || true
  sudo chmod 666 /var/run/docker.sock || true
  sudo chown :docker /var/run/docker.sock || true
  newgrp docker || true
  docker run hello-world || true
} || {
  blue_text "Erro ao configurar permissões do Docker. Continuando..."
}

# Docker Compose
blue_text "Instalando Docker Compose..."
{
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  docker-compose --version || {
    blue_text "Erro ao verificar Docker Compose. Continuando..."
  }
}

# Instalar Node.js e npm
blue_text "Instalando Node.js e npm..."
{
  sudo apt-get remove -y nodejs npm || true
  sudo apt-get install -y curl
  curl -fsSL https://deb.nodesource.com/setup_12.x | sudo -E bash -
  sudo apt-get install -y nodejs
  node -v || blue_text "Erro ao instalar Node.js. Continuando..."
  npm --version || blue_text "Erro ao instalar npm. Continuando..."
}

# Instalar GoLang
blue_text "Instalando GoLang..."
{
  if go version &>/dev/null; then
    blue_text "GoLang já instalado. Verificando versão..."
    GO_VERSION=$(go version | awk '{print $3}')
    if [[ "$GO_VERSION" != "go1.14.3" ]]; then
      sudo rm -rf /usr/local/go
      wget https://dl.google.com/go/go1.14.3.linux-amd64.tar.gz
      sudo tar -C /usr/local -xvf go1.14.3.linux-amd64.tar.gz
      rm go1.14.3.linux-amd64.tar.gz
    fi
  else
    wget https://dl.google.com/go/go1.14.3.linux-amd64.tar.gz
    sudo tar -C /usr/local -xvf go1.14.3.linux-amd64.tar.gz
    rm go1.14.3.linux-amd64.tar.gz
  fi
  echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
  source ~/.profile
} || {
  blue_text "Erro ao instalar ou configurar GoLang. Continuando..."
}

# Configurar variáveis de ambiente para GoLang
blue_text "Configurando variáveis de ambiente para GoLang..."
{
  echo "export GOPATH=\$HOME/go" >> ~/.bashrc
  echo "export GOROOT=/usr/local/go" >> ~/.bashrc
  source ~/.bashrc
}

# Hyperledger Fabric Samples
blue_text "Configurando Hyperledger Fabric Samples..."
{
  if [ ! -d "fabric-samples" ]; then
    git clone https://github.com/hyperledger/fabric-samples.git
  fi
  cd fabric-samples || exit
  chmod +x ./scripts/bootstrap.sh
  ./scripts/bootstrap.sh 2.5 1.5 || blue_text "Erro ao configurar Hyperledger Fabric. Continuando..."
  cd ..
}

# Verificação final
blue_text "Verificando configurações..."
{
  docker --version || blue_text "Erro ao verificar Docker."
  docker-compose --version || blue_text "Erro ao verificar Docker Compose."
  node -v || blue_text "Erro ao verificar Node.js."
  npm --version || blue_text "Erro ao verificar npm."
  go version || blue_text "Erro ao verificar GoLang."
}

sudo apt  install golang-go

blue_text "\nAmbiente configurado com sucesso!"
