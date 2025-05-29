use staking_stark::Staking::{IStakingDispatcher, IStakingDispatcherTrait};
use staking_stark::ExampleExternalContract::{
    IExampleExternalContractDispatcher, IExampleExternalContractDispatcherTrait,
};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, cheat_caller_address, start_cheat_block_timestamp_global};
use starknet::{ContractAddress, get_block_timestamp};


const RECIPIENT: ContractAddress = 'RECIPIENT'.try_into().unwrap();

use core::traits::Into;
use core::option::OptionTrait;


// Fixed point precision - using 18 decimals (like Ethereum's wei)


// HELPER-SETUP FUNCTIONS----------------------------------------------------------------->

// Main parsing function
fn parse_decimal_to_u256(decimal_str: ByteArray) -> u256 {
    let PRECISION: u256 = 1000000000000000000_u256; // 10^18
    let mut integer_part: u256 = 0;
    let mut fractional_part: u256 = 0;
    let mut found_decimal = false;
    let mut decimal_places: u32 = 0;
    
    let len = decimal_str.len();
    let mut i: u32 = 0;
    
    while i != len {
        let char = decimal_str.at(i).unwrap();
        let dot_u8 = 46_u8;    // ASCII value for '.'
        let zero_u8 = 48_u8;  // ASCII value for '0'
        let nine_u8 = 57_u8;  // ASCII value for '9'

        if char == dot_u8 {
            found_decimal = true;
        } else if char >= zero_u8 && char <= nine_u8 {
            let digit: u256 = (char - zero_u8).into();

            if !found_decimal {
                // Building integer part
                integer_part = integer_part * 10 + digit;
            } else if decimal_places < 18 { // Limit to 18 decimal places
                // Building fractional part
                fractional_part = fractional_part * 10 + digit;
                decimal_places += 1;
            }
        }
        
        i += 1;
    }
    
    // Convert to fixed-point representation
    let integer_scaled = integer_part * PRECISION;
    
    // Scale fractional part to 18 decimal places
    let mut fractional_scaled = fractional_part;
    let mut remaining_places = 18 - decimal_places;
    
    while remaining_places != 0 {
        fractional_scaled *= 10;
        remaining_places -= 1;
    }
    
    integer_scaled + fractional_scaled
}

// Deploys the mock stark token.
fn deploy_mock_stark() -> ContractAddress {
    let INITIAL_SUPPLY: u256 = 100_000_000_000_000_000_000; // 100_STRK_IN_FRI
    let mut calldata = array![];
    calldata.append_serde(INITIAL_SUPPLY);
    calldata.append_serde(RECIPIENT);
    declare_and_deploy("MockSTRKToken",calldata)
}
// Deploys the ExampleExternalContract.
fn deploy_example_external_contract() -> ContractAddress{
    let mut calldata = array![];
    declare_and_deploy("ExampleExternalContract",calldata)   
}
// Deploys the Staking contract.
fn deploy_staking() -> IStakingDispatcher{
    let mut calldata = array![];
    // need address of mock token and example external contract so lets deploy and extract their addresses
    let mock_stark_address = deploy_mock_stark();
    let example_external_contract_address = deploy_example_external_contract();
    calldata.append_serde(mock_stark_address);
    calldata.append_serde(example_external_contract_address);
    IStakingDispatcher{
        contract_address: declare_and_deploy("Staking", calldata),
    }
}
// HELPER-SETUP FUNCTIONS-----------------------------------------------------------------<


// Let there be testings...

#[test]
fn test_decimal_conversion()  {
    // Simply pass the string directly - Cairo handles the conversion
    let arg1:ByteArray = "0.001";
    let result1 = parse_decimal_to_u256(arg1.clone());
    assert(result1==1_000_000_000_000_000,'Wrong conversion result1!');
    
    let arg2:ByteArray = "123.456";
    let result2 = parse_decimal_to_u256(arg2.clone());
    assert(result2==123_456_000_000_000_000_000,'Wrong conversion result2!');

    let arg3:ByteArray = "1000.000000000000000001";
    let result3 = parse_decimal_to_u256(arg3.clone());
    assert(result3==1_000_000_000_000_000_000_001,'Wrong conversion result3!');

    let arg4:ByteArray = "0.000000000000000001";
    let result4 = parse_decimal_to_u256(arg4.clone());    
    assert(result4==1,'Wrong conversion result4!');
    // For "0.001":
    // integer_part = 0
    // fractional_part = 1 (from the digit '1')
    // decimal_places = 3
    // 
    // integer_scaled = 0 * 10^18 = 0
    // fractional_scaled = 1 * 10^(18-3) = 1 * 10^15 = 1000000000000000
    // result = 0 + 1000000000000000 = 1000000000000000
    println!("Result of conversion 1: {}->{}", arg1.clone(),result1);
    println!("Result of conversion 2: {}->{}", arg2.clone(),result2);
    println!("Result of conversion 3: {}->{}", arg3.clone(),result3);
    println!("Result of conversion 4: {}->{}", arg4.clone(),result4);
}

struct TestEnv {
    staking: IStakingDispatcher,
    token: IERC20Dispatcher,
    tester: ContractAddress,
    amount_staked: u256,
}

fn setup_stake(amount_to_stake:u256) -> TestEnv {
    let staking = deploy_staking();
    let token = staking.token_dispatcher();
    let tester = RECIPIENT;
    

    // Approve
    cheat_caller_address(token.contract_address, tester, CheatSpan::TargetCalls(1));
    token.approve(staking.contract_address, amount_to_stake);

    assert(token.allowance(tester, staking.contract_address) == amount_to_stake, 'Allowance not set');

    // Stake
    cheat_caller_address(staking.contract_address, tester, CheatSpan::TargetCalls(1));
    staking.stake(amount_to_stake);

    TestEnv {
        staking,
        token,
        tester,
        amount_staked: amount_to_stake,
    }
}
#[test]
#[should_panic(expected: "Withdrawals are not open yet")]
fn test_withdraw_before_open(){
let tets_env = setup_stake(parse_decimal_to_u256("0.5")); // 0.5 STRK
    // Try to withdraw before the contract is open for withdraw
    cheat_caller_address(tets_env.staking.contract_address, tets_env.tester, CheatSpan::TargetCalls(1));
    tets_env.staking.withdraw();
}

#[test]
fn test_getters(){
let tets_env = setup_stake(parse_decimal_to_u256("0.5")); // 0.5 STRK
    // Test the getters
    let balance = tets_env.staking.balances(tets_env.tester);
    assert(balance == tets_env.amount_staked, 'Balance not matched');
    
    let total_balance = tets_env.staking.total_balance();
    assert(total_balance == tets_env.amount_staked, 'Total balance not matched');
    
    let deadline = tets_env.staking.deadline();
    assert(deadline > 0, 'Deadline should be set');
    
    let threshold = tets_env.staking.threshold();
    assert(threshold > 0, 'Threshold should be set');
    
    let open_for_withdraw = tets_env.staking.open_for_withdraw();
    assert(!open_for_withdraw, 'not open for withdraw yet');
    
    let external_contract = tets_env.staking.example_external_contract();
    
    assert(external_contract !=0.try_into().unwrap(), 'External address should be set');
    
    let completed = tets_env.staking.completed();
    assert(!completed, 'external con. not completed yet');

    let time_left = tets_env.staking.time_left();
    assert(time_left==60, 'Time left should be positive');
}

#[test]
fn test_staking_functionality(){
    let amount_to_stake: u256 = parse_decimal_to_u256("0.1") ; // 0.1 STRK
    let setup = setup_stake(amount_to_stake);
    let expected_balance = setup.amount_staked;
    let new_balance = setup.staking.balances(setup.tester);
    assert(new_balance == expected_balance, 'Balance not matched');
}
// Contract logic starts from staking to span 2 different path ->
// 1. If enough is staked and time has passed, the external contract should be completed
// 2. If not enough is staked and time has passed, the external contract should not be complete
// and the Staker contract should be open for withdrawal
#[test]
fn test_execute_functionality(){
    let amount_to_stake: u256 = parse_decimal_to_u256("1.0"); // 1 STRK
    let setup = setup_stake(amount_to_stake);
    // First lets check if th external contract is not completed.
    let external_contract = setup.staking.example_external_contract();
    assert(!IExampleExternalContractDispatcher{contract_address:external_contract}.is_completed(), 'ex-contract not completed yet');

    // Now lets cheat time and execute the contract.
    start_cheat_block_timestamp_global(get_block_timestamp() + 60); // cheat time by 60 seconds
    // anyone can call execute
    setup.staking.execute();
    // Now lets check if the external contract is completed.
    assert(IExampleExternalContractDispatcher{contract_address:external_contract}.is_completed(), 'ex-contract must completed now');   
}
#[test]
fn test_execute_functionality_not_enough_staked(){
    let amount_to_stake: u256 = parse_decimal_to_u256("0.1"); // 0.1 STRK
    let setup = setup_stake(amount_to_stake);
    // First lets check if th external contract is not completed.
    let external_contract = setup.staking.example_external_contract();
    assert(!IExampleExternalContractDispatcher{contract_address:external_contract}.is_completed(), 'ex-contract not completed yet');

    // Now lets cheat time and execute the contract.
    start_cheat_block_timestamp_global(get_block_timestamp() + 60); // cheat time by 60 seconds
    // anyone can call execute
    setup.staking.execute();
    // Now lets check if the external contract is completed.
    assert(setup.staking.open_for_withdraw(), 'Staking  be open for withdraw');
    // Now we can withdraw our tokens.
    let balance_before_withdraw = setup.staking.balances(setup.tester);
    println!("Before withdraw-> balance:{}",balance_before_withdraw);
    cheat_caller_address(setup.staking.contract_address, setup.tester, CheatSpan::TargetCalls(1)); 
    setup.staking.withdraw();
    // Check if the balance is zero after withdraw
    let balance_after_withdraw = setup.staking.balances(setup.tester);
    println!("After withdraw-> balance:{}",balance_after_withdraw);
    assert(balance_after_withdraw == 0, 'Balance must be zero');
}


