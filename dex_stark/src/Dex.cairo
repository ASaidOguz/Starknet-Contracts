use starknet::ContractAddress;

#[starknet::interface]
pub trait IDex<TContractState> {
    /// Initializes the DEX with the specified amounts of tokens and STRK.
    ///
    /// Args:
    ///     self: The contract state.
    ///     tokens: The amount of tokens to initialize the DEX with.
    ///     strk: The amount of STRK to initialize the DEX with.
    ///
    /// Returns:
    ///     (u256, u256): The amounts of tokens and STRK initialized.
    fn init(ref self: TContractState, tokens: u256, strk: u256) -> (u256, u256);

    /// Calculates the price based on the input amount and reserves.
    ///
    /// Args:
    ///     self: The contract state.
    ///     x_input: The input amount of tokens.
    ///     x_reserves: The reserve amount of tokens.
    ///     y_reserves: The reserve amount of STRK.
    ///
    /// Returns:
    ///     u256: The output amount of STRK.
    fn price(self: @TContractState, x_input: u256, x_reserves: u256, y_reserves: u256) -> u256;

    /// Returns the liquidity for the specified address.
    ///
    /// Args:
    ///     self: The contract state.
    ///     lp_address: The address of the liquidity provider.
    ///
    /// Returns:
    ///     u256: The liquidity amount.
    fn get_liquidity(self: @TContractState, lp_address: ContractAddress) -> u256;

    /// Returns the total liquidity in the DEX.
    ///
    /// Args:
    ///     self: The contract state.
    ///
    /// Returns:
    ///     u256: The total liquidity amount.
    fn get_total_liquidity(self: @TContractState) -> u256;

    /// Swaps STRK for tokens.
    ///
    /// Args:
    ///     self: The contract state.
    ///     strk_input: The amount of STRK to swap.
    ///
    /// Returns:
    ///     u256: The amount of tokens received.
    fn strk_to_token(ref self: TContractState, strk_input: u256) -> u256;

    /// Swaps tokens for STRK.
    ///
    /// Args:
    ///     self: The contract state.
    ///     token_input: The amount of tokens to swap.
    ///
    /// Returns:
    ///     u256: The amount of STRK received.
    fn token_to_strk(ref self: TContractState, token_input: u256) -> u256;

    /// Deposits STRK and tokens into the liquidity pool.
    ///
    /// Args:
    ///     self: The contract state.
    ///     strk_amount: The amount of STRK to deposit.
    ///     token_amount: The amount of tokens to deposit.
    /// Returns:
    ///     u256: The amount of liquidity minted.
    fn deposit(ref self: TContractState, strk_amount: u256,token_amount:u256) -> u256;

    /// get deposit token amount when deposit strk_amount STRK.
    ///
    /// Args:
    ///     self: The contract state.
    ///     strk_amount: The amount of STRK to deposit.
    ///
    /// Returns:
    ///     u256: The token amount of the deposit.
    fn get_deposit_token_amount(self: @TContractState, strk_amount: u256) -> u256;

    /// Withdraws STRK and tokens from the liquidity pool.
    ///
    /// Args:
    ///     self: The contract state.
    ///     amount: The amount of liquidity to withdraw.
    ///
    /// Returns:
    ///     (u256, u256): The amounts of STRK and tokens withdrawn.
    fn withdraw(ref self: TContractState, amount: u256) -> (u256, u256);
}

#[starknet::contract]
mod Dex {
    use core::num::traits::{CheckedMul,CheckedSub,CheckedAdd};
    use dex_stark::Balloons::{IBalloonsDispatcher, IBalloonsDispatcherTrait};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use super::IDex;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    // we have internal k constant of the 2 token invariant so why we need this ????
    /// const TokensPerStrk: u256 = 100;

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        initialized:bool,
        strk_token: IERC20Dispatcher,
        token: IBalloonsDispatcher,
        total_liquidity: u256,
        liquidity: Map<ContractAddress, u256>,
    }

    
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        StrkToTokenSwap:StrkToTokenSwap,
        TokenToStrkSwap:TokenToStrkSwap,
        LiquidityProvided: LiquidityProvided,
        LiquidityRemoved: LiquidityRemoved,
    }

    /// Event emitted when a STRK to token swap occurs.
    #[derive(Drop, starknet::Event)]
    struct StrkToTokenSwap {
        swapper: ContractAddress,
        token_output: u256,
        strk_input: u256,
    }

    /// Event emitted when a token to STRK swap occurs.
    #[derive(Drop, starknet::Event)]
    struct TokenToStrkSwap {
        swapper: ContractAddress,
        tokens_input: u256,
        strk_output: u256,
    }

    /// Event emitted when liquidity is provided to the DEX.
    #[derive(Drop, starknet::Event)]
    struct LiquidityProvided {
        liquidity_provider: ContractAddress,
        liquidity_minted: u256,
        strk_input: u256,
        tokens_input: u256,
    }

    /// Event emitted when liquidity is removed from the DEX.
    #[derive(Drop, starknet::Event)]
    struct LiquidityRemoved {
        liquidity_remover: ContractAddress,
        liquidity_withdrawn: u256,
        tokens_output: u256,
        strk_output: u256,
    }

    /// Constructor for the Dex contract.
    ///
    /// Initializes the contract with the specified STRK and token addresses.
    ///
    /// Args:
    ///     self: The contract state.
    ///     strk_token_address: The address of the STRK token contract.
    ///     token_address: The address of the token contract.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        strk_token_address: ContractAddress,
        token_address: ContractAddress,
        owner:ContractAddress
    ) {

        //self.ownnable.initializer(get_caller_address()); -->❌✖️🅧🇽❎❌🗙

        // contract is deployed by universal deployer, so we cant use get_contract_address() inside contructor 
        // it will return universal deployer address as owner -> updated correclty below. 
        self.ownable.initializer(owner); // ✅ explicitly set owner
        self.strk_token.write(IERC20Dispatcher { contract_address: strk_token_address });
        self.token.write(IBalloonsDispatcher { contract_address: token_address });
    }

    #[abi(embed_v0)]
    impl DexImpl of IDex<ContractState> {
        /// Initializes the DEX with the specified amounts of tokens and STRK.
        ///
        /// Args:
        ///     self: The contract state.
        ///     tokens: The amount of tokens to initialize the DEX with.
        ///     strk: The amount of STRK to initialize the DEX with.
        ///
        /// Returns:
        ///     (u256, u256): The amounts of tokens and STRK initialized.
        fn init(ref self: ContractState, tokens: u256, strk: u256) -> (u256, u256) {
            // validate owner,
            self.ownable.assert_only_owner();
            assert(!self.initialized.read(), 'Already initialized');
            let caller = get_caller_address();
           
            let success_token = self.token.read().transfer_from(caller,get_contract_address(),tokens);
            assert(success_token, 'Token transfer failed');
            let success_strk = self.strk_token.read().transfer_from(caller,get_contract_address(),strk);
            assert(success_strk, 'STRK transfer failed');
            // Calculate safely sqrt of the product of tokens and strk
            // to avoid overflow.
            let liqudity_provided = self._calculate_sqrt(self._checked_mul(tokens,strk));
            // Update the liquidity mapping and total liquidity.
            self.liquidity.write(caller, liqudity_provided);
            self.total_liquidity.write(liqudity_provided);
            // Emit the LiquidityProvided event.
            self.emit(LiquidityProvided {
                liquidity_provider: caller,
                liquidity_minted: liqudity_provided,
                strk_input: strk,
                tokens_input: tokens,
            });
            // Mark the contract as initialized.
            self.initialized.write(true);
            (tokens, strk)
        }

        // Todo Checkpoint 3:  Implement your function price here.
        /// Calculates the price based on the input amount and reserves.
        ///
        /// Args:
        ///     self: The contract state.
        ///     x_input: The input amount of tokens.
        ///     x_reserves: The reserve amount of tokens.
        ///     y_reserves: The reserve amount of STRK.
        ///
        /// Returns:
        ///     u256: The output amount of STRK.
        fn price(self: @ContractState, x_input: u256, x_reserves: u256, y_reserves: u256) -> u256 {
       // Constants for the 0.3% fee (Uniswap V2 style)
        // These are hardcoded as they represent the protocol's fee structure.
        let FEE_NUMERATOR: u256 = 997;
        let FEE_DENOMINATOR: u256 = 1000;

        // Calculate the numerator for the amount of Y tokens received:
        // numerator = x_input * y_reserves * FEE_NUMERATOR
        let numerator = self._checked_mul(self._checked_mul(x_input, y_reserves), FEE_NUMERATOR);

        // Calculate the first term of the denominator: x_reserves * FEE_DENOMINATOR
        let term1_denominator = self._checked_mul(x_reserves, FEE_DENOMINATOR);

        // Calculate the second term of the denominator: x_input * FEE_NUMERATOR
        let term2_denominator = self._checked_mul(x_input, FEE_NUMERATOR);

        // Calculate the full denominator: term1_denominator + term2_denominator
        let denominator = self._checked_add(term1_denominator, term2_denominator);

        // Perform the final division to get y_out.
        // Integer division here naturally truncates, which matches the expected behavior
        // for this type of calculation in EVM-like environments.
        let y_out = self._checked_div(numerator, denominator);

        y_out
        }

        // Todo Checkpoint 5:  Implement your function get_liquidity here.
        /// Returns the liquidity for the specified address.
        ///
        /// Args:
        ///     self: The contract state.
        ///     lp_address: The address of the liquidity provider.
        ///
        /// Returns:
        ///     u256: The liquidity amount.
        fn get_liquidity(self: @ContractState, lp_address: ContractAddress) -> u256 {
            self.liquidity.read(lp_address)   
        }

        // Todo Checkpoint 5:  Implement your function get_total_liquidity here.
        /// Returns the total liquidity in the DEX.
        ///
        /// Args:
        ///     self: The contract state.
        ///
        /// Returns:
        ///     u256: The total liquidity amount.
        fn get_total_liquidity(self: @ContractState) -> u256 {
            self.total_liquidity.read()
        }

        // Todo Checkpoint 4:  Implement your function strk_to_token here.
        /// Swaps STRK for tokens.
        ///
        /// Args:
        ///     self: The contract state.
        ///     strk_input: The amount of STRK to swap.
        ///
        /// Returns:
        ///     u256: The amount of tokens received.
        fn strk_to_token(ref self: ContractState, strk_input: u256) -> u256 {
            assert(strk_input !=0_u256,'Cannot swap 0 strk');
            // first get the reserves of tokens and STRK
            let x_reserves = self.strk_token.read().balance_of(get_contract_address());
            let y_reserves=  self.token.read().balance_of(get_contract_address());
            // calculate the output tokens using the price function
            let token_output = self.price(strk_input,x_reserves,y_reserves);
            // transfer the tokens to the caller
            let caller = get_caller_address();
            let success_stark = self.strk_token.read().transfer_from(caller,get_contract_address(),strk_input);
            assert(success_stark, 'STRK transfer failed');
            let success_token = self.token.read().transfer(caller, token_output);
            assert(success_token, 'Token transfer failed');
            // Emit the StrkToTokenSwap event.
            self.emit(StrkToTokenSwap {
                swapper: caller,
                token_output: token_output,
                strk_input: strk_input,
            });
            token_output
        }

        // Todo Checkpoint 4:  Implement your function token_to_strk here.
        /// Swaps tokens for STRK.
        ///
        /// Args:
        ///     self: The contract state.
        ///     token_input: The amount of tokens to swap.
        ///
        /// Returns:
        ///     u256: The amount of STRK received.
        fn token_to_strk(ref self: ContractState, token_input: u256) -> u256 {
            assert(token_input !=0_u256,'Cannot swap 0 tokens');
                 // first get the reserves of tokens and STRK
            let x_reserves = self.token.read().balance_of(get_contract_address());
            let y_reserves= self.strk_token.read().balance_of(get_contract_address());
              // calculate the output tokens using the price function
            let strk_output = self.price(token_input,x_reserves,y_reserves);
              // transfer the tokens to the caller
            let caller = get_caller_address();
            let success_token = self.token.read().transfer_from(caller,get_contract_address(),token_input);
            assert(success_token, 'Token transfer failed');
            let success_strk = self.strk_token.read().transfer(caller, strk_output);
            assert(success_strk, 'STRK transfer failed');
            // Emit the TokenToStrkSwap event.
            self.emit(TokenToStrkSwap {
                swapper: caller,
                tokens_input: token_input,
                strk_output: strk_output,
            });
            strk_output
        }

        // Todo Checkpoint 5:  Implement your function deposit here.
        /// Deposits STRK and tokens into the liquidity pool.
        ///
        /// Args:
        ///     self: The contract state.
        ///     strk_amount: The amount of STRK to deposit.
        ///     token_amount: The amount of tokens to deposit.
        /// Returns:
        ///     u256: The amount of liquidity minted.
        /// 
        ///  Function argument incorrect --> need to add token_amount as well.
        /// They would change the STRK/token ratio, which would distort prices.
        /// It would break the constant product invariant x * y = k.
        /// It's not a real liquidity addition — it's closer to a swap without removing output tokens.
        fn deposit(ref self: ContractState, strk_amount: u256,token_amount:u256) -> u256 {
                assert(strk_amount != 0_u256||token_amount!=0_u256, 'Deposit must greater than 0');
                let caller = get_caller_address();
                let get_token_amount = self.get_deposit_token_amount(strk_amount);
                assert(token_amount == get_token_amount, 'Pair invalid');

                let y_reserves = self.strk_token.read().balance_of(get_contract_address());

                let total_liquidity = self.total_liquidity.read();


                    let liquidity_minted = if total_liquidity == 0_u256 {
                        self._calculate_sqrt(self._checked_mul(token_amount, strk_amount))
                    } else {
                        self._checked_mul(strk_amount, total_liquidity) / y_reserves
                    };
                    let old_user_liquidity = self.liquidity.read(caller);
                    let new_user_liquidity = self._checked_add(old_user_liquidity, liquidity_minted);
                    self.liquidity.write(caller, new_user_liquidity);

                    let new_total_liquidity = self._checked_add(total_liquidity, liquidity_minted);
                    self.total_liquidity.write(new_total_liquidity);
                    // Transfer funds in
                let success_token = self.token.read().transfer_from(caller, get_contract_address(), token_amount);
                assert(success_token, 'Token transfer failed');
                let success_strk = self.strk_token.read().transfer_from(caller, get_contract_address(), strk_amount);
                assert(success_strk, 'STRK transfer failed');

                        self.emit(LiquidityProvided {
                                    liquidity_provider: caller,
                                    liquidity_minted,
                                    strk_input: strk_amount,
                                    tokens_input: token_amount,
                                });

                    liquidity_minted
        }

        // Todo Checkpoint 5:  Implement your function get_deposit_token_amount here.
        /// get deposit token amount when deposit strk_amount STRK.
        ///
        /// Args:
        ///     self: The contract state.
        ///     strk_amount: The amount of STRK to deposit.
        ///
        /// Returns:
        ///     u256: The token_amount of deposit.
        fn get_deposit_token_amount(self: @ContractState, strk_amount: u256) -> u256 {
                  // first get the reserves of tokens and STRK
            let x_reserves = self.token.read().balance_of(get_contract_address());
            let y_reserves= self.strk_token.read().balance_of(get_contract_address());
            // calculate the output tokens using the price function
            let token_output = self.price(strk_amount,x_reserves,y_reserves);
            token_output
        }

        // Todo Checkpoint 5:  Implement your function withdraw here.
        /// Withdraws STRK and tokens from the liquidity pool.
        ///
        /// Args:
        ///     self: The contract state.
        ///     amount: The amount of liquidity to withdraw.
        ///
        /// Returns:
        ///     (u256, u256): The amounts of STRK and tokens withdrawn.
        fn withdraw(ref self: ContractState, amount: u256) -> (u256, u256) {
            let caller = get_caller_address();
            assert(amount <= self.get_liquidity(caller), 'Insufficient liquidity');
            let total_liquidity = self.get_total_liquidity();
            let strk_reserves = self.strk_token.read().balance_of(get_contract_address());
            let token_reserves = self.token.read().balance_of(get_contract_address());
            // Calculate the amount of STRK and tokens to withdraw
            let strk_output = self._checked_div(self._checked_mul(amount,strk_reserves),total_liquidity);//->In case of 0 return we do mul first
            let token_output = self._checked_mul(amount,token_reserves)/total_liquidity;

            // Update the liquidity mapping and total liquidity.
            let old_user_liquidity = self.liquidity.read(caller);
            let new_user_liquidity = self._checked_sub(old_user_liquidity, amount);
            self.liquidity.write(caller, new_user_liquidity);
            let new_total_liquidity = self._checked_sub(total_liquidity, amount);
            self.total_liquidity.write(new_total_liquidity);
            // Transfer the STRK and tokens to the caller
            let success_strk = self.strk_token.read().transfer(caller, strk_output);
            assert(success_strk, 'STRK transfer failed');
            let success_token = self.token.read().transfer(caller, token_output);
            assert(success_token, 'Token transfer failed');
            // Emit the LiquidityRemoved event.
            self.emit(LiquidityRemoved {
                liquidity_remover: caller,
                liquidity_withdrawn: amount,
                tokens_output: token_output,
                strk_output: strk_output,
            });
            (strk_output, token_output)
        }
    }

    #[generate_trait]
     pub impl InternalImpl of InternalTrait {
        // need to implement better sqrt function for optimized calculation.Might be incorrect!!!!!
       fn _calculate_sqrt(self:@ContractState,value:u256) -> u256 {
            let one = 1_u256;
            if value == 0_u256 {
            return 0_u256;
        }

        let mut z = value;
        let mut x = value / 2_u256 + one;

        while x < z {
            z = x;
            x = (value / x + x) / 2_u256;
        }

            z 
        }

        fn _checked_mul(self: @ContractState, a: u256, b: u256) -> u256 {
            match a.checked_mul(b) {
                Some(result) => result,
                None => {      // Handle overflow case
                    assert(false, 'Multiplication Overflow!!');
                    0 // This line will never be reached, but is needed to satisfy the return type,
                }
            }
        }

        fn _checked_add(self: @ContractState, a: u256, b: u256) -> u256{
            match a.checked_add(b){
                Some(result) => result,
                 None => {      // Handle overflow case
                    assert(false, 'Add Overflow!!');
                    0 // This line will never be reached, but is needed to satisfy the return type,
                }
            }
        }

        fn _checked_sub(self: @ContractState, a: u256, b: u256) -> u256{
            match a.checked_sub(b){
                Some(result) => result,
                 None => {      // Handle overflow case
                    assert(false, 'Sub Overflow!!');
                    0 // This line will never be reached, but is needed to satisfy the return type,
                }
            }
        }

        fn _checked_div(self: @ContractState,a: u256, b: u256) -> u256 {
             assert(b != 0, 'math div zero');
             a / b
        }
    }
}