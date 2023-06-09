# Nomad Token
Solidity smart contracts `NomadBadge` and `NomadRewardToken` - Chainlink hackathon spring 2023

* `NomadBadge (NBG)`: [https://sepolia.etherscan.io/address/0x487e0Fc813e4e529AFBb464ECD910Bdb1ddDdbdd](https://sepolia.etherscan.io/address/0x487e0Fc813e4e529AFBb464ECD910Bdb1ddDdbdd)
* `NomadRewardToken (NRT)`: [https://sepolia.etherscan.io/address/0x0ab9cDa8A48901d51D1F6D33296E269f0F6cf084](https://sepolia.etherscan.io/address/0x0ab9cDa8A48901d51D1F6D33296E269f0F6cf084)

### Architecture
![diagram](https://github.com/maikotrindade/nomad-token/assets/3600906/9b704bd8-cf9c-4d58-94f4-5325c132d03e)

### Repositories
- [Nomad Token](https://github.com/maikotrindade/nomad-token) - Smart contracts
- [Nomad core](https://github.com/maikotrindade/nomad-core) - Backend
- [Nomad app](https://github.com/maikotrindade/nomad-app) - Frontend

## Smart contracts - nomad-token
tech stack: solidity, typescript, javascript, chainlink, openzeppelin, hardhat, npm

### Installing dependencies
```
npm install
```
### Setup secrets
````
ALCHEMY_KEY = ...
ADMIN_ACCOUNT_ADDRESS = ...
ADMIN_ACCOUNT_PRIVATE_KEY = ...
MONGO_CONNECTION_URL = ...
PORT=...
AVIATIONSTACK_ACCESS_KEY = ...
````

### Deploying the contract
You can target any network from your Hardhat config using:
```
npx hardhat run --network sepolia scripts/deploy.ts
```

## Backend - nomad-core
tech stack: typescript, javascript, nodejs, alchemysdk, ethersjs, mongoose, express, dotenv, node-cron, heroku, heroku-scheduler, axios, cors, helmet, nodemon, compression

### Scripts
`node` server.ts

### Server
`heroku logs --tail`
Server location: [nomad-core.herokuapp.com](https://nomad-core.herokuapp.com/)


## Frontend - nomad-app
tech stack: kotlin, kotlinx-coroutines, jetpack compose, firebase-crashlytics, firebase-auth-ktx, accompanist-flowlayout, compose.material3, okhttp3, retrofit2

Google Play: [Nomad Rewards App](https://play.google.com/store/apps/details?id=io.github.maikotrindade.nomadrewards)
