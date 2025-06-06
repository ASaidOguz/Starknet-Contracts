use starknet::ContractAddress;
use starknet::account::Call;

pub type TransactionID = felt252;
// lets alias it so we can use it in our contract.
pub type TransactionState = multisig_wallet_stark::CustomInterfaceMultisigComponent::TransactionState;

#[starknet::interface]
pub trait IMultisigWallet<TContractState> {
    fn transfer_funds(ref self: TContractState, to: ContractAddress, amount: u256);
    fn get_quorum(self: @TContractState) -> u32;
    fn is_signer(self: @TContractState, signer: ContractAddress) -> bool;
    fn get_signers(self: @TContractState) -> Array<ContractAddress>;
    fn is_confirmed(self: @TContractState, id: TransactionID) -> bool;
    fn is_confirmed_by(self: @TContractState, id: TransactionID, signer: ContractAddress) -> bool;
    fn is_executed(self: @TContractState, id: TransactionID) -> bool;
    fn get_submitted_block(self: @TContractState, id: TransactionID) -> u64;
    fn get_transaction_state(self: @TContractState, id: TransactionID) -> TransactionState;
    fn get_transaction_confirmations(self: @TContractState, id: TransactionID) -> u32;
    fn hash_transaction(
        self: @TContractState,
        to: ContractAddress,
        selector: felt252,
        calldata: Array<felt252>,
        salt: felt252,
    ) -> TransactionID;
    fn hash_transaction_batch(self: @TContractState, calls: Array<Call>, salt: felt252) -> TransactionID;
    // Customized add_signer: add a single signer
    fn add_signer(ref self: TContractState, new_quorum: u32, signer_to_add: ContractAddress);
    fn remove_signer(ref self: TContractState, new_quorum: u32, signer_to_remove: ContractAddress);
    fn replace_signer(
        ref self: TContractState, signer_to_remove: ContractAddress, signer_to_add: ContractAddress,
    );
    fn change_quorum(ref self: TContractState, new_quorum: u32);
    fn submit_transaction(
        ref self: TContractState,
        to: ContractAddress,
        selector: felt252,
        calldata: Array<felt252>,
        salt: felt252,
    ) -> TransactionID;
    fn submit_transaction_batch(
        ref self: TContractState, calls: Array<Call>, salt: felt252,
    ) -> TransactionID;
    fn confirm_transaction(ref self: TContractState, id: TransactionID);
    fn revoke_confirmation(ref self: TContractState, id: TransactionID);
    fn execute_transaction(
        ref self: TContractState,
        to: ContractAddress,
        selector: felt252,
        calldata: Array<felt252>,
        salt: felt252,
    );
    fn execute_transaction_batch(ref self: TContractState, calls: Array<Call>, salt: felt252);
}

#[starknet::contract]
mod CustomMultisigWallet {
    use multisig_wallet_stark::CustomMultisigComponent::MultisigComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin_access::ownable::OwnableComponent;
    use super::{ContractAddress, IMultisigWallet,TransactionID,TransactionState,Call};
    use starknet::storage::{ StoragePointerReadAccess,StoragePointerWriteAccess};
    
    use openzeppelin_governance::multisig::storage_utils::{SignersInfoStorePackingV2,TxInfoStorePacking};
    
    component!(path: MultisigComponent, storage: multisig, event: MultisigEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    //#[abi(embed_v0)]
    impl MultisigImpl = MultisigComponent::MultisigImpl<ContractState>;
    impl MultisigInternalImpl = MultisigComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        multisig: MultisigComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        strk_contract_address:ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MultisigEvent: MultisigComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, quorum: u32, signer: ContractAddress,strk_contract_address: ContractAddress) {
        self.strk_contract_address.write(strk_contract_address);
        // first signer will be the owner of the multisig wallet who has privilieged to submit transaction.
        self.ownable.initializer(signer);
        self.multisig.initializer(quorum, signer);
    }

    #[abi(embed_v0)]
    impl MultisigWalletImpl of IMultisigWallet<ContractState> {
        // This function should be called via submit transaction --> multsig functionality.
        fn transfer_funds(ref self: ContractState, to: ContractAddress, amount: u256) {
            // below line will ensure that only the multisig can call this function.
            self.multisig.assert_only_self();
            // Transfer STRK tokens to the specified address
            let strk_contract_address = self.strk_contract_address.read();
            let token_dispatcher = IERC20Dispatcher { contract_address: strk_contract_address };
            token_dispatcher.transfer(to, amount);
        }
       // view func for quorum.
       fn get_quorum(self: @ContractState) -> u32{
        self.multisig.get_quorum()
       }
       // view func for is_signer
       fn is_signer(self:@ContractState,signer:ContractAddress)->bool{
        self.multisig.is_signer(signer)
       }
       // view func for get_signers
       fn get_signers(self: @ContractState) -> Array<ContractAddress>{
        self.multisig.get_signers()
       }
       // view func for is_confirmed
       fn is_confirmed(self: @ContractState, id: TransactionID) -> bool{
        self.multisig.is_confirmed(id)
       }
       // view func for is_confirmed_by
       fn is_confirmed_by(self: @ContractState, id: TransactionID, signer: ContractAddress) -> bool{
        self.multisig.is_confirmed_by(id,signer)
       }
       // view func for is_executed
       fn is_executed(self: @ContractState, id: TransactionID) -> bool{
        self.multisig.is_executed(id)
       }
       // view func for get_submitted_block
       fn get_submitted_block(self: @ContractState, id: TransactionID) -> u64{
        self.multisig.get_submitted_block(id)
       }
       // view func for get_transaction_state 
       fn get_transaction_state(self: @ContractState, id: TransactionID) -> TransactionState{
        self.multisig.get_transaction_state(id)
       }
       // view func for get_transaction_confirmation count
       fn get_transaction_confirmations(self: @ContractState, id: TransactionID) -> u32{
        self.multisig.get_transaction_confirmations(id)
       }
       // view func for hash_transaction
       fn hash_transaction(
                 self: @ContractState,
                 to: ContractAddress,
                 selector: felt252,
                 calldata: Array<felt252>,
                 salt: felt252,
                           ) -> TransactionID{
                            self.multisig.hash_transaction(to,selector,calldata,salt)
                           }
       // view func for hash_transaction_batch
       fn hash_transaction_batch(self: @ContractState, calls: Array<Call>, salt: felt252) -> TransactionID{
        self.multisig.hash_transaction_batch(calls,salt)
       }

       // Customized add_signer: add a single signer -> 
       // This function should be called via submit transaction --> multsig functionality.
       fn add_signer(ref self: ContractState, new_quorum: u32, signer_to_add: ContractAddress){
        self.multisig.add_signer(new_quorum,signer_to_add);
       }

       // This function should be called via submit transaction --> multsig functionality.
       fn remove_signer(ref self: ContractState, new_quorum: u32, signer_to_remove: ContractAddress){
        self.multisig.remove_signer(new_quorum,signer_to_remove);
       }

       // This function should be called via submit transaction --> multsig functionality.
       fn replace_signer(
                  ref self: ContractState, signer_to_remove: ContractAddress, signer_to_add: ContractAddress,
                        ){
                            self.multisig.replace_signer(signer_to_remove,signer_to_add);
                        }
       // This function should be called via submit transaction --> multsig functionality.
       // i added the assert_only_self() code for this section so for changing quorum we decide as community.
       fn change_quorum(ref self: ContractState, new_quorum: u32){
        self.multisig.assert_only_self();
        self.multisig.change_quorum(new_quorum);
       }

       // only admin(owner) can submit transaction.
       // a veto mechanism maybe added but it would completly break the principle of multisig
       // where admin can veto or confirm direclty.
       fn submit_transaction(
                ref self: ContractState,
                to: ContractAddress,
                selector: felt252,
                calldata: Array<felt252>,
                salt: felt252,
                         ) -> TransactionID{
                            // this way only owner can call this function.
                            self.ownable.assert_only_owner();
                            self.multisig.submit_transaction(to,selector,calldata,salt)
                         }

        fn submit_transaction_batch(
            ref self: ContractState, calls: Array<Call>, salt: felt252,
        ) -> TransactionID{
            // this way only owner can call this function.
            self.ownable.assert_only_owner();
            self.multisig.submit_transaction_batch(calls,salt)
        }
        // This should be called by one of the delegated signer.For confirmation.
        fn confirm_transaction(ref self: ContractState, id: TransactionID){
            self.multisig.confirm_transaction(id);
        }
        // This should be called by one of the delegated signer.For revoke a confirmation.
        fn revoke_confirmation(ref self: ContractState, id: TransactionID){
            self.multisig.revoke_confirmation(id);
        }
        // This should be called by one of the delegated signer for execution
        fn execute_transaction(
            ref self: ContractState,
            to: ContractAddress,
            selector: felt252,
            calldata: Array<felt252>,
            salt: felt252,
        ){
            self.multisig.execute_transaction(to,selector,calldata,salt)
        }
        // This should be called by one of the delegated signer for batch execution.
        fn execute_transaction_batch(ref self: ContractState, calls: Array<Call>, salt: felt252){
            self.multisig.execute_transaction_batch(calls,salt)
        }
    }
}