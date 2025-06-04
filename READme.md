## STARKNET CONTRACTS 

- Starknet Erc20 openzeppelin contract have been added and built simple project.
- Starknet Erc721 openzeppelin contract have been added and built simple project.
- Starknet simple staking project and testing completed.
- Starknet Dice Game (Randomness on deterministic networks).
- Starknet Token Vendor simple vendor project where you can buy tokens with strk.
- Starknet Dex simple dex project where you can swap 2 tokesn and add liqudity.

---- Added new bash script to generate declare-deploy project contracts.After generating Makefile you can check your 
setup by 
```
make help
```
to see your deployable contracts.


- Integration tests added + in each testing suite comment section shows which part of the code have been tested.

Erc20 and Erc721 projects have own READme files to interact and have Makefile section where it can be easly start and deploy either.

local chain or sepolia testnet.

- Need to update all zero checks with "use core::num::traits::Zero;"
