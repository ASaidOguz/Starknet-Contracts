use token_vendor::Vendor::{IVendorDispatcher, IVendorDispatcherTrait};
use token_vendor::ProtocolToken::{IProtocolTokenDispatcher, IProtocolTokenDispatcherTrait};
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher,
                                           IERC20DispatcherTrait,
                                           IERC20MetadataDispatcher,
                                           IERC20MetadataDispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, cheat_caller_address};
use starknet::ContractAddress;

const RECIPIENT: ContractAddress = 'RECIPIENT'.try_into().unwrap();
const OTHER: ContractAddress = 'OTHER'.try_into().unwrap();

// Should deploy the MockSTRKToken contract
fn deploy_mock_strk_token() -> ContractAddress {
    let INITIAL_SUPPLY: u256 = 100000000000000000000; // 100_STRK_IN_FRI
    let mut calldata = array![];
    calldata.append_serde(INITIAL_SUPPLY);
    calldata.append_serde(RECIPIENT);
    declare_and_deploy("MockSTRKToken", calldata)
}

// Should deploy the ProtocolToken contract
fn deploy_protocol_token_token() -> ContractAddress {
    let mut calldata = array![];
    calldata.append_serde(RECIPIENT);
    let protocol_token_address = declare_and_deploy("ProtocolToken", calldata);
    println!("-- ProtocolToken contract deployed on: 0x{:x}", protocol_token_address);
    protocol_token_address
}

// Should deploy the Vendor contract
fn deploy_vendor_contract() -> ContractAddress {
    let strk_token_address = deploy_mock_strk_token();
    let protocol_token_address = deploy_protocol_token_token();
    let tester_address = RECIPIENT;
    let mut calldata = array![];
    calldata.append_serde(strk_token_address);
    calldata.append_serde(protocol_token_address);
    calldata.append_serde(tester_address);
    let vendor_contract_address = declare_and_deploy("Vendor", calldata);
    println!("-- Vendor contract deployed on: 0x{:x}", vendor_contract_address);

        // send strk to vendor contract
    // change the caller address of the strk_token_address to be tester_address
    cheat_caller_address(strk_token_address, tester_address, CheatSpan::TargetCalls(1));
    let strk_amount_fri: u256 = 1000000000000000000; // 1_STRK_IN_FRI
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };
    assert(
        strk_token_dispatcher.transfer(vendor_contract_address, strk_amount_fri), 'Transfer failed',
    );
    let vendor_strk_balance = strk_token_dispatcher.balance_of(vendor_contract_address);
    println!("-- Vendor strk balance: {:?} STRK in fri", vendor_strk_balance);

     // send GLD token to vendor contract
    // Change the caller address of the your_token_address to be tester_address
    cheat_caller_address(protocol_token_address, tester_address, CheatSpan::TargetCalls(1));
    let your_token_dispatcher = IProtocolTokenDispatcher { contract_address: protocol_token_address };
    let INITIAL_BALANCE: u256 = 1000000000000000000000; // 1000_GLD_IN_FRI
    assert(
        your_token_dispatcher.transfer(vendor_contract_address, INITIAL_BALANCE), 'Transfer failed',
    );
    let vendor_token_balance = your_token_dispatcher.balance_of(vendor_contract_address);
    println!("-- Vendor GLD token balance: {:?} GLD in fri", vendor_token_balance);
    vendor_contract_address
}

#[test]
fn test_protocol_metadata(){
    let protocol_token_address = deploy_protocol_token_token();
    let protocol_token_dispatcher = IProtocolTokenDispatcher { contract_address: protocol_token_address };
    let metadata_dispatcher = IERC20MetadataDispatcher { contract_address: protocol_token_address };

    // Check the name and symbol of the token
    let name = metadata_dispatcher.name();
    let symbol = metadata_dispatcher.symbol();
    println!("-- Token Name: {:?}", name);
    println!("-- Token Symbol: {:?}", symbol);
    assert_eq!(name , "ProtocolToken", "Name should be Protocol Token");
    assert_eq!(symbol , "PRTCL", "Symbol should be PRTCL");

    // Check the total supply
    let total_supply = protocol_token_dispatcher.total_supply();
    println!("-- Total supply: {:?}", total_supply);
}
#[test]
fn test_deploy_mock_strk_token() {
    let INITIAL_BALANCE: u256 = 10000000000000000000; // 10_STRK_IN_FRI
    let contract_address = deploy_mock_strk_token();
    let strk_token_dispatcher = IERC20Dispatcher { contract_address };
    assert(
        strk_token_dispatcher.balance_of(RECIPIENT) == INITIAL_BALANCE, 'Balance should be >
    0',
    );
}

#[test]
fn test_deploy_protocol_token() {
    let MINIMUN_SUPPLY: u256 = 1000000000000000000000; // 1000_GLD_IN_FRI
    let contract_address = deploy_protocol_token_token();
    let your_token_dispatcher = IProtocolTokenDispatcher { contract_address };
    let total_supply = your_token_dispatcher.total_supply();
    println!("-- Total supply: {:?}", total_supply);
    assert(total_supply >= MINIMUN_SUPPLY, 'supply should be at least 1000');
}

#[test]
fn test_deploy_vendor() {
    deploy_vendor_contract();
}

// Should let us sell tokens and we should get the appropriate amount strk back...
#[test]
fn test_sell_tokens() {
    let vendor_contract_address = deploy_vendor_contract();
    let vendor_dispatcher = IVendorDispatcher { contract_address: vendor_contract_address };
    let protocol_token_address = vendor_dispatcher.protocol_token();
    let protocol_token_dispatcher = IProtocolTokenDispatcher { contract_address: protocol_token_address };

    let tester_address = RECIPIENT;

    println!("-- Tester address: {:?}", tester_address);
    let starting_balance = protocol_token_dispatcher.balance_of(tester_address); // 1000 PRTCL_IN_FRI
    println!("---- Starting token balance: {:?} GLD in fri", starting_balance);

    println!("-- Selling back 0.1 GLD tokens ...");
    let prtcl_token_amount_fri: u256 = 100000000000000000; // 0.1_PRTCL_IN_FRI

        // Change the caller address of the protocol_token_contract to the tester_address
    cheat_caller_address(protocol_token_address, tester_address, CheatSpan::TargetCalls(1));
    protocol_token_dispatcher.approve(vendor_contract_address, prtcl_token_amount_fri);

    // check allowance
    let allowance = protocol_token_dispatcher.allowance(tester_address, vendor_contract_address);
    assert(allowance == prtcl_token_amount_fri, 'Allowance equal to sold amount');

        // Change the caller address of the your_token_address to the tester_address
    cheat_caller_address(vendor_contract_address, tester_address, CheatSpan::TargetCalls(1));
    vendor_dispatcher.sell_tokens(prtcl_token_amount_fri);
    println!("-- Sold 0.1 PRTCL tokens");

        let new_balance = protocol_token_dispatcher.balance_of(tester_address);
    println!("---- New token balance: {:?} GLD in fri", new_balance);
    let expected_balance = starting_balance
        - prtcl_token_amount_fri; // 2000 - 0.1 = 1999.9_GLD_IN_FRI
    assert(new_balance == expected_balance, 'Balance should be decreased');
}

//Should let the owner (and nobody else) withdraw the strk from the contract...
#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_failing_withdraw_tokens() {
    let vendor_contract_address = deploy_vendor_contract();
    let vendor_dispatcher = IVendorDispatcher { contract_address: vendor_contract_address };
    let protocol_token_address = vendor_dispatcher.protocol_token();
    let protocol_token_dispatcher = IProtocolTokenDispatcher { contract_address: protocol_token_address };
    let strk_token_address = vendor_dispatcher.strk_token();
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };

    let tester_address = RECIPIENT;

    println!("-- Tester address: {:?}", tester_address);
    let starting_balance = protocol_token_dispatcher.balance_of(tester_address); // 1000 PRTCL_IN_FRI
    println!("---- Starting token balance: {:?} PRTCL in fri", starting_balance);

    println!("-- Buying 0.1 STRK worth of tokens ...");
    let strk_amount_fri: u256 = 100000000000000000; // 0.1_STRK_IN_FRI
    // Change the caller address of the STRK_token_contract to the tester_address
    cheat_caller_address(strk_token_address, tester_address, CheatSpan::TargetCalls(1));
    strk_token_dispatcher.approve(vendor_contract_address, strk_amount_fri);
    // check allowance
    let allowance = strk_token_dispatcher.allowance(tester_address, vendor_contract_address);
    assert(allowance == strk_amount_fri, 'Allowance should be equal');

        // Change the caller address of the your_token_address to the tester_address
    cheat_caller_address(vendor_contract_address, tester_address, CheatSpan::TargetCalls(1));
    vendor_dispatcher.buy_tokens(strk_amount_fri);
       println!("-- Bought 0.1 STRK worth of tokens");
    let tokens_per_strk: u256 = vendor_dispatcher.tokens_per_strk(); // 100 tokens per STRK
    let expected_tokens = strk_amount_fri * tokens_per_strk; // 10_GLD_IN_FRI ;
    println!("---- Expect to receive: {:?} PRTCL in fri", expected_tokens);
    let new_balance = protocol_token_dispatcher.balance_of(tester_address);
    println!("---- New token balance: {:?} PRTCL in fri", new_balance);
    

    let vendor_strk_balance = strk_token_dispatcher.balance_of(vendor_contract_address);
    println!("---- Vendor contract strk balance: {:?} STRK in fri", vendor_strk_balance);

    let not_owner_address = OTHER;
    let not_owner_balance = strk_token_dispatcher.balance_of(not_owner_address);
    println!("---- Other address strk balance: {:?} STRK in fri", not_owner_balance);
    // Change the caller address of the vendor_contract_address to the not_owner_address
    cheat_caller_address(vendor_contract_address, not_owner_address, CheatSpan::TargetCalls(1));
    vendor_dispatcher.withdraw();
}

#[test]
fn test_success_withdraw_tokens() {
    let vendor_contract_address = deploy_vendor_contract();
    let vendor_dispatcher = IVendorDispatcher { contract_address: vendor_contract_address };
    let strk_token_address = vendor_dispatcher.strk_token();
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };

    let owner_address = RECIPIENT;

    println!("-- Tester address: {:?}", owner_address);

    println!("-- Buying 0.1 STRK worth of tokens ...");
    let strk_amount_fri: u256 = 100000000000000000; // 0.1_STRK_IN_FRI
    // Change the caller address of the STRK_token_contract to the owner_address
    cheat_caller_address(strk_token_address, owner_address, CheatSpan::TargetCalls(1));
    strk_token_dispatcher.approve(vendor_contract_address, strk_amount_fri);

    // Change the caller address of the your_token_address to the owner_address
    cheat_caller_address(vendor_contract_address, owner_address, CheatSpan::TargetCalls(1));
    vendor_dispatcher.buy_tokens(strk_amount_fri);
    println!("-- Bought 0.1 STRK worth of tokens");

    let owner_strk_balance_before_withdraw = strk_token_dispatcher.balance_of(owner_address);
    println!(
        "---- Owner token balance before withdraw: {:?} STRK in fri",
        owner_strk_balance_before_withdraw,
    );

    let vendor_strk_balance = strk_token_dispatcher.balance_of(vendor_contract_address);
    println!("---- Vendor contract strk balance: {:?} STRK in fri", vendor_strk_balance);

    println!("-- Withdrawing strk from Vendor contract ...");
    // Change the caller address of the vendor_contract_address to the owner_address
    cheat_caller_address(vendor_contract_address, owner_address, CheatSpan::TargetCalls(1));
    vendor_dispatcher.withdraw();

    // Check the deployer's balance after withdraw
    let deployer_balance_after = strk_token_dispatcher.balance_of(owner_address);
    println!("---- Deployer balance after withdraw: {:?} STRK in fri", deployer_balance_after);

    // Assert that the deployer's balance increased by the vendor's balance
    assert(
        owner_strk_balance_before_withdraw + vendor_strk_balance == deployer_balance_after,
        'Balance should be the same',
    );
}