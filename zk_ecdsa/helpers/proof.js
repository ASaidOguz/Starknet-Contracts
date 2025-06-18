function flattenFieldsAsArray(fields) {
  const flattenedPublicInputs = fields.map(hexToUint8Array);
  return flattenUint8Arrays(flattenedPublicInputs);
}

function flattenUint8Arrays(arrays) {
  const totalLength = arrays.reduce((acc, val) => acc + val.length, 0);
  const result = new Uint8Array(totalLength);

  let offset = 0;
  for (const arr of arrays) {
    result.set(arr, offset);
    offset += arr.length;
  }

  return result;
}

function hexToUint8Array(hex) {
  // If input is hex string with '0x' prefix, strip it
  if (hex.startsWith('0x') || hex.startsWith('0X')) {
    hex = hex.slice(2);
  }

  // Pad to even length (so we don't get invalid parseInt ranges)
  if (hex.length % 2 !== 0) {
    hex = '0' + hex;
  }

  const len = hex.length / 2;
  const u8 = new Uint8Array(len);

  for (let i = 0; i < len; i++) {
    u8[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  }

  return u8;
}

export { flattenFieldsAsArray, hexToUint8Array, flattenUint8Arrays };


// Example usage:

// let fields = ["0x1234", "0xabcd", "0xdeadbeef"];
// let result = flattenFieldsAsArray(fields);
// console.log(result);