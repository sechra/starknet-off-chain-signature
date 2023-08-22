import { selector, typedData } from "starknet";

const types = {
  StarkNetDomain: [
    { name: "name", type: "felt" },
    { name: "version", type: "felt" },
    { name: "chainId", type: "felt" },
  ],
  StructWithEnum: [
    { name: "some_felt252", type: "felt" },
    { name: "some_complex_enum", type: "felt*" },
  ],
};

interface StructWithEnum {
  some_felt252: string;
  some_complex_enum: string[];
}

function getDomain(chainId: string): typedData.StarkNetDomain {
  return {
    name: "dappName",
    version: "1",
    chainId,
  };
}

function getTypedDataHash(myStruct: StructWithEnum, chainId: string, owner: bigint): string {
  return typedData.getMessageHash(getTypedData(myStruct, chainId), owner);
}

// Needed to reproduce the same structure as:
// https://github.com/0xs34n/starknet.js/blob/1a63522ef71eed2ff70f82a886e503adc32d4df9/__mocks__/typedDataStructArrayExample.json
function getTypedData(myStruct: StructWithEnum, chainId: string): typedData.TypedData {
  return {
    types,
    primaryType: "StructWithEnum",
    domain: getDomain(chainId),
    message: { ...myStruct },
  };
}
const structWithEnum: StructWithEnum = {
  some_felt252: "712",
  some_complex_enum: [selector.getSelectorFromName("SomeEnum::ThirdChoice(felt,felt)"), "42", "128"],
};

// h('StarkNetDomain(name:felt,version:felt,chainId:felt)')
console.log(`const STARKNET_DOMAIN_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StarkNetDomain")};`);
console.log(`const ENUM_FIRST_CHOICE_TYPE_HASH: felt252 = ${selector.getSelectorFromName("SomeEnum::FirstChoice()")};`);
console.log(
  `const ENUM_SECOND_CHOICE_TYPE_HASH: felt252 = ${selector.getSelectorFromName("SomeEnum::SecondChoice(felt)")};`,
);
console.log(
  `const ENUM_THIRD_CHOICE_TYPE_HASH: felt252 = ${selector.getSelectorFromName("SomeEnum::ThirdChoice(felt,felt)")};`,
);
console.log(`const STRUCT_WITH_ENUM_TYPE_HASH: felt252 = ${typedData.getTypeHash(types, "StructWithEnum")};`);

console.log(`test test_valid_hash ${getTypedDataHash(structWithEnum, "0", 420n)};`);
