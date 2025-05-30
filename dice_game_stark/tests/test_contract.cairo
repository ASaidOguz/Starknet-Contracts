use dice_game_stark::DiceGame::{DiceGame, IDiceGameDispatcherTrait};
use dice_game_stark::RiggedRoll::{IRiggedRollDispatcher, IRiggedRollDispatcherTrait};
use core::keccak::keccak_u256s_le_inputs;
use openzeppelin_testing::declare_and_deploy;
use openzeppelin_token::erc20::interface::IERC20DispatcherTrait;
use openzeppelin_utils::serde::SerializedAppend;
use snforge_std::cheatcodes::events::EventsFilterTrait;
use snforge_std::{
    CheatSpan, EventSpyAssertionsTrait, EventSpyTrait, cheat_caller_address, spy_events,
};
use starknet::{ContractAddress, get_block_number};

const OWNER: ContractAddress = 'OWNER'.try_into().unwrap();

const ROLL_DICE_AMOUNT: u256 = 2000000000000000; // 0.002_STRK_IN_FRI
// Should deploy the MockSTRKToken contract
fn deploy_mock_strk_token() -> ContractAddress {
    let INITIAL_SUPPLY: u256 = 10000000000000000000000000000000; // 100_STRK_IN_FRI
    let reciever = OWNER;
    let mut calldata = array![];
    calldata.append_serde(INITIAL_SUPPLY);
    calldata.append_serde(reciever);
    declare_and_deploy("MockSTRKToken", calldata)
}

// Should deploy the DiceGame contract
fn deploy_dice_game_contract() -> (ContractAddress,ContractAddress) {
    let strk_token_address = deploy_mock_strk_token();
    let mut calldata = array![];
    calldata.append_serde(strk_token_address);
    let dice_game_contract_address = declare_and_deploy("DiceGame", calldata);
    println!("-- Dice Game contract deployed on: 0x{:x}", dice_game_contract_address);
    (dice_game_contract_address,strk_token_address)
}

fn deploy_rigged_roll_contract() -> ContractAddress {
    let (dice_game_contract_address,strk_token_address) = deploy_dice_game_contract();
    let mut calldata = array![];
    calldata.append_serde(dice_game_contract_address);
    calldata.append_serde(strk_token_address);
    calldata.append_serde(OWNER);
    let rigged_roll_contract_address = declare_and_deploy("RiggedRoll", calldata);
    println!("-- Rigged Roll contract deployed on: 0x{:x}", rigged_roll_contract_address);
    rigged_roll_contract_address
}

   // Internal func for Check for zero address...
    fn  _isZeroAddress(address: ContractAddress) -> bool {
        let zero_address:ContractAddress = 0.try_into().unwrap();
        address != zero_address
    }
#[test]
fn test_getters(){
    let rigged_roll_contract= deploy_rigged_roll_contract();
    let rigged_roll_dispatcher = IRiggedRollDispatcher{contract_address:rigged_roll_contract};
    let dice_game_dispatcher = rigged_roll_dispatcher.dice_game_dispatcher();
    let strk_token_dispatcher = rigged_roll_dispatcher.token_dispatcher().contract_address;
    assert(_isZeroAddress(dice_game_dispatcher.contract_address),'diceGameDispatcher cant be 0 ');
    assert(_isZeroAddress(strk_token_dispatcher),'tokenDispatcher cant be 0');
}

#[test]
fn test_rigged_roll() {
   let rigged_roll_contract_address = deploy_rigged_roll_contract();
   let rigged_roll_dispatcher = IRiggedRollDispatcher{contract_address:rigged_roll_contract_address};
   

    let mut expected_roll = 0;
    let dice_game_dispatcher = rigged_roll_dispatcher.dice_game_dispatcher();
    let strk_token_dispatcher = dice_game_dispatcher.strk_token_dispatcher();
    cheat_caller_address(strk_token_dispatcher.contract_address, OWNER, CheatSpan::TargetCalls(2));
    strk_token_dispatcher.transfer(rigged_roll_dispatcher.contract_address, ROLL_DICE_AMOUNT);
    strk_token_dispatcher.transfer(dice_game_dispatcher.contract_address, ROLL_DICE_AMOUNT*10);
    //let dice_game_contract_address = dice_game_dispatcher.contract_address;
    let tester_address = OWNER;
    while true {

        cheat_caller_address(rigged_roll_dispatcher.contract_address, tester_address, CheatSpan::TargetCalls(1));
        let success=rigged_roll_dispatcher.rig_roll_dice(ROLL_DICE_AMOUNT);
        expected_roll=expected_roll+1;
        println!("-- Roll dice not success!");
        if success{
            println!("-- Roll dice success!");
            break;
        }
    }
   let block_no=rigged_roll_dispatcher.get_winning_block();
   assert_eq!(block_no,get_block_number(), "block no incorrect!");
   println!("-- Expected roll: {:?}", expected_roll);
   let hack_contract_balance = rigged_roll_dispatcher.token_dispatcher().balance_of(rigged_roll_contract_address);
   println!("-- Hack contract balance: {:?}", hack_contract_balance);
   println!("-- Roll amount: {:?}", ROLL_DICE_AMOUNT);
   assert(hack_contract_balance == ROLL_DICE_AMOUNT*4/10, 'Balance wrong');
   cheat_caller_address(
            rigged_roll_contract_address, OWNER, CheatSpan::TargetCalls(1),
        );
    let success:bool=rigged_roll_dispatcher.get_prize();
    assert(success, 'Prize transfer failed');
    let owner_balance = rigged_roll_dispatcher.token_dispatcher().balance_of(OWNER);
    println!("-- Owner balance: {:?}", owner_balance);
}