## STAKING STARKNET 

Usage :
You need to have installed [scarb](https://docs.swmansion.com/scarb/docs.html) and starknet foundry.

For coverage buidling ,[Cairo-coverage](https://github.com/software-mansion/cairo-coverage) need to be installed.

Then just clone repository by 

```
git clone https://github.com/ASaidOguz/Starknet-Contracts
```

move into nft project 
```
cd Starknet-Contracts/erc721_stark
```

and build the project by
```
scarb build
```

Everything you need to declare and testing resides in Makefile.

For coverage reports 

```
genhtml -o coverage_report coverage/coverage.lcov
```






