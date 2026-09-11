pragma circom 2.0.0;

include "node_modules/circomlib/circuits/comparators.circom";
include "./common.circom";

template Verify() {
    // sender info
    signal input token;
    signal input amount[10];
    signal input spendkey;
    signal input tag[10];
    signal input changetag;
    signal input merklepath[320];
    signal input pathbits[320];

    // receiver info
    signal input sendamount;
    signal input to;
    signal input newtag;

    signal output root;
    signal output newcommitment;
    signal output changecommitment;
    signal output nullifier[10];

    signal nullifykey;
    signal oldcommitment[10];
    signal zaddress;

    component lt = LessEqThan(252);
    var totalamount = 0;
    for (var i = 0; i < 10; i++) {
        totalamount += amount[i];
    }
    lt.in[0] <== sendamount;
    lt.in[1] <== totalamount;
    lt.out === 1;

    component calczaddress = Zaddress();
    calczaddress.spendkey <== spendkey;
    zaddress <== calczaddress.zaddress;

    component oldcm[10];
    for (var i = 0; i < 10; i++) {
        oldcm[i] = Commitment();
        oldcm[i].token <== token;
        oldcm[i].amount <== amount[i];
        oldcm[i].to <== zaddress;
        oldcm[i].tag <== tag[i];
        oldcommitment[i] <== oldcm[i].commitment;
    }

    component mpath = Merklepath();
    for (var i = 0; i < 10; i++) {
        mpath.commitment[i] <== oldcommitment[i];
    }
    for (var i = 0; i < 320; i++) {
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
    cngcm.amount <== totalamount - sendamount;
    cngcm.to <== zaddress;
    cngcm.tag <== changetag;
    changecommitment <== cngcm.commitment;

    component nk = Nullifykey();
    nk.spendkey <== spendkey;
    nullifykey <== nk.nullifykey;

    component nf[10];
    for (var i = 0; i < 10; i++) {
        nf[i] = Nullifier();
        nf[i].commitment <== oldcommitment[i];
        nf[i].nullifykey <== nullifykey;
        nullifier[i] <== nf[i].nullifier;
    }
}

component main = Verify();
