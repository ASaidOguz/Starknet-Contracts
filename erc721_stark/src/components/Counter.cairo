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