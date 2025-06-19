## ZK-ECDSA signature verification

- Using starknet garaga for ecdsa verification
- It can check for signature mallability. 
- Can be easly tested with mallable signature input -> input_mal.txt just change it via generate_input.sh and run (Has already check function for this)

```
nargo execute 
```


- [Garaga starknet](https://garaga.gitbook.io/garaga/smart-contract-generators/noir)

For generating starknet verifier 

```
garaga gen --system ultra_starknet_honk --vk target/vk
```