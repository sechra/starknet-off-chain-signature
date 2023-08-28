use box::BoxTrait;
use hash::LegacyHash;
use starknet::{
    contract_address_const, get_tx_info, get_caller_address, testing::set_caller_address
};

// sn_keccak('StarkNetDomain(name:felt,version:felt,chainId:felt)')
const STARKNET_DOMAIN_TYPE_HASH: felt252 =
    selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)");

// sn_keccak('SimpleStruct(some_felt252:felt,some_u128:felt)')                                                                          
const SIMPLE_STRUCT_TYPE_HASH: felt252 =
    selector!("SimpleStruct(some_felt252:felt,some_u128:u128)");

#[derive(Drop, Copy)]
struct SimpleStruct {
    some_felt252: felt252,
    some_u128: u128,
}

#[derive(Drop, Copy)]
struct StarknetDomain {
    name: felt252,
    version: felt252,
    chain_id: felt252,
}

trait IStructHash<T> {
    fn hash_struct(self: @T) -> felt252;
}

trait IOffchainMessageHash<T> {
    fn get_message_hash(self: @T) -> felt252;
}

impl OffchainMessageHashSimpleStruct of IOffchainMessageHash<SimpleStruct> {
    fn get_message_hash(self: @SimpleStruct) -> felt252 {
        let domain = StarknetDomain {
            name: 'dappName', version: 1, chain_id: get_tx_info().unbox().chain_id
        };
        let mut state = LegacyHash::hash(0, 'StarkNet Message');
        state = LegacyHash::hash(state, domain.hash_struct());
        // This can be a field within the struct, it doesn't have to be get_caller_address().
        state = LegacyHash::hash(state, get_caller_address());
        state = LegacyHash::hash(state, self.hash_struct());
        // Hashing with the amount of elements being hashed 
        state = LegacyHash::hash(state, 4);
        state
    }
}

impl StructHashStarknetDomain of IStructHash<StarknetDomain> {
    fn hash_struct(self: @StarknetDomain) -> felt252 {
        let mut state = LegacyHash::hash(0, STARKNET_DOMAIN_TYPE_HASH);
        state = LegacyHash::hash(state, *self.name);
        state = LegacyHash::hash(state, *self.version);
        state = LegacyHash::hash(state, *self.chain_id);
        state = LegacyHash::hash(state, 4);
        state
    }
}

impl StructHashSimpleStruct of IStructHash<SimpleStruct> {
    fn hash_struct(self: @SimpleStruct) -> felt252 {
        let mut state = LegacyHash::hash(0, SIMPLE_STRUCT_TYPE_HASH);
        state = LegacyHash::hash(state, *self.some_felt252);
        state = LegacyHash::hash(state, *self.some_u128);
        state = LegacyHash::hash(state, 3);
        state
    }
}

#[test]
#[available_gas(2000000)]
fn test_valid_hash() {
    // This value was computed using StarknetJS
    let simple_struct_hashed = 0x1e739b39f83b38f182edaed69f730f18eff802d3ef44be91c3733cdcab6de2f;
    let simple_struct = SimpleStruct { some_felt252: 712, some_u128: 42 };
    set_caller_address(contract_address_const::<420>());
    assert(simple_struct.get_message_hash() == simple_struct_hashed, 'Hash should be valid');
}
