pragma circom 2.0.0;

include "./common.circom";

template VerifyHash() {
    signal input token;
    signal input amount;
    signal input spendkey;
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
    newcm.amount <== amount;
    newcm.to <== newzaddress;
    newcm.tag <== newtag;
    newcommitment <== newcm.commitment;

    component nk = Nullifykey();
    nk.spendkey <== spendkey;
    nullifykey <== nk.nullifykey;

    component nf = Nullifier();
    nf.commitment <== oldcommitment;
    nf.nullifykey <== nullifykey;
    nullifier <== nf.nullifier;
}

component main = VerifyHash();
