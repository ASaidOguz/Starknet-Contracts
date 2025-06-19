#!/bin/bash
# change input to input_mal to use dirty signature.
input_file="input_mal.txt" # Your original input source (e.g., key=value pairs)
output_toml_file="Prover.toml"
output_json_file="inputs.json" # New: for JavaScript consumption

# Extract only the value inside quotes for a given key
extract_value() {
    local key=$1
    # Extract the part inside quotes after the equals sign
    grep "^$key\s*=" "$input_file" | sed -E 's/^[^=]+= *"(.*)"/\1/'
}

# Convert hex string (without 0x) to quoted decimal byte array for Prover.toml
# e.g., "0xab" -> ["171"]
hex_to_dec_quoted_array_toml() {
    local hexstr=$1
    local len=${#hexstr}
    local arr=()
    for (( i=0; i<len; i+=2 )); do
        local hexbyte="${hexstr:i:2}"
        local dec=$((16#$hexbyte))
        arr+=("\"$dec\"") # Quoted decimal string for TOML
    done
    echo "["$(IFS=,; echo "${arr[*]}")"]"
}

# Convert hex string (without 0x) to decimal byte array for JSON
# e.g., "0xab" -> [171]
hex_to_dec_array_json() {
    local hexstr=$1
    local len=${#hexstr}
    local arr=()
    for (( i=0; i<len; i+=2 )); do
        local hexbyte="${hexstr:i:2}"
        local dec=$((16#$hexbyte))
        arr+=("$dec") # Decimal number for JSON (not quoted)
    done
    echo "["$(IFS=,; echo "${arr[*]}")"]"
}


# Read values from file
expected_address_raw=$(extract_value expected_address)
hashed_message_raw=$(extract_value hashed_message)
pub_key_x_raw=$(extract_value pub_key_x)
pub_key_y_raw=$(extract_value pub_key_y)
signature_raw=$(extract_value signature)

# Strip 0x from everything except expected_address (for processing)
hashed_message_clean=${hashed_message_raw#0x}
pub_key_x_clean=${pub_key_x_raw#0x}
pub_key_y_clean=${pub_key_y_raw#0x}
signature_clean=${signature_raw#0x}

# Strip last byte (2 hex chars) from signature to remove v (for processing)
signature_processed=${signature_clean:0:${#signature_clean}-2}

# --- Prepare for Prover.toml ---
# Convert hex strings to decimal quoted arrays for TOML
hashed_message_arr_toml=$(hex_to_dec_quoted_array_toml "$hashed_message_clean")
pub_key_x_arr_toml=$(hex_to_dec_quoted_array_toml "$pub_key_x_clean")
pub_key_y_arr_toml=$(hex_to_dec_quoted_array_toml "$pub_key_y_clean")
signature_arr_toml=$(hex_to_dec_quoted_array_toml "$signature_processed")

# Write Prover.toml
cat > "$output_toml_file" <<EOF
expected_address = "$expected_address_raw"
hashed_message = $hashed_message_arr_toml
pub_key_x = $pub_key_x_arr_toml
pub_key_y = $pub_key_y_arr_toml
signature = $signature_arr_toml
EOF
echo "Wrote $output_toml_file"

# --- Prepare for inputs.json ---
# Convert hex strings to decimal arrays for JSON (no quotes around numbers)
hashed_message_arr_json=$(hex_to_dec_array_json "$hashed_message_clean")
pub_key_x_arr_json=$(hex_to_dec_array_json "$pub_key_x_clean")
pub_key_y_arr_json=$(hex_to_dec_array_json "$pub_key_y_clean")
signature_arr_json=$(hex_to_dec_array_json "$signature_processed")


# Write inputs.json
cat > "$output_json_file" <<EOF
{
  "expected_address": "$expected_address_raw",
  "hashed_message": $hashed_message_arr_json,
  "pub_key_x": $pub_key_x_arr_json,
  "pub_key_y": $pub_key_y_arr_json,
  "signature": $signature_arr_json
}
EOF
echo "Wrote $output_json_file"