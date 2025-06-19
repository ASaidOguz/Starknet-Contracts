## ZK-ECDSA signature verification

- Using starknet garaga for ecdsa verification
- It can check for signature mallability. 
- You can use [bb backend](https://github.com/AztecProtocol/aztec-packages/blob/master/barretenberg/bbup/README.md) engine cli too.
- Can be easly tested with mallable signature input -> input_mal.txt just change it via generate_input.sh and run (Has already check function for this)

```
nargo execute 
```


- [Garaga starknet](https://garaga.gitbook.io/garaga/smart-contract-generators/noir)



usage :

- clone the repo 
```
git clone https://github.com/ASaidOguz/Starknet-Contracts
```

- navigate to zk_ecdsa

```
cd Starknet-Contracts/zk_ecdsa
```

- install node packages (bb.js noir.js)

```
yarn install
```

- You can create your own (verification key)  vk-calldata by popoulating inputs.txt and then run

```
./generate_input.sh
```

this will generate inputs for the circuit and then run the generate_vk-calldata.js to procure the calldata vk
for starknet verifier.
```
node  generate_vk-calldata.js
```

After calldata generation just move to zk_sig_verify folder and run (assume you have already [starknet-foundry](https://foundry-rs.github.io/starknet-foundry/) and [scarb](https://foundry-rs.github.io/starknet-foundry/getting-started/scarb.html) and [starknet-devnet](https://0xspaceshard.github.io/starknet-devnet/docs/running/install))

For generating starknet verifier from scratch u can do it by running garaga line

```
garaga gen --system ultra_starknet_honk --vk target/vk
```

- start local chain
```
make start_dev
```

- set account for interactions
```
make set_account
```

- Declare starknet verifier 
```
make declare_local_UltraStarknetHonkVerifier
```

- Deploy starknet verifier 
```
make deploy_local_UltraStarknetHonkVerifier
```

- Interact with the verifier 

```
make verify_proof
```

You can parse response with response-check.js 
```
node response-check.js 
```
 just read the comments for more info in code and if everything is succesful you will see this screen

![final-screen](./images/Ekran%20Alıntısı.PNG)