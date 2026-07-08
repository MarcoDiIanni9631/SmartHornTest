:- dynamic at/2.
:- discontiguous at/2.
:- discontiguous nextlab/2.
% RewardStateVar_10.sol:RewardSystem contract
signatures([('external_fun_claimRewards_67', '0x0962ef7900000000000000000000000000000000000000000000000000000000'), ('external_fun_currentBalance_3', '0xce845d1d00000000000000000000000000000000000000000000000000000000')]).

globals([0x00]).
memory([0x00, 0x04, 0x40, 0x80, 0x128, 0xa0, 0xc0, 0xe0]).
fun(obj_allocate_unbounded, [], [var(v2)], 'obj_allocate_unbounded_Block0_1').
fun(obj_constructor_RewardSystem_68, [], [], 'obj_constructor_RewardSystem_68_ret').
fun(obj_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [], 'obj_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb_Block0_1').
fun(subO_abi_decode_t_uint256, [var(v0), var(v1)], [var(v3)], 'subO_abi_decode_t_uint256_Block0_1').
fun(subO_abi_decode_tuple_, [var(v0), var(v1)], [var(v3), var(v4)], 'subO_abi_decode_tuple__Block0_1').
fun(subO_abi_decode_tuple_t_uint256, [var(v0), var(v1)], [var(v12), var(v4), var(v5), var(v11)], 'subO_abi_decode_tuple_t_uint256_Block0_1').
fun(subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack, [var(v0)], [var(v3), var(v4)], 'subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_Block0_1').
fun(subO_abi_encode_t_uint256_to_t_uint256_fromStack, [var(v0), var(v1)], [var(v2)], 'subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_1').
fun(subO_abi_encode_tuple__to__fromStack, [var(v0)], [var(v2)], 'subO_abi_encode_tuple__to__fromStack_Block0_1').
fun(subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack, [var(v0)], [var(v6), var(v3), var(v4), var(v5)], 'subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_1').
fun(subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack, [var(v0), var(v1)], [var(v4), var(v5)], 'subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_Block0_1').
fun(subO_allocate_unbounded, [], [var(v2)], 'subO_allocate_unbounded_Block0_1').
fun(subO_array_storeLengthForEncoding_t_string_memory_ptr_fromStack, [var(v0), var(v1)], [var(v4)], 'subO_array_storeLengthForEncoding_t_string_memory_ptr_fromStack_Block0_1').
fun(subO_assert_helper, [var(v0)], [var(v1)], 'subO_assert_helper_Block0_1').
fun(subO_checked_add_t_uint256, [var(v0), var(v1)], [var(v6), var(v3), var(v4), var(v5)], 'subO_checked_add_t_uint256_Block0_1').
fun(subO_checked_mul_t_uint256, [var(v0), var(v1)], [var(v9), var(v3), var(v4), var(v5), var(v8), var(v7), var(v11), var(v10), var(v6)], 'subO_checked_mul_t_uint256_Block0_1').
fun(subO_cleanup_from_storage_t_uint256, [var(v0)], [], 'subO_cleanup_from_storage_t_uint256_ret').
fun(subO_cleanup_t_rational_0_by_1, [var(v0)], [], 'subO_cleanup_t_rational_0_by_1_ret').
fun(subO_cleanup_t_rational_1042_by_1, [var(v0)], [], 'subO_cleanup_t_rational_1042_by_1_ret').
fun(subO_cleanup_t_rational_10_by_1, [var(v0)], [], 'subO_cleanup_t_rational_10_by_1_ret').
fun(subO_cleanup_t_rational_20_by_1, [var(v0)], [], 'subO_cleanup_t_rational_20_by_1_ret').
fun(subO_cleanup_t_rational_2_by_1, [var(v0)], [], 'subO_cleanup_t_rational_2_by_1_ret').
fun(subO_cleanup_t_rational_42_by_1, [var(v0)], [], 'subO_cleanup_t_rational_42_by_1_ret').
fun(subO_cleanup_t_rational_5_by_1, [var(v0)], [], 'subO_cleanup_t_rational_5_by_1_ret').
fun(subO_cleanup_t_uint256, [var(v0)], [], 'subO_cleanup_t_uint256_ret').
fun(subO_convert_t_rational_0_by_1_to_t_uint256, [var(v0)], [var(v3), var(v4), var(v2)], 'subO_convert_t_rational_0_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_1042_by_1_to_t_uint256, [var(v0)], [var(v3), var(v4), var(v2)], 'subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_10_by_1_to_t_uint256, [var(v0)], [var(v3), var(v4), var(v2)], 'subO_convert_t_rational_10_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_20_by_1_to_t_uint256, [var(v0)], [var(v3), var(v4), var(v2)], 'subO_convert_t_rational_20_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_2_by_1_to_t_uint256, [var(v0)], [var(v3), var(v4), var(v2)], 'subO_convert_t_rational_2_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_42_by_1_to_t_uint256, [var(v0)], [var(v3), var(v4), var(v2)], 'subO_convert_t_rational_42_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_5_by_1_to_t_uint256, [var(v0)], [var(v3), var(v4), var(v2)], 'subO_convert_t_rational_5_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_uint256_to_t_uint256, [var(v0)], [var(v3), var(v4), var(v2)], 'subO_convert_t_uint256_to_t_uint256_Block0_1').
fun(subO_external_fun_claimRewards_67, [], [var(v0), var(v3), var(v4), var(v5), var(v6), var(v1)], 'subO_external_fun_claimRewards_67_Block0_1').
fun(subO_external_fun_currentBalance_3, [], [var(v0), var(v3), var(v4), var(v5), var(v6), var(v1)], 'subO_external_fun_currentBalance_3_Block0_1').
fun(subO_extract_from_storage_value_dynamict_uint256, [var(v0), var(v1)], [var(v6), var(v4), var(v5)], 'subO_extract_from_storage_value_dynamict_uint256_Block0_1').
fun(subO_extract_from_storage_value_offset_0_t_uint256, [var(v0)], [var(v3), var(v2)], 'subO_extract_from_storage_value_offset_0_t_uint256_Block0_1').
fun(subO_fun_claimRewards_67, [var(v0)], [var(v9), var(v29), var(v41), var(v16), var(v36), var(v4), var(v39), var(v8), var(v33), var(v19), var(v22), var(v2), var(v12), var(v42), var(v15), var(v24), var(v6), var(v17), var(v35), var(v21), var(v3), var(v32), var(v14), var(v23), var(v43), var(v11), var(v10), var(v28), var(v37)], 'subO_fun_claimRewards_67_Block0_1').
fun(subO_getter_fun_currentBalance_3, [], [var(v1)], 'subO_getter_fun_currentBalance_3_Block0_1').
fun(subO_identity, [var(v0)], [], 'subO_identity_ret').
fun(subO_increment_wrapping_t_uint256, [var(v0)], [var(v3), var(v4)], 'subO_increment_wrapping_t_uint256_Block0_1').
fun(subO_panic_error_0x01, [], [], 'subO_panic_error_0x01_Block0_1').
fun(subO_panic_error_0x11, [], [], 'subO_panic_error_0x11_Block0_1').
fun(subO_prepare_store_t_uint256, [var(v0)], [], 'subO_prepare_store_t_uint256_ret').
fun(subO_read_from_storage_split_dynamic_t_uint256, [var(v0), var(v1)], [var(v3), var(v4)], 'subO_read_from_storage_split_dynamic_t_uint256_Block0_1').
fun(subO_read_from_storage_split_offset_0_t_uint256, [var(v0)], [var(v3), var(v2)], 'subO_read_from_storage_split_offset_0_t_uint256_Block0_1').
fun(subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7, [var(v0)], [var(v5), var(v7), var(v6), var(v1), var(v2)], 'subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_1').
fun(subO_revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74, [], [], 'subO_revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74_Block0_1').
fun(subO_revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db, [], [], 'subO_revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db_Block0_1').
fun(subO_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [], 'subO_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb_Block0_1').
fun(subO_revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b, [], [], 'subO_revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b_Block0_1').
fun(subO_shift_left_0, [var(v0)], [var(v2)], 'subO_shift_left_0_Block0_1').
fun(subO_shift_right_0_unsigned, [var(v0)], [var(v2)], 'subO_shift_right_0_unsigned_Block0_1').
fun(subO_shift_right_224_unsigned, [var(v0)], [var(v3)], 'subO_shift_right_224_unsigned_Block0_1').
fun(subO_shift_right_unsigned_dynamic, [var(v0), var(v1)], [var(v3)], 'subO_shift_right_unsigned_dynamic_Block0_1').
fun(subO_store_literal_in_memory_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7, [var(v0)], [var(v3)], 'subO_store_literal_in_memory_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_1').
fun(subO_update_byte_slice_32_shift_0, [var(v0), var(v1)], [var(v4), var(v5), var(v8), var(v7), var(v6)], 'subO_update_byte_slice_32_shift_0_Block0_1').
fun(subO_update_storage_value_offset_0_t_uint256_to_t_uint256, [var(v0), var(v1)], [var(v3), var(v5), var(v4), var(v2)], 'subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_1').
fun(subO_validator_revert_t_uint256, [var(v0)], [var(v3), var(v1), var(v2)], 'subO_validator_revert_t_uint256_Block0_1').
fun(r_RewardSystem_68_deployed, [], [var(v0), var(v9), var(v3), var(v4), var(v5), var(v8), var(v7), var(v11)], 'RewardSystem_68_deployed_Block0_1').
fun(init_contract, [], [var(v0), var(v3), var(v4), var(v5), var(v6), var(v2)], 'init_contract_Block0_1').

% Combined at and nextlab relations
at('obj_allocate_unbounded_Block0_1', asgn(var(v2), expr(mload([mem(0x40)])))).
nextlab('obj_allocate_unbounded_Block0_1', 'obj_allocate_unbounded_ret').
at('obj_allocate_unbounded_ret', ret([var(v2)])).
at('obj_constructor_RewardSystem_68_ret', ret([])).
at('obj_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb_Block0_1', revert([num(0x00), mem(0x00)])).
at('subO_abi_decode_t_uint256_Block0_1', asgn(var(v3), expr(calldataload([var(v0)])))).
nextlab('subO_abi_decode_t_uint256_Block0_1', 'subO_abi_decode_t_uint256_Block0_2').
at('subO_abi_decode_t_uint256_Block0_2', fun_call(subO_validator_revert_t_uint256, [var(v3)], [])).
nextlab('subO_abi_decode_t_uint256_Block0_2', 'subO_abi_decode_t_uint256_ret').
at('subO_abi_decode_t_uint256_ret', ret([var(v3)])).
at('subO_abi_decode_tuple__Block0_1', asgn(var(v3), expr(sub([var(v0), var(v1)])))).
nextlab('subO_abi_decode_tuple__Block0_1', 'subO_abi_decode_tuple__Block0_2').
at('subO_abi_decode_tuple__Block0_2', asgn(var(v4), expr(slt([num(0x00), var(v3)])))).
nextlab('subO_abi_decode_tuple__Block0_2', 'subO_abi_decode_tuple__Block0_3').
at('subO_abi_decode_tuple__Block0_3', cj(var(v4), 'subO_abi_decode_tuple__ret', 'subO_abi_decode_tuple__Block1_1')).
at('subO_abi_decode_tuple__ret', ret([])).
at('subO_abi_decode_tuple__Block1_1', fun_call(subO_revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b, [], [])).
at('subO_abi_decode_tuple_t_uint256_Block0_1', asgn(var(v4), expr(sub([var(v0), var(v1)])))).
nextlab('subO_abi_decode_tuple_t_uint256_Block0_1', 'subO_abi_decode_tuple_t_uint256_Block0_2').
at('subO_abi_decode_tuple_t_uint256_Block0_2', asgn(var(v5), expr(slt([num(0x20), var(v4)])))).
nextlab('subO_abi_decode_tuple_t_uint256_Block0_2', 'subO_abi_decode_tuple_t_uint256_Block0_3').
at('subO_abi_decode_tuple_t_uint256_Block0_3', cj(var(v5), 'subO_abi_decode_tuple_t_uint256_Block2_1', 'subO_abi_decode_tuple_t_uint256_Block1_1')).
at('subO_abi_decode_tuple_t_uint256_Block2_1', asgn(var(v11), expr(add([num(0x00), var(v0)])))).
nextlab('subO_abi_decode_tuple_t_uint256_Block2_1', 'subO_abi_decode_tuple_t_uint256_Block2_2').
at('subO_abi_decode_tuple_t_uint256_Block2_2', fun_call(subO_abi_decode_t_uint256, [var(v1), var(v11)], [var(v12)])).
nextlab('subO_abi_decode_tuple_t_uint256_Block2_2', 'subO_abi_decode_tuple_t_uint256_ret').
at('subO_abi_decode_tuple_t_uint256_ret', ret([var(v12)])).
at('subO_abi_decode_tuple_t_uint256_Block1_1', fun_call(subO_revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b, [], [])).
at('subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_Block0_1', fun_call(subO_array_storeLengthForEncoding_t_string_memory_ptr_fromStack, [num(0x20), var(v0)], [var(v3)])).
nextlab('subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_Block0_1', 'subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_Block0_2').
at('subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_Block0_2', fun_call(subO_store_literal_in_memory_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7, [var(v3)], [])).
nextlab('subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_Block0_2', 'subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_Block0_3').
at('subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_Block0_3', asgn(var(v4), expr(add([num(0x20), var(v3)])))).
nextlab('subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_Block0_3', 'subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_ret').
at('subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack_ret', ret([var(v4)])).
at('subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_1', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v2)])).
nextlab('subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_1', 'subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_2').
at('subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_2', mstore([var(v2), var(v1)])).
nextlab('subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_2', 'subO_abi_encode_t_uint256_to_t_uint256_fromStack_ret').
at('subO_abi_encode_t_uint256_to_t_uint256_fromStack_ret', ret([])).
at('subO_abi_encode_tuple__to__fromStack_Block0_1', asgn(var(v2), expr(add([num(0x00), var(v0)])))).
nextlab('subO_abi_encode_tuple__to__fromStack_Block0_1', 'subO_abi_encode_tuple__to__fromStack_ret').
at('subO_abi_encode_tuple__to__fromStack_ret', ret([var(v2)])).
at('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_1', asgn(var(v3), expr(add([num(0x20), var(v0)])))).
nextlab('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_1', 'subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_2').
at('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_2', asgn(var(v4), expr(sub([var(v0), var(v3)])))).
nextlab('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_2', 'subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_3').
at('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_3', asgn(var(v5), expr(add([num(0x00), var(v0)])))).
nextlab('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_3', 'subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_4').
at('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_4', mstore([var(v4), var(v5)])).
nextlab('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_4', 'subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_5').
at('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_5', fun_call(subO_abi_encode_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_to_t_string_memory_ptr_fromStack, [var(v3)], [var(v6)])).
nextlab('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_Block0_5', 'subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_ret').
at('subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack_ret', ret([var(v6)])).
at('subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_Block0_1', asgn(var(v4), expr(add([num(0x20), var(v0)])))).
nextlab('subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_Block0_1', 'subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_Block0_2').
at('subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_Block0_2', asgn(var(v5), expr(add([num(0x00), var(v0)])))).
nextlab('subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_Block0_2', 'subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_Block0_3').
at('subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_Block0_3', fun_call(subO_abi_encode_t_uint256_to_t_uint256_fromStack, [var(v5), var(v1)], [])).
nextlab('subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_Block0_3', 'subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_ret').
at('subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_ret', ret([var(v4)])).
at('subO_allocate_unbounded_Block0_1', asgn(var(v2), expr(mload([mem(0x40)])))).
nextlab('subO_allocate_unbounded_Block0_1', 'subO_allocate_unbounded_ret').
at('subO_allocate_unbounded_ret', ret([var(v2)])).
at('subO_array_storeLengthForEncoding_t_string_memory_ptr_fromStack_Block0_1', mstore([var(v1), var(v0)])).
nextlab('subO_array_storeLengthForEncoding_t_string_memory_ptr_fromStack_Block0_1', 'subO_array_storeLengthForEncoding_t_string_memory_ptr_fromStack_Block0_2').
at('subO_array_storeLengthForEncoding_t_string_memory_ptr_fromStack_Block0_2', asgn(var(v4), expr(add([num(0x20), var(v0)])))).
nextlab('subO_array_storeLengthForEncoding_t_string_memory_ptr_fromStack_Block0_2', 'subO_array_storeLengthForEncoding_t_string_memory_ptr_fromStack_ret').
at('subO_array_storeLengthForEncoding_t_string_memory_ptr_fromStack_ret', ret([var(v4)])).
at('subO_assert_helper_Block0_1', asgn(var(v1), expr(iszero([var(v0)])))).
nextlab('subO_assert_helper_Block0_1', 'subO_assert_helper_Block0_2').
at('subO_assert_helper_Block0_2', cj(var(v1), 'subO_assert_helper_ret', 'subO_assert_helper_Block1_1')).
at('subO_assert_helper_ret', ret([])).
at('subO_assert_helper_Block1_1', fun_call(subO_panic_error_0x01, [], [])).
at('subO_checked_add_t_uint256_Block0_1', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v3)])).
nextlab('subO_checked_add_t_uint256_Block0_1', 'subO_checked_add_t_uint256_Block0_2').
at('subO_checked_add_t_uint256_Block0_2', fun_call(subO_cleanup_t_uint256, [var(v1)], [var(v4)])).
nextlab('subO_checked_add_t_uint256_Block0_2', 'subO_checked_add_t_uint256_Block0_3').
at('subO_checked_add_t_uint256_Block0_3', asgn(var(v5), expr(add([var(v4), var(v3)])))).
nextlab('subO_checked_add_t_uint256_Block0_3', 'subO_checked_add_t_uint256_Block0_4').
at('subO_checked_add_t_uint256_Block0_4', asgn(var(v6), expr(gt([var(v5), var(v3)])))).
nextlab('subO_checked_add_t_uint256_Block0_4', 'subO_checked_add_t_uint256_Block0_5').
at('subO_checked_add_t_uint256_Block0_5', cj(var(v6), 'subO_checked_add_t_uint256_ret', 'subO_checked_add_t_uint256_Block1_1')).
at('subO_checked_add_t_uint256_ret', ret([var(v5)])).
at('subO_checked_add_t_uint256_Block1_1', fun_call(subO_panic_error_0x11, [], [])).
at('subO_checked_mul_t_uint256_Block0_1', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v3)])).
nextlab('subO_checked_mul_t_uint256_Block0_1', 'subO_checked_mul_t_uint256_Block0_2').
at('subO_checked_mul_t_uint256_Block0_2', fun_call(subO_cleanup_t_uint256, [var(v1)], [var(v4)])).
nextlab('subO_checked_mul_t_uint256_Block0_2', 'subO_checked_mul_t_uint256_Block0_3').
at('subO_checked_mul_t_uint256_Block0_3', asgn(var(v5), expr(mul([var(v4), var(v3)])))).
nextlab('subO_checked_mul_t_uint256_Block0_3', 'subO_checked_mul_t_uint256_Block0_4').
at('subO_checked_mul_t_uint256_Block0_4', fun_call(subO_cleanup_t_uint256, [var(v5)], [var(v6)])).
nextlab('subO_checked_mul_t_uint256_Block0_4', 'subO_checked_mul_t_uint256_Block0_5').
at('subO_checked_mul_t_uint256_Block0_5', asgn(var(v7), expr(div([var(v3), var(v6)])))).
nextlab('subO_checked_mul_t_uint256_Block0_5', 'subO_checked_mul_t_uint256_Block0_6').
at('subO_checked_mul_t_uint256_Block0_6', asgn(var(v8), expr(eq([var(v7), var(v4)])))).
nextlab('subO_checked_mul_t_uint256_Block0_6', 'subO_checked_mul_t_uint256_Block0_7').
at('subO_checked_mul_t_uint256_Block0_7', asgn(var(v9), expr(iszero([var(v3)])))).
nextlab('subO_checked_mul_t_uint256_Block0_7', 'subO_checked_mul_t_uint256_Block0_8').
at('subO_checked_mul_t_uint256_Block0_8', asgn(var(v10), expr(or([var(v8), var(v9)])))).
nextlab('subO_checked_mul_t_uint256_Block0_8', 'subO_checked_mul_t_uint256_Block0_9').
at('subO_checked_mul_t_uint256_Block0_9', asgn(var(v11), expr(iszero([var(v10)])))).
nextlab('subO_checked_mul_t_uint256_Block0_9', 'subO_checked_mul_t_uint256_Block0_10').
at('subO_checked_mul_t_uint256_Block0_10', cj(var(v11), 'subO_checked_mul_t_uint256_ret', 'subO_checked_mul_t_uint256_Block1_1')).
at('subO_checked_mul_t_uint256_ret', ret([var(v6)])).
at('subO_checked_mul_t_uint256_Block1_1', fun_call(subO_panic_error_0x11, [], [])).
at('subO_cleanup_from_storage_t_uint256_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_0_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_1042_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_10_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_20_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_2_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_42_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_5_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_uint256_ret', ret([var(v0)])).
at('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_0_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_0_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_0_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_0_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_0_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_1042_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_1042_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_1042_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_10_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_10_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_10_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_10_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_10_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_10_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_10_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_10_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_10_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_10_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_10_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_20_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_20_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_20_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_20_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_20_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_20_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_20_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_20_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_20_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_20_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_20_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_2_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_2_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_2_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_2_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_2_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_42_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_42_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_42_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_42_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_42_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_42_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_42_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_42_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_42_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_42_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_42_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_5_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_5_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_5_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_5_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_5_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_5_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_5_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_5_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_5_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_5_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_5_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_uint256_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_uint256_to_t_uint256_Block0_1', 'subO_convert_t_uint256_to_t_uint256_Block0_2').
at('subO_convert_t_uint256_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_uint256_to_t_uint256_Block0_2', 'subO_convert_t_uint256_to_t_uint256_Block0_3').
at('subO_convert_t_uint256_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_uint256_to_t_uint256_Block0_3', 'subO_convert_t_uint256_to_t_uint256_ret').
at('subO_convert_t_uint256_to_t_uint256_ret', ret([var(v4)])).
at('subO_external_fun_claimRewards_67_Block0_1', asgn(var(v0), expr(callvalue))).
nextlab('subO_external_fun_claimRewards_67_Block0_1', 'subO_external_fun_claimRewards_67_Block0_2').
at('subO_external_fun_claimRewards_67_Block0_2', cj(var(v0), 'subO_external_fun_claimRewards_67_Block2_1', 'subO_external_fun_claimRewards_67_Block1_1')).
at('subO_external_fun_claimRewards_67_Block2_1', asgn(var(v1), expr(calldatasize))).
nextlab('subO_external_fun_claimRewards_67_Block2_1', 'subO_external_fun_claimRewards_67_Block2_2').
at('subO_external_fun_claimRewards_67_Block2_2', fun_call(subO_abi_decode_tuple_t_uint256, [var(v1), num(0x04)], [var(v3)])).
nextlab('subO_external_fun_claimRewards_67_Block2_2', 'subO_external_fun_claimRewards_67_Block2_3').
at('subO_external_fun_claimRewards_67_Block2_3', fun_call(subO_fun_claimRewards_67, [var(v3)], [])).
nextlab('subO_external_fun_claimRewards_67_Block2_3', 'subO_external_fun_claimRewards_67_Block2_4').
at('subO_external_fun_claimRewards_67_Block2_4', fun_call(subO_allocate_unbounded, [], [var(v4)])).
nextlab('subO_external_fun_claimRewards_67_Block2_4', 'subO_external_fun_claimRewards_67_Block2_5').
at('subO_external_fun_claimRewards_67_Block2_5', fun_call(subO_abi_encode_tuple__to__fromStack, [var(v4)], [var(v5)])).
nextlab('subO_external_fun_claimRewards_67_Block2_5', 'subO_external_fun_claimRewards_67_Block2_6').
at('subO_external_fun_claimRewards_67_Block2_6', asgn(var(v6), expr(sub([var(v4), var(v5)])))).
nextlab('subO_external_fun_claimRewards_67_Block2_6', 'subO_external_fun_claimRewards_67_Block2_7').
at('subO_external_fun_claimRewards_67_Block2_7', return([var(v6), var(v4)])).
at('subO_external_fun_claimRewards_67_Block1_1', fun_call(subO_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [])).
at('subO_external_fun_currentBalance_3_Block0_1', asgn(var(v0), expr(callvalue))).
nextlab('subO_external_fun_currentBalance_3_Block0_1', 'subO_external_fun_currentBalance_3_Block0_2').
at('subO_external_fun_currentBalance_3_Block0_2', cj(var(v0), 'subO_external_fun_currentBalance_3_Block2_1', 'subO_external_fun_currentBalance_3_Block1_1')).
at('subO_external_fun_currentBalance_3_Block2_1', asgn(var(v1), expr(calldatasize))).
nextlab('subO_external_fun_currentBalance_3_Block2_1', 'subO_external_fun_currentBalance_3_Block2_2').
at('subO_external_fun_currentBalance_3_Block2_2', fun_call(subO_abi_decode_tuple_, [var(v1), num(0x04)], [])).
nextlab('subO_external_fun_currentBalance_3_Block2_2', 'subO_external_fun_currentBalance_3_Block2_3').
at('subO_external_fun_currentBalance_3_Block2_3', fun_call(subO_getter_fun_currentBalance_3, [], [var(v3)])).
nextlab('subO_external_fun_currentBalance_3_Block2_3', 'subO_external_fun_currentBalance_3_Block2_4').
at('subO_external_fun_currentBalance_3_Block2_4', fun_call(subO_allocate_unbounded, [], [var(v4)])).
nextlab('subO_external_fun_currentBalance_3_Block2_4', 'subO_external_fun_currentBalance_3_Block2_5').
at('subO_external_fun_currentBalance_3_Block2_5', fun_call(subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack, [var(v3), var(v4)], [var(v5)])).
nextlab('subO_external_fun_currentBalance_3_Block2_5', 'subO_external_fun_currentBalance_3_Block2_6').
at('subO_external_fun_currentBalance_3_Block2_6', asgn(var(v6), expr(sub([var(v4), var(v5)])))).
nextlab('subO_external_fun_currentBalance_3_Block2_6', 'subO_external_fun_currentBalance_3_Block2_7').
at('subO_external_fun_currentBalance_3_Block2_7', return([var(v6), var(v4)])).
at('subO_external_fun_currentBalance_3_Block1_1', fun_call(subO_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [])).
at('subO_extract_from_storage_value_dynamict_uint256_Block0_1', asgn(var(v4), expr(mul([num(0x08), var(v1)])))).
nextlab('subO_extract_from_storage_value_dynamict_uint256_Block0_1', 'subO_extract_from_storage_value_dynamict_uint256_Block0_2').
at('subO_extract_from_storage_value_dynamict_uint256_Block0_2', fun_call(subO_shift_right_unsigned_dynamic, [var(v0), var(v4)], [var(v5)])).
nextlab('subO_extract_from_storage_value_dynamict_uint256_Block0_2', 'subO_extract_from_storage_value_dynamict_uint256_Block0_3').
at('subO_extract_from_storage_value_dynamict_uint256_Block0_3', fun_call(subO_cleanup_from_storage_t_uint256, [var(v5)], [var(v6)])).
nextlab('subO_extract_from_storage_value_dynamict_uint256_Block0_3', 'subO_extract_from_storage_value_dynamict_uint256_ret').
at('subO_extract_from_storage_value_dynamict_uint256_ret', ret([var(v6)])).
at('subO_extract_from_storage_value_offset_0_t_uint256_Block0_1', fun_call(subO_shift_right_0_unsigned, [var(v0)], [var(v2)])).
nextlab('subO_extract_from_storage_value_offset_0_t_uint256_Block0_1', 'subO_extract_from_storage_value_offset_0_t_uint256_Block0_2').
at('subO_extract_from_storage_value_offset_0_t_uint256_Block0_2', fun_call(subO_cleanup_from_storage_t_uint256, [var(v2)], [var(v3)])).
nextlab('subO_extract_from_storage_value_offset_0_t_uint256_Block0_2', 'subO_extract_from_storage_value_offset_0_t_uint256_ret').
at('subO_extract_from_storage_value_offset_0_t_uint256_ret', ret([var(v3)])).
at('subO_fun_claimRewards_67_Block0_1', fun_call(subO_convert_t_rational_0_by_1_to_t_uint256, [num(0x00)], [var(v2)])).
nextlab('subO_fun_claimRewards_67_Block0_1', 'subO_fun_claimRewards_67_Block0_2').
at('subO_fun_claimRewards_67_Block0_2', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v3)])).
nextlab('subO_fun_claimRewards_67_Block0_2', 'subO_fun_claimRewards_67_Block0_3').
at('subO_fun_claimRewards_67_Block0_3', asgn(var(v4), expr(gt([var(v2), var(v3)])))).
nextlab('subO_fun_claimRewards_67_Block0_3', 'subO_fun_claimRewards_67_Block0_4').
at('subO_fun_claimRewards_67_Block0_4', fun_call(subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7, [var(v4)], [])).
nextlab('subO_fun_claimRewards_67_Block0_4', 'subO_fun_claimRewards_67_Block0_5').
at('subO_fun_claimRewards_67_Block0_5', fun_call(subO_convert_t_rational_42_by_1_to_t_uint256, [num(0x2a)], [var(v6)])).
nextlab('subO_fun_claimRewards_67_Block0_5', 'subO_fun_claimRewards_67_Block0_6').
at('subO_fun_claimRewards_67_Block0_6', fun_call(subO_convert_t_rational_10_by_1_to_t_uint256, [num(0x0a)], [var(v8)])).
nextlab('subO_fun_claimRewards_67_Block0_6', 'subO_fun_claimRewards_67_Block0_7').
at('subO_fun_claimRewards_67_Block0_7', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v9)])).
nextlab('subO_fun_claimRewards_67_Block0_7', 'subO_fun_claimRewards_67_Block0_8').
at('subO_fun_claimRewards_67_Block0_8', asgn(var(v10), expr(lt([var(v8), var(v9)])))).
nextlab('subO_fun_claimRewards_67_Block0_8', 'subO_fun_claimRewards_67_Block0_9').
at('subO_fun_claimRewards_67_Block0_9', asgn(var(v11), expr(eq([num(0x00), var(v10)])))).
nextlab('subO_fun_claimRewards_67_Block0_9', 'subO_fun_claimRewards_67_Block0_10').
at('subO_fun_claimRewards_67_Block0_10', cj(var(v11), 'subO_fun_claimRewards_67_Block3_1', 'subO_fun_claimRewards_67_Block2_1')).
at('subO_fun_claimRewards_67_Block3_1', fun_call(subO_convert_t_rational_0_by_1_to_t_uint256, [num(0x00)], [var(v17)])).
nextlab('subO_fun_claimRewards_67_Block3_1', 'subO_fun_claimRewards_67_Block3_2').
at('subO_fun_claimRewards_67_Block3_2', goto('subO_fun_claimRewards_67_Block5_1_2')).
at('subO_fun_claimRewards_67_Block2_1', fun_call(subO_read_from_storage_split_offset_0_t_uint256, [off(0x00)], [var(v12)])).
nextlab('subO_fun_claimRewards_67_Block2_1', 'subO_fun_claimRewards_67_Block2_2').
at('subO_fun_claimRewards_67_Block2_2', fun_call(subO_convert_t_rational_2_by_1_to_t_uint256, [num(0x02)], [var(v14)])).
nextlab('subO_fun_claimRewards_67_Block2_2', 'subO_fun_claimRewards_67_Block2_3').
at('subO_fun_claimRewards_67_Block2_3', fun_call(subO_checked_mul_t_uint256, [var(v14), var(v0)], [var(v15)])).
nextlab('subO_fun_claimRewards_67_Block2_3', 'subO_fun_claimRewards_67_Block2_4').
at('subO_fun_claimRewards_67_Block2_4', fun_call(subO_checked_add_t_uint256, [var(v15), var(v12)], [var(v16)])).
nextlab('subO_fun_claimRewards_67_Block2_4', 'subO_fun_claimRewards_67_Block2_5').
at('subO_fun_claimRewards_67_Block2_5', fun_call(subO_update_storage_value_offset_0_t_uint256_to_t_uint256, [var(v16), off(0x00)], [])).
nextlab('subO_fun_claimRewards_67_Block2_5', 'subO_fun_claimRewards_67_Block2_6').
at('subO_fun_claimRewards_67_Block2_6', goto('subO_fun_claimRewards_67_Block1_1')).
at('subO_fun_claimRewards_67_Block5_1_2', asgn(var(v19), expr(phiFunction([var(v17)])))).
nextlab('subO_fun_claimRewards_67_Block5_1_2', 'subO_fun_claimRewards_67_Block5_2').
at('subO_fun_claimRewards_67_Block5_1_5', asgn(var(v19), expr(phiFunction([var(v32)])))).
nextlab('subO_fun_claimRewards_67_Block5_1_5', 'subO_fun_claimRewards_67_Block5_2').
at('subO_fun_claimRewards_67_Block5_2', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v21)])).
nextlab('subO_fun_claimRewards_67_Block5_2', 'subO_fun_claimRewards_67_Block5_3').
at('subO_fun_claimRewards_67_Block5_3', fun_call(subO_cleanup_t_uint256, [var(v19)], [var(v22)])).
nextlab('subO_fun_claimRewards_67_Block5_3', 'subO_fun_claimRewards_67_Block5_4').
at('subO_fun_claimRewards_67_Block5_4', asgn(var(v23), expr(lt([var(v21), var(v22)])))).
nextlab('subO_fun_claimRewards_67_Block5_4', 'subO_fun_claimRewards_67_Block5_5').
at('subO_fun_claimRewards_67_Block5_5', asgn(var(v24), expr(iszero([var(v23)])))).
nextlab('subO_fun_claimRewards_67_Block5_5', 'subO_fun_claimRewards_67_Block5_6').
at('subO_fun_claimRewards_67_Block5_6', cj(var(v24), 'subO_fun_claimRewards_67_Block9_1', 'subO_fun_claimRewards_67_Block8_1')).
at('subO_fun_claimRewards_67_Block1_1', fun_call(subO_read_from_storage_split_offset_0_t_uint256, [off(0x00)], [var(v33)])).
nextlab('subO_fun_claimRewards_67_Block1_1', 'subO_fun_claimRewards_67_Block1_2').
at('subO_fun_claimRewards_67_Block1_2', fun_call(subO_convert_t_rational_5_by_1_to_t_uint256, [num(0x05)], [var(v35)])).
nextlab('subO_fun_claimRewards_67_Block1_2', 'subO_fun_claimRewards_67_Block1_3').
at('subO_fun_claimRewards_67_Block1_3', fun_call(subO_cleanup_t_uint256, [var(v33)], [var(v36)])).
nextlab('subO_fun_claimRewards_67_Block1_3', 'subO_fun_claimRewards_67_Block1_4').
at('subO_fun_claimRewards_67_Block1_4', asgn(var(v37), expr(lt([var(v35), var(v36)])))).
nextlab('subO_fun_claimRewards_67_Block1_4', 'subO_fun_claimRewards_67_Block1_5').
at('subO_fun_claimRewards_67_Block1_5', fun_call(subO_assert_helper, [var(v37)], [])).
nextlab('subO_fun_claimRewards_67_Block1_5', 'subO_fun_claimRewards_67_Block1_6').
at('subO_fun_claimRewards_67_Block1_6', fun_call(subO_convert_t_rational_1042_by_1_to_t_uint256, [num(0x0412)], [var(v39)])).
nextlab('subO_fun_claimRewards_67_Block1_6', 'subO_fun_claimRewards_67_Block1_7').
at('subO_fun_claimRewards_67_Block1_7', fun_call(subO_convert_t_rational_20_by_1_to_t_uint256, [num(0x14)], [var(v41)])).
nextlab('subO_fun_claimRewards_67_Block1_7', 'subO_fun_claimRewards_67_Block1_8').
at('subO_fun_claimRewards_67_Block1_8', fun_call(subO_cleanup_t_uint256, [var(v39)], [var(v42)])).
nextlab('subO_fun_claimRewards_67_Block1_8', 'subO_fun_claimRewards_67_Block1_9').
at('subO_fun_claimRewards_67_Block1_9', asgn(var(v43), expr(lt([var(v41), var(v42)])))).
nextlab('subO_fun_claimRewards_67_Block1_9', 'subO_fun_claimRewards_67_Block1_10').
at('subO_fun_claimRewards_67_Block1_10', fun_call(subO_assert_helper, [var(v43)], [])).
nextlab('subO_fun_claimRewards_67_Block1_10', 'subO_fun_claimRewards_67_ret').
at('subO_fun_claimRewards_67_ret', ret([])).
at('subO_fun_claimRewards_67_Block9_1', fun_call(subO_read_from_storage_split_offset_0_t_uint256, [off(0x00)], [var(v28)])).
nextlab('subO_fun_claimRewards_67_Block9_1', 'subO_fun_claimRewards_67_Block9_2').
at('subO_fun_claimRewards_67_Block9_2', fun_call(subO_checked_add_t_uint256, [var(v0), var(v28)], [var(v29)])).
nextlab('subO_fun_claimRewards_67_Block9_2', 'subO_fun_claimRewards_67_Block9_3').
at('subO_fun_claimRewards_67_Block9_3', fun_call(subO_update_storage_value_offset_0_t_uint256_to_t_uint256, [var(v29), off(0x00)], [])).
nextlab('subO_fun_claimRewards_67_Block9_3', 'subO_fun_claimRewards_67_Block9_4').
at('subO_fun_claimRewards_67_Block9_4', goto('subO_fun_claimRewards_67_Block6_1')).
at('subO_fun_claimRewards_67_Block8_1', goto('subO_fun_claimRewards_67_Block7_1')).
at('subO_fun_claimRewards_67_Block6_1', fun_call(subO_increment_wrapping_t_uint256, [var(v19)], [var(v32)])).
nextlab('subO_fun_claimRewards_67_Block6_1', 'subO_fun_claimRewards_67_Block6_2').
at('subO_fun_claimRewards_67_Block6_2', goto('subO_fun_claimRewards_67_Block5_1_5')).
at('subO_fun_claimRewards_67_Block7_1', goto('subO_fun_claimRewards_67_Block1_1')).
at('subO_getter_fun_currentBalance_3_Block0_1', fun_call(subO_read_from_storage_split_dynamic_t_uint256, [num(0x00), num(0x00)], [var(v1)])).
nextlab('subO_getter_fun_currentBalance_3_Block0_1', 'subO_getter_fun_currentBalance_3_ret').
at('subO_getter_fun_currentBalance_3_ret', ret([var(v1)])).
at('subO_identity_ret', ret([var(v0)])).
at('subO_increment_wrapping_t_uint256_Block0_1', asgn(var(v3), expr(add([num(0x01), var(v0)])))).
nextlab('subO_increment_wrapping_t_uint256_Block0_1', 'subO_increment_wrapping_t_uint256_Block0_2').
at('subO_increment_wrapping_t_uint256_Block0_2', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_increment_wrapping_t_uint256_Block0_2', 'subO_increment_wrapping_t_uint256_ret').
at('subO_increment_wrapping_t_uint256_ret', ret([var(v4)])).
at('subO_panic_error_0x01_Block0_1', mstore([num(0x4e487b7100000000000000000000000000000000000000000000000000000000), mem(0x00)])).
nextlab('subO_panic_error_0x01_Block0_1', 'subO_panic_error_0x01_Block0_2').
at('subO_panic_error_0x01_Block0_2', mstore([num(0x01), mem(0x04)])).
nextlab('subO_panic_error_0x01_Block0_2', 'subO_panic_error_0x01_Block0_3').
at('subO_panic_error_0x01_Block0_3', revert([num(0x24), mem(0x00)])).
at('subO_panic_error_0x11_Block0_1', mstore([num(0x4e487b7100000000000000000000000000000000000000000000000000000000), mem(0x00)])).
nextlab('subO_panic_error_0x11_Block0_1', 'subO_panic_error_0x11_Block0_2').
at('subO_panic_error_0x11_Block0_2', mstore([num(0x11), mem(0x04)])).
nextlab('subO_panic_error_0x11_Block0_2', 'subO_panic_error_0x11_Block0_3').
at('subO_panic_error_0x11_Block0_3', revert([num(0x24), mem(0x00)])).
at('subO_prepare_store_t_uint256_ret', ret([var(v0)])).
at('subO_read_from_storage_split_dynamic_t_uint256_Block0_1', asgn(var(v3), expr(sload([var(v0)])))).
nextlab('subO_read_from_storage_split_dynamic_t_uint256_Block0_1', 'subO_read_from_storage_split_dynamic_t_uint256_Block0_2').
at('subO_read_from_storage_split_dynamic_t_uint256_Block0_2', fun_call(subO_extract_from_storage_value_dynamict_uint256, [var(v1), var(v3)], [var(v4)])).
nextlab('subO_read_from_storage_split_dynamic_t_uint256_Block0_2', 'subO_read_from_storage_split_dynamic_t_uint256_ret').
at('subO_read_from_storage_split_dynamic_t_uint256_ret', ret([var(v4)])).
at('subO_read_from_storage_split_offset_0_t_uint256_Block0_1', asgn(var(v2), expr(sload([var(v0)])))).
nextlab('subO_read_from_storage_split_offset_0_t_uint256_Block0_1', 'subO_read_from_storage_split_offset_0_t_uint256_Block0_2').
at('subO_read_from_storage_split_offset_0_t_uint256_Block0_2', fun_call(subO_extract_from_storage_value_offset_0_t_uint256, [var(v2)], [var(v3)])).
nextlab('subO_read_from_storage_split_offset_0_t_uint256_Block0_2', 'subO_read_from_storage_split_offset_0_t_uint256_ret').
at('subO_read_from_storage_split_offset_0_t_uint256_ret', ret([var(v3)])).
at('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_1', asgn(var(v1), expr(iszero([var(v0)])))).
nextlab('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_1', 'subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_2').
at('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_2', cj(var(v1), 'subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_ret', 'subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_1')).
at('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_ret', ret([])).
at('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_1', fun_call(subO_allocate_unbounded, [], [var(v2)])).
nextlab('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_1', 'subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_2').
at('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_2', mstore([num(0x08c379a000000000000000000000000000000000000000000000000000000000), var(v2)])).
nextlab('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_2', 'subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_3').
at('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_3', asgn(var(v5), expr(add([num(0x04), var(v2)])))).
nextlab('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_3', 'subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_4').
at('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_4', fun_call(subO_abi_encode_tuple_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7__to_t_string_memory_ptr__fromStack, [var(v5)], [var(v6)])).
nextlab('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_4', 'subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_5').
at('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_5', asgn(var(v7), expr(sub([var(v2), var(v6)])))).
nextlab('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_5', 'subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_6').
at('subO_require_helper_t_stringliteral_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block1_6', revert([var(v7), var(v2)])).
at('subO_revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74_Block0_1', revert([num(0x00), mem(0x00)])).
at('subO_revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db_Block0_1', revert([num(0x00), mem(0x00)])).
at('subO_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb_Block0_1', revert([num(0x00), mem(0x00)])).
at('subO_revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b_Block0_1', revert([num(0x00), mem(0x00)])).
at('subO_shift_left_0_Block0_1', asgn(var(v2), expr(shl([var(v0), num(0x00)])))).
nextlab('subO_shift_left_0_Block0_1', 'subO_shift_left_0_ret').
at('subO_shift_left_0_ret', ret([var(v2)])).
at('subO_shift_right_0_unsigned_Block0_1', asgn(var(v2), expr(shr([var(v0), num(0x00)])))).
nextlab('subO_shift_right_0_unsigned_Block0_1', 'subO_shift_right_0_unsigned_ret').
at('subO_shift_right_0_unsigned_ret', ret([var(v2)])).
at('subO_shift_right_224_unsigned_Block0_1', asgn(var(v3), expr(shr([var(v0), num(0xe0)])))).
nextlab('subO_shift_right_224_unsigned_Block0_1', 'subO_shift_right_224_unsigned_ret').
at('subO_shift_right_224_unsigned_ret', ret([var(v3)])).
at('subO_shift_right_unsigned_dynamic_Block0_1', asgn(var(v3), expr(shr([var(v1), var(v0)])))).
nextlab('subO_shift_right_unsigned_dynamic_Block0_1', 'subO_shift_right_unsigned_dynamic_ret').
at('subO_shift_right_unsigned_dynamic_ret', ret([var(v3)])).
at('subO_store_literal_in_memory_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_1', asgn(var(v3), expr(add([num(0x00), var(v0)])))).
nextlab('subO_store_literal_in_memory_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_1', 'subO_store_literal_in_memory_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_2').
at('subO_store_literal_in_memory_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_2', mstore([num(0x506f696e7473206d7573742062652067726561746572207468616e207a65726f), var(v3)])).
nextlab('subO_store_literal_in_memory_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_Block0_2', 'subO_store_literal_in_memory_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_ret').
at('subO_store_literal_in_memory_888ac6140e55689af008cd0fe0bb0528a29e1f99dc09d54949db482c83b4c3a7_ret', ret([])).
at('subO_update_byte_slice_32_shift_0_Block0_1', fun_call(subO_shift_left_0, [var(v1)], [var(v4)])).
nextlab('subO_update_byte_slice_32_shift_0_Block0_1', 'subO_update_byte_slice_32_shift_0_Block0_2').
at('subO_update_byte_slice_32_shift_0_Block0_2', asgn(var(v5), expr(not([num(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)])))).
nextlab('subO_update_byte_slice_32_shift_0_Block0_2', 'subO_update_byte_slice_32_shift_0_Block0_3').
at('subO_update_byte_slice_32_shift_0_Block0_3', asgn(var(v6), expr(and([var(v5), var(v0)])))).
nextlab('subO_update_byte_slice_32_shift_0_Block0_3', 'subO_update_byte_slice_32_shift_0_Block0_4').
at('subO_update_byte_slice_32_shift_0_Block0_4', asgn(var(v7), expr(and([num(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), var(v4)])))).
nextlab('subO_update_byte_slice_32_shift_0_Block0_4', 'subO_update_byte_slice_32_shift_0_Block0_5').
at('subO_update_byte_slice_32_shift_0_Block0_5', asgn(var(v8), expr(or([var(v7), var(v6)])))).
nextlab('subO_update_byte_slice_32_shift_0_Block0_5', 'subO_update_byte_slice_32_shift_0_ret').
at('subO_update_byte_slice_32_shift_0_ret', ret([var(v8)])).
at('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_1', fun_call(subO_convert_t_uint256_to_t_uint256, [var(v1)], [var(v2)])).
nextlab('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_1', 'subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_2').
at('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_2', fun_call(subO_prepare_store_t_uint256, [var(v2)], [var(v3)])).
nextlab('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_2', 'subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_3').
at('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_3', asgn(var(v4), expr(sload([var(v0)])))).
nextlab('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_3', 'subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_4').
at('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_4', fun_call(subO_update_byte_slice_32_shift_0, [var(v3), var(v4)], [var(v5)])).
nextlab('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_4', 'subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_5').
at('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_5', sstore([var(v5), var(v0)])).
nextlab('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_5', 'subO_update_storage_value_offset_0_t_uint256_to_t_uint256_ret').
at('subO_update_storage_value_offset_0_t_uint256_to_t_uint256_ret', ret([])).
at('subO_validator_revert_t_uint256_Block0_1', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v1)])).
nextlab('subO_validator_revert_t_uint256_Block0_1', 'subO_validator_revert_t_uint256_Block0_2').
at('subO_validator_revert_t_uint256_Block0_2', asgn(var(v2), expr(eq([var(v1), var(v0)])))).
nextlab('subO_validator_revert_t_uint256_Block0_2', 'subO_validator_revert_t_uint256_Block0_3').
at('subO_validator_revert_t_uint256_Block0_3', asgn(var(v3), expr(iszero([var(v2)])))).
nextlab('subO_validator_revert_t_uint256_Block0_3', 'subO_validator_revert_t_uint256_Block0_4').
at('subO_validator_revert_t_uint256_Block0_4', cj(var(v3), 'subO_validator_revert_t_uint256_ret', 'subO_validator_revert_t_uint256_Block1_1')).
at('subO_validator_revert_t_uint256_ret', ret([])).
at('subO_validator_revert_t_uint256_Block1_1', revert([num(0x00), mem(0x00)])).
at('start_contract', fun_call(init_contract, [], [])).
nextlab('start_contract', 'runtime_contract').
at('runtime_contract', fun_call(r_RewardSystem_68_deployed, [], [])).
at('init_contract_Block0_1', asgn(var(v0), expr(memoryguard))).
nextlab('init_contract_Block0_1', 'init_contract_Block0_2').
at('init_contract_Block0_2', mstore([var(v0), mem(0x40)])).
nextlab('init_contract_Block0_2', 'init_contract_Block0_3').
at('init_contract_Block0_3', asgn(var(v2), expr(callvalue))).
nextlab('init_contract_Block0_3', 'init_contract_Block0_4').
at('init_contract_Block0_4', cj(var(v2), 'init_contract_Block2_1', 'init_contract_Block1_1')).
at('init_contract_Block2_1', fun_call(obj_constructor_RewardSystem_68, [], [])).
nextlab('init_contract_Block2_1', 'init_contract_ret').
at('init_contract_ret', ret([])).
at('init_contract_Block1_1', fun_call(obj_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [])).
at('RewardSystem_68_deployed_Block0_1', asgn(var(v0), expr(memoryguard))).
nextlab('RewardSystem_68_deployed_Block0_1', 'RewardSystem_68_deployed_Block0_2').
at('RewardSystem_68_deployed_Block0_2', mstore([var(v0), mem(0x40)])).
nextlab('RewardSystem_68_deployed_Block0_2', 'RewardSystem_68_deployed_Block0_3').
at('RewardSystem_68_deployed_Block0_3', asgn(var(v3), expr(calldatasize))).
nextlab('RewardSystem_68_deployed_Block0_3', 'RewardSystem_68_deployed_Block0_4').
at('RewardSystem_68_deployed_Block0_4', asgn(var(v4), expr(lt([num(0x04), var(v3)])))).
nextlab('RewardSystem_68_deployed_Block0_4', 'RewardSystem_68_deployed_Block0_5').
at('RewardSystem_68_deployed_Block0_5', asgn(var(v5), expr(iszero([var(v4)])))).
nextlab('RewardSystem_68_deployed_Block0_5', 'RewardSystem_68_deployed_Block0_6').
at('RewardSystem_68_deployed_Block0_6', cj(var(v5), 'RewardSystem_68_deployed_Block2_1', 'RewardSystem_68_deployed_Block1_1')).
at('RewardSystem_68_deployed_Block2_1', fun_call(subO_revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74, [], [])).
at('RewardSystem_68_deployed_Block1_1', asgn(var(v7), expr(calldataload([num(0x00)])))).
nextlab('RewardSystem_68_deployed_Block1_1', 'RewardSystem_68_deployed_Block1_2').
at('RewardSystem_68_deployed_Block1_2', fun_call(subO_shift_right_224_unsigned, [var(v7)], [var(v8)])).
nextlab('RewardSystem_68_deployed_Block1_2', 'RewardSystem_68_deployed_Block1_3').
at('RewardSystem_68_deployed_Block1_3', asgn(var(v9), expr(eq([num(0x0962ef79), var(v8)])))).
nextlab('RewardSystem_68_deployed_Block1_3', 'RewardSystem_68_deployed_Block1_4').
at('RewardSystem_68_deployed_Block1_4', cj(var(v9), 'RewardSystem_68_deployed_Block5_1', 'RewardSystem_68_deployed_Block4_1')).
at('RewardSystem_68_deployed_Block5_1', asgn(var(v11), expr(eq([num(0xce845d1d), var(v8)])))).
nextlab('RewardSystem_68_deployed_Block5_1', 'RewardSystem_68_deployed_Block5_2').
at('RewardSystem_68_deployed_Block5_2', cj(var(v11), 'RewardSystem_68_deployed_Block8_1', 'RewardSystem_68_deployed_Block7_1')).
at('RewardSystem_68_deployed_Block4_1', fun_call(subO_external_fun_claimRewards_67, [], [])).
at('RewardSystem_68_deployed_Block8_1', goto('RewardSystem_68_deployed_Block3_1')).
at('RewardSystem_68_deployed_Block7_1', fun_call(subO_external_fun_currentBalance_3, [], [])).
at('RewardSystem_68_deployed_Block3_1', goto('RewardSystem_68_deployed_Block2_1')).



:- include('RewardStateVar_10.aux.pl').