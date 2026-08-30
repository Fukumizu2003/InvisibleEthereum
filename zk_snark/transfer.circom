pragma circom 2.0.0;

include "node_modules/circomlib/circuits/comparators.circom";
include "./common.circom";

template VerifyHash() {
    signal input token;
    signal input amount;
    signal input sendamount;
    signal input spendkey;
    signal input merklepath[32];
    signal input pathbits[32];
    signal input to;
    signal input tag;
    signal input newtag;

    signal output root;
    signal output newcommitment;
    signal output changecommitment;
    signal output nullifier;

    signal nullifykey;
    signal oldcommitment;
    signal hashbuf[33];
    signal zaddress;

    component lt = LessThan(252);
    lt.in[0] <== sendamount;
    lt.in[1] <== amount;
    lt.out === 1;

    component calczaddress = Zaddress();
    calczaddress.spendkey <== spendkey;
    zaddress <== calczaddress.zaddress;

    component oldcm = Commitment();
    oldcm.token <== token;
    oldcm.amount <== amount;
    oldcm.to <== zaddress;
    oldcm.tag <== tag;
    oldcommitment <== oldcm.commitment;

    component mpath = Merklepath();
    mpath.commitment <== oldcommitment;
    for (var i = 0; i < 32; i++) {
        mpath.merklepath[i] <== merklepath[i];
        mpath.pathbits[i] <== pathbits[i];
    }
    root <== mpath.root;
    
    component newcm = Commitment();
    newcm.token <== token;
    newcm.amount <== sendamount;
    newcm.to <== to;
    newcm.tag <== newtag;
    newcommitment <== newcm.commitment;

    component cngcm = Commitment();
    cngcm.token <== token;
    cngcm.amount <== amount - sendamount;
    cngcm.to <== zaddress;
    cngcm.tag <== tag;
    changecommitment <== cngcm.commitment;

    component nk = Nullifykey();
    nk.spendkey <== spendkey;
    nullifykey <== nk.nullifykey;

    component nf = Nullifier();
    nf.commitment <== oldcommitment;
    nf.nullifykey <== nullifykey;
    nullifier <== nf.nullifier;
}

component main = VerifyHash();
