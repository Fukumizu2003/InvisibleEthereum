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

template VerifyHash() {
    signal input token;
    signal input amount;
    signal input zprivkey;
    signal input merklepath[32];
    signal input pathbits[32];
    signal input newzaddress;
    signal input tag;
    signal input newtag;
    
    signal output root;
    signal output newcommitment;
    signal output nullifier;

    signal nullifykey;
    signal oldcommitment;
    signal hashbuf[33];
    signal zaddress;
    
    component assert252bits = Num2Bits(252);
    assert252bits.in <== amount;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== zprivkey;
    zaddress <== hasher.out;

    component hasher1 = Poseidon(4);
    hasher1.inputs[0] <== token;
    hasher1.inputs[1] <== amount;
    hasher1.inputs[2] <== zaddress;
    hasher1.inputs[3] <== tag;
    oldcommitment <== hasher1.out;

    hashbuf[0] <== oldcommitment;
    component rl[32];
    component pathHasher[32];
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

    component hasher2 = Poseidon(4);
    hasher2.inputs[0] <== token;
    hasher2.inputs[1] <== amount;
    hasher2.inputs[2] <== newzaddress;
    hasher2.inputs[3] <== newtag;
    newcommitment <== hasher2.out;

    component hasher3 = Poseidon(1);
    hasher3.inputs[0] <== zprivkey;
    nullifykey <== hasher3.out;

    component hasher4 = Poseidon(2);
    hasher4.inputs[0] <== oldcommitment;
    hasher4.inputs[1] <== nullifykey;
    nullifier <== hasher4.out;
}

component main = VerifyHash();
