
use zk_ecdsa_verify::honk_verifier::{IUltraStarknetHonkVerifierDispatcher,
                                    IUltraStarknetHonkVerifierDispatcherTrait};

use openzeppelin_testing::declare_and_deploy;
use snforge_std::fs::{FileTrait,read_txt};

fn deploy_verifier() -> IUltraStarknetHonkVerifierDispatcher {
    let mut empty_calldata = array![];
    let verifier_address = declare_and_deploy("UltraStarknetHonkVerifier",empty_calldata);
    IUltraStarknetHonkVerifierDispatcher{contract_address:verifier_address}
}

fn prepare_calldata(path:ByteArray) -> Span<felt252>{
    let formatted_calldata = FileTrait::new(path);
    let calldata = read_txt(@formatted_calldata);
    calldata.span()
}

#[test]
fn test_ultrahonkverifier_verify_proof() {
    let verifier = deploy_verifier();
    let proof_calldata = prepare_calldata("../calldata_formatted.txt");
    
    let response = verifier.verify_ultra_starknet_honk_proof(proof_calldata);
    // Assert that response is Some (not None)
    assert!(response.is_some(), "Proof verification failed - returned None");
      
}
