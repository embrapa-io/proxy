# Nginx Proxy Manager for Embrapa I/O

Configuração de deploy do **NginxProxyManager** no ecossistema do **Embrapa I/O**.

## Sobre

Este repositório contém a configuração para instanciar o [Nginx Proxy Manager](https://nginxproxymanager.com) em produção utilizando Docker Compose. O Nginx Proxy Manager é uma ferramenta que facilita o gerenciamento de proxies reversos, certificados SSL e hosts virtuais através de uma interface web intuitiva.

## Arquitetura

A stack é composta por três serviços:

- **proxy**: Container principal do Nginx Proxy Manager
- **db**: Banco de dados MariaDB Aria para persistência de configurações
- **backup**: Serviço automatizado de backup dos dados e configurações (profile: production)

### Volumes

Todos os volumes são externos e nomeados através de variáveis de ambiente:

- `data_proxy` (padrão: `proxy_data`): Dados de configuração do Nginx Proxy Manager
- `data_letsencrypt` (padrão: `proxy_letsencrypt`): Certificados SSL do Let's Encrypt
- `data_db` (padrão: `proxy_db`): Banco de dados MariaDB Aria
- `data_backup` (padrão: `proxy_backup`): Armazenamento de backups

### Networks

- **io**: Rede externa nomeada através da variável `COMPOSE_PROJECT_NAME` para comunicação com outros serviços do ecossistema Embrapa I/O

### Healthchecks

Todos os serviços possuem healthchecks configurados:

- **db**: Verifica conectividade do MariaDB usando `mysqladmin ping`
- **proxy**: Verifica disponibilidade da interface web usando `curl`
- **backup**: Depende do healthcheck do banco de dados

## Pré-requisitos

1. Docker e Docker Compose instalados
2. Script de setup automático (recomendado - veja seção Instalação)

Ou manualmente:

2. Criar os volumes externos:
   ```bash
   docker volume create proxy_data
   docker volume create proxy_letsencrypt
   docker volume create proxy_db
   docker volume create proxy_backup
   ```

3. Criar a rede externa:
   ```bash
   docker network create proxy  # ou o nome definido em COMPOSE_PROJECT_NAME
   ```

## Instalação

1. Clone o repositório:
   ```bash
   git clone https://github.com/embrapa-io/proxy.git
   cd proxy
   ```

2. Execute o script de setup automatizado:
   ```bash
   ./setup.sh
   ```

   O script irá:
   - Criar o arquivo `.env` a partir do `.env.example`
   - Criar todos os volumes externos necessários
   - Criar a rede externa
   - Solicitar senhas seguras para o banco de dados
   - Iniciar os serviços

3. Ou configure manualmente:

   a. Copie o arquivo de exemplo:
   ```bash
   cp .env.example .env
   ```

   b. Edite o `.env` e configure as variáveis:
   ```bash
   nano .env
   ```

   **IMPORTANTE**: Altere as senhas padrão (`DB_PASSWORD` e `MYSQL_ROOT_PASSWORD`)!

   c. Crie os recursos (veja Pré-requisitos)

   d. Inicie os serviços:
   ```bash
   docker compose up -d
   ```

## Acesso

Após a inicialização dos serviços, acesse a interface web:

- **Interface Admin**: `http://seu-servidor:${ADMIN_PORT}` (padrão: porta 81 ou 9081)
- **HTTP Proxy**: porta `${HTTP_PORT}` (padrão: 80 ou 9080)
- **HTTPS Proxy**: porta `${HTTPS_PORT}` (padrão: 443 ou 9443)

Credenciais padrão (primeira inicialização):
- Email: `admin@example.com`
- Password: `changeme`

**IMPORTANTE**: Altere as credenciais padrão imediatamente após o primeiro login!

### Verificando o Status

```bash
docker compose ps
```

Ambos os serviços devem mostrar status `healthy`:
```
NAME            STATUS
proxy-db-1      Up (healthy)
proxy-proxy-1   Up (healthy)
```

## Configuração

### Variáveis de Ambiente

Todas as configurações são feitas através do arquivo `.env`:

#### Configurações Gerais

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `COMPOSE_PROJECT_NAME` | Nome do projeto/rede | `proxy` |
| `COMPOSE_PROFILES` | Perfil ativo (development/production) | `development` |

#### Portas

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `HTTP_PORT` | Porta HTTP do proxy | `80` |
| `HTTPS_PORT` | Porta HTTPS do proxy | `443` |
| `ADMIN_PORT` | Porta da interface administrativa | `81` |

#### Banco de Dados

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `DB_PORT` | Porta do banco de dados | `3306` |
| `DB_NAME` | Nome do banco de dados | `proxy` |
| `DB_USER` | Usuário do banco de dados | `proxy` |
| `DB_PASSWORD` | Senha do banco de dados | *obrigatório* |
| `MYSQL_ROOT_PASSWORD` | Senha root do MySQL | *obrigatório* |

#### Volumes

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `DATA_PROXY` | Nome do volume de dados | `proxy_data` |
| `DATA_LETSENCRYPT` | Nome do volume de certificados | `proxy_letsencrypt` |
| `DATA_DB` | Nome do volume do banco | `proxy_db` |
| `DATA_BACKUP` | Nome do volume de backups | `proxy_backup` |

#### Outras Configurações

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `DISABLE_IPV6` | Desabilitar IPv6 | `true` |
| `BACKUP_INTERVAL` | Intervalo entre backups (segundos) | `86400` (24h) |
| `BACKUP_RETENTION_DAYS` | Dias de retenção dos backups | `7` |

## Backup

O serviço de backup é executado automaticamente quando o perfil `production` está ativo:

```bash
# Ativar o perfil production no .env
COMPOSE_PROFILES=production

# Iniciar com o perfil production
docker compose --profile production up -d
```

O serviço de backup:
- Executa automaticamente de acordo com o intervalo configurado em `BACKUP_INTERVAL`
- Armazena backups no volume `data_backup`
- Compacta em formato `.tar.gz` com timestamp
- Remove automaticamente backups mais antigos que `BACKUP_RETENTION_DAYS` dias

**Conteúdo dos Backups**:
- Dados de configuração do Nginx Proxy Manager (`/data`)
- Certificados SSL (`/etc/letsencrypt`)
- Banco de dados MariaDB (`/var/lib/mysql`)

### Backup Manual

Para executar um backup manual:

```bash
docker-compose exec backup sh -c "tar -czf /backup/manual_proxy_data_$(date +%Y%m%d_%H%M%S).tar.gz -C /data ."
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
   docker run --rm -v proxy_data:/data -v $(pwd)/backup:/backup alpine sh -c "cd /data && tar -xzf /backup/proxy_data_YYYYMMDD_HHMMSS.tar.gz"
   ```

3. Reinicie os serviços:
   ```bash
   docker-compose up -d
   ```

## Manutenção

### Visualizar logs

```bash
# Todos os serviços
docker compose logs -f

# Serviço específico
docker compose logs -f proxy
docker compose logs -f db
docker compose logs --follow db  # com flag --follow

# Últimas N linhas
docker compose logs --tail 50 proxy
```

### Verificar healthchecks

```bash
# Status geral
docker compose ps

# Inspecionar healthcheck de um serviço
docker inspect --format='{{json .State.Health}}' proxy-db-1 | jq
```

### Atualizar imagens

```bash
docker compose pull
docker compose up -d
```

### Parar serviços

```bash
docker compose stop

# Parar serviço específico
docker compose stop proxy
```

### Remover serviços

```bash
docker compose down

# Para remover também os volumes (CUIDADO: isso apaga todos os dados!)
# docker compose down -v
```

## Detalhes Técnicos

### MariaDB Aria vs InnoDB

Esta configuração utiliza a imagem `jc21/mariadb-aria` que força o uso do **Aria storage engine** ao invés do InnoDB. Isso significa:

- ✅ **Normal**: Logs mostram `[Note] Plugin 'InnoDB' is disabled.`
- ✅ **Esperado**: Healthcheck NÃO verifica InnoDB
- ✅ **Aria Engine**: Otimizado para leitura e cache de tabelas
- ⚠️ **Importante**: Não use verificações de InnoDB em healthchecks

### Healthchecks Implementados

**Banco de Dados (db)**:
```yaml
test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
interval: 10s
timeout: 5s
retries: 5
start_period: 30s
```

**Proxy**:
```yaml
test: ["CMD", "curl", "-f", "-s", "http://localhost:81/"]
interval: 10s
timeout: 5s
retries: 3
start_period: 30s
```

### Dependências entre Serviços

O serviço `proxy` possui `depends_on` com condição `service_healthy` para o `db`, garantindo que:
1. O banco de dados inicia primeiro
2. O proxy só inicia após o banco estar `healthy`
3. O backup depende do banco estar `healthy` (quando profile production ativo)

## Segurança

- **Altere as senhas padrão** antes de colocar em produção
- **Altere as credenciais administrativas** após o primeiro acesso
- Configure firewall apropriado para as portas expostas
- Mantenha os backups em local seguro
- Atualize regularmente as imagens Docker
- Use senhas fortes para `DB_PASSWORD` e `MYSQL_ROOT_PASSWORD`

## Troubleshooting

### Problema: Serviços não iniciam

1. Verifique se os volumes e a rede externa foram criados:
   ```bash
   docker volume ls | grep proxy
   docker network ls | grep proxy
   ```

2. Verifique os healthchecks:
   ```bash
   docker compose ps
   ```

   Se o status for `unhealthy`, verifique os logs:
   ```bash
   docker compose logs db
   docker compose logs proxy
   ```

### Problema: Healthcheck do banco falha

O banco usa MariaDB Aria (não InnoDB). Verifique os logs:

```bash
docker compose logs --follow db
```

Procure por:
- `[Note] Plugin 'InnoDB' is disabled.` - normal para esta imagem
- `ready for connections` - indica que o banco está pronto

### Problema: Conflito de portas

Se você receber erro `port is already allocated`:

1. Verifique quais portas estão em uso:
   ```bash
   lsof -i :80
   lsof -i :443
   lsof -i :81
   ```

2. Altere as portas no arquivo `.env`:
   ```bash
   HTTP_PORT=9080
   HTTPS_PORT=9443
   ADMIN_PORT=9081
   ```

### Problema: Não consigo acessar a interface web

1. Verifique se o serviço está healthy:
   ```bash
   docker compose ps
   ```

2. Verifique se a porta está sendo escutada:
   ```bash
   lsof -i :${ADMIN_PORT}
   ```

3. Teste o endpoint diretamente:
   ```bash
   curl -v http://localhost:${ADMIN_PORT}/
   ```

### Problema: Backup não está funcionando

1. Certifique-se que o perfil `production` está ativo:
   ```bash
   grep COMPOSE_PROFILES .env
   docker compose --profile production up -d
   ```

2. Verifique os logs do serviço de backup:
   ```bash
   docker compose logs backup
   ```

## Exemplos de Uso

### Desenvolvimento Local

Para desenvolvimento com portas alternativas (evitando conflitos):

```bash
# .env
HTTP_PORT=9080
HTTPS_PORT=9443
ADMIN_PORT=9081
COMPOSE_PROFILES=development
```

```bash
docker compose up -d
# Acesso: http://localhost:9081
```

### Produção

Para produção com backups automáticos:

```bash
# .env
HTTP_PORT=80
HTTPS_PORT=443
ADMIN_PORT=81
COMPOSE_PROFILES=production
BACKUP_INTERVAL=86400  # 24 horas
BACKUP_RETENTION_DAYS=30  # 30 dias
```

```bash
docker compose --profile production up -d
```

### Verificação de Saúde

```bash
# Verificar status dos serviços
docker compose ps

# Deve mostrar:
# proxy-db-1      Up (healthy)
# proxy-proxy-1   Up (healthy)

# Inspecionar healthcheck específico
docker inspect proxy-db-1 --format='{{.State.Health.Status}}'
```

### Acesso aos Logs em Tempo Real

```bash
# Todos os serviços
docker compose logs -f

# Apenas erros do banco
docker compose logs -f db 2>&1 | grep -i error

# Últimas 100 linhas do proxy
docker compose logs --tail 100 proxy
```

## Suporte

Para problemas e questões:

- Issues: https://github.com/embrapa-io/proxy/issues
- Documentação oficial do Nginx Proxy Manager: https://nginxproxymanager.com

## Licença

Este projeto segue a licença especificada no arquivo LICENSE.
