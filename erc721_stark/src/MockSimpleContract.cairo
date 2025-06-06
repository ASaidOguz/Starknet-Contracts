#[starknet::interface]
pub trait MockSimpleContractInterface<T> {
    fn name_get(self: @T) -> felt252;
    fn name_set(ref self: T, name: felt252);
}

#[starknet::contract]
pub mod MockSimpleContract {
   
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    
    #[storage]
    struct Storage {
        name: felt252,
    }
   
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NameChanged: NameChanged,
    }

    #[derive(Drop, starknet::Event)]
    struct NameChanged {
        previous: felt252,
        current: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252) {
        self.name.write(name);
    }

    #[abi(embed_v0)]
    impl NineCairo of super::MockSimpleContractInterface<ContractState> {
        fn name_get(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn name_set(ref self: ContractState, name: felt252) {
            let previous = self.name.read();
            self.name.write(name);
            self.emit(NameChanged { previous, current: name });
        }
    }
}