## ERC20 STARKNET

Usage :
You need to have installed [scarb](https://docs.swmansion.com/scarb/docs.html) and starknet foundry.

Then just clone repository by 

```
git clone https://github.com/ASaidOguz/Starknet-Contracts
```

move into erc20 project 
```
cd Starknet-Contracts/erc20_stark
```

and build the project by
```
scarb build
```

Everything you need to declare-deploy-interaction and  testing resides in Makefile.


Unlike solidity u256 ,in starknet it uses tuple for u256
```
struct u256 {
  low: felt252,
  high: felt252
}
```
so while deploying the contructor call data should be like this 

```
--constructor-calldata 10000000 0 0xYourRecipientAddress

```
or use --arguments flag for serialized elements.

After Declare and Deployment makefile will copy the returned values as ;

```
./deployments
```
folder will hold the json for declare and deploy.

So you dont need to use contract address or class_hash values for interacting 
All the actions can be viewed by 
```
make help
```

