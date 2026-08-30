pragma circom 2.0.0;

include "./common.circom";

template Verify() {
    signal input token;
    signal input amount;
    signal input spendkey;
    signal input merklepath[32];
    signal input pathbits[32];
    signal input tag;

    signal output root;
    signal output nullifier;

    signal nullifykey;
    signal commitment;
    signal hashbuf[33];
    signal zaddress;

    component calczaddress = Zaddress();
    calczaddress.spendkey <== spendkey;
    zaddress <== calczaddress.zaddress;

    component cm = Commitment();
    cm.token <== token;
    cm.amount <== amount;
    cm.to <== zaddress;
    cm.tag <== tag;
    commitment <== cm.commitment;

    component mpath = Merklepath();
    mpath.commitment <== commitment;
    for (var i = 0; i < 32; i++) {
        mpath.merklepath[i] <== merklepath[i];
        mpath.pathbits[i] <== pathbits[i];
    }
    root <== mpath.root;

    component nk = Nullifykey();
    nk.spendkey <== spendkey;
    nullifykey <== nk.nullifykey;

    component nf = Nullifier();
    nf.commitment <== commitment;
    nf.nullifykey <== nullifykey;
    nullifier <== nf.nullifier;
}

component main {public[token, amount]} = Verify();
