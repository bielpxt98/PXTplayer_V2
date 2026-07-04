# PXT Player Backend

Backend Node.js/Express para intermediar chamadas do PXT Player à API Xtream Codes.

## Requisitos

- Node.js 18 ou superior
- npm

## Como rodar

```bash
cd pxt-player-backend
npm install
npm start
```

Por padrão, o servidor sobe em `http://localhost:3000`. Para trocar a porta, defina a variável `PORT` antes de executar `npm start`.

## Health check

```bash
curl http://localhost:3000/health
```

Resposta esperada:

```json
{
  "ok": true
}
```

## Login Xtream

### Requisição

`POST /api/login`

O campo `dns` aceita URLs com `http://` ou `https://`. Se o protocolo não for enviado, o backend usa `http://` por padrão. Barras finais são removidas antes da chamada à API Xtream.

```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "dns": "https://servidor.com",
    "username": "usuario",
    "password": "senha"
  }'
```

O backend chama a API Xtream neste formato, sem salvar ou retornar a senha:

```text
{dns}/player_api.php?username={username}&password={password}
```

A tentativa usa timeout de 10 segundos.

### Exemplo de resposta de sucesso

```json
{
  "ok": true,
  "account": {
    "username": "usuario",
    "status": "Active",
    "exp_date": "1893456000",
    "is_trial": "0",
    "active_cons": "1",
    "max_connections": "2"
  },
  "server": {
    "url": "servidor.com",
    "port": "80",
    "https_port": "443",
    "server_protocol": "http"
  }
}
```

### Exemplo de erro

Campos obrigatórios ausentes retornam HTTP 400:

```json
{
  "ok": false,
  "error": "dns, username and password are required"
}
```

Outros erros também seguem o mesmo formato:

```json
{
  "ok": false,
  "error": "Invalid username or password."
}
```

## Bootstrap do catálogo

`POST /api/bootstrap` carrega, em memória, o catálogo inicial de filmes e séries retornado pela API Xtream em um cache por conta (`dns + username`). O backend não grava esses dados em disco, não guarda a senha no cache e não retorna a senha em respostas; os dados ficam disponíveis apenas enquanto o processo do servidor estiver em execução. O cache é válido por 6 horas.

A rota valida `dns`, `username` e `password`. Antes de chamar a API Xtream, ela verifica se já existe cache pronto para a conta. Se o cache estiver pronto e válido, o backend retorna as contagens do cache. Se já houver um carregamento em andamento, retorna `loading`. Se o cache estiver expirado, mantém os dados antigos disponíveis e inicia uma atualização em segundo plano quando possível. Quando precisa carregar, chama as ações abaixo em paralelo sempre que possível e registra logs de cache criado, cache usado, cache expirado, cache limpo e carregamento em andamento:

- `action=get_vod_categories`
- `action=get_vod_streams`
- `action=get_series_categories`
- `action=get_series`

### Requisição

```bash
curl -X POST http://localhost:3000/api/bootstrap \
  -H "Content-Type: application/json" \
  -d '{
    "dns": "https://servidor.com",
    "username": "usuario",
    "password": "senha"
  }'
```

### Exemplo de resposta com cache pronto

```json
{
  "ok": true,
  "ready": true,
  "loading": false,
  "movieCategories": 18,
  "movies": 8500,
  "seriesCategories": 12,
  "series": 640,
  "startedAt": "2026-07-04T12:34:00.000Z",
  "loadedAt": "2026-07-04T12:34:56.789Z",
  "updatedAt": "2026-07-04T12:34:56.789Z",
  "errors": {},
  "source": "cache"
}
```

### Exemplo de resposta durante carregamento

```json
{
  "ok": true,
  "ready": false,
  "loading": true,
  "movieCategories": 0,
  "movies": 0,
  "seriesCategories": 0,
  "series": 0,
  "startedAt": "2026-07-04T12:34:00.000Z",
  "loadedAt": null,
  "updatedAt": "2026-07-04T12:34:00.000Z",
  "errors": {},
  "status": "loading"
}
```

Se uma parte do catálogo falhar, o servidor não é derrubado. As partes carregadas são mantidas em memória, `ready` fica `false` e o campo `errors` informa individualmente o que falhou:

```json
{
  "ok": true,
  "ready": false,
  "movieCategories": 0,
  "movies": 0,
  "seriesCategories": 12,
  "series": 640,
  "loadedAt": "2026-07-04T12:34:56.789Z",
  "loadTimeMs": 1432,
  "errors": {
    "movieCategories": "Xtream server responded with HTTP 502.",
    "movies": "Xtream server responded with HTTP 502."
  }
}
```

## Status do cache por conta

`GET /api/cache/status?dns=...&username=...` informa se existe cache para uma conta específica, se ele está pronto ou carregando e as contagens carregadas. A senha não é enviada nessa rota.

```bash
curl "http://localhost:3000/api/cache/status?dns=https%3A%2F%2Fservidor.com&username=usuario"
```

Exemplo de resposta:

```json
{
  "ok": true,
  "exists": true,
  "ready": true,
  "loading": false,
  "counts": {
    "movieCategories": 18,
    "movies": 8500,
    "seriesCategories": 12,
    "series": 640
  },
  "loadedAt": "2026-07-04T12:34:56.789Z",
  "updatedAt": "2026-07-04T12:34:56.789Z"
}
```

## Limpeza do cache por conta

`POST /api/cache/clear` remove apenas o cache da conta indicada por `dns + username`. A senha não é necessária e não é armazenada.

```bash
curl -X POST http://localhost:3000/api/cache/clear \
  -H "Content-Type: application/json" \
  -d '{
    "dns": "https://servidor.com",
    "username": "usuario"
  }'
```

Exemplo de resposta:

```json
{
  "ok": true,
  "cleared": true
}
```

## Status do bootstrap

`GET /api/bootstrap/status` informa se o catálogo em memória está pronto e quantos itens foram carregados.

```bash
curl http://localhost:3000/api/bootstrap/status
```

Exemplo de resposta antes do bootstrap:

```json
{
  "ready": false,
  "loadedAt": null,
  "movieCategories": 0,
  "movies": 0,
  "seriesCategories": 0,
  "series": 0,
  "errors": {}
}
```

Exemplo de resposta após o bootstrap:

```json
{
  "ready": true,
  "loadedAt": "2026-07-04T12:34:56.789Z",
  "movieCategories": 18,
  "movies": 8500,
  "seriesCategories": 12,
  "series": 640,
  "errors": {}
}
```
