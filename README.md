# Nomad Token
Solidity smart contracts `NomadBadge` and `NomadRewardToken`

### Architecture
![diagram](https://github.com/maikotrindade/nomad-token/assets/3600906/9b704bd8-cf9c-4d58-94f4-5325c132d03e)

### Repositories
- [Nomad Token](https://github.com/maikotrindade/nomad-token) - Smart contracts
- [Nomad core](https://github.com/maikotrindade/nomad-core) - Backend
- [Nomad app](https://github.com/maikotrindade/nomad-app) - Frontend

## Installing dependencies
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

## Deploying the contract
You can target any network from your Hardhat config using:
```
npx hardhat run --network sepolia scripts/deploy.ts
```
