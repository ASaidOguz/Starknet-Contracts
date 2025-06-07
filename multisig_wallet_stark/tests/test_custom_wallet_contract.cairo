use starknet::ContractAddress;
use starknet::account::Call;

pub type TransactionID = felt252;
pub type TransactionState = multisig_wallet_stark::CustomInterfaceMultisigComponent::TransactionState;

use multisig_wallet_stark::CustomMultisigWallet::{ICustomMultisigWalletDispatcher,
                                                  ICustomMultisigWalletDispatcherTrait, };
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::{CheatSpan, cheat_caller_address};


const INITIAL_RECIPIENT_SUPPLY: u256 = 1_000_000_000_000_000_000_000; // 1000_STRK_IN_FRI
const ONE_TOKEN_UNIT: u256 = 1_000_000_000_000_000_000; // 1_TOKE_UNIT_IN_FRI
const TEN_TOKEN_UNIT: u256 = 10_000_000_000_000_000_000; // 10_TOKE_UNIT_IN_FRI

/// OWNER and SIGNERS 
const OWNER: ContractAddress = 'OWNER'.try_into().unwrap();

const SIGNER1: ContractAddress = 'SIGNER1'.try_into().unwrap();
const SIGNER2: ContractAddress = 'SIGNER2'.try_into().unwrap();
const SIGNER3: ContractAddress = 'SIGNER3'.try_into().unwrap();
// random guy who try to mess things up.
const RANDOM_ENTITY: ContractAddress = 'RANDOM_ENTITY'.try_into().unwrap();

fn create_signer_array()-> Array<ContractAddress>{
    let mut calldata:Array<ContractAddress> = array![];
    calldata.append(SIGNER1);
    calldata.append(SIGNER2);
    calldata.append(SIGNER3);
    calldata
}

fn create_batch_call(to: ContractAddress, selector:felt252) -> Array<Call> {
    let mut quorum = 1_u32;
    let signers = create_signer_array();
    let mut calls: Array<Call> = array![];

    // Option 2: For loop with proper syntax
    for i in 0..signers.len() {
        let mut calldata = array![];
        calldata.append_serde(quorum);
        calldata.append_serde(*signers.at(i));
        calls.append(Call {
            to: to,
            selector: selector,  // Still might need fixing
            calldata: calldata.span(),
        });
       
    }

    calls
}

fn deploy_mock_strktoken() -> IERC20Dispatcher{
    let mut calldata = array![];
    calldata.append_serde(INITIAL_RECIPIENT_SUPPLY);
    calldata.append_serde(OWNER);
    let strk_token_address = declare_and_deploy("MockSTRKToken", calldata);
    let strk_token_dispatcher = IERC20Dispatcher { contract_address: strk_token_address };
    strk_token_dispatcher
}
// By deploying owner has the priviliged to submit tx and tx batches.Rest of the 
// elements completely carried on by multisig governance methodology.
// change_quorum() function as well .
fn deploy_custom_multisig_wallet() ->(ICustomMultisigWalletDispatcher,IERC20Dispatcher){
   let strk_dispatcher = deploy_mock_strktoken();
    let mut calldata = array![];
    //initial quorum should be 1 cause we set 1 signer at a time.
    let quorum:u32= 1;
    let signer:ContractAddress= OWNER;
    calldata.append_serde(quorum);
    calldata.append_serde(signer);
    calldata.append_serde(strk_dispatcher.contract_address);
    
    let custom_multisig_wallet_address = declare_and_deploy("CustomMultisigWallet",calldata);
    // need to fund the wallet for future operations.
    cheat_caller_address(strk_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(1));
    strk_dispatcher.transfer(custom_multisig_wallet_address,INITIAL_RECIPIENT_SUPPLY);
    // wallet funded with INITIAL_RECIPIENT_SUPPLY and ready to be used 
    // Wallet dispatcher returned.
    (ICustomMultisigWalletDispatcher{contract_address:custom_multisig_wallet_address},strk_dispatcher)
}

#[test]
fn test_wallet_deploys(){
    let (wallet_dispatcher,strk_dispatcher)= deploy_custom_multisig_wallet();
    println!("Stark-Token contract deployed at {:?}",strk_dispatcher.contract_address);
    println!("Stark-Token contract deployed at {:?}",wallet_dispatcher.contract_address);
    // lets check if our wallet has been funded.
    assert_eq!(strk_dispatcher.balance_of(wallet_dispatcher.contract_address),
                                            INITIAL_RECIPIENT_SUPPLY,
                                            "Wallet not Funded!");
    // lets check quorum and signer.
    let quorum = wallet_dispatcher.get_quorum();
    let signers = wallet_dispatcher.get_signers();

    println!("Quorum: {}", quorum);
    println!("Signers:");

    // Loop through the Array of signers
    let mut i = 0;
    let signers_len = signers.len();
    while i < signers_len {
        let current_signer = signers.at(i); // .at(i) returns the element directly for ContractAddress
        println!("  Signer {}: {:?}", i, current_signer);
        i += 1;
    }

    // You can also add assertions here based on your constructor's initial signer
    assert_eq!(quorum, 1, "Initial quorum should be 1"); // Assuming your constructor sets quorum to 1 initially
    assert_eq!(signers_len, 1, "Expected 1 initial signer");
    assert_eq!(signers.at(0),@OWNER , "Initial signer address is incorrect");
}

#[test]
fn test_add_signer_propose(){
    let (wallet_dispatcher,_)= deploy_custom_multisig_wallet();
    // lets craft submit_transaction function arguments.
        // to: ContractAddress,
        // selector: felt252,
        // calldata: Array<felt252>,
        // salt: felt252,
    let to = wallet_dispatcher.contract_address;
    let selector = selector!("add_signer");
    println!("add_signer selector: {}",selector);
    let mut calldata= array![];
    let new_quorum:u32 = 2;
    let new_signer:ContractAddress= SIGNER1;
    calldata.append_serde(new_quorum);
    calldata.append_serde(new_signer);
    let salt = 0;

    cheat_caller_address(wallet_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(3));
    let tx_id = wallet_dispatcher.submit_transaction(to,selector,calldata.clone(),salt);
    wallet_dispatcher.confirm_transaction(tx_id);
    println!("Transaction ID:{}",tx_id);
    wallet_dispatcher.execute_transaction(to,selector,calldata.clone(),salt);

        // lets check quorum and signers.
    let quorum = wallet_dispatcher.get_quorum();
    let signers = wallet_dispatcher.get_signers();

    println!("Quorum: {}", quorum);
    println!("Signers:");

    // Loop through the Array of signers
    let mut i = 0;
    let signers_len = signers.len();
    while i < signers_len {
        let current_signer = signers.at(i); // .at(i) returns the element directly for ContractAddress
        println!("  Signer {}: {:?}", i, current_signer);
        i += 1;
    }

    // You can also add assertions here based on your constructor's initial signer
    assert_eq!(quorum, 2, "New quorum should be 2"); // Assuming your constructor sets quorum to 1 initially
    assert_eq!(signers_len, 2, "Expected 2 signers");
    assert_eq!(signers.at(0),@OWNER , "Initial signer address is incorrect");
    assert_eq!(signers.at(1),@SIGNER1 , "New signer address is incorrect");

}

#[test]
fn test_transferfund_propose(){
    
    let (wallet_dispatcher,strk_dispatcher) = deploy_custom_multisig_wallet();
    // we gonna create batch call for add_signer function -> after this we gonna have 4 signers.
    // lets add change_quorum call into batch call.
    let mut quorum_calldata = array![];
    quorum_calldata.append_serde(3);
    let quorum_call = Call{
        to:wallet_dispatcher.contract_address,
        selector:selector!("change_quorum"),
        calldata:quorum_calldata.span(),
    };

    let selector = selector!("add_signer");
    let mut calls =create_batch_call(wallet_dispatcher.contract_address,selector);
    calls.append(quorum_call);
    let salt =0;

    cheat_caller_address(wallet_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(3));
    let tx_id = wallet_dispatcher.submit_transaction_batch(calls.clone(),salt);
    // submitting tx already confirms it so its redundant;
    wallet_dispatcher.confirm_transaction(tx_id);
    wallet_dispatcher.execute_transaction_batch(calls.clone(),0);
    // Now we have 4 signers
    let signers= wallet_dispatcher.get_signers();
    assert_eq!(signers.len(),4,"Incorrect signer length");
    // New quorum level 3 -> need at least 3 signers to execute a tx.
    assert_eq!(wallet_dispatcher.get_quorum(),3,"Change quorum failed");

    // Now lets propose transfer tx to our newly signers.
    let transfer_selector = selector!("transfer_funds");
    let mut transfer_calldata = array![];
    transfer_calldata.append_serde(OWNER);
    transfer_calldata.append_serde(TEN_TOKEN_UNIT);
    cheat_caller_address(wallet_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(1));
    // we send tx and confirmed same time.
    let transfer_tx_id = wallet_dispatcher.submit_transaction(
        wallet_dispatcher.contract_address,
        transfer_selector,
        transfer_calldata.clone(),
        0);
    // signer-1 confirms tx.
    cheat_caller_address(wallet_dispatcher.contract_address, SIGNER1, CheatSpan::TargetCalls(1));
    wallet_dispatcher.confirm_transaction(transfer_tx_id);
    // signer-2 confirms tx.
    cheat_caller_address(wallet_dispatcher.contract_address, SIGNER2, CheatSpan::TargetCalls(1));
    wallet_dispatcher.confirm_transaction(transfer_tx_id);
    // signer-3 execute tx.
    cheat_caller_address(wallet_dispatcher.contract_address, SIGNER3, CheatSpan::TargetCalls(2));
    wallet_dispatcher.confirm_transaction(transfer_tx_id);
    wallet_dispatcher.execute_transaction(wallet_dispatcher.contract_address,
        transfer_selector,
        transfer_calldata.clone(),
        0);
    // finaly assert balance of owner for 10 Token Unit--->
    assert_eq!(strk_dispatcher.balance_of(OWNER),TEN_TOKEN_UNIT,"Wrong balance!");
}

