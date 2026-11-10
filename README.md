# Rotina TEA

Aplicativo Flutter para apoiar a organização da rotina de crianças autistas.

## Executar com Docker

É necessário ter Docker Engine ou Docker Desktop instalado e em execução.

Na raiz do projeto, execute:

```sh
docker compose -f docker-compose.yml -f docker-compose.local.yml up --build
```

Abra [http://localhost:8080](http://localhost:8080) no navegador. Para encerrar,
pressione `Ctrl+C` ou execute `docker compose down` em outro terminal.

O aplicativo web salva tarefas e preferências no armazenamento local do
navegador. Esses dados pertencem à origem (host e porta) usada para abrir o
aplicativo; mantenha o mesmo endereço para continuar acessando os mesmos dados.

## Implantar no Coolify

Use o `docker-compose.yml` do repositório e configure **Ports Exposes** como
`80`. Não publique uma porta do host; o proxy do Coolify encaminha o domínio
para a porta interna do container. O arquivo `docker-compose.local.yml` é
somente para execução local.

## Executar localmente

Com o Flutter instalado, use:

```sh
flutter pub get
flutter run -d chrome
```
