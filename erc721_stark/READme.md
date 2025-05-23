## ERC721 STARKNET NFT


Usage :
You need to have installed [scarb](https://docs.swmansion.com/scarb/docs.html) and starknet foundry.

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

Everything you need to declare-deploy-interaction and  testing resides in Makefile.



Current contract's (Erc721 example taken from Speedrun starknet)
 counter implementation is exposed to public and it may act as security concern -> May counter raised or decreesed to cause DOS for the contract(Cant mint item already exist) .For learning purposes it can be set in abi and tweek on it if you want.

Simple fix => 
```
    // Exposing entry points
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    //#[abi(embed_v0)] -> Remove this abi embedded annotation to set this impl internal 
    impl CounterImpl = CounterComponent::CounterImpl<ContractState>; 
    #[abi(embed_v0)]
    impl ERC721Impl= ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721EnumerableImpl =
        ERC721EnumerableComponent::ERC721EnumerableImpl<ContractState>;
```

Essential part of the testing with mock contracts's never forget the main entry point of the contract 
compilation's always start from lib.cairo so just simply set your mock contract inside of src and 
add as "pub mod Mock" so scarb can understand and compile and create artifact for your mocks.
Then use it in tests with declare funtion easily.

