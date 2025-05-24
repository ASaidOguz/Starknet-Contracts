
#[starknet::interface]
pub trait IErc20TL<TState>{
    fn mint(ref self:TState,recipient:ContractAddress,amount:u256) -> bool;
}

use starknet::ContractAddress;
#[starknet::contract]
mod Erc20TL {
    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin_access::ownable::OwnableComponent;
   
    
    use super::*;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // ERC20 Mixin -> in mixing it already has metadata implemented.
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_supply: u256,
        owner: ContractAddress
    ) {
        
        // Recipient is the address that will receive the initial supply of tokens and owner of the contract
        self.ownable.initializer(owner); // Or `recipient` if that's the design

        // Initialize ERC20 after Ownable, or in an order that makes sense for your logic
        let name = "Erc20TL";
        let symbol = "ETL";
        self.erc20.initializer(name, symbol);
        self.erc20.mint(owner, initial_supply);
    }

    #[abi(embed_v0)]
    pub impl IErc20TLImpl of IErc20TL<ContractState>{
    fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
        self.ownable.assert_only_owner(); // Enforce owner-only access
        self.erc20.mint(recipient, amount); // Call the internal ERC20 mint
        true
        }
    }
}