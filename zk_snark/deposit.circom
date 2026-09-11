pragma circom 2.0.0;

include "./common.circom";

template Verify() {
    signal input token;
    signal input amount;
    signal input to;
    signal input tag;

    signal output commitment;

    component cm = Commitment();
    cm.token <== token;
    cm.amount <== amount;
    cm.to <== to;
    cm.tag <== tag;
    
    commitment <== cm.commitment;
}

component main {public [token, amount]} = Verify();
