## ZK-ECDSA signature verification

- Using starknet garaga for ecdsa verification
- It can check for signature mallability. 
- Can be easly tested with mallable signature input -> input_mal.txt just change it via generate_input.sh and run

```
nargo execute 
```

![Sig-Mal](./images/Ekran%20Alıntısı.PNG)

- [Garaga starknet](https://garaga.gitbook.io/garaga/smart-contract-generators/noir)

For generating starknet verifier 

```
garaga gen --system ultra_starknet_honk --vk target/vk
```