:- dynamic at/2.
:- discontiguous at/2.
:- discontiguous nextlab/2.
% BootVesting.sol:BootVesting contract
signatures([('external_fun_claimable_143', '0x3125ac3200000000000000000000000000000000000000000000000000000000'), ('external_fun_vestedFull_9', '0xe273f0d500000000000000000000000000000000000000000000000000000000'), ('external_fun_vestedPartial_11', '0xe42e4ba300000000000000000000000000000000000000000000000000000000')]).

globals([0x00, 0x01]).
memory([0x00, 0x04, 0x40]).
fun(obj_allocate_unbounded, [], [var(v2)], 'obj_allocate_unbounded_Block0_1').
fun(obj_constructor_BootVesting_144, [], [], 'obj_constructor_BootVesting_144_ret').
fun(obj_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [], 'obj_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb_Block0_1').
fun(subO_abi_decode_t_uint256, [var(v0), var(v1)], [var(v3)], 'subO_abi_decode_t_uint256_Block0_1').
fun(subO_abi_decode_tuple_, [var(v0), var(v1)], [var(v4), var(v3)], 'subO_abi_decode_tuple__Block0_1').
fun(subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256, [var(v0), var(v1)], [var(v11), var(v15), var(v4), var(v17), var(v12), var(v5), var(v21), var(v18), var(v14), var(v20)], 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block0_1').
fun(subO_abi_encode_t_uint256_to_t_uint256_fromStack, [var(v0), var(v1)], [var(v2)], 'subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_1').
fun(subO_abi_encode_tuple__to__fromStack, [var(v0)], [var(v2)], 'subO_abi_encode_tuple__to__fromStack_Block0_1').
fun(subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack, [var(v0), var(v1)], [var(v4), var(v5)], 'subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack_Block0_1').
fun(subO_allocate_unbounded, [], [var(v2)], 'subO_allocate_unbounded_Block0_1').
fun(subO_assert_helper, [var(v0)], [var(v1)], 'subO_assert_helper_Block0_1').
fun(subO_checked_add_t_uint256, [var(v0), var(v1)], [var(v4), var(v3), var(v5), var(v6)], 'subO_checked_add_t_uint256_Block0_1').
fun(subO_checked_sub_t_uint256, [var(v0), var(v1)], [var(v4), var(v3), var(v5), var(v6)], 'subO_checked_sub_t_uint256_Block0_1').
fun(subO_cleanup_from_storage_t_uint256, [var(v0)], [], 'subO_cleanup_from_storage_t_uint256_ret').
fun(subO_cleanup_t_rational_0_by_1, [var(v0)], [], 'subO_cleanup_t_rational_0_by_1_ret').
fun(subO_cleanup_t_rational_1000_by_1, [var(v0)], [], 'subO_cleanup_t_rational_1000_by_1_ret').
fun(subO_cleanup_t_rational_100_by_1, [var(v0)], [], 'subO_cleanup_t_rational_100_by_1_ret').
fun(subO_cleanup_t_rational_1042_by_1, [var(v0)], [], 'subO_cleanup_t_rational_1042_by_1_ret').
fun(subO_cleanup_t_rational_1_by_1, [var(v0)], [], 'subO_cleanup_t_rational_1_by_1_ret').
fun(subO_cleanup_t_rational_2_by_1, [var(v0)], [], 'subO_cleanup_t_rational_2_by_1_ret').
fun(subO_cleanup_t_uint256, [var(v0)], [], 'subO_cleanup_t_uint256_ret').
fun(subO_constant_AMOUNT_7, [], [var(v2)], 'subO_constant_AMOUNT_7_Block0_1').
fun(subO_constant_YEAR_4, [], [var(v2)], 'subO_constant_YEAR_4_Block0_1').
fun(subO_convert_t_rational_0_by_1_to_t_uint256, [var(v0)], [var(v4), var(v3), var(v2)], 'subO_convert_t_rational_0_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_1000_by_1_to_t_uint256, [var(v0)], [var(v4), var(v3), var(v2)], 'subO_convert_t_rational_1000_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_100_by_1_to_t_uint256, [var(v0)], [var(v4), var(v3), var(v2)], 'subO_convert_t_rational_100_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_1042_by_1_to_t_uint256, [var(v0)], [var(v4), var(v3), var(v2)], 'subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_1_by_1_to_t_uint256, [var(v0)], [var(v4), var(v3), var(v2)], 'subO_convert_t_rational_1_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_rational_2_by_1_to_t_uint256, [var(v0)], [var(v4), var(v3), var(v2)], 'subO_convert_t_rational_2_by_1_to_t_uint256_Block0_1').
fun(subO_convert_t_uint256_to_t_uint256, [var(v0)], [var(v4), var(v3), var(v2)], 'subO_convert_t_uint256_to_t_uint256_Block0_1').
fun(subO_external_fun_claimable_143, [], [var(v7), var(v1), var(v8), var(v4), var(v0), var(v5), var(v6), var(v9), var(v3)], 'subO_external_fun_claimable_143_Block0_1').
fun(subO_external_fun_vestedFull_9, [], [var(v1), var(v4), var(v0), var(v5), var(v6), var(v3)], 'subO_external_fun_vestedFull_9_Block0_1').
fun(subO_external_fun_vestedPartial_11, [], [var(v1), var(v4), var(v0), var(v5), var(v6), var(v3)], 'subO_external_fun_vestedPartial_11_Block0_1').
fun(subO_extract_from_storage_value_dynamict_uint256, [var(v0), var(v1)], [var(v4), var(v5), var(v6)], 'subO_extract_from_storage_value_dynamict_uint256_Block0_1').
fun(subO_extract_from_storage_value_offset_0_t_uint256, [var(v0)], [var(v3), var(v2)], 'subO_extract_from_storage_value_offset_0_t_uint256_Block0_1').
fun(subO_fun_claimable_143, [var(v0), var(v1), var(v2), var(v3)], [var(v48), var(v27), var(v17), var(v23), var(v78), var(v41), var(v36), var(v86), var(v67), var(v7), var(v75), var(v12), var(v43), var(v25), var(v30), var(v49), var(v59), var(v44), var(v56), var(v50), var(v35), var(v8), var(v10), var(v79), var(v81), var(v5), var(v6), var(v32), var(v14), var(v80), var(v28), var(v29), var(v52), var(v84), var(v58), var(v11), var(v15), var(v54), var(v82), var(v73), var(v74), var(v16), var(v76), var(v88), var(v45), var(v24), var(v19), var(v21), var(v18), var(v47), var(v13), var(v46), var(v22), var(v77), var(v87)], 'subO_fun_claimable_143_Block0_1').
fun(subO_getter_fun_vestedFull_9, [], [var(v1)], 'subO_getter_fun_vestedFull_9_Block0_1').
fun(subO_getter_fun_vestedPartial_11, [], [var(v2)], 'subO_getter_fun_vestedPartial_11_Block0_1').
fun(subO_identity, [var(v0)], [], 'subO_identity_ret').
fun(subO_increment_wrapping_t_uint256, [var(v0)], [var(v4), var(v3)], 'subO_increment_wrapping_t_uint256_Block0_1').
fun(subO_panic_error_0x01, [], [], 'subO_panic_error_0x01_Block0_1').
fun(subO_panic_error_0x11, [], [], 'subO_panic_error_0x11_Block0_1').
fun(subO_prepare_store_t_uint256, [var(v0)], [], 'subO_prepare_store_t_uint256_ret').
fun(subO_read_from_storage_split_dynamic_t_uint256, [var(v0), var(v1)], [var(v4), var(v3)], 'subO_read_from_storage_split_dynamic_t_uint256_Block0_1').
fun(subO_read_from_storage_split_offset_0_t_uint256, [var(v0)], [var(v3), var(v2)], 'subO_read_from_storage_split_offset_0_t_uint256_Block0_1').
fun(subO_require_helper, [var(v0)], [var(v1)], 'subO_require_helper_Block0_1').
fun(subO_revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74, [], [], 'subO_revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74_Block0_1').
fun(subO_revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db, [], [], 'subO_revert_error_c1322bf8034eace5e0b5c7295db60986aa89aae5e0ea0873e4689e076861a5db_Block0_1').
fun(subO_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [], 'subO_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb_Block0_1').
fun(subO_revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b, [], [], 'subO_revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b_Block0_1').
fun(subO_shift_left_0, [var(v0)], [var(v2)], 'subO_shift_left_0_Block0_1').
fun(subO_shift_right_0_unsigned, [var(v0)], [var(v2)], 'subO_shift_right_0_unsigned_Block0_1').
fun(subO_shift_right_224_unsigned, [var(v0)], [var(v3)], 'subO_shift_right_224_unsigned_Block0_1').
fun(subO_shift_right_unsigned_dynamic, [var(v0), var(v1)], [var(v3)], 'subO_shift_right_unsigned_dynamic_Block0_1').
fun(subO_update_byte_slice_32_shift_0, [var(v0), var(v1)], [var(v7), var(v8), var(v4), var(v5), var(v6)], 'subO_update_byte_slice_32_shift_0_Block0_1').
fun(subO_update_storage_value_offset_0_t_uint256_to_t_uint256, [var(v0), var(v1)], [var(v4), var(v3), var(v2), var(v5)], 'subO_update_storage_value_offset_0_t_uint256_to_t_uint256_Block0_1').
fun(subO_validator_revert_t_uint256, [var(v0)], [var(v3), var(v2), var(v1)], 'subO_validator_revert_t_uint256_Block0_1').
fun(r_BootVesting_144_deployed, [], [var(v11), var(v7), var(v8), var(v4), var(v0), var(v5), var(v9), var(v13), var(v3)], 'BootVesting_144_deployed_Block0_1').
fun(init_contract, [], [var(v4), var(v0), var(v5), var(v6), var(v3), var(v2)], 'init_contract_Block0_1').

% Combined at and nextlab relations
at('obj_allocate_unbounded_Block0_1', asgn(var(v2), expr(mload([mem(0x40)])))).
nextlab('obj_allocate_unbounded_Block0_1', 'obj_allocate_unbounded_ret').
at('obj_allocate_unbounded_ret', ret([var(v2)])).
at('obj_constructor_BootVesting_144_ret', ret([])).
at('obj_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb_Block0_1', revert([num(0x00), mem(0x00)])).
at('subO_abi_decode_t_uint256_Block0_1', asgn(var(v3), expr(calldataload([var(v0)])))).
nextlab('subO_abi_decode_t_uint256_Block0_1', 'subO_abi_decode_t_uint256_Block0_2').
at('subO_abi_decode_t_uint256_Block0_2', fun_call(subO_validator_revert_t_uint256, [var(v3)], [])).
nextlab('subO_abi_decode_t_uint256_Block0_2', 'subO_abi_decode_t_uint256_ret').
at('subO_abi_decode_t_uint256_ret', ret([var(v3)])).
at('subO_abi_decode_tuple__Block0_1', asgn(var(v3), expr(sub([var(v0), var(v1)])))).
nextlab('subO_abi_decode_tuple__Block0_1', 'subO_abi_decode_tuple__Block0_2').
at('subO_abi_decode_tuple__Block0_2', asgn(var(v4), expr(slt([num(0x00), var(v3)])))).
nextlab('subO_abi_decode_tuple__Block0_2', 'subO_abi_decode_tuple__Block0_jump').
at('subO_abi_decode_tuple__Block0_jump', cj(var(v4), 'subO_abi_decode_tuple__ret', 'subO_abi_decode_tuple__Block1_1')).
at('subO_abi_decode_tuple__ret', ret([])).
at('subO_abi_decode_tuple__Block1_1', fun_call(subO_revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b, [], [])).
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block0_1', asgn(var(v4), expr(sub([var(v0), var(v1)])))).
nextlab('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block0_1', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block0_2').
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block0_2', asgn(var(v5), expr(slt([num(0x80), var(v4)])))).
nextlab('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block0_2', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block0_jump').
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block0_jump', cj(var(v5), 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_1', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block1_1')).
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_1', asgn(var(v11), expr(add([num(0x00), var(v0)])))).
nextlab('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_1', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_2').
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_2', fun_call(subO_abi_decode_t_uint256, [var(v1), var(v11)], [var(v12)])).
nextlab('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_2', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_3').
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_3', asgn(var(v14), expr(add([num(0x20), var(v0)])))).
nextlab('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_3', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_4').
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_4', fun_call(subO_abi_decode_t_uint256, [var(v1), var(v14)], [var(v15)])).
nextlab('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_4', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_5').
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_5', asgn(var(v17), expr(add([num(0x40), var(v0)])))).
nextlab('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_5', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_6').
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_6', fun_call(subO_abi_decode_t_uint256, [var(v1), var(v17)], [var(v18)])).
nextlab('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_6', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_7').
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_7', asgn(var(v20), expr(add([num(0x60), var(v0)])))).
nextlab('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_7', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_8').
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_8', fun_call(subO_abi_decode_t_uint256, [var(v1), var(v20)], [var(v21)])).
nextlab('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block2_8', 'subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_ret').
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_ret', ret([var(v12), var(v15), var(v18), var(v21)])).
at('subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256_Block1_1', fun_call(subO_revert_error_dbdddcbe895c83990c08b3492a0e83918d802a52331272ac6fdb6a7c4aea3b1b, [], [])).
at('subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_1', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v2)])).
nextlab('subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_1', 'subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_2').
at('subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_2', mstore([var(v2), var(v1)])).
nextlab('subO_abi_encode_t_uint256_to_t_uint256_fromStack_Block0_2', 'subO_abi_encode_t_uint256_to_t_uint256_fromStack_ret').
at('subO_abi_encode_t_uint256_to_t_uint256_fromStack_ret', ret([])).
at('subO_abi_encode_tuple__to__fromStack_Block0_1', asgn(var(v2), expr(add([num(0x00), var(v0)])))).
nextlab('subO_abi_encode_tuple__to__fromStack_Block0_1', 'subO_abi_encode_tuple__to__fromStack_ret').
at('subO_abi_encode_tuple__to__fromStack_ret', ret([var(v2)])).
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
at('subO_assert_helper_Block0_1', asgn(var(v1), expr(iszero([var(v0)])))).
nextlab('subO_assert_helper_Block0_1', 'subO_assert_helper_Block0_jump').
at('subO_assert_helper_Block0_jump', cj(var(v1), 'subO_assert_helper_ret', 'subO_assert_helper_Block1_1')).
at('subO_assert_helper_ret', ret([])).
at('subO_assert_helper_Block1_1', fun_call(subO_panic_error_0x01, [], [])).
at('subO_checked_add_t_uint256_Block0_1', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v3)])).
nextlab('subO_checked_add_t_uint256_Block0_1', 'subO_checked_add_t_uint256_Block0_2').
at('subO_checked_add_t_uint256_Block0_2', fun_call(subO_cleanup_t_uint256, [var(v1)], [var(v4)])).
nextlab('subO_checked_add_t_uint256_Block0_2', 'subO_checked_add_t_uint256_Block0_3').
at('subO_checked_add_t_uint256_Block0_3', asgn(var(v5), expr(add([var(v4), var(v3)])))).
nextlab('subO_checked_add_t_uint256_Block0_3', 'subO_checked_add_t_uint256_Block0_4').
at('subO_checked_add_t_uint256_Block0_4', asgn(var(v6), expr(gt([var(v5), var(v3)])))).
nextlab('subO_checked_add_t_uint256_Block0_4', 'subO_checked_add_t_uint256_Block0_jump').
at('subO_checked_add_t_uint256_Block0_jump', cj(var(v6), 'subO_checked_add_t_uint256_ret', 'subO_checked_add_t_uint256_Block1_1')).
at('subO_checked_add_t_uint256_ret', ret([var(v5)])).
at('subO_checked_add_t_uint256_Block1_1', fun_call(subO_panic_error_0x11, [], [])).
at('subO_checked_sub_t_uint256_Block0_1', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v3)])).
nextlab('subO_checked_sub_t_uint256_Block0_1', 'subO_checked_sub_t_uint256_Block0_2').
at('subO_checked_sub_t_uint256_Block0_2', fun_call(subO_cleanup_t_uint256, [var(v1)], [var(v4)])).
nextlab('subO_checked_sub_t_uint256_Block0_2', 'subO_checked_sub_t_uint256_Block0_3').
at('subO_checked_sub_t_uint256_Block0_3', asgn(var(v5), expr(sub([var(v4), var(v3)])))).
nextlab('subO_checked_sub_t_uint256_Block0_3', 'subO_checked_sub_t_uint256_Block0_4').
at('subO_checked_sub_t_uint256_Block0_4', asgn(var(v6), expr(gt([var(v3), var(v5)])))).
nextlab('subO_checked_sub_t_uint256_Block0_4', 'subO_checked_sub_t_uint256_Block0_jump').
at('subO_checked_sub_t_uint256_Block0_jump', cj(var(v6), 'subO_checked_sub_t_uint256_ret', 'subO_checked_sub_t_uint256_Block1_1')).
at('subO_checked_sub_t_uint256_ret', ret([var(v5)])).
at('subO_checked_sub_t_uint256_Block1_1', fun_call(subO_panic_error_0x11, [], [])).
at('subO_cleanup_from_storage_t_uint256_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_0_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_1000_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_100_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_1042_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_1_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_rational_2_by_1_ret', ret([var(v0)])).
at('subO_cleanup_t_uint256_ret', ret([var(v0)])).
at('subO_constant_AMOUNT_7_Block0_1', fun_call(subO_convert_t_rational_100_by_1_to_t_uint256, [num(0x64)], [var(v2)])).
nextlab('subO_constant_AMOUNT_7_Block0_1', 'subO_constant_AMOUNT_7_ret').
at('subO_constant_AMOUNT_7_ret', ret([var(v2)])).
at('subO_constant_YEAR_4_Block0_1', fun_call(subO_convert_t_rational_100_by_1_to_t_uint256, [num(0x64)], [var(v2)])).
nextlab('subO_constant_YEAR_4_Block0_1', 'subO_constant_YEAR_4_ret').
at('subO_constant_YEAR_4_ret', ret([var(v2)])).
at('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_0_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_0_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_0_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_0_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_0_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_0_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_1000_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_1000_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_1000_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_1000_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_1000_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_1000_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_1000_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_1000_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_1000_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_1000_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_1000_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_100_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_100_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_100_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_100_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_100_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_100_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_100_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_100_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_100_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_100_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_100_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_1042_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_1042_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_1042_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_1042_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_1_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_1_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_1_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_1_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_1_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_1_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_1_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_1_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_1_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_1_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_1_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_rational_2_by_1, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_1', 'subO_convert_t_rational_2_by_1_to_t_uint256_Block0_2').
at('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_2', 'subO_convert_t_rational_2_by_1_to_t_uint256_Block0_3').
at('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_rational_2_by_1_to_t_uint256_Block0_3', 'subO_convert_t_rational_2_by_1_to_t_uint256_ret').
at('subO_convert_t_rational_2_by_1_to_t_uint256_ret', ret([var(v4)])).
at('subO_convert_t_uint256_to_t_uint256_Block0_1', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v2)])).
nextlab('subO_convert_t_uint256_to_t_uint256_Block0_1', 'subO_convert_t_uint256_to_t_uint256_Block0_2').
at('subO_convert_t_uint256_to_t_uint256_Block0_2', fun_call(subO_identity, [var(v2)], [var(v3)])).
nextlab('subO_convert_t_uint256_to_t_uint256_Block0_2', 'subO_convert_t_uint256_to_t_uint256_Block0_3').
at('subO_convert_t_uint256_to_t_uint256_Block0_3', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v4)])).
nextlab('subO_convert_t_uint256_to_t_uint256_Block0_3', 'subO_convert_t_uint256_to_t_uint256_ret').
at('subO_convert_t_uint256_to_t_uint256_ret', ret([var(v4)])).
at('subO_external_fun_claimable_143_Block0_1', asgn(var(v0), expr(callvalue))).
nextlab('subO_external_fun_claimable_143_Block0_1', 'subO_external_fun_claimable_143_Block0_jump').
at('subO_external_fun_claimable_143_Block0_jump', cj(var(v0), 'subO_external_fun_claimable_143_Block2_1', 'subO_external_fun_claimable_143_Block1_1')).
at('subO_external_fun_claimable_143_Block2_1', asgn(var(v1), expr(calldatasize))).
nextlab('subO_external_fun_claimable_143_Block2_1', 'subO_external_fun_claimable_143_Block2_2').
at('subO_external_fun_claimable_143_Block2_2', fun_call(subO_abi_decode_tuple_t_uint256t_uint256t_uint256t_uint256, [var(v1), num(0x04)], [var(v3), var(v4), var(v5), var(v6)])).
nextlab('subO_external_fun_claimable_143_Block2_2', 'subO_external_fun_claimable_143_Block2_3').
at('subO_external_fun_claimable_143_Block2_3', fun_call(subO_fun_claimable_143, [var(v6), var(v5), var(v4), var(v3)], [])).
nextlab('subO_external_fun_claimable_143_Block2_3', 'subO_external_fun_claimable_143_Block2_4').
at('subO_external_fun_claimable_143_Block2_4', fun_call(subO_allocate_unbounded, [], [var(v7)])).
nextlab('subO_external_fun_claimable_143_Block2_4', 'subO_external_fun_claimable_143_Block2_5').
at('subO_external_fun_claimable_143_Block2_5', fun_call(subO_abi_encode_tuple__to__fromStack, [var(v7)], [var(v8)])).
nextlab('subO_external_fun_claimable_143_Block2_5', 'subO_external_fun_claimable_143_Block2_6').
at('subO_external_fun_claimable_143_Block2_6', asgn(var(v9), expr(sub([var(v7), var(v8)])))).
nextlab('subO_external_fun_claimable_143_Block2_6', 'subO_external_fun_claimable_143_Block2_7').
at('subO_external_fun_claimable_143_Block2_7', return([var(v9), var(v7)])).
at('subO_external_fun_claimable_143_Block1_1', fun_call(subO_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [])).
at('subO_external_fun_vestedFull_9_Block0_1', asgn(var(v0), expr(callvalue))).
nextlab('subO_external_fun_vestedFull_9_Block0_1', 'subO_external_fun_vestedFull_9_Block0_jump').
at('subO_external_fun_vestedFull_9_Block0_jump', cj(var(v0), 'subO_external_fun_vestedFull_9_Block2_1', 'subO_external_fun_vestedFull_9_Block1_1')).
at('subO_external_fun_vestedFull_9_Block2_1', asgn(var(v1), expr(calldatasize))).
nextlab('subO_external_fun_vestedFull_9_Block2_1', 'subO_external_fun_vestedFull_9_Block2_2').
at('subO_external_fun_vestedFull_9_Block2_2', fun_call(subO_abi_decode_tuple_, [var(v1), num(0x04)], [])).
nextlab('subO_external_fun_vestedFull_9_Block2_2', 'subO_external_fun_vestedFull_9_Block2_3').
at('subO_external_fun_vestedFull_9_Block2_3', fun_call(subO_getter_fun_vestedFull_9, [], [var(v3)])).
nextlab('subO_external_fun_vestedFull_9_Block2_3', 'subO_external_fun_vestedFull_9_Block2_4').
at('subO_external_fun_vestedFull_9_Block2_4', fun_call(subO_allocate_unbounded, [], [var(v4)])).
nextlab('subO_external_fun_vestedFull_9_Block2_4', 'subO_external_fun_vestedFull_9_Block2_5').
at('subO_external_fun_vestedFull_9_Block2_5', fun_call(subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack, [var(v3), var(v4)], [var(v5)])).
nextlab('subO_external_fun_vestedFull_9_Block2_5', 'subO_external_fun_vestedFull_9_Block2_6').
at('subO_external_fun_vestedFull_9_Block2_6', asgn(var(v6), expr(sub([var(v4), var(v5)])))).
nextlab('subO_external_fun_vestedFull_9_Block2_6', 'subO_external_fun_vestedFull_9_Block2_7').
at('subO_external_fun_vestedFull_9_Block2_7', return([var(v6), var(v4)])).
at('subO_external_fun_vestedFull_9_Block1_1', fun_call(subO_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [])).
at('subO_external_fun_vestedPartial_11_Block0_1', asgn(var(v0), expr(callvalue))).
nextlab('subO_external_fun_vestedPartial_11_Block0_1', 'subO_external_fun_vestedPartial_11_Block0_jump').
at('subO_external_fun_vestedPartial_11_Block0_jump', cj(var(v0), 'subO_external_fun_vestedPartial_11_Block2_1', 'subO_external_fun_vestedPartial_11_Block1_1')).
at('subO_external_fun_vestedPartial_11_Block2_1', asgn(var(v1), expr(calldatasize))).
nextlab('subO_external_fun_vestedPartial_11_Block2_1', 'subO_external_fun_vestedPartial_11_Block2_2').
at('subO_external_fun_vestedPartial_11_Block2_2', fun_call(subO_abi_decode_tuple_, [var(v1), num(0x04)], [])).
nextlab('subO_external_fun_vestedPartial_11_Block2_2', 'subO_external_fun_vestedPartial_11_Block2_3').
at('subO_external_fun_vestedPartial_11_Block2_3', fun_call(subO_getter_fun_vestedPartial_11, [], [var(v3)])).
nextlab('subO_external_fun_vestedPartial_11_Block2_3', 'subO_external_fun_vestedPartial_11_Block2_4').
at('subO_external_fun_vestedPartial_11_Block2_4', fun_call(subO_allocate_unbounded, [], [var(v4)])).
nextlab('subO_external_fun_vestedPartial_11_Block2_4', 'subO_external_fun_vestedPartial_11_Block2_5').
at('subO_external_fun_vestedPartial_11_Block2_5', fun_call(subO_abi_encode_tuple_t_uint256__to_t_uint256__fromStack, [var(v3), var(v4)], [var(v5)])).
nextlab('subO_external_fun_vestedPartial_11_Block2_5', 'subO_external_fun_vestedPartial_11_Block2_6').
at('subO_external_fun_vestedPartial_11_Block2_6', asgn(var(v6), expr(sub([var(v4), var(v5)])))).
nextlab('subO_external_fun_vestedPartial_11_Block2_6', 'subO_external_fun_vestedPartial_11_Block2_7').
at('subO_external_fun_vestedPartial_11_Block2_7', return([var(v6), var(v4)])).
at('subO_external_fun_vestedPartial_11_Block1_1', fun_call(subO_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [])).
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
at('subO_fun_claimable_143_Block0_1', fun_call(subO_convert_t_rational_1_by_1_to_t_uint256, [num(0x01)], [var(v5)])).
nextlab('subO_fun_claimable_143_Block0_1', 'subO_fun_claimable_143_Block0_2').
at('subO_fun_claimable_143_Block0_2', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v6)])).
nextlab('subO_fun_claimable_143_Block0_2', 'subO_fun_claimable_143_Block0_3').
at('subO_fun_claimable_143_Block0_3', asgn(var(v7), expr(lt([var(v5), var(v6)])))).
nextlab('subO_fun_claimable_143_Block0_3', 'subO_fun_claimable_143_Block0_4').
at('subO_fun_claimable_143_Block0_4', asgn(var(v8), expr(iszero([var(v7)])))).
nextlab('subO_fun_claimable_143_Block0_4', 'subO_fun_claimable_143_Block0_5').
at('subO_fun_claimable_143_Block0_5', fun_call(subO_require_helper, [var(v8)], [])).
nextlab('subO_fun_claimable_143_Block0_5', 'subO_fun_claimable_143_Block0_6').
at('subO_fun_claimable_143_Block0_6', fun_call(subO_convert_t_rational_2_by_1_to_t_uint256, [num(0x02)], [var(v10)])).
nextlab('subO_fun_claimable_143_Block0_6', 'subO_fun_claimable_143_Block0_7').
at('subO_fun_claimable_143_Block0_7', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v11)])).
nextlab('subO_fun_claimable_143_Block0_7', 'subO_fun_claimable_143_Block0_8').
at('subO_fun_claimable_143_Block0_8', asgn(var(v12), expr(gt([var(v10), var(v11)])))).
nextlab('subO_fun_claimable_143_Block0_8', 'subO_fun_claimable_143_Block0_9').
at('subO_fun_claimable_143_Block0_9', asgn(var(v13), expr(iszero([var(v12)])))).
nextlab('subO_fun_claimable_143_Block0_9', 'subO_fun_claimable_143_Block0_10').
at('subO_fun_claimable_143_Block0_10', fun_call(subO_require_helper, [var(v13)], [])).
nextlab('subO_fun_claimable_143_Block0_10', 'subO_fun_claimable_143_Block0_11').
at('subO_fun_claimable_143_Block0_11', fun_call(subO_cleanup_t_uint256, [var(v2)], [var(v14)])).
nextlab('subO_fun_claimable_143_Block0_11', 'subO_fun_claimable_143_Block0_12').
at('subO_fun_claimable_143_Block0_12', fun_call(subO_cleanup_t_uint256, [var(v1)], [var(v15)])).
nextlab('subO_fun_claimable_143_Block0_12', 'subO_fun_claimable_143_Block0_13').
at('subO_fun_claimable_143_Block0_13', asgn(var(v16), expr(gt([var(v14), var(v15)])))).
nextlab('subO_fun_claimable_143_Block0_13', 'subO_fun_claimable_143_Block0_14').
at('subO_fun_claimable_143_Block0_14', fun_call(subO_require_helper, [var(v16)], [])).
nextlab('subO_fun_claimable_143_Block0_14', 'subO_fun_claimable_143_Block0_15').
at('subO_fun_claimable_143_Block0_15', fun_call(subO_cleanup_t_uint256, [var(v3)], [var(v17)])).
nextlab('subO_fun_claimable_143_Block0_15', 'subO_fun_claimable_143_Block0_16').
at('subO_fun_claimable_143_Block0_16', fun_call(subO_cleanup_t_uint256, [var(v1)], [var(v18)])).
nextlab('subO_fun_claimable_143_Block0_16', 'subO_fun_claimable_143_Block0_17').
at('subO_fun_claimable_143_Block0_17', asgn(var(v19), expr(gt([var(v17), var(v18)])))).
nextlab('subO_fun_claimable_143_Block0_17', 'subO_fun_claimable_143_Block0_18').
at('subO_fun_claimable_143_Block0_18', fun_call(subO_require_helper, [var(v19)], [])).
nextlab('subO_fun_claimable_143_Block0_18', 'subO_fun_claimable_143_Block0_19').
at('subO_fun_claimable_143_Block0_19', fun_call(subO_convert_t_rational_0_by_1_to_t_uint256, [num(0x00)], [var(v21)])).
nextlab('subO_fun_claimable_143_Block0_19', 'subO_fun_claimable_143_Block0_20').
at('subO_fun_claimable_143_Block0_20', fun_call(subO_convert_t_rational_0_by_1_to_t_uint256, [num(0x00)], [var(v22)])).
nextlab('subO_fun_claimable_143_Block0_20', 'subO_fun_claimable_143_Block0_21').
at('subO_fun_claimable_143_Block0_21', fun_call(subO_convert_t_rational_0_by_1_to_t_uint256, [num(0x00)], [var(v23)])).
nextlab('subO_fun_claimable_143_Block0_21', 'subO_fun_claimable_143_Block0_22').
at('subO_fun_claimable_143_Block0_22', fun_call(subO_convert_t_rational_0_by_1_to_t_uint256, [num(0x00)], [var(v24)])).
nextlab('subO_fun_claimable_143_Block0_22', 'subO_fun_claimable_143_Block0_23').
at('subO_fun_claimable_143_Block0_23', goto('subO_fun_claimable_143_Block2_1')).
at('subO_fun_claimable_143_Block2_1', asgn(var(v25), expr(phiFunction([var(v24)])))).
nextlab('subO_fun_claimable_143_Block2_1', 'subO_fun_claimable_143_Block2_2').
at('subO_fun_claimable_143_Block2_1_2', asgn(var(v25), expr(phiFunction([var(v67)])))).
nextlab('subO_fun_claimable_143_Block2_1_2', 'subO_fun_claimable_143_Block2_2_2').
at('subO_fun_claimable_143_Block2_2', asgn(var(v32), expr(phiFunction([var(v23)])))).
nextlab('subO_fun_claimable_143_Block2_2', 'subO_fun_claimable_143_Block2_3').
at('subO_fun_claimable_143_Block2_2_2', asgn(var(v32), expr(phiFunction([var(v36)])))).
nextlab('subO_fun_claimable_143_Block2_2_2', 'subO_fun_claimable_143_Block2_3_2').
at('subO_fun_claimable_143_Block2_3', asgn(var(v41), expr(phiFunction([var(v2)])))).
nextlab('subO_fun_claimable_143_Block2_3', 'subO_fun_claimable_143_Block2_4').
at('subO_fun_claimable_143_Block2_3_2', asgn(var(v41), expr(phiFunction([var(v3)])))).
nextlab('subO_fun_claimable_143_Block2_3_2', 'subO_fun_claimable_143_Block2_4_2').
at('subO_fun_claimable_143_Block2_4', asgn(var(v52), expr(phiFunction([var(v22)])))).
nextlab('subO_fun_claimable_143_Block2_4', 'subO_fun_claimable_143_Block2_5').
at('subO_fun_claimable_143_Block2_4_2', asgn(var(v52), expr(phiFunction([var(v73)])))).
nextlab('subO_fun_claimable_143_Block2_4_2', 'subO_fun_claimable_143_Block2_5_2').
at('subO_fun_claimable_143_Block2_5', asgn(var(v56), expr(phiFunction([var(v21)])))).
nextlab('subO_fun_claimable_143_Block2_5', 'subO_fun_claimable_143_Block2_6').
at('subO_fun_claimable_143_Block2_5_2', asgn(var(v56), expr(phiFunction([var(v74)])))).
nextlab('subO_fun_claimable_143_Block2_5_2', 'subO_fun_claimable_143_Block2_6').
at('subO_fun_claimable_143_Block2_6', fun_call(subO_cleanup_t_uint256, [var(v0)], [var(v27)])).
nextlab('subO_fun_claimable_143_Block2_6', 'subO_fun_claimable_143_Block2_7').
at('subO_fun_claimable_143_Block2_7', fun_call(subO_cleanup_t_uint256, [var(v25)], [var(v28)])).
nextlab('subO_fun_claimable_143_Block2_7', 'subO_fun_claimable_143_Block2_8').
at('subO_fun_claimable_143_Block2_8', asgn(var(v29), expr(lt([var(v27), var(v28)])))).
nextlab('subO_fun_claimable_143_Block2_8', 'subO_fun_claimable_143_Block2_9').
at('subO_fun_claimable_143_Block2_9', asgn(var(v30), expr(iszero([var(v29)])))).
nextlab('subO_fun_claimable_143_Block2_9', 'subO_fun_claimable_143_Block2_jump').
at('subO_fun_claimable_143_Block2_jump', cj(var(v30), 'subO_fun_claimable_143_Block6_1', 'subO_fun_claimable_143_Block5_1')).
at('subO_fun_claimable_143_Block6_1', fun_call(subO_constant_AMOUNT_7, [], [var(v35)])).
nextlab('subO_fun_claimable_143_Block6_1', 'subO_fun_claimable_143_Block6_2').
at('subO_fun_claimable_143_Block6_2', fun_call(subO_checked_add_t_uint256, [var(v35), var(v32)], [var(v36)])).
nextlab('subO_fun_claimable_143_Block6_2', 'subO_fun_claimable_143_Block6_3').
at('subO_fun_claimable_143_Block6_3', fun_call(subO_constant_YEAR_4, [], [var(v43)])).
nextlab('subO_fun_claimable_143_Block6_3', 'subO_fun_claimable_143_Block6_4').
at('subO_fun_claimable_143_Block6_4', fun_call(subO_checked_add_t_uint256, [var(v43), var(v41)], [var(v44)])).
nextlab('subO_fun_claimable_143_Block6_4', 'subO_fun_claimable_143_Block6_5').
at('subO_fun_claimable_143_Block6_5', fun_call(subO_cleanup_t_uint256, [var(v44)], [var(v45)])).
nextlab('subO_fun_claimable_143_Block6_5', 'subO_fun_claimable_143_Block6_6').
at('subO_fun_claimable_143_Block6_6', fun_call(subO_cleanup_t_uint256, [var(v1)], [var(v46)])).
nextlab('subO_fun_claimable_143_Block6_6', 'subO_fun_claimable_143_Block6_7').
at('subO_fun_claimable_143_Block6_7', asgn(var(v47), expr(lt([var(v45), var(v46)])))).
nextlab('subO_fun_claimable_143_Block6_7', 'subO_fun_claimable_143_Block6_8').
at('subO_fun_claimable_143_Block6_8', asgn(var(v48), expr(iszero([var(v47)])))).
nextlab('subO_fun_claimable_143_Block6_8', 'subO_fun_claimable_143_Block6_9').
at('subO_fun_claimable_143_Block6_9', asgn(var(v49), expr(eq([num(0x00), var(v48)])))).
nextlab('subO_fun_claimable_143_Block6_9', 'subO_fun_claimable_143_Block6_jump').
at('subO_fun_claimable_143_Block6_jump', cj(var(v49), 'subO_fun_claimable_143_Block10_1', 'subO_fun_claimable_143_Block9_1')).
at('subO_fun_claimable_143_Block5_1', goto('subO_fun_claimable_143_Block4_1')).
at('subO_fun_claimable_143_Block10_1', fun_call(subO_constant_AMOUNT_7, [], [var(v58)])).
nextlab('subO_fun_claimable_143_Block10_1', 'subO_fun_claimable_143_Block10_2').
at('subO_fun_claimable_143_Block10_2', fun_call(subO_checked_add_t_uint256, [var(v58), var(v56)], [var(v59)])).
nextlab('subO_fun_claimable_143_Block10_2', 'subO_fun_claimable_143_Block10_3').
at('subO_fun_claimable_143_Block10_3', goto('subO_fun_claimable_143_Block8_1_9')).
at('subO_fun_claimable_143_Block9_1', fun_call(subO_checked_sub_t_uint256, [var(v41), var(v1)], [var(v50)])).
nextlab('subO_fun_claimable_143_Block9_1', 'subO_fun_claimable_143_Block9_2').
at('subO_fun_claimable_143_Block9_2', fun_call(subO_checked_add_t_uint256, [var(v50), var(v52)], [var(v54)])).
nextlab('subO_fun_claimable_143_Block9_2', 'subO_fun_claimable_143_Block9_3').
at('subO_fun_claimable_143_Block9_3', goto('subO_fun_claimable_143_Block8_1_8')).
at('subO_fun_claimable_143_Block4_1', fun_call(subO_read_from_storage_split_offset_0_t_uint256, [off(0x00)], [var(v75)])).
nextlab('subO_fun_claimable_143_Block4_1', 'subO_fun_claimable_143_Block4_2').
at('subO_fun_claimable_143_Block4_2', fun_call(subO_checked_add_t_uint256, [var(v56), var(v75)], [var(v76)])).
nextlab('subO_fun_claimable_143_Block4_2', 'subO_fun_claimable_143_Block4_3').
at('subO_fun_claimable_143_Block4_3', fun_call(subO_update_storage_value_offset_0_t_uint256_to_t_uint256, [var(v76), off(0x00)], [])).
nextlab('subO_fun_claimable_143_Block4_3', 'subO_fun_claimable_143_Block4_4').
at('subO_fun_claimable_143_Block4_4', fun_call(subO_update_storage_value_offset_0_t_uint256_to_t_uint256, [var(v52), off(0x01)], [])).
nextlab('subO_fun_claimable_143_Block4_4', 'subO_fun_claimable_143_Block4_5').
at('subO_fun_claimable_143_Block4_5', fun_call(subO_read_from_storage_split_offset_0_t_uint256, [off(0x00)], [var(v77)])).
nextlab('subO_fun_claimable_143_Block4_5', 'subO_fun_claimable_143_Block4_6').
at('subO_fun_claimable_143_Block4_6', fun_call(subO_checked_add_t_uint256, [var(v52), var(v77)], [var(v78)])).
nextlab('subO_fun_claimable_143_Block4_6', 'subO_fun_claimable_143_Block4_7').
at('subO_fun_claimable_143_Block4_7', fun_call(subO_cleanup_t_uint256, [var(v32)], [var(v79)])).
nextlab('subO_fun_claimable_143_Block4_7', 'subO_fun_claimable_143_Block4_8').
at('subO_fun_claimable_143_Block4_8', fun_call(subO_cleanup_t_uint256, [var(v78)], [var(v80)])).
nextlab('subO_fun_claimable_143_Block4_8', 'subO_fun_claimable_143_Block4_9').
at('subO_fun_claimable_143_Block4_9', asgn(var(v81), expr(gt([var(v79), var(v80)])))).
nextlab('subO_fun_claimable_143_Block4_9', 'subO_fun_claimable_143_Block4_10').
at('subO_fun_claimable_143_Block4_10', asgn(var(v82), expr(iszero([var(v81)])))).
nextlab('subO_fun_claimable_143_Block4_10', 'subO_fun_claimable_143_Block4_11').
at('subO_fun_claimable_143_Block4_11', fun_call(subO_assert_helper, [var(v82)], [])).
nextlab('subO_fun_claimable_143_Block4_11', 'subO_fun_claimable_143_Block4_12').
at('subO_fun_claimable_143_Block4_12', fun_call(subO_convert_t_rational_1042_by_1_to_t_uint256, [num(0x0412)], [var(v84)])).
nextlab('subO_fun_claimable_143_Block4_12', 'subO_fun_claimable_143_Block4_13').
at('subO_fun_claimable_143_Block4_13', fun_call(subO_convert_t_rational_1000_by_1_to_t_uint256, [num(0x03e8)], [var(v86)])).
nextlab('subO_fun_claimable_143_Block4_13', 'subO_fun_claimable_143_Block4_14').
at('subO_fun_claimable_143_Block4_14', fun_call(subO_cleanup_t_uint256, [var(v84)], [var(v87)])).
nextlab('subO_fun_claimable_143_Block4_14', 'subO_fun_claimable_143_Block4_15').
at('subO_fun_claimable_143_Block4_15', asgn(var(v88), expr(lt([var(v86), var(v87)])))).
nextlab('subO_fun_claimable_143_Block4_15', 'subO_fun_claimable_143_Block4_16').
at('subO_fun_claimable_143_Block4_16', fun_call(subO_assert_helper, [var(v88)], [])).
nextlab('subO_fun_claimable_143_Block4_16', 'subO_fun_claimable_143_ret').
at('subO_fun_claimable_143_ret', ret([])).
at('subO_fun_claimable_143_Block8_1_8', asgn(var(v73), expr(phiFunction([var(v54)])))).
nextlab('subO_fun_claimable_143_Block8_1_8', 'subO_fun_claimable_143_Block8_2_8').
at('subO_fun_claimable_143_Block8_1_9', asgn(var(v73), expr(phiFunction([var(v52)])))).
nextlab('subO_fun_claimable_143_Block8_1_9', 'subO_fun_claimable_143_Block8_2_9').
at('subO_fun_claimable_143_Block8_2_8', asgn(var(v74), expr(phiFunction([var(v56)])))).
nextlab('subO_fun_claimable_143_Block8_2_8', 'subO_fun_claimable_143_Block8_3').
at('subO_fun_claimable_143_Block8_2_9', asgn(var(v74), expr(phiFunction([var(v59)])))).
nextlab('subO_fun_claimable_143_Block8_2_9', 'subO_fun_claimable_143_Block8_3').
at('subO_fun_claimable_143_Block8_3', goto('subO_fun_claimable_143_Block3_1')).
at('subO_fun_claimable_143_Block3_1', fun_call(subO_increment_wrapping_t_uint256, [var(v25)], [var(v67)])).
nextlab('subO_fun_claimable_143_Block3_1', 'subO_fun_claimable_143_Block3_2').
at('subO_fun_claimable_143_Block3_2', goto('subO_fun_claimable_143_Block2_1_2')).
at('subO_getter_fun_vestedFull_9_Block0_1', fun_call(subO_read_from_storage_split_dynamic_t_uint256, [num(0x00), num(0x00)], [var(v1)])).
nextlab('subO_getter_fun_vestedFull_9_Block0_1', 'subO_getter_fun_vestedFull_9_ret').
at('subO_getter_fun_vestedFull_9_ret', ret([var(v1)])).
at('subO_getter_fun_vestedPartial_11_Block0_1', fun_call(subO_read_from_storage_split_dynamic_t_uint256, [num(0x00), num(0x01)], [var(v2)])).
nextlab('subO_getter_fun_vestedPartial_11_Block0_1', 'subO_getter_fun_vestedPartial_11_ret').
at('subO_getter_fun_vestedPartial_11_ret', ret([var(v2)])).
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
at('subO_require_helper_Block0_1', asgn(var(v1), expr(iszero([var(v0)])))).
nextlab('subO_require_helper_Block0_1', 'subO_require_helper_Block0_jump').
at('subO_require_helper_Block0_jump', cj(var(v1), 'subO_require_helper_ret', 'subO_require_helper_Block1_1')).
at('subO_require_helper_ret', ret([])).
at('subO_require_helper_Block1_1', revert([num(0x00), mem(0x00)])).
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
nextlab('subO_validator_revert_t_uint256_Block0_3', 'subO_validator_revert_t_uint256_Block0_jump').
at('subO_validator_revert_t_uint256_Block0_jump', cj(var(v3), 'subO_validator_revert_t_uint256_ret', 'subO_validator_revert_t_uint256_Block1_1')).
at('subO_validator_revert_t_uint256_ret', ret([])).
at('subO_validator_revert_t_uint256_Block1_1', revert([num(0x00), mem(0x00)])).
at('start_contract', fun_call(init_contract, [], [])).
nextlab('start_contract', 'runtime_contract').
at('runtime_contract', fun_call(r_BootVesting_144_deployed, [], [])).
at('init_contract_Block0_1', asgn(var(v0), expr(memoryguard))).
nextlab('init_contract_Block0_1', 'init_contract_Block0_2').
at('init_contract_Block0_2', mstore([var(v0), mem(0x40)])).
nextlab('init_contract_Block0_2', 'init_contract_Block0_3').
at('init_contract_Block0_3', asgn(var(v2), expr(callvalue))).
nextlab('init_contract_Block0_3', 'init_contract_Block0_jump').
at('init_contract_Block0_jump', cj(var(v2), 'init_contract_Block2_1', 'init_contract_Block1_1')).
at('init_contract_Block2_1', fun_call(obj_constructor_BootVesting_144, [], [])).
nextlab('init_contract_Block2_1', 'init_contract_ret').
at('init_contract_ret', ret([])).
at('init_contract_Block1_1', fun_call(obj_revert_error_ca66f745a3ce8ff40e2ccaf1ad45db7774001b90d25810abd9040049be7bf4bb, [], [])).
at('BootVesting_144_deployed_Block0_1', asgn(var(v0), expr(memoryguard))).
nextlab('BootVesting_144_deployed_Block0_1', 'BootVesting_144_deployed_Block0_2').
at('BootVesting_144_deployed_Block0_2', mstore([var(v0), mem(0x40)])).
nextlab('BootVesting_144_deployed_Block0_2', 'BootVesting_144_deployed_Block0_3').
at('BootVesting_144_deployed_Block0_3', asgn(var(v3), expr(calldatasize))).
nextlab('BootVesting_144_deployed_Block0_3', 'BootVesting_144_deployed_Block0_4').
at('BootVesting_144_deployed_Block0_4', asgn(var(v4), expr(lt([num(0x04), var(v3)])))).
nextlab('BootVesting_144_deployed_Block0_4', 'BootVesting_144_deployed_Block0_5').
at('BootVesting_144_deployed_Block0_5', asgn(var(v5), expr(iszero([var(v4)])))).
nextlab('BootVesting_144_deployed_Block0_5', 'BootVesting_144_deployed_Block0_jump').
at('BootVesting_144_deployed_Block0_jump', cj(var(v5), 'BootVesting_144_deployed_Block2_1', 'BootVesting_144_deployed_Block1_1')).
at('BootVesting_144_deployed_Block2_1', fun_call(subO_revert_error_42b3090547df1d2001c96683413b8cf91c1b902ef5e3cb8d9f6f304cf7446f74, [], [])).
at('BootVesting_144_deployed_Block1_1', asgn(var(v7), expr(calldataload([num(0x00)])))).
nextlab('BootVesting_144_deployed_Block1_1', 'BootVesting_144_deployed_Block1_2').
at('BootVesting_144_deployed_Block1_2', fun_call(subO_shift_right_224_unsigned, [var(v7)], [var(v8)])).
nextlab('BootVesting_144_deployed_Block1_2', 'BootVesting_144_deployed_Block1_3').
at('BootVesting_144_deployed_Block1_3', asgn(var(v9), expr(eq([num(0x3125ac32), var(v8)])))).
nextlab('BootVesting_144_deployed_Block1_3', 'BootVesting_144_deployed_Block1_jump').
at('BootVesting_144_deployed_Block1_jump', cj(var(v9), 'BootVesting_144_deployed_Block5_1', 'BootVesting_144_deployed_Block4_1')).
at('BootVesting_144_deployed_Block5_1', asgn(var(v11), expr(eq([num(0xe273f0d5), var(v8)])))).
nextlab('BootVesting_144_deployed_Block5_1', 'BootVesting_144_deployed_Block5_jump').
at('BootVesting_144_deployed_Block5_jump', cj(var(v11), 'BootVesting_144_deployed_Block8_1', 'BootVesting_144_deployed_Block7_1')).
at('BootVesting_144_deployed_Block4_1', fun_call(subO_external_fun_claimable_143, [], [])).
at('BootVesting_144_deployed_Block8_1', asgn(var(v13), expr(eq([num(0xe42e4ba3), var(v8)])))).
nextlab('BootVesting_144_deployed_Block8_1', 'BootVesting_144_deployed_Block8_jump').
at('BootVesting_144_deployed_Block8_jump', cj(var(v13), 'BootVesting_144_deployed_Block11_1', 'BootVesting_144_deployed_Block10_1')).
at('BootVesting_144_deployed_Block7_1', fun_call(subO_external_fun_vestedFull_9, [], [])).
at('BootVesting_144_deployed_Block11_1', goto('BootVesting_144_deployed_Block3_1')).
at('BootVesting_144_deployed_Block10_1', fun_call(subO_external_fun_vestedPartial_11, [], [])).
at('BootVesting_144_deployed_Block3_1', goto('BootVesting_144_deployed_Block2_1')).



:- include('BootVesting.aux.pl').