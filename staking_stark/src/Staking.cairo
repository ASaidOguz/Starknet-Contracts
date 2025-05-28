use openzeppelin_token::erc20::interface::{IERC20Dispatcher,IERC20DispatcherTrait};
use starknet::ContractAddress;

#[starknet::interface] // This interface defines the methods for a staking contract with Generic type T.
pub trait IStaking<T>{
    // Core functions
    fn execute(ref self: T);
    fn stake(ref self: T, amount: u256);
    fn withdraw(ref self: T);
    // Getters
    fn balances(self: @T, account: ContractAddress) -> u256;
    fn completed(self: @T) -> bool;
    fn deadline(self: @T) -> u64;
    fn example_external_contract(self: @T) -> ContractAddress;
    fn open_for_withdraw(self: @T) -> bool;
    fn token_dispatcher(self: @T) -> IERC20Dispatcher;
    fn threshold(self: @T) -> u256;
    fn total_balance(self: @T) -> u256;
    fn time_left(self: @T) -> u64;
}

#[starknet::contract]
pub mod Staking{

    use staking_stark::ExampleExternalContract::{
        IExampleExternalContractDispatcher, IExampleExternalContractDispatcherTrait,
    };
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{get_block_timestamp, get_caller_address, get_contract_address};
    use super::{ContractAddress, IERC20Dispatcher, IERC20DispatcherTrait, IStaking};

    const THRESHOLD: u256 = 1000000000000000000; // ONE_STRK_IN_FRI: 10 ^ 18;

    #[event]
    #[derive(Drop,starknet::Event)] //->This enables the type (Event enum) to clean up resources when it goes out of scope.
    enum Event{
        Staking: Staking,
        Withdraw: Withdraw,
    }

    #[derive(Drop, starknet::Event)]
    struct Staking {
        #[key]
        sender: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdraw{
        #[key]
        caller :ContractAddress,
        amount:u256,
    }

    #[storage]
    struct Storage {
        token_dispatcher: IERC20Dispatcher,
        balances: Map<ContractAddress, u256>,
        deadline: u64,
        open_for_withdraw: bool,
        external_contract_address: ContractAddress,
    }

    #[constructor]
    pub fn constructor(
        ref self:ContractState,
        strk_contract:ContractAddress,
        external_contract_address:ContractAddress,
        ){
        self.token_dispatcher.write(IERC20Dispatcher{contract_address: strk_contract});
        self.external_contract_address.write(external_contract_address);
        let current_time = get_block_timestamp();
        self.deadline.write(current_time + 60);
        }
    #[abi(embed_v0)]
    impl StakingImpl of IStaking<ContractState>{
        fn stake(
            ref self:ContractState,
            amount:u256
        ){
            assert!(self.time_left() > 0, "Staking period has ended");
            let caller = get_caller_address();
            let token_dispatcher = self.token_dispatcher();
            let success =token_dispatcher.transfer_from(caller, get_contract_address(), amount);
            // Check if the transfer was succesful.
            assert!(success,"Transfer failed");
            // First calculate total amount of contract and write. 
            let current_balance = self.balances.read(get_contract_address());
            self.balances.write(get_contract_address(),current_balance +amount);
            // Then write the amount for the caller.
            self.balances.write(caller,amount);
            // Emit the staking event.
            self.emit(Staking{sender:caller, 
                              amount:amount
                            });
        }

        fn execute(ref self: ContractState) {
           self.not_completed();
           assert!(self.time_left() == 0, "Staking period is not over yet");
           let total_balance = self.balances.read(get_contract_address());
           if total_balance >= self.threshold(){
                self.complete_transfer(total_balance);
           }else{
            self.open_for_withdraw.write(true);
           }
        }
        /// Withdraw function allows users to withdraw their staked tokens after the deadline has passed.
        fn withdraw(ref self:ContractState){
            assert!(self.open_for_withdraw(), "Withdrawals are not open yet");
            let caller = get_caller_address();
            let amount = self.balances.read(caller);
            assert!(amount > 0, "No balance to withdraw");
            self.balances.write(caller,0_u256); // Reset caller's balance to zero
            let token_dispatcher = self.token_dispatcher();
            let success = token_dispatcher.transfer(caller,amount);
            assert!(success, "Transfer failed");
        }
        /// This function returns the balance of a specific account.
        fn balances(self: @ContractState, account:ContractAddress) ->u256{
            self.balances.read(account)
        }
        // This function returns the total balance of the contract, which is the sum of all staked amounts.
        fn total_balance(self:@ContractState) -> u256{
            self.balances.read(get_contract_address())
        }
        /// This function returns the deadline for staking, which is the time when the staking period ends.
        fn deadline(self:@ContractState) ->u64{
            self.deadline.read()
        }

        fn threshold(self:@ContractState) -> u256{
            THRESHOLD
        }

        fn token_dispatcher(self: @ContractState) -> IERC20Dispatcher {
            self.token_dispatcher.read()
        }

        fn open_for_withdraw(self:@ContractState) -> bool{
            self.open_for_withdraw.read()
        }

        fn example_external_contract(self: @ContractState) -> ContractAddress {
            self.external_contract_address.read()
        }

        fn completed(self: @ContractState) -> bool {
            let external_contract=self.example_external_contract();
            let external_contract_dispatcher = IExampleExternalContractDispatcher{contract_address: external_contract};
            external_contract_dispatcher.is_completed()
        }
      
        fn time_left(self: @ContractState) -> u64 {
            let current_time = get_block_timestamp();
            let deadline = self.deadline.read();
            if current_time < deadline {
                deadline - current_time
            } else {
                0_u64
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // ToDo Checkpoint 2: Implement your complete_transfer function here
        // This function should be called after the deadline has passed and the staked amount is
        // greater than or equal to the threshold You have to call/use this function in the above
        // `execute` function This function should call the `complete` function of the external
        // contract and transfer the staked amount to the external contract
        fn complete_transfer(
            ref self: ContractState, amount: u256,
        ) { 
            let external_contract = self.example_external_contract();
            let external_contract_dispatcher = IExampleExternalContractDispatcher{contract_address:external_contract};
            external_contract_dispatcher.complete();
            let token_dispatcher = self.token_dispatcher();
            let success = token_dispatcher.transfer(external_contract, amount);
            assert!(success, "Transfer to external contract failed");
            self.open_for_withdraw.write(false);
        }
        // ToDo Checkpoint 3: Implement your not_completed function here
        fn not_completed(ref self: ContractState) {
            let external_contract = self.example_external_contract();
            let external_contract_dispatcher = IExampleExternalContractDispatcher{contract_address:external_contract};
            assert!(
                !external_contract_dispatcher.is_completed(),
                "External contract has already completed"
            );
        }
    }


}


///🔐 Internal vs External in Smart Contracts
///In most smart contract frameworks (like Cairo, ink!, or Substrate):

//Concept	    Internal Trait (#[generate_trait])	        External Interface (#[external], #[endpoint], etc.)
//Visibility	        Internal only	                                       Public-facing
//Call source	  Can only be called by the contract	        Can be called by users or other contracts
//Purpose	          Code reuse, modularity	                      Exposing API for interaction

//🔧 1. Use #[generate_trait] for internal logic
//Purpose: Encapsulation, modularity, reuse within the contract.
//These functions are not accessible externally (i.e., cannot be called by users or other contracts).

