pragma circom 2.0.0;

include "node_modules/circomlib/circuits/poseidon.circom";
include "node_modules/circomlib/circuits/bitify.circom";

template VerifyHash() {
    signal input token;
    signal input amount;
    signal input to;
    signal input tag;
    signal output commitment;

    component assert96bits = Num2Bits(96);
    assert96bits.in <== tag;

    component hasher = Poseidon(4);
    hasher.inputs[0] <== token;
    hasher.inputs[1] <== amount;
    hasher.inputs[2] <== to;
    hasher.inputs[3] <== tag;
    
    commitment <== hasher.out;
}

component main {public [token, amount]} = VerifyHash();
