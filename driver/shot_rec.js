// const { newBarretenbergApiSync } = require("@aztec/bb.js")
const { buildPoseidon } = require("circomlibjs")
const { writeFileSync, readFileSync } = require('fs');
const { resolve } = require('path');
const { stringify } = require('@iarna/toml')
const { execSync } = require('child_process');
const crypto = require('crypto');


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

const getShotProof = (inputs) => {
    let path = `${resolve(__dirname)}/../circuits/shot/`;
    // write board prover.toml
    writeFileSync(`${path}/Prover.toml`, stringify(inputs));
    // generate witness with nargo (nargo compile main has already been run)
    execSync('nargo execute witness', { cwd: path });
    // generate proof with bb.js using recursive prover
    execSync('bb.js prove -o proof', { cwd: path });
    // write proof into json
    // execSync('bb.js proof_as_fields -p proof -n 4 -o proof.json', { cwd: path });
    // read the proof in as json
    // const proof = JSON.parse(readFileSync(`${path}/proof.json`));
    // return proof;
}

const getBoardVkey = (regen) => {
    let path = `${resolve(__dirname)}/../circuits/board/`;
    if (regen) {
        console.log("regenerating vkey");
        // compile circuit
        execSync('nargo compile main', { cwd: path });
        // write vkey
        execSync('bb.js write_vk -o vk', { cwd: path });
        // write vk to fields
        execSync('bb.js vk_as_fields -i vk -o vk.json', { cwd: path });
    }
    // read vkey
    const vkey = JSON.parse(readFileSync(`${path}/vk.json`));
    return {
        hash: vkey[0],
        key: vkey.slice(1)
    }
}
async function generateShotProof() {
    // instantiate
    let poseidon = await buildPoseidon();
    let F = poseidon.F;
    let _poseidon = (data) => F.toObject(poseidon(data));    

    // get vkey
    let vkey = await getBoardVkey(false)

    // set board configurations and secret trapdoors
    const host_board_placement = [
        0n, 0n, 1n,
        1n, 0n, 1n,
        2n, 0n, 1n,
        3n, 0n, 1n,
        4n, 0n, 1n
    ];
    // const host_trapdoor = F.toObject(crypto.randomBytes(30));
    const host_trapdoor = F.toObject(Buffer.from("230c1ab1f6f36da5189d670d6dc84eefb79109f3e4ad8a1388645f49ff16", 'hex'));

    const guest_board_placement = [
        0n, 0n, 0n,
        0n, 1n, 0n,
        0n, 2n, 0n,
        0n, 3n, 0n,
        0n, 4n, 0n
    ];
    // const guest_trapdoor = F.toObject(crypto.randomBytes(30));
    const guest_trapdoor = F.toObject(Buffer.from("abcc168f944376b7ccb8d1a5979e4b08e2f381bad9f7f14129538cb6373f", 'hex'));

    // hash board configuraitons
    const host_board_hash = numToHex(F.toObject(poseidon([
        ...host_board_placement,
        host_trapdoor
    ])));

    const guest_board_hash = numToHex(F.toObject(poseidon([
        ...guest_board_placement,
        guest_trapdoor
    ])));

    // shot tree
    let shotTree = new IncrementalMerkleTree(_poseidon, 8, 0)
    // insert shot 0 (x * y)
    // shot index = guest (boolean 0 or 1) + x + y * 10
    shotTree.insert(0, 1n);
    // insert next shot
    let shot = [3, 7];
    let shotIndex = (100 + shot[0] + shot[1] * 10);
    shotTree.insert(shotIndex, 1n);
    const shotPath = tree
        .createProof(shotIndex) // index of bob
        .siblings.map((sibling) => numToHex(sibling[0]));

    // // generate shot proof 0
    // let shot_0_proof = getShotProof({
    //     hash: guest_board_hash,
    //     shot: [0n, 0n].map(coordinate => numToHex(coordinate)),
    //     hit: true,
    //     ships: guest_board_placement.map(coordinate => numToHex(coordinate)),
    //     trapdoor: numToHex(guest_trapdoor)
    // });

    console.log("shot_proof: ", shot_0_proof)
    // execSync('nargo execute witness', { cwd: path });
    // execSync('bb.js prove -o proof', { cwd: path });
    let path = `${resolve(__dirname)}/../circuits/shot/`;
    execSync('bb.js verify -k vk -p proof', { cwd: path, stdio: 'inherit' });

    

}

async function main() {
    await generateShotProof();
}

main()