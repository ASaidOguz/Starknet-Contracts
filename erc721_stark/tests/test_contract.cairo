#[cfg(test)]


use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use erc721_stark::Erc721Nft::IErc721NftDispatcher;
use erc721_stark::Erc721Nft::IErc721NftDispatcherTrait;

use erc721_stark::NftFactory::INftFactoryDispatcher;
use erc721_stark::NftFactory::INftFactoryDispatcherTrait;
use core::traits::TryInto;
use core::array::{ArrayTrait};
// ADD THESE IMPORTS for your counter reader dispatcher
use erc721_stark::Erc721Nft::ICounterReaderDispatcher;
use erc721_stark::Erc721Nft::ICounterReaderDispatcherTrait;
use erc721_stark::components::Counter::{ICounterDispatcher,ICounterDispatcherTrait};

// OpenZeppelin ERC721 interfaces and their dispatchers
use openzeppelin_token::erc721::interface::IERC721Dispatcher;
use openzeppelin_token::erc721::interface::IERC721DispatcherTrait;
use openzeppelin_token::erc721::interface::IERC721MetadataDispatcher;
use openzeppelin_token::erc721::interface::IERC721MetadataDispatcherTrait;
use openzeppelin_token::erc721::extensions::erc721_enumerable::interface::IERC721EnumerableDispatcher;
use openzeppelin_token::erc721::extensions::erc721_enumerable::interface::IERC721EnumerableDispatcherTrait;

// OpenZeppelin Ownable interface and its dispatcher
use openzeppelin_access::ownable::interface::IOwnableDispatcher;
use openzeppelin_access::ownable::interface::IOwnableDispatcherTrait; // You might need this for the `owner()` trait method
// Utils functions-> serde does the serialization and deserialization for constructor arguments.
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_utils::serde::SerializedAppend;

use snforge_std::{CheatSpan, cheat_caller_address};
use starknet::{ContractAddress,ClassHash};

// const 
const ALICE: ContractAddress = 'ALICE'.try_into().unwrap();
const BOB: ContractAddress = 'BOB'.try_into().unwrap();
const OWNER:ContractAddress= 'OWNER'.try_into().unwrap();

// Declare and deploy the contract and return its dispatcher.
fn deploy(owner:ContractAddress) -> IErc721NftDispatcher {
    let name:ByteArray="BestofBleach";
    let symbol:ByteArray="BOB";
    let owner =OWNER;
    let mut calldata = array![];
    // need address of mock token and example external contract so lets deploy and extract their addresses
    calldata.append_serde(owner);
    calldata.append_serde(name);
    calldata.append_serde(symbol);
    let contract_address= declare_and_deploy(
        "Erc721Nft",
        calldata,);
    // Return the dispatcher.
    // It allows to interact with the contract based on its interface.
    IErc721NftDispatcher { contract_address }
}

fn deploy_nft_factory(owner:ContractAddress) -> INftFactoryDispatcher {
    // need to declare nft contract so our environment has the classHash of it.
    let class_hash = declare("Erc721Nft").unwrap().contract_class().class_hash;
    let class_hash_value = *class_hash;

    let mut calldata = array![];
    calldata.append_serde(owner);
    calldata.append_serde(class_hash_value);

    let contract_address = declare_and_deploy(
        "NftFactory",
        calldata,
    );
    // Return the dispatcher.
    INftFactoryDispatcher { contract_address }
}

fn deploy_mock_contracts() -> (ContractAddress,ContractAddress) {
    // Deploy the MockTokenReceiver contract
    let mock_token_receiver = declare("MockTokenReceiver").unwrap().contract_class();
    let mock_simple_contract = declare("MockSimpleContract").unwrap().contract_class();
    let name ='mock_contract';
    let constructor_args_token_receiver = array![]; 
    let constructor_args_simple_contract = array![name];
    let (mock_token_receiver_address, _) = mock_token_receiver.deploy(@constructor_args_token_receiver).unwrap();
    let (mock_simple_contract_address, _) = mock_simple_contract.deploy(@constructor_args_simple_contract).unwrap();

    return(mock_token_receiver_address,mock_simple_contract_address);
}

#[test]
fn test_deploy_nftfactory(){
    let nft_factory = deploy_nft_factory(OWNER);
    println!("NftFactory deployed at: {:?}", nft_factory.contract_address);

    let contract_name:ByteArray="Factory-Born";
    let symbol:ByteArray="FB";
    let deployed_nft_contract =nft_factory.deploy_nft_contract(contract_name.clone(), symbol.clone());
    println!("Deployed NFT contract at: {:?}", deployed_nft_contract);
    let ierc721metada:IERC721MetadataDispatcher =IERC721MetadataDispatcher{
        contract_address: deployed_nft_contract,
    };

    let deployed_name = ierc721metada.name();
    println!("Deployed NFT contract name: {:?}", deployed_name.clone());
    assert_eq!(deployed_name, contract_name, "Deployed contract name does not match expected name");
    
    let deployed_symbol = ierc721metada.symbol();
    println!("Deployed NFT contract symbol: {:?}", deployed_symbol.clone());
    assert_eq!(deployed_symbol, symbol, "Deployed contract symbol does not match expected symbol");
}

#[test]
fn test_nftfactory_deployed_contract(){
    let nft_factory = deploy_nft_factory(OWNER);
    let contract_name:ByteArray="Factory-Born";
    let symbol:ByteArray="FB";
    cheat_caller_address(nft_factory.contract_address, ALICE, CheatSpan::TargetCalls(3)); 
    let deployed_nft_contract =nft_factory.deploy_nft_contract(contract_name.clone(), symbol.clone());
    let _ =nft_factory.deploy_nft_contract(contract_name.clone(), symbol.clone());
    let _ =nft_factory.deploy_nft_contract(contract_name.clone(), symbol.clone());
    let nft_contract_dispatcher = IErc721NftDispatcher {
        contract_address: deployed_nft_contract,
    };
    let ipfs_hash:ByteArray="QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or";
    let nft_id=nft_contract_dispatcher.mint_item(ALICE,ipfs_hash );
    // Check if the minting was successful
    assert_eq!(nft_id, 1); 
  
    let nft_contracts=nft_factory.get_deployed_nfts_by_deployer(ALICE);
    
    for i in 0..nft_contracts.len() {
    let contract = *nft_contracts.at(i);
    println!("Deployed NFT contract address: {:?}", contract);
                }
    assert_eq!(nft_contracts.len(), 3, "Deployer should have one");
}

// Our Main Contract Erc721Nft
//fn mint_item(to: ContractAddress, token_uri: ByteArray) -> u256;
#[test]
fn test_deploy_mint(){
    let contract = deploy(OWNER);
    println!("Contract deployed at: {:?}", contract.contract_address);
    let ipfs_hash:ByteArray="QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or";
    let nft_id=contract.mint_item(ALICE,ipfs_hash );
    // Check if the minting was successful
    assert_eq!(nft_id, 1);  
    let counter_reader:ICounterReaderDispatcher = ICounterReaderDispatcher{
        contract_address: contract.contract_address,
    };
    assert_eq!(counter_reader.get_current_token_id(), 1);
}

#[test]
fn test_token_uri(){
    let contract = deploy(OWNER);
    let ipfs_hash:ByteArray="QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or";
    let nft_id=contract.mint_item(ALICE,ipfs_hash );
    // Check if the minting was successful
    assert_eq!(nft_id, 1); 
}

#[test]
fn test_ownership(){
    let contract = deploy(OWNER);
    let ipfs_hash:ByteArray="QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or";
    let nft_id=contract.mint_item(ALICE,ipfs_hash );
    // Check if the minting was successful
    assert_eq!(nft_id, 1);  
    // Transfer ownership to BOB
    let iownable_dispatcher:IOwnableDispatcher = IOwnableDispatcher{
        contract_address: contract.contract_address,
    };
    let current_owner= iownable_dispatcher.owner();
    // --- CRITICAL STEP: Cheat the caller address to be the current owner before transfer_ownership ---
    println!("Attempting to transfer ownership from 0x{:x} to 0x{:x}", current_owner, BOB);
    // Make the current owner the caller for 1 call.
    cheat_caller_address(contract.contract_address, current_owner, CheatSpan::TargetCalls(1)); 

    iownable_dispatcher.transfer_ownership(BOB);
    // Check if the ownership was transferred successfully
    assert_eq!(iownable_dispatcher.owner(), BOB);
    // Check if we can renounce ownership;
    cheat_caller_address(contract.contract_address, BOB, CheatSpan::TargetCalls(1)); 
    iownable_dispatcher.renounce_ownership();

    let zero_address:ContractAddress= 0.try_into().unwrap();
    assert_eq!(iownable_dispatcher.owner(),zero_address);
}

    // IERC721Metadata
    //fn name() -> ByteArray;
    //fn symbol() -> ByteArray;
    //fn token_uri(token_id: u256) -> ByteArray;
#[test]
fn test_erc721metadata(){
    let contract=deploy(OWNER);
    let ierc721metada:IERC721MetadataDispatcher =IERC721MetadataDispatcher{
        contract_address: contract.contract_address,
    };
    let name = ierc721metada.name();
    let symbol = ierc721metada.symbol();
    let ipfs_hash:ByteArray="QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or";
    let nft_id=contract.mint_item(ALICE,ipfs_hash );
    let token_uri = ierc721metada.token_uri(nft_id);
    // Check the token URI
    assert_eq!(token_uri, "https://ipfs.io/ipfs/QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or");
    // Check the name and symbol of the token
    assert_eq!(name, "BestofBleach");
    assert_eq!(symbol, "BOB");
}

#[test]
fn test_erc721enumerable(){
   
    let contract=deploy(OWNER);
    let ipfs_hash:ByteArray="QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or";
    let nft_id=contract.mint_item(ALICE,ipfs_hash );
    let ierc721enumerable:IERC721EnumerableDispatcher =IERC721EnumerableDispatcher{
        contract_address: contract.contract_address,
    };
    // Check the total supply of tokens
    let total_supply = ierc721enumerable.total_supply();
    assert_eq!(total_supply, 1);
    let token_id = ierc721enumerable.token_by_index(0);
    assert_eq!(token_id, nft_id);
    // Check the owner of the token
    let token_id_by_index = ierc721enumerable.token_of_owner_by_index(ALICE,0);
    assert_eq!(token_id_by_index, 1);
}
// IERC721
//fn balance_of(account: ContractAddress) -> u256;
//fn owner_of(token_id: u256) -> ContractAddress;

//fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256);
//fn approve(to: ContractAddress, token_id: u256);
//fn set_approval_for_all(operator: ContractAddress, approved: bool);
//fn get_approved(token_id: u256) -> ContractAddress;
//fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool;
#[test]
fn test_erc721(){
    let contract=deploy(OWNER);
    let ipfs_hash:ByteArray="QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or";
    let nft_id=contract.mint_item(ALICE, ipfs_hash.clone());
    let ierc721_dispatcher:IERC721Dispatcher =IERC721Dispatcher{
        contract_address: contract.contract_address,
    };
    // Check the balance of ALICE
    let balance = ierc721_dispatcher.balance_of(ALICE);
    assert_eq!(balance, 1);
    // Check the owner of the token
    let owner = ierc721_dispatcher.owner_of(nft_id);
    assert_eq!(owner, ALICE);
    // Check the approved address for the token
    cheat_caller_address(contract.contract_address, ALICE, CheatSpan::TargetCalls(1)); 
    ierc721_dispatcher.approve(BOB, nft_id);
    let approved_address = ierc721_dispatcher.get_approved(nft_id);
    assert_eq!(approved_address, BOB);
    cheat_caller_address(contract.contract_address, BOB, CheatSpan::TargetCalls(1)); 
    ierc721_dispatcher.transfer_from(ALICE, BOB, nft_id);
    assert_eq!(ierc721_dispatcher.owner_of(nft_id), BOB);
    cheat_caller_address(contract.contract_address, BOB, CheatSpan::TargetCalls(2));
    let bobs_2ndToken=contract.mint_item(BOB,ipfs_hash.clone());
    // Lets approve ALICE to transfer BOB's token
    ierc721_dispatcher.set_approval_for_all(ALICE,true);

    cheat_caller_address(contract.contract_address, ALICE, CheatSpan::TargetCalls(2));
    ierc721_dispatcher.transfer_from(BOB, ALICE, nft_id);
    ierc721_dispatcher.transfer_from(BOB, ALICE, bobs_2ndToken);
    // Check the balances after transfer
    let alice_balance = ierc721_dispatcher.balance_of(ALICE);
    let bob_balance = ierc721_dispatcher.balance_of(BOB);
    assert_eq!(alice_balance, 2);
    assert_eq!(bob_balance, 0);
    // Check the owner of the token after transfer
    let new_owner = ierc721_dispatcher.owner_of(nft_id);
    assert_eq!(new_owner, ALICE);
    let owner_of_bobs_2ndToken = ierc721_dispatcher.owner_of(bobs_2ndToken);
    assert_eq!(owner_of_bobs_2ndToken, ALICE);
}
// IERC721
//fn safe_transfer_from(
        //from: ContractAddress,
        //to: ContractAddress,
        //token_id: u256,
        //data: Span<felt252>
    //);
#[test]
fn test_safe_transfer_from_to_receiver_contract_success() {
    let (mock_receiver, _) = deploy_mock_contracts();
    let contract = deploy(OWNER);
    let ipfs_hash: ByteArray = "QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or";
    let nft_id = contract.mint_item(ALICE, ipfs_hash.clone());
    let ierc721_dispatcher: IERC721Dispatcher = IERC721Dispatcher{
        contract_address: contract.contract_address,
    };
    
    // Transfer should succeed because mock_receiver implements IERC721Receiver
    cheat_caller_address(contract.contract_address, ALICE, CheatSpan::TargetCalls(1)); 
    ierc721_dispatcher.safe_transfer_from(ALICE, mock_receiver, nft_id, array![].span());
    
    // Verify transfer succeeded
    let new_owner = ierc721_dispatcher.owner_of(nft_id);
    assert_eq!(new_owner, mock_receiver);
}

#[test]
#[should_panic(expected: 'ENTRYPOINT_NOT_FOUND')]
fn test_safe_transfer_from_to_non_receiver_contract_fails() {
    let (_, mock_simple) = deploy_mock_contracts();
    let contract = deploy(OWNER);
    let ipfs_hash: ByteArray = "QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or";
    let nft_id = contract.mint_item(ALICE, ipfs_hash.clone());
    let ierc721_dispatcher: IERC721Dispatcher = IERC721Dispatcher{
        contract_address: contract.contract_address,
    };
    
    // This should panic with 'ERC721: safe transfer failed' 
    // because mock_simple doesn't implement IERC721Receiver
    cheat_caller_address(contract.contract_address, ALICE, CheatSpan::TargetCalls(1)); 
    ierc721_dispatcher.safe_transfer_from(ALICE, mock_simple, nft_id, array![].span());
}

#[test]
#[ignore]
#[should_panic(expected: 'ERC721: token already minted')]
fn test_proof_of_concept(){
    // This test is poc(proof of concept for vulnaerability originated by counter abi expose )
    // remove comment line from abi embed of CounterImpl  
    //  run via "snforge test --ignored"
    
    // deploy and mint for Alice.
    let contract = deploy(OWNER);
    let ipfs_hash:ByteArray="QmVsC32PYDe1cM9zoA8JMninKjeFmHB4xRXi1As2vrv5or";
    let _=contract.mint_item(ALICE,ipfs_hash.clone());
    let counter_dispatcher = ICounterDispatcher{ contract_address: contract.contract_address };
    counter_dispatcher.decrement();
    // this should panic cause contract cant contain already used element.
    let _ = contract.mint_item(BOB,ipfs_hash.clone());
}