use dep::ecrecover;

fn main(
  pub_key_x: [u8; 32],
  pub_key_y: [u8; 32],
  signature: [u8; 64],
  hashed_message: pub [u8; 32],
  expected_address: Field
) {
   // Extract s value from signature (second 32 bytes)
  let mut s_bytes: [u8; 32] = [0; 32];
  for i in 0..32 {
    s_bytes[i] = signature[i + 32];
  }
    // secp256k1 curve order / 2
 let max_s_bytes: [u8; 32] = [
    0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0x5D, 0x57, 0x6E, 0x73, 0x57, 0xA4, 0x50, 0x1D,
    0xDF, 0xE9, 0x2F, 0x46, 0x68, 0x1B, 0x20, 0xA0
  ];

  // signature mallability check ;
  assert(bytes_less_than_or_equal(s_bytes, max_s_bytes) == 1,"signature invalid");

  let address = ecrecover::ecrecover(pub_key_x, pub_key_y, signature, hashed_message);
  assert(address == expected_address,"address incorrect");
}

// Helper function to compare two 32-byte arrays (big-endian)
// Returns 1 if a <= b, 0 if a > b
fn bytes_less_than_or_equal(a: [u8; 32], b: [u8; 32]) -> u8 {
  let mut result = 1; // assume equal (a <= b)
  let mut found_difference = 0;
  
  for i in 0..32 {
    if (found_difference == 0) {
      if a[i] < b[i] {
        result = 1; // a < b, so a <= b
        found_difference = 1;
      } else if a[i] > b[i] {
        result = 0; // a > b
        found_difference = 1;
      }
      // if equal, keep looking
    }
  }
  
  result
}