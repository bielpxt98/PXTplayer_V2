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
