import fs from 'fs/promises';
import path from 'path';

// The response received from the Starknet contract call
const contractResponse = [
  0x0, 0x20, 0xee, 0x0, 0x55, 0x0, 0xc9, 0x0, 0x9d, 0x0, 0x12, 0x0, 0x79, 0x0, 0xc9, 0x0, 0x7a, 0x0, 0x7, 0x0,
  0xb7, 0x0, 0x7e, 0x0, 0x8a, 0x0, 0xd6, 0x0, 0x2e, 0x0, 0xa2, 0x0, 0x44, 0x0, 0xff, 0x0, 0x37, 0x0, 0xf9, 0x0,
  0xad, 0x0, 0xee, 0x0, 0xf1, 0x0, 0x67, 0x0, 0x5c, 0x0, 0x76, 0x0, 0x26, 0x0, 0x43, 0x0, 0xf2, 0x0, 0x2c, 0x0,
  0x4, 0x0, 0x34, 0x0, 0x54, 0x0
];

// Assuming the format: [is_some, length, item1, item2, ..., itemN]
// Let's assume 0x0 is "Some", and 0x20 is the *number of public outputs*, not necessarily the byte length.
// The `actual response data length 64` suggests `contractResponse.slice(2)` has 64 elements.
const expectedSpanLengthFromResponse = contractResponse[1]; // Should be 32 (0x20)
const responseData = contractResponse.slice(2); // The actual data received from the verifier

async function compareHashedMessage() {
  const inputsPath = path.resolve('./../inputs.json'); // Path to your original inputs.json

  let originalInputs;
  try {
    const inputsFileContent = await fs.readFile(inputsPath, 'utf-8');
    originalInputs = JSON.parse(inputsFileContent);
    console.log("Original inputs loaded successfully from inputs.json.");
  } catch (error) {
    console.error(`Error loading or parsing inputs.json: ${error.message}`);
    return; // Exit if inputs cannot be loaded
  }

  // Original hashed_message is an array of 32 decimal bytes
  const originalHashedMessage = originalInputs.hashed_message;
  // Original expected_address is a hex string (felt)
  const originalExpectedAddressHex = originalInputs.expected_address;

  console.log(`\nStarknet Response Info:`);
  console.log(`  Option Indicator: ${contractResponse[0]}`);
  console.log(`  Reported Span Length: ${expectedSpanLengthFromResponse} (0x${expectedSpanLengthFromResponse.toString(16)})`);
  console.log(`  Actual Data Elements in Response: ${responseData.length}`);


  // --- Logic for parsing the 64 felt252s ---
  // If the response data has 64 elements, but your Noir public outputs are:
  // - hashed_message ([u8; 32]) = 32 felts
  // - expected_address (Field) = 1 felt
  // Total expected public outputs = 33 felts.
  // 64 is not 33. This means either:
  // 1. The verifier returns more than just these public inputs.
  // 2. The mapping from Noir types to Starknet felts is different.
  // 3. Your `zk_ecdsa.json` `abi` has more public outputs than expected.

  // Let's first verify how many public inputs Noir expects:
  // A robust way to check public inputs is to run `noir.execute` and inspect its `publicInputs`
  // We'll simulate that to get the expected length and order.

  // Re-creating a minimal Noir execution to get publicInputs structure
  // This requires a working `noir.execute` setup (which you have in generate_vk-calldata.js)
  // For this standalone script, we'll assume the public inputs structure from previous discussions.

  // Public inputs from Noir are usually flattened: [field1, byte0, byte1, ..., field2, ...]
  // For your Noir circuit: `hashed_message: pub [u8; 32], expected_address: Field`
  // Noir's default flattening would make `publicInputs`: [expected_address_felt, byte0_felt, ..., byte31_felt]
  // Which is 1 + 32 = 33 felt252s.

  // Given the 64-element response, let's explore possibilities:
  // POSSIBILITY A: The verifier outputs *all* intermediate felt values (unlikely but possible if badly designed)
  // POSSIBILITY B: The `Span<u256>` is being returned as 32 `u256` values, meaning 64 `felt252`s? This is also illogical for a 32-byte hash.
  // POSSIBILITY C: The `Span<u256>` contains more than just the public outputs, or the public outputs are packed differently.
  // POSSIBILITY D: The `hashed_message` is being returned as 32 `felt252`s, AND `expected_address` as 1 `felt252`, AND *something else* making it 64.

  // Let's assume the 64 elements are the public outputs, and try to extract the `hashed_message` from them.
  // This will require knowing the exact order and packing.
  // If `hashed_message` is the LAST public output and is returned as 32 individual felts,
  // then it would be the LAST 32 elements.
  // If `expected_address` is first (1 felt), then `hashed_message` (32 felts), that's 33 total.

  // The most common reason for a `u256` in Starknet to lead to 64 elements is if you have 32 `u16` values being returned as `felt252`s.
  // Or perhaps your `hashed_message` `[u8; 32]` is somehow expanded.

  // Let's try to slice the last 32 elements of the `responseData` as the `hashed_message`
  // and see if it matches, assuming `hashed_message` is indeed the *last* public output.
  // If your `hashed_message` is 32 bytes, and each byte is a felt, then 32 felts.
  // This would mean there are 32 other felts that we don't account for.

  // Let's check a few assumptions:
  // 1. Is `hashed_message` returned as 32 separate felt252s?
  // 2. What about `expected_address`?

  let receivedHashedMessage = [];
  let receivedExpectedAddress = null;

  // Given that `expected_address` is a `Field` (felt252) and `hashed_message` is `[u8; 32]`
  // and Cairo converts `[u8; N]` to `felt252`s, the public outputs from Noir would be:
  // [expected_address_as_felt, byte0_of_hash_as_felt, ..., byte31_of_hash_as_felt]
  // This is 1 + 32 = 33 felts.

  // The 64 elements is the mystery.

  // Let's assume for a moment that your `Span<u256>` means that it's returning 32 `u256`s for some reason.
  // If each `u256` is composed of 2 `felt252`s, then 32 `u256`s means 64 `felt252`s.
  // This would imply each byte of your `hashed_message` is somehow wrapped into a `u256`!
  // This is highly inefficient and unlikely, but matches the `64` length.

  // If `hashed_message` (32 bytes) is returned as 32 `u256` values (each byte in a separate u256)
  // then that would be 32 * 2 = 64 felt252s.
  // In this case, each pair of `felt252`s would represent one byte, with one felt being 0.
  // E.g., `[0x0, 0xee, 0x0, 0x55, ...]`

  // Let's try to extract 32 bytes from the 64 felt252s, assuming `[0x0, byte_value, 0x0, byte_value, ...]` pattern.
  // This means every second element starting from index 1 (of responseData) would be a byte.

  if (responseData.length === 64) {
    for (let i = 0; i < responseData.length; i += 2) {
      // Check if the first felt of the pair is effectively zero (or the other way around)
      // and the second felt holds the byte value.
      // This pattern is common when a single u8 is cast to a u256 then to felt252 limbs
      // if the higher limb is zero.
      if (Number(responseData[i]) === 0) {
        receivedHashedMessage.push(Number(responseData[i + 1]));
      } else if (Number(responseData[i+1]) === 0) { // Or if the byte is in the first limb
        receivedHashedMessage.push(Number(responseData[i]));
      } else {
        console.warn(`Unexpected non-zero felt pair: [0x${responseData[i].toString(16)}, 0x${responseData[i+1].toString(16)}]`);
        // If both are non-zero, this interpretation is wrong.
        // We'll take the lower 8 bits of the first element as the byte if it's not the exact pattern.
        receivedHashedMessage.push(Number(responseData[i]) & 0xFF);
      }
    }
  } else {
    console.error(`Unexpected response data length: ${responseData.length}. Expected 64 elements for 32 u256-wrapped bytes.`);
    return;
  }

  if (receivedHashedMessage.length !== originalHashedMessage.length) {
    console.error(`After parsing, the length of received hashed message (${receivedHashedMessage.length}) does not match original (${originalHashedMessage.length}).`);
    return;
  }

  console.log("\n--- Comparison ---");
  console.log("Original Hashed Message (decimal bytes):", originalHashedMessage);
  console.log("Received Hashed Message (decimal bytes):  ", receivedHashedMessage);

  // Compare the arrays
  const areEqual = originalHashedMessage.every((val, index) => val === receivedHashedMessage[index]);

  if (areEqual) {
    console.log("\n✅ The received hashed message matches the original hashed message!");
  } else {
    console.log("\n❌ The received hashed message DOES NOT match the original hashed message.");
    console.log("Difference at index (first 5):");
    for (let i = 0; i < Math.min(originalHashedMessage.length, 5); i++) {
        if (originalHashedMessage[i] !== receivedHashedMessage[i]) {
            console.log(`  Index ${i}: Original=${originalHashedMessage[i]}, Received=${receivedHashedMessage[i]}`);
        }
    }
  }
  console.log("-------------------\n");


  // If you also want to check expected_address, you'd need to know its position.
  // It's likely the felt before the hashed_message bytes if Noir outputs it first.
  // But with 64 elements for 33 outputs, it's very non-standard.

  // Let's assume the first 2 elements of `responseData` (if not 0x0, 0x20) are related to expected_address
  // and the next 62 are something else, or that `expected_address` is also packed into `u256`
  // if `u256` is indeed what the Span returns.
  // A `felt252` fits into one `u256` (lower limb), so `expected_address` would also be 2 felts.
  // (1 `u256` for expected_address) + (1 `u256` for hashed_message packed) = 4 felts total.
  // This still doesn't explain 64 felts.

  // **The most plausible explanation for 64 elements is that each of the 32 bytes of `hashed_message`
  // is individually cast to a `u256` (resulting in 2 felts per byte) and then all those `u256`s are
  // put into the `Span`. This would yield 32 * 2 = 64 felts.**
  // If this is the case, `expected_address` might not be returned, or it's somewhere else in the 64.
  // The structure `[0x0, VALUE]` for each byte suggests `VALUE` is the byte and `0x0` is padding.

  // The code above now implements this interpretation (taking every second element as the byte value).
}

compareHashedMessage().catch(err => {
  console.error("Error during comparison:", err);
});