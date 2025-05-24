#[starknet::interface]
pub trait IMockStarkToken<TState>{
    fn mint(ref self:TState,recipient:ContractAddress,amount:u256) -> bool;
}
use starknet::ContractAddress;
 
#[starknet::contract]
mod MockStarkToken {
    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    // Import the interface for MockStarkToken and ContractAddress
    use super::*;
    // MockStarkToken contract that implements the ERC20 interface
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    
    // ERC20 Mixin
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    // Storage for MockStarkToken
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }
    // Event for MockStarkToken
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,  
    }
    // constructor for MockStarkToken
    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_supply: u256,
        recipient: ContractAddress
    ) {
        // Mock Stark contract elements.
        let name = "MockStarkToken";
        let symbol = "MSTRK";
        self.erc20.initializer(name, symbol);
        self.erc20.mint(recipient, initial_supply);
    }
    // Internal func for Check for zero address...
    fn  _isZeroAddress(address: ContractAddress) -> bool {
        let zero_address:ContractAddress = 0.try_into().unwrap();
        address != zero_address
    }

    #[abi(embed_v0)]
    pub impl IMockStarkTokenImpl of IMockStarkToken<ContractState>{
    fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
        // Ensure recipient is not zero address
        assert!(_isZeroAddress(recipient), "Recipient cannot be zero address");
        self.erc20.mint(recipient, amount); // Call the internal ERC20 mint
        true
        }
    }
}