#[cfg(test)]

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use core::traits::TryInto;
use snforge_std::{CheatSpan, cheat_caller_address,test_address};
use starknet::ContractAddress;

// OpenZeppelin Ownable interface and its dispatcher
use openzeppelin_access::ownable::interface::IOwnableDispatcher;
use openzeppelin_access::ownable::interface::IOwnableDispatcherTrait; // You might need this for the `owner()` trait method

// These imports are necessary for the OwnableComponent initiliazer test.
use openzeppelin_access::ownable::OwnableComponent;
use openzeppelin_access::ownable::OwnableComponent::{OwnableMixinImpl, InternalImpl as OwnableInternalImpl};

type OwnableComponentState = OwnableComponent::ComponentState<Erc20TL::ContractState>;

fn OWNABLE_COMPONENT_STATE() -> OwnableComponentState {
    OwnableComponent::component_state_for_testing()
}

use openzeppelin_token::erc20::ERC20Component;
use openzeppelin_token::erc20::ERC20Component::{ERC20MixinImpl, InternalImpl as ERC20InternalImpl};

type ERC20ComponentState = ERC20Component::ComponentState<Erc20TL::ContractState>;
// const 
const ALICE: ContractAddress = 'ALICE'.try_into().unwrap();
const BOB: ContractAddress = 'BOB'.try_into().unwrap();
const OWNER:ContractAddress= 'OWNER'.try_into().unwrap();

// Main Contract's dispatcher.
use erc20_stark::Erc20TL::IErc20TLDispatcher;
use erc20_stark::Erc20TL::IErc20TLDispatcherTrait;

use erc20_stark::Erc20TL::Erc20TL;

// Contract state
fn CONTRACT_STATE() -> Erc20TL::ContractState {
    Erc20TL::contract_state_for_testing()
}
// Setup function to initialize the contract state
fn ERC20_COMPONENT_STATE() -> ERC20ComponentState {
    ERC20Component::component_state_for_testing()
}

fn setup() ->(ERC20ComponentState, OwnableComponentState) {
    let _=CONTRACT_STATE();
    let mut ownable_state = OWNABLE_COMPONENT_STATE();
    let mut erc20_state = ERC20_COMPONENT_STATE(); // you’ll have this too
    ownable_state.initializer(OWNER); // Or NEW_OWNER if you prefer
        let name = "Erc20TL";
        let symbol = "ETL";
    erc20_state.initializer(name, symbol);
    (erc20_state, ownable_state)
}
#[test]
   fn test_components(){
   let (erc20_state,ownable_state)=setup();
   assert_eq!(erc20_state.name(), "Erc20TL", "Name mismatch in ERC20 component");
   assert_eq!(erc20_state.symbol(), "ETL", "Symbol mismatch in ERC20 component");
   assert_eq!(ownable_state.owner(), OWNER, "Owner mismatch in Ownable component");
}



// Mock Stark Token interface and its dispatcher
use erc20_stark::MockStarkToken::IMockStarkTokenDispatcher;
//use erc20_stark::MockStarkToken::IMockStarkTokenDispatcherTrait;

// IERC20METADATA interface and its dispatcher
use openzeppelin_token::erc20::interface::IERC20MetadataDispatcher;
use openzeppelin_token::erc20::interface::IERC20MetadataDispatcherTrait; // You might need this for the `symbol()` trait method

// ERC20 Mixin interface and its dispatcher
use openzeppelin_token::erc20::interface::IERC20Dispatcher;
use openzeppelin_token::erc20::interface::IERC20DispatcherTrait; // You might need this for the `balance_of()` trait method


fn deploy_mocks() ->IMockStarkTokenDispatcher {
    // Create the amount as a u256
    let amount: u256 = 1_000_000_000_000_000_000_000_0000;

    // Manually extract low and high (felt252) values -> it's neccessary to convert u256 to two felt252 values.
    let amount_low: felt252 = amount.low.into();
    let amount_high: felt252 = amount.high.into();

    // Create constructor args as raw felts
    let constructor_args = array![
        amount_low,
        amount_high,
        ALICE.into()  // assuming OWNER is a valid felt252 or ContractAddress
    ];

    // Deploy the contract
    let contract = declare("MockStarkToken").unwrap().contract_class();
    let (contract_address, _ ) = contract.deploy(@constructor_args).unwrap();
    // This contract will be used as a mock for payment logic in the main contract
    // Return dispatcher for contract
    IMockStarkTokenDispatcher { contract_address }
}

fn deploy() -> IErc20TLDispatcher{
        // Create the amount as a u256
    let amount: u256 = 1_000_000_000_000_000_000_000_0000;

    // Manually extract low and high (felt252) values -> it's neccessary to convert u256 to two felt252 values.
    let amount_low: felt252 = amount.low.into();
    let amount_high: felt252 = amount.high.into();

    // Create constructor args as raw felts
    let constructor_args = array![
        amount_low,
        amount_high,
        OWNER.into()  // assuming OWNER is a valid felt252 or ContractAddress
    ];

    // Deploy the contract
    let contract = declare("Erc20TL").unwrap().contract_class();
    let (contract_address, _ ) = contract.deploy(@constructor_args).unwrap();

    // Return dispatcher for contract
    IErc20TLDispatcher { contract_address }
}

#[test] // added as test attribute to run this function as a test so if this changes coverage???
fn test_deploy()  {
    // Create the amount as a u256
    let amount: u256 = 1_000_000_000_000_000_000_000_0000;

    // Manually extract low and high (felt252) values -> it's neccessary to convert u256 to two felt252 values.
    let amount_low: felt252 = amount.low.into();
    let amount_high: felt252 = amount.high.into();

    // Create constructor args as raw felts
    let constructor_args = array![
        amount_low,
        amount_high,
        OWNER.into()  // assuming OWNER is a valid felt252 or ContractAddress
    ];

    // Deploy the contract
    let contract = declare("Erc20TL").unwrap().contract_class();
    let (contract_address, _ ) = contract.deploy(@constructor_args).unwrap();
    println!("Contract deployed at: {:?}", contract_address);

}

// IErc20TL
//fn mint(ref self:TState,recipient:ContractAddress,amount:u256) -> bool;
#[test]
fn test_deploy_mint(){
    // Deploy the contract
    let contract = deploy();
    let amount: u256 = 1_000_000_000_000_000_000_000_0000;
    cheat_caller_address(contract.contract_address, OWNER, CheatSpan::TargetCalls(1)); 
    let result= contract.mint(ALICE, amount);
    assert!(result, "Minting failed");
    let ierc20_dispatcher = IERC20Dispatcher{contract_address:contract.contract_address};
    let balance = ierc20_dispatcher.balance_of(OWNER);
    assert_eq!(balance, amount, "Balance mismatch for owner after minting");
    let balance_alice = ierc20_dispatcher.balance_of(ALICE);
    assert_eq!(balance_alice, amount, "Balance mismatch for Alice after minting");
}

    // IOwnable
//fn owner() -> ContractAddress;
//fn transfer_ownership(new_owner: ContractAddress);
//fn renounce_ownership();
#[test]
fn test_owner_can_mint(){
    // Deploy the contract
    let erc20TL_contract = deploy();
    let amount:u256 = 1_000_000_000_000_000_000_000_0000;
    cheat_caller_address(erc20TL_contract.contract_address, OWNER, CheatSpan::TargetCalls(1));
    let result = erc20TL_contract.mint(ALICE, amount);
    assert!(result, "Minting failed");
    let ierc20_dispatcher = IERC20Dispatcher{contract_address:erc20TL_contract.contract_address};
    let balance = ierc20_dispatcher.balance_of(ALICE);
    assert_eq!(balance, amount, "Balance mismatch for Alice after minting");
}
#[test]
fn test_transferownership(){
    // deploy contract
    let erc20TL_dispatcher = deploy();
    // lets create IownerDispatcher
    let iowner_dispatcher = IOwnableDispatcher{contract_address:erc20TL_dispatcher.contract_address};
    // Now let owner call the transferOwnership method
    cheat_caller_address(iowner_dispatcher.contract_address,OWNER, CheatSpan::TargetCalls(1));
    let new_owner = ALICE;
    let _ = iowner_dispatcher.transfer_ownership(new_owner);
    assert_eq!(iowner_dispatcher.owner(),new_owner,"Ownership transfer failed");
} 
#[test]
fn test_renounce_ownership(){
    // deploy contract
    let erc20TL_dispatcher = deploy();
    // lets create IownerDispatcher
    let iowner_dispatcher = IOwnableDispatcher{contract_address:erc20TL_dispatcher.contract_address};
    // Now let owner call the renounceOwnership method
    cheat_caller_address(iowner_dispatcher.contract_address,OWNER, CheatSpan::TargetCalls(1));
    let _ = iowner_dispatcher.renounce_ownership();
    let zero_address:ContractAddress= 0.try_into().unwrap();
    assert_eq!(iowner_dispatcher.owner(),zero_address,"Ownership should be renounced");
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_non_owner_cant_mint(){
    // Deploy the contract
    let erc20TL_contract = deploy();
    let amount:u256 = 1_000_000_000_000_000_000_000_0000;
    // Result not important cause it will panic
    cheat_caller_address(erc20TL_contract.contract_address, BOB, CheatSpan::TargetCalls(1));
    let _ = erc20TL_contract.mint(ALICE, amount);
}

    // IERC20Metadata
//fn name() -> ByteArray;
//fn symbol() -> ByteArray;
//fn decimals() -> u8;
#[test]
fn test_ierc20metadata(){
    // Deploy the contract
    let erc20TL_contract = deploy();
    let ierc20_metadata = IERC20MetadataDispatcher{contract_address:erc20TL_contract.contract_address};
    // Not to self :::: Tests stop in the first assert failure, so the rest of the tests will not run if this fails.
    // Check name
    let name = ierc20_metadata.name();
    assert_eq!(name, "Erc20TL", "Name mismatch");
    
    // Check symbol
    let symbol = ierc20_metadata.symbol();
    assert_eq!(symbol, "ETL", "Symbol mismatch");

    // Check decimals
    let decimals = ierc20_metadata.decimals();
    assert_eq!(decimals, 18, "Decimals mismatch");
}
    // IERC20
//fn total_supply() -> u256;
//fn balance_of(account: ContractAddress) -> u256;
//fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;
//fn transfer(recipient: ContractAddress, amount: u256) -> bool;
//fn transfer_from(
        //sender: ContractAddress, recipient: ContractAddress, amount: u256
    //) -> bool;
//fn approve(spender: ContractAddress, amount: u256) -> bool;
#[test]
fn test_ierc20(){
// Deploy our contract 
    let erc20TL_dispatcher = deploy();
    let ierc20_dispatcher = IERC20Dispatcher{contract_address:erc20TL_dispatcher.contract_address};
    // Check total supply
    let total_supply = ierc20_dispatcher.total_supply();
    let expected_supply: u256 = 1_000_000_000_000_000_000_000_0000;
    assert_eq!(total_supply, expected_supply, "Total supply mismatch");
    // Check balance of owner
    let owner_balance = ierc20_dispatcher.balance_of(OWNER);
    assert_eq!(owner_balance, expected_supply, "Owner balance mismatch");
    // Check balance of Alice   
    let alice_balance =ierc20_dispatcher.balance_of(ALICE);
    assert_eq!(alice_balance,0, "Alice balance should be zero initially");
    // First Owner sends some tokens to Alice by transfer;
    let transfer_amount: u256 = expected_supply / 2; // Half of the total supply
    cheat_caller_address(erc20TL_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(1));
    let transfer_result = ierc20_dispatcher.transfer(ALICE, transfer_amount);
    assert!(transfer_result, "Transfer failed");
    // Check balances after transfer
    let owner_balance_after_transfer = ierc20_dispatcher.balance_of(OWNER);
    assert_eq!(owner_balance_after_transfer, expected_supply - transfer_amount, "Owner balance after transfer mismatch");
    // Let owner drain himself by Alice through approve and transfer_from
    cheat_caller_address(erc20TL_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(1));
    let approve_result = ierc20_dispatcher.approve(ALICE, transfer_amount);
    assert!(approve_result, "Approve failed");
    // Now Alice can transfer from Owner to herself
    cheat_caller_address(erc20TL_dispatcher.contract_address, ALICE, CheatSpan::TargetCalls(1));
    let transfer_from_result = ierc20_dispatcher.transfer_from(OWNER, ALICE, transfer_amount);
    assert!(transfer_from_result, "Transfer from failed");
    // Check balances after transfer_from
    let owner_balance_after_transfer_from = ierc20_dispatcher.balance_of(OWNER);
    assert_eq!(owner_balance_after_transfer_from, 0, "Owner balance after transfer_from should be zero");
    let alice_balance_after_transfer_from = ierc20_dispatcher.balance_of(ALICE);
    assert_eq!(alice_balance_after_transfer_from, transfer_amount*2, "Alice balance after transfer_from mismatch");
    // Check allowance
    let allowance = ierc20_dispatcher.allowance(OWNER, ALICE);
    assert_eq!(allowance, 0, "Allowance mismatch after transfer_from");
}

//Concept	                            Cairo
//Modular logic	  ->      Component module (#[starknet::component])
//Generic host	  ->                 TContractState
//Required structure	->       +HasComponent<TContractState>
//Hooks or extra behavior	->    +ERC20HooksTrait<TContractState>
//Public ABI	  ->      #[abi(embed_v0)] + impl of IERC20<ContractState>