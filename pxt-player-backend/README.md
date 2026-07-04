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

## Busca global de filmes e séries

`POST /api/search` pesquisa somente no cache completo da conta (`dns + username`) já carregado pelo `POST /api/bootstrap`. A rota não chama a API Xtream, não baixa catálogo durante a busca, não usa categorias abertas no Roku e não depende de histórico de navegação ou itens visíveis na tela. Se o cache ainda não existir ou não estiver pronto, a resposta é `cache_not_ready`.

A busca usa um índice em memória criado por conta (`dns + username`) assim que o bootstrap/cache fica pronto, com `moviesIndex` e `seriesIndex`. O índice mantém apenas os dados necessários para resposta e busca (`type`, `id`, `name`, `normalizedName`, `poster`, `category_id`, ano/data quando existir e `container_extension` para filmes), evitando varrer o catálogo bruto completo durante a pesquisa. A busca normaliza o texto para lowercase, remove acentos, ignora espaços duplicados e compara a consulta com `name`, `title` e `stream_name` quando esses campos existem. O parâmetro `type` aceita `movies`, `series` ou `all`; os resultados são ordenados por itens que começam com a busca, depois itens em que alguma palavra começa com a busca e, por fim, itens que apenas contêm a busca. O limite padrão é 50, com suporte opcional a `limit` no corpo e máximo de 100 itens.

### Exemplo de busca de filmes

```bash
curl -X POST http://localhost:3000/api/search \
  -H "Content-Type: application/json" \
  -d '{
    "dns": "https://servidor.com",
    "username": "usuario",
    "query": "hom",
    "type": "movies",
    "limit": 50
  }'
```

Exemplo de resposta:

```json
{
  "ok": true,
  "query": "hom",
  "type": "movies",
  "limit": 50,
  "count": 1,
  "results": [
    {
      "type": "movie",
      "id": "123",
      "name": "Homem Aranha",
      "poster": "https://servidor.com/posters/homem-aranha.jpg",
      "category_id": "10",
      "year": "2021",
      "container_extension": "mp4"
    }
  ]
}
```

### Exemplo de busca de séries

```bash
curl -X POST http://localhost:3000/api/search \
  -H "Content-Type: application/json" \
  -d '{
    "dns": "https://servidor.com",
    "username": "usuario",
    "query": "home",
    "type": "series"
  }'
```

Exemplo de resposta:

```json
{
  "ok": true,
  "query": "home",
  "type": "series",
  "count": 1,
  "results": [
    {
      "type": "series",
      "id": "987",
      "name": "Home Before Dark",
      "poster": "https://servidor.com/covers/home-before-dark.jpg",
      "category_id": "22",
      "releaseDate": "2020-01-01"
    }
  ]
}
```

### Exemplo de busca all

```bash
curl -X POST http://localhost:3000/api/search \
  -H "Content-Type: application/json" \
  -d '{
    "dns": "https://servidor.com",
    "username": "usuario",
    "query": "hom",
    "type": "all"
  }'
```

Exemplo de resposta sem resultados:

```json
{
  "ok": true,
  "query": "hom",
  "type": "all",
  "limit": 50,
  "count": 0,
  "results": []
}
```

### Resposta quando o cache não está pronto

```json
{
  "ok": false,
  "error": "cache_not_ready"
}
```

### Status da busca

`GET /api/search/status?dns=...&username=...` informa se o cache da conta está pronto para pesquisa. A senha não é enviada nessa rota.

```bash
curl "http://localhost:3000/api/search/status?dns=https%3A%2F%2Fservidor.com&username=usuario"
```

Exemplo de resposta:

```json
{
  "ok": true,
  "exists": true,
  "ready": true,
  "loading": false,
  "searchable": true,
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

## Teste de desempenho com catálogo grande

O backend inclui um teste de desempenho para validar o bootstrap, o status do cache e a busca global antes da integração com o Roku. O teste não altera o app Roku e não grava senha em logs ou respostas.

### Rodar com mock grande

Sem variáveis Xtream, o script inicia um servidor Xtream mock local e gera automaticamente pelo menos 20.000 filmes, 10.000 séries e categorias variadas:

```bash
npm run test:large
```

O comando `npm run test:performance` executa o mesmo script:

```bash
npm run test:performance
```

### Rodar com conta Xtream real

Defina as variáveis abaixo para testar contra uma conta real. A senha é usada somente para chamar o bootstrap e não é impressa no relatório:

```bash
XTREAM_DNS="https://servidor.com" \
XTREAM_USERNAME="usuario" \
XTREAM_PASSWORD="senha" \
npm run test:performance
```

### Como interpretar o relatório

O script imprime um JSON no fim da execução:

```json
{
  "bootstrapTimeMs": 0,
  "movies": 20000,
  "series": 10000,
  "cacheReady": true,
  "averageSearchMs": 0,
  "memoryUsageMb": 0
}
```

- `bootstrapTimeMs`: tempo total entre chamar `/api/bootstrap` e o `/api/cache/status` ficar `ready: true`.
- `movies` e `series`: quantidades carregadas no cache por conta.
- `cacheReady`: deve ser `true`; se for `false`, a busca deve responder `cache_not_ready`.
- `averageSearchMs`: média das chamadas a `/api/search`, que usam o índice em memória por conta (`dns + username`) em vez do catálogo bruto completo.
- `memoryUsageMb`: uso aproximado de memória RSS do processo que executa o teste.
