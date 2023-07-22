use dep::std;

//
//  Circuit to determine shot validity and whether it was a hit or not
//
//  Input:
//      hash { pub Field } - Hash computed outside circuit representing current board state
//      hit { u1 } - Report on whether or not shot is a hit
//      ships { [Field: 15] } - Array that represents x and y coordinate of ships followed by orientation (horizontal / vertical) 
//
fn main(
    hash: pub Field,
    shot: pub [Field; 2],
    hit: pub bool,
    shot_root: pub Field,
    next_shot: pub [Field; 2],
    shot_path: pub [Field; 8],
    ships: [Field; 15],
    trapdoor: Field
) {
    // Ensure shots within board boundaries
    assert(shot[0] as u4 < 10);
    assert(shot[1] as u4 < 10);

    // // Ensure computed hash is equal to provided hash
    let mut preimage = [0; 16];
    for i in 0..15 {
        preimage[i] = ships[i];
    }
    preimage[15] = trapdoor;
    let computed_hash = std::hash::poseidon::bn254::hash_16(preimage);
    assert(hash == computed_hash);

    // Check whether shot coordinate is a hit or not and then contrain against hit declaration
    let hits = check_for_hit(ships, shot);
    assert(hits == hit);

    //
}

//
//  Checks whether a shot is taken at a coordinate that contains a ship
//
//  Input:
//      ships { [Field; 15] } - Array that represents x and y coordinate of ships followed by orientation (horizontal / vertical)
//      shot { [Field; 2] } - Array containing the x and y coordinate of a shot
//
//  Return - A boolean value of whether or not a shot has hit a coordinate occupied by a ship
//
fn check_for_hit(ships: [Field; 15], shot: [Field; 2]) -> bool {
    let shot = shot[0] + shot[1] * 10;
    let carrier = check_hit_5([ships[0], ships[1], ships[2]], shot);
    let battleship = check_hit_4([ships[3], ships[4], ships[5]], shot);
    let cruiser = check_hit_3([ships[6], ships[7], ships[8]], shot);
    let submarine = check_hit_3([ships[9], ships[10], ships[11]], shot);
    let destroyer = check_hit_2([ships[12], ships[13], ships[14]], shot);
    carrier | battleship | cruiser | submarine | destroyer
}


fn check_hit_5(ship: [Field; 3], shot: Field) -> bool {
    let mut hit = false;
    for i in 0..5 {
        let coordinate = ((ship[0] + i) + ship[1] * 10) * (1 - ship[2]) + (ship[0] + (ship[1] + i) * 10) * ship[2];
        // std::println(coordinate);
        // std::println(shot);
        std::println(hit);

        hit = hit | (coordinate  == shot);
        std::println(hit);
    }
    hit
}

fn check_hit_4(ship: [Field; 3], shot: Field) -> bool {
    let mut hit = false;
    for i in 0..4 {
        let coordinate = ((ship[0] + i) + ship[1] * 10) * (1 - ship[2]) + (ship[0] + (ship[1] + i) * 10) * ship[2];
        hit = hit | (coordinate  == shot);
    }
    hit
}

fn check_hit_3(ship: [Field; 3], shot: Field) -> bool {
    let mut hit = false;
    for i in 0..3 {
        let coordinate = ((ship[0] + i) + ship[1] * 10) * (1 - ship[2]) + (ship[0] + (ship[1] + i) * 10) * ship[2];
        hit = hit | (coordinate  == shot);
    }
    hit
}

fn check_hit_2(ship: [Field; 3], shot: Field) -> bool {
    let mut hit = false;
    for i in 0..2 {
        let coordinate = ((ship[0] + i) + ship[1] * 10) * (1 - ship[2]) + (ship[0] + (ship[1] + i) * 10) * ship[2];
        hit = hit | (coordinate  == shot);
    }
    hit
}

/**
 * Checks that a shot index is 0, and if it is update the shot index to be 1
 */
fn check_shot(turn: Field, shot: Field, path: [Field], root: Field) -> Field {
    // compute shot index in shot tree
    let shot_index = ((turn as u8) % 2) as Field + shot;
    // confirm a given shot has not already been made by checking inclusion in tree
    let valid_shot_root = compute_merkle_root_poseidon(
        0,
        shot_index,
        path
    );
    assert(valid_shot_root == root);
    // compute new root after inserting shot into shot tree
    compute_merkle_root_poseidon(
        1,
        shot_index,
        path
    )
}

// poseidon merkle root computation
fn compute_merkle_root_poseidon(leaf: Field, index: Field, hash_path: [Field]) -> Field {
    let n = hash_path.len();
    let index_bits = index.to_le_bits(n as u32);
    let mut current = leaf;
    for i in 0..n {
        let path_bit = index_bits[i] as bool;
        let (hash_left, hash_right) = if path_bit {
            (hash_path[i], current)
         } else {
            (current, hash_path[i])
         };

      current = std::hash::poseidon::bn254::hash_2([hash_left, hash_right]);
    };
    current
}

#[test]
fn test_ship() {
    let hash = 0x2874f63001927d1ad51b7264258fde28634385ef3bcc196da2447eaa94db15f4;
    let shot = [0, 0];
    let hit = false;
    let ships = [
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000001,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000002,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000003,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000000000000000000000000004,
        0x0000000000000000000000000000000000000000000000000000000000000000
    ];
    let trapdoor = 0x104782fabe8912ef34e70733b587dacd3f1d7aade4fd7ab290e7794aa6bcb130;

    main(hash, shot, hit, ships, trapdoor);
}

// #[test]
// fn test_hash() {
//     let ships = [
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000001,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000002,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000003,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000004,
//         0x0000000000000000000000000000000000000000000000000000000000000000
//     ];
//     let computed_hash = std::hash::poseidon::bn254::hash_15(ships);
//     let expected_hash = 0x2f4e9e81a02e1a3a7368115f21ca8980e61dd250cb8fa88b7f790ff967d7b2a2;
//     std::println(computed_hash);
//     std::println(expected_hash);

//     let preimage = [
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000001,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000002,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000003,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x0000000000000000000000000000000000000000000000000000000000000004,
//         0x0000000000000000000000000000000000000000000000000000000000000000,
//         0x104782fabe8912ef34e70733b587dacd3f1d7aade4fd7ab290e7794aa6bcb130
//     ];
//     let computed_hash2 = std::hash::poseidon::bn254::hash_16(preimage);
//     let expected_hash2 = 0x2874f63001927d1ad51b7264258fde28634385ef3bcc196da2447eaa94db15f4;
//     std::println(computed_hash2);
//     std::println(expected_hash2);
// }