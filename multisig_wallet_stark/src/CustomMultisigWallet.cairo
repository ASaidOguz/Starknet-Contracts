use starknet::ContractAddress;

#[starknet::interface]
pub trait IMultisigWallet<TContractState> {
    fn transfer_funds(ref self: TContractState, to: ContractAddress, amount: u256);
}

#[starknet::contract]
mod CustomMultisigWallet {
    use multisig_wallet_stark::CustomMultisigComponent::MultisigComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use super::{ContractAddress, IMultisigWallet};
    use starknet::storage::{ StoragePointerReadAccess,StoragePointerWriteAccess};
  

    component!(path: MultisigComponent, storage: multisig, event: MultisigEvent);

    #[abi(embed_v0)]
    impl MultisigImpl = MultisigComponent::MultisigImpl<ContractState>;
    impl MultisigInternalImpl = MultisigComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        multisig: MultisigComponent::Storage,
        strk_contract_address:ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MultisigEvent: MultisigComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, quorum: u32, signer: ContractAddress,strk_contract_address: ContractAddress) {
        self.strk_contract_address.write(strk_contract_address);
        self.multisig.initializer(quorum, signer);
    }

    #[abi(embed_v0)]
    impl MultisigWalletImpl of IMultisigWallet<ContractState> {
        fn transfer_funds(ref self: ContractState, to: ContractAddress, amount: u256) {
            // below line will ensure that only the multisig can call this function.
            self.multisig.assert_only_self();
            // Transfer STRK tokens to the specified address
            let strk_contract_address = self.strk_contract_address.read();
            let token_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            token_dispatcher.transfer(to, amount);
        }
    }
}