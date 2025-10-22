#!/bin/bash
# Script de setup inicial do Nginx Proxy Manager
# Este script cria os volumes e a rede externa necessários

set -e

echo "=========================================="
echo "Setup do Nginx Proxy Manager - Embrapa I/O"
echo "=========================================="
echo ""

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não está instalado. Por favor, instale o Docker primeiro."
    exit 1
fi

echo "✓ Docker está instalado"
echo ""

# Criar volumes externos
echo "Criando volumes externos..."
docker volume create npm_data 2>/dev/null && echo "✓ Volume npm_data criado" || echo "⚠ Volume npm_data já existe"
docker volume create npm_letsencrypt 2>/dev/null && echo "✓ Volume npm_letsencrypt criado" || echo "⚠ Volume npm_letsencrypt já existe"
docker volume create npm_db 2>/dev/null && echo "✓ Volume npm_db criado" || echo "⚠ Volume npm_db já existe"
echo ""

# Criar rede externa
echo "Criando rede externa 'io'..."
docker network create io 2>/dev/null && echo "✓ Rede 'io' criada" || echo "⚠ Rede 'io' já existe"
echo ""

# Criar arquivo .env se não existir
if [ ! -f .env ]; then
    echo "Criando arquivo .env a partir do exemplo..."
    cp .env.example .env
    echo "✓ Arquivo .env criado"
    echo ""
    echo "⚠️  IMPORTANTE: Edite o arquivo .env e altere as senhas padrão!"
    echo "   Edite com: nano .env"
else
    echo "⚠ Arquivo .env já existe"
fi

echo ""
echo "=========================================="
echo "Setup concluído!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Edite o arquivo .env e configure suas senhas:"
echo "   nano .env"
echo ""
echo "2. Inicie os serviços:"
echo "   docker compose up -d"
echo ""
echo "3. Acesse a interface web:"
echo "   http://seu-servidor:81"
echo ""
echo "Credenciais padrão (primeira vez):"
echo "   Email: admin@example.com"
echo "   Senha: changeme"
echo ""
echo "⚠️  Altere as credenciais após o primeiro login!"
echo ""
