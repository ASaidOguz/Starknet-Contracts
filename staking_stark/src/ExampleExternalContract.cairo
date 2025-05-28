#[starknet::interface]
pub trait IExampleExternalContract<T> {
    fn complete(ref self: T);
    fn is_completed(self: @T) -> bool;
}

#[starknet::contract]
pub mod ExampleExternalContract {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        completed: bool,
    }

    #[abi(embed_v0)]
    impl ExampleExternalContractImpl of super::IExampleExternalContract<ContractState> {
        fn complete(ref self: ContractState) {
            self.completed.write(true);
        }
        fn is_completed(self: @ContractState) -> bool {
            self.completed.read()
        }
    }
}