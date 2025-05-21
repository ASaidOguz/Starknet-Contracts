## ERC20 STARKNET

Unlike solidity u256 in starknet it uses tuple for u256
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