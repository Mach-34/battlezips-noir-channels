// const { newBarretenbergApiSync } = require("@aztec/bb.js")
const { buildPoseidon } = require("circomlibjs")
const { writeFileSync, readFileSync } = require('fs');
const { resolve } = require('path');
const { stringify } = require('@iarna/toml')
const { execSync } = require('child_process');


const numToHex = (num) => {
    const hex = num.toString(16);
    // Add missing padding based of hex number length
    const padded = `${'0'.repeat(64 - hex.length)}${hex}`;
    return `0x${Buffer.from(padded, 'hex').toString('hex')}`;
};

const generateProverToml = (inputs) => {
    writeFileSync(`${resolve(__dirname)}/../circuits/board/Prover.toml`, stringify(inputs));
    console.log('Generating Prover.toml')
}

const getBoardProof = (inputs) => {
    let path = `${resolve(__dirname)}/../circuits/board/`;
    // write board prover.toml
    writeFileSync(`${path}/Prover.toml`, stringify(inputs));
    // generate witness with nargo (nargo compile main has already been run)
    execSync('nargo execute witness', { cwd: path });
    // generate proof with bb.js using recursive prover
    execSync('bb.js prove -o proof -r', { cwd: path });
    // write proof into json
    execSync('bb.js proof_as_fields -p proof -n 1 -o proof.json', { cwd: path });
    // read the proof in as json
    const proof = JSON.parse(readFileSync(`${path}/proof.json`));
    return proof;
}

async function generateGameOpeningProof() {
    // instantiate
    let poseidon = await buildPoseidon();
    let F = poseidon.F;

    // set board configurations
    const host_board_placement = [
        0, 0, 1,
        1, 0, 1,
        2, 0, 1,
        3, 0, 1,
        4, 0, 1
    ];
    const guest_board_placement = [
        0, 0, 0,
        0, 1, 0,
        0, 2, 0,
        0, 3, 0,
        0, 4, 0
    ];
    
    // hash board configuraitons
    const host_board_hash = numToHex(F.toObject(poseidon(host_board_placement)));
    const guest_board_hash = numToHex(F.toObject(poseidon(guest_board_placement)));

    // generate proofs for board configurations
    console.log("generating host proof");
    let host_proof = getBoardProof({
        hash: host_board_hash,
        ships: host_board_placement
    });
    console.log("generating guest proof");
    let guest_proof = getBoardProof({
        hash: guest_board_hash,
        ships: guest_board_placement
    });

    // generate recursive board proof (game opening)
    let inputs = {
        vkey_hash: "0x298fa0d63b987da1272142d4a03072bfff869910f9c037844657cb79324ed1bf", // cant figure out how to hardcode
        host_proof,
        host_board_hash,
        guest_proof,
        guest_board_hash
    };
    writeFileSync(`${resolve(__dirname)}/../circuits/board_recursive/Prover.toml`, stringify(inputs));
    console.log("Prove validity of recursive board verification/ opening proof: ");
    let path = `${resolve(__dirname)}/../circuits/board/`;
    execSync('nargo execute witness', { cwd: path });
    execSync('bb.js prove -o proof -r', { cwd: path });
    execSync('bb.js verify -k vk -p proof -r', { cwd: path, stdio: 'inherit' });
}

async function main() {
    await generateGameOpeningProof();
}

main()