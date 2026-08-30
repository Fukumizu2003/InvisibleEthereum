pragma circom 2.0.0;

include "node_modules/circomlib/circuits/poseidon.circom";
include "node_modules/circomlib/circuits/bitify.circom";

template AssertBit() {
    signal input bit;
    bit * (1 - bit) === 0;
}

template RorL() {
    signal input bit;
    signal input hash;
    signal input sibling;
    signal output right;
    signal output left;
    signal hashwhen0;
    signal siblingwhen0;
    signal hashwhen1;
    signal siblingwhen1;

    component assertion = AssertBit();
    assertion.bit <== bit;

    hashwhen0 <== hash * (1 - bit);
    siblingwhen0 <== sibling * (1 - bit);
    hashwhen1 <== hash * bit;
    siblingwhen1 <== sibling * bit;
    left <== hash + sibling - hashwhen1 - siblingwhen0;
    right <== hash + sibling - hashwhen0 - siblingwhen1;
}

template Zaddress() {
    signal input spendkey;

    signal output zaddress;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== spendkey;

    zaddress <== hasher.out;
}

template Commitment() {
    signal input token;
    signal input amount;
    signal input to;
    signal input tag;

    signal output commitment;

    component assert96bits = Num2Bits(96);
    assert96bits.in <== tag;

    component assert252bits = Num2Bits(252);
    assert252bits.in <== amount;

    component hasher = Poseidon(4);
    hasher.inputs[0] <== token;
    hasher.inputs[1] <== amount;
    hasher.inputs[2] <== to;
    hasher.inputs[3] <== tag;
    
    commitment <== hasher.out;
}

template Nullifykey() {
    signal input spendkey;

    signal output nullifykey;

    signal nullify_ascii <== 0x6e756c6c696679;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== spendkey;
    hasher.inputs[1] <== nullify_ascii;

    nullifykey <== hasher.out;
}

template Nullifier() {
    signal input commitment;
    signal input nullifykey;

    signal output nullifier;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== commitment;
    hasher.inputs[1] <== nullifykey;

    nullifier <== hasher.out;
}

template Merklepath() {
    signal input commitment;
    signal input merklepath[32];
    signal input pathbits[32];

    signal output root;

    signal hashbuf[33];

    component rl[32];
    component pathHasher[32];
    hashbuf[0] <== commitment;
    for (var i = 0; i < 32; i++) {
        rl[i] = RorL();
        rl[i].bit <== pathbits[i];
        rl[i].hash <== hashbuf[i];
        rl[i].sibling <== merklepath[i];
        pathHasher[i] = Poseidon(2);
        pathHasher[i].inputs[0] <== rl[i].left;
        pathHasher[i].inputs[1] <== rl[i].right;
        hashbuf[i+1] <== pathHasher[i].out;
    }
    root <== hashbuf[32];
}
