use starknet::ContractAddress;
#[starknet::interface]
pub trait IVendor<T> {
    fn buy_tokens(ref self: T, token_amount: u256);
    fn withdraw(ref self: T);
    fn sell_tokens(ref self: T, token_amount: u256);
    fn tokens_per_strk(self: @T) -> u256;
    fn protocol_token(self: @T) -> ContractAddress;
    fn strk_token(self: @T) -> ContractAddress;
}

#[starknet::contract]
mod Vendor{
    use core::num::traits::CheckedMul;
    use token_vendor::ProtocolToken::{IProtocolTokenDispatcher,IProtocolTokenDispatcherTrait};
    use core::traits::TryInto;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    use starknet::{get_caller_address, get_contract_address};
    use super::{ContractAddress, IVendor};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    const TOKENSPERSTARK : u256 = 100;

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        strk_token: IERC20Dispatcher,
        protocol_token: IProtocolTokenDispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        BuyTokens: BuyTokens,
        SellTokens: SellTokens,
        withdraw: Withdraw,
    }

    #[derive(Drop, starknet::Event)]
    struct BuyTokens {
        buyer: ContractAddress,
        strk_amount: u256,
        tokens_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct SellTokens {
        seller:ContractAddress,
        strk_amount:u256,
        tokens_amount:u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdraw{
        owner:ContractAddress,
        withdraw_amount:u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        strk_token_address: ContractAddress,
        protocol_token_address: ContractAddress,
        owner:ContractAddress
    ) {
        self.strk_token.write(IERC20Dispatcher { contract_address: strk_token_address });
        self.protocol_token.write(IProtocolTokenDispatcher { contract_address: protocol_token_address });
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl IVendorImpl of IVendor<ContractState>{
        fn buy_tokens(ref self:ContractState, token_amount:u256) {
           let caller = get_caller_address();
           let strk_amount= self._calculate_strk_token(token_amount);
           let strk_success = self.strk_token.read().transfer_from(caller, get_contract_address(), strk_amount);
              assert(strk_success, 'Transfer stark failed');
              assert(self._check_for_token(token_amount),'Not enough protocol tokens');
           let token_success = self.protocol_token.read().transfer(caller,token_amount);
              assert(token_success, 'Transfer protocol failed');
            self.emit(BuyTokens{
                buyer:caller,
                strk_amount:strk_amount,
                tokens_amount:token_amount,
            });   
        }

        fn withdraw(ref self: ContractState){
           self.ownable.assert_only_owner();
           let caller = get_caller_address();
           let withdraw_amount = self.strk_token.read().balance_of(get_contract_address());
           let success = self.strk_token.read().transfer(caller, withdraw_amount);
            assert(success,'Transfer STRK failed!');
            self.emit(Withdraw{
                owner: caller,
                withdraw_amount: withdraw_amount,
            });
        }
        
        fn sell_tokens(ref self: ContractState, token_amount: u256){
            let caller = get_caller_address();
            let success = self.protocol_token.read().transfer_from(caller, get_contract_address(),token_amount);
              assert(success,'Transfer PRTCL failed!');
            let strk_amount = self._calculate_strk_token(token_amount);
              assert(self._check_for_strk(strk_amount), 'Not enough STRK tokens');
            let strk_success = self.strk_token.read().transfer(caller, strk_amount);
              assert(strk_success, 'Transfer STRK failed!');
            self.emit(SellTokens{
                seller: caller,
                strk_amount: strk_amount,
                tokens_amount: token_amount,
            });
        }

        fn tokens_per_strk(self: @ContractState) -> u256{
            TOKENSPERSTARK
        }
        fn protocol_token(self: @ContractState) -> ContractAddress{
            self.protocol_token.read().contract_address
        }

        fn strk_token(self: @ContractState) -> ContractAddress{
            self.strk_token.read().contract_address
        }
    }

    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
       fn _calculate_protocol_token(self:@ContractState,amount:u256) -> u256 {
           let tokens_per_strk= self.tokens_per_strk();
            // Overflow check for multiplication  
            match amount.checked_mul(tokens_per_strk){
                Some(result) => result,
                None => {
                    // Handle overflow case
                    assert(false, 'Overflow!!');
                    0 // This line will never be reached, but is needed to satisfy the return type
                }
            }
           
        }
       fn _calculate_strk_token(self:@ContractState,amount:u256) -> u256{
           // Manual division check (division doesn't overflow, but can divide by zero) -> Even if its constant its good
           // practice to check.
          let tokens_per_strk = self.tokens_per_strk();
               assert(tokens_per_strk != 0, 'Division by zero');
           amount/ tokens_per_strk
       }
       // What about the tx fee from contract -> user in case ask for max amount of tokens?
       fn _check_for_token(self:@ContractState, amount:u256)->bool{
            self.protocol_token.read().balance_of(get_contract_address())>= amount
       }

       fn _check_for_strk(self:@ContractState, amount:u256) -> bool{
            self.strk_token.read().balance_of(get_contract_address()) >= amount
       }
    }
}
    


// Use Case	               Use try_into()?	Use overflowing_*()?
// Convert u256 → u64 safely	✅ Yes	    ❌ Not needed
// Check for overflow in math	❌ No	    ✅ Yes
// Multiply u256 * u256 safely	❌ No	    ✅ Yes
// Convert u128 → u64 safely	✅ Yes	    ❌ Not needed