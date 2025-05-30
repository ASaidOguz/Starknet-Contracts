use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

#[starknet::interface]
pub trait IDiceGame<T> {
    fn roll_dice(ref self: T, amount: u256);
    fn last_dice_value(self: @T) -> u256;
    fn nonce(self: @T) -> u256;
    fn prize(self: @T) -> u256;
    fn strk_token_dispatcher(self: @T) -> IERC20Dispatcher;
}

#[starknet::contract]
pub mod DiceGame {
    use core::keccak::keccak_u256s_le_inputs;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_block_number, get_caller_address, get_contract_address};
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Roll: Roll,
        Winner: Winner,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Roll {
        #[key]
        pub player: ContractAddress,
        pub amount: u256,
        pub roll: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Winner {
        pub winner: ContractAddress,
        pub amount: u256,
    }

    #[storage]
    struct Storage {
        strk_token: IERC20Dispatcher,
        nonce: u256,
        prize: u256,
        last_dice_value: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, strk_token_address: ContractAddress) {
        self.strk_token.write(IERC20Dispatcher { contract_address: strk_token_address });
        self._reset_prize();
    }


    #[abi(embed_v0)]
    impl DiceGameImpl of super::IDiceGame<ContractState> {
        fn roll_dice(ref self: ContractState, amount: u256) {
            // >= 0.002 STRK
            assert(amount >= 2000000000000000, 'Not enough STRK');
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            // call approve on UI
            self.strk_token.read().transfer_from(caller, this_contract, amount);

            let prev_block: u256 = get_block_number().into() - 1;
            let array = array![prev_block, self.nonce.read()];
            let roll = keccak_u256s_le_inputs(array.span()) % 16;
            self.last_dice_value.write(roll);
            self.nonce.write(self.nonce.read() + 1);
            let new_prize = self.prize.read() + amount * 4 / 10;
            self.prize.write(new_prize);

            self.emit(Roll { player: caller, amount, roll });

            if (roll > 5) {
                return;
            }

            let contract_balance = self.strk_token.read().balance_of(this_contract);
            let prize = self.prize.read();
            assert(contract_balance >= prize, 'Not enough balance');
            self.strk_token.read().transfer(caller, prize);

            self._reset_prize();
            self.emit(Winner { winner: caller, amount: prize });
        }
        fn last_dice_value(self: @ContractState) -> u256 {
            self.last_dice_value.read()
        }
        fn nonce(self: @ContractState) -> u256 {
            self.nonce.read()
        }

        fn prize(self: @ContractState) -> u256 {
            self.prize.read()
        }
        fn strk_token_dispatcher(self: @ContractState) -> IERC20Dispatcher {
            self.strk_token.read()
        }
    }

    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        fn _reset_prize(ref self: ContractState) {
            let contract_balance = self.strk_token.read().balance_of(get_contract_address());
            self.prize.write(contract_balance / 10);
        }
    }
}



// Let’s say you hash u256 = 1.

// In Little Endian:
// 0x01 00 00 00 ... 00 -> 32 byte array (left to right)

// In Big Endian:
// 0x00 00 00 00 ... 01 -> 32 byte array (right to left)

// These are totally different byte arrays, and therefore Keccak will produce completely different hash values.

// Yes, reversing bytes would devastate numerical meaning.
// But for Keccak, bytes are bytes — the number they represent is meaningless.
// Always be intentional about endianness when feeding numbers to hash functions.

