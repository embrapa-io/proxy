# Nginx Proxy Manager - Embrapa I/O

Configuração de deploy do NginxProxyManager no ecossistema do Embrapa I/O.

## Sobre

Este repositório contém a configuração para instanciar o [Nginx Proxy Manager](https://nginxproxymanager.com) em produção utilizando Docker Compose. O Nginx Proxy Manager é uma ferramenta que facilita o gerenciamento de proxies reversos, certificados SSL e hosts virtuais através de uma interface web intuitiva.

## Arquitetura

A stack é composta por três serviços:

- **app**: Container principal do Nginx Proxy Manager
- **db**: Banco de dados MariaDB para persistência de configurações
- **backup**: Serviço automatizado de backup dos dados e configurações

### Volumes

Todos os volumes são externos para garantir a persistência dos dados:

- `npm_data`: Dados de configuração do Nginx Proxy Manager
- `npm_letsencrypt`: Certificados SSL do Let's Encrypt
- `npm_db`: Banco de dados MariaDB

### Networks

- **io**: Rede externa para comunicação com outros serviços do ecossistema Embrapa I/O
- **internal**: Rede interna para comunicação entre os serviços da stack

## Pré-requisitos

1. Docker e Docker Compose instalados
2. Criar os volumes externos:
   ```bash
   docker volume create npm_data
   docker volume create npm_letsencrypt
   docker volume create npm_db
   ```

3. Criar a rede externa:
   ```bash
   docker network create io
   ```

## Instalação

1. Clone o repositório:
   ```bash
   git clone https://github.com/embrapa-io/proxy.git
   cd proxy
   ```

2. Copie o arquivo de exemplo de variáveis de ambiente:
   ```bash
   cp .env.example .env
   ```

3. Edite o arquivo `.env` e configure as variáveis de ambiente:
   ```bash
   nano .env
   ```
   
   **IMPORTANTE**: Altere as senhas padrão (`DB_PASSWORD` e `MYSQL_ROOT_PASSWORD`) antes de iniciar os serviços!

4. Inicie os serviços:
   ```bash
   docker-compose up -d
   ```

## Acesso

Após a inicialização dos serviços, acesse a interface web:

- URL: `http://seu-servidor:81`
- Credenciais padrão (primeira inicialização):
  - Email: `admin@example.com`
  - Password: `changeme`

**IMPORTANTE**: Altere as credenciais padrão imediatamente após o primeiro login!

## Configuração

### Variáveis de Ambiente

Todas as configurações são feitas através do arquivo `.env`:

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `HTTP_PORT` | Porta HTTP | 80 |
| `HTTPS_PORT` | Porta HTTPS | 443 |
| `ADMIN_PORT` | Porta da interface administrativa | 81 |
| `DB_PORT` | Porta do banco de dados | 3306 |
| `DB_NAME` | Nome do banco de dados | npm |
| `DB_USER` | Usuário do banco de dados | npm |
| `DB_PASSWORD` | Senha do banco de dados | *obrigatório* |
| `MYSQL_ROOT_PASSWORD` | Senha root do MySQL | *obrigatório* |
| `DISABLE_IPV6` | Desabilitar IPv6 | true |
| `BACKUP_INTERVAL` | Intervalo entre backups (segundos) | 86400 (24h) |
| `BACKUP_RETENTION_DAYS` | Dias de retenção dos backups | 7 |

## Backup

O serviço de backup executa automaticamente de acordo com o intervalo configurado em `BACKUP_INTERVAL`. Os backups são armazenados no diretório `./backup` e incluem:

- Dados de configuração do Nginx Proxy Manager
- Certificados SSL
- Banco de dados

Os backups são compactados em formato `.tar.gz` com timestamp no nome do arquivo. Backups mais antigos que `BACKUP_RETENTION_DAYS` dias são automaticamente removidos.

### Backup Manual

Para executar um backup manual:

```bash
docker-compose exec backup sh -c "tar -czf /backup/manual_npm_data_$(date +%Y%m%d_%H%M%S).tar.gz -C /data ."
```

### Restauração

Para restaurar um backup:

1. Pare os serviços:
   ```bash
   docker-compose down
   ```

2. Extraia o backup desejado:
   ```bash
   # Exemplo para restaurar dados
   docker run --rm -v npm_data:/data -v $(pwd)/backup:/backup alpine sh -c "cd /data && tar -xzf /backup/npm_data_YYYYMMDD_HHMMSS.tar.gz"
   ```

3. Reinicie os serviços:
   ```bash
   docker-compose up -d
   ```

## Manutenção

### Visualizar logs

```bash
# Todos os serviços
docker-compose logs -f

# Serviço específico
docker-compose logs -f app
docker-compose logs -f db
docker-compose logs -f backup
```

### Atualizar imagens

```bash
docker-compose pull
docker-compose up -d
```

### Parar serviços

```bash
docker-compose stop
```

### Remover serviços

```bash
docker-compose down
# Para remover também os volumes (CUIDADO: isso apaga todos os dados!)
# docker-compose down -v
```

## Segurança

- **Altere as senhas padrão** antes de colocar em produção
- **Altere as credenciais administrativas** após o primeiro acesso
- Configure firewall apropriado para as portas expostas
- Mantenha os backups em local seguro
- Atualize regularmente as imagens Docker

## Troubleshooting

### Problema: Serviços não iniciam

Verifique se os volumes e a rede externa foram criados:

```bash
docker volume ls | grep npm
docker network ls | grep io
```

### Problema: Não consigo acessar a interface web

Verifique se a porta 81 está aberta no firewall e se o serviço está rodando:

```bash
docker-compose ps
netstat -tlnp | grep 81
```

### Problema: Backup não está funcionando

Verifique os logs do serviço de backup:

```bash
docker-compose logs backup
```

## Suporte

Para problemas e questões:

- Issues: https://github.com/embrapa-io/proxy/issues
- Documentação oficial do Nginx Proxy Manager: https://nginxproxymanager.com

## Licença

Este projeto segue a licença especificada no arquivo LICENSE.
