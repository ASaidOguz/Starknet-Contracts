#[starknet::interface]
pub trait ICounter<TState>{
    fn current(self:@TState)-> u256;
    fn increment(ref self:TState);
    fn decrement(ref self:TState);
}

#[starknet::component]
pub mod CounterComponent{
    use starknet::storage::{StoragePointerReadAccess,StoragePointerWriteAccess};
    use super::ICounter;

    #[storage]
    pub struct Storage{
        value :u256,
    }

    #[embeddable_as(CounterImpl)]
    impl Counter<
        TContractState, +HasComponent<TContractState>,
        > of ICounter<ComponentState<TContractState>>{
            /// In Cairo, the @ symbol is used to indicate that a value is passed by copy, not by reference.
            /// So this means that below func'is view type read-only func.
            /// current function is used to get the current value of the counter.
            fn current(self:@ComponentState<TContractState>) -> u256{
                self.value.read()
            }
            /// increment function is used to increase the value of the counter by 1.
            fn increment(ref self:ComponentState<TContractState>){
                self.value.write(self.value.read()+1);
            }
            /// decrement function is used to decrease the value of the counter by 1.
            fn decrement(ref self:ComponentState<TContractState>){
                self.value.write(self.value.read()-1);
            }
        }
}

#[cfg(test)]
#[starknet::contract]
mod TestCounterContract {
    use super::*;
    use super::CounterComponent;
    
    
    component!(path: CounterComponent, storage: counter, event: CounterEvent);
    
    // Embed the Counter component implementation
    #[abi(embed_v0)]
    impl CounterImpl = CounterComponent::CounterImpl<ContractState>;
    
    #[storage]
    struct Storage {
        #[substorage(v0)]
        counter: CounterComponent::Storage,
    }
    
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        CounterEvent: CounterComponent::Event,
    }
    
}
#[cfg(test)]
mod counter_unit_tests {
    use super::{ICounterDispatcher, ICounterDispatcherTrait};
    use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
    use starknet::ContractAddress;
    
    // Helper function to deploy test contract
    fn deploy_test_counter() -> ContractAddress {
        let contract = declare("TestCounterContract").unwrap().contract_class();
        let (contract_address, _) = contract.deploy(@array![]).unwrap();
        contract_address
    }
    
    #[test]
    fn test_initial_value() {
        let contract_address = deploy_test_counter();
        let dispatcher = ICounterDispatcher { contract_address };
        
        // Test that counter starts at 0
        let initial_value = dispatcher.current();
        assert(initial_value == 0, 'Initial value should be 0');
    }
    
    #[test]
    fn test_increment() {
        let contract_address = deploy_test_counter();
        let dispatcher = ICounterDispatcher { contract_address };
        
        // Test single increment
        dispatcher.increment();
        assert(dispatcher.current() == 1, 'Should be 1 after increment');
        
        // Test multiple increments
        dispatcher.increment();
        dispatcher.increment();
        assert(dispatcher.current() == 3, 'Should be 3 after 3 increments');
    }
    #[test]
    fn test_decrement() {
        let contract_address = deploy_test_counter();
        let dispatcher = ICounterDispatcher { contract_address };
        
        // Test single decrement
        dispatcher.increment(); // Start at 1
        dispatcher.decrement();
        assert(dispatcher.current() == 0, 'Should be 0 after decrement');
        
        // Test multiple decrements
        dispatcher.increment(); // Start at 1
        dispatcher.increment(); // Now at 2
        dispatcher.decrement();
        assert(dispatcher.current() == 1, 'Should be 1 after decrement');
        
        dispatcher.decrement();
        assert(dispatcher.current() == 0, 'Should be 0 after second');
    }
}