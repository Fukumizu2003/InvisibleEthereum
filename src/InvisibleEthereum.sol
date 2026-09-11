// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "node_modules/@zk-kit/incremental-merkle-tree.sol/IncrementalBinaryTree.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DepositVerifier.sol";
import "./TransferVerifier.sol";
import "./WithdrawVerifier.sol";

contract InvisibleEthereum is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    event NewCommitment(uint256 indexed index, uint256 commitment, uint256[5] crypted_transaction);
    
    using IncrementalBinaryTree for IncrementalTreeData;

    uint256 public totalCommitments;
    IncrementalTreeData public merkleTree;
    mapping (uint256 => bool) public merkleRootHistory;
    mapping (uint256 => bool) public nullifiers;

    // Verifier addresses will be altered in the future.
    DepositVerifier depositVerifier = DepositVerifier(0xd17404c5354C55F0215cCc0c81902F997Dd574BB);
    TransferVerifier transferVerifier = TransferVerifier(0xB43c4F9102a45cA875D2Bc5CfFF26391f198EfCd);
    WithdrawVerifier withdrawVerifier = WithdrawVerifier(0xef4f9639457f282edD4FE214d3DC3ff4A8E27DBA);

    uint256 public constant fixedFee = 0.00005 ether;
    uint256 public constant upperLimit = 0x1000000000000000000000000000000000000000000000000000000000000000;

    constructor() Ownable(msg.sender) {
        merkleTree.initWithDefaultZeroes(32);
    }

    /*
        _pubSignals[0]: commitment
        _pubSignals[1]: token_contract_address
        _pubSignals[2]: amount
    */
    function deposit(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[3] calldata _pubSignals,
        uint256[5] calldata transaction
    ) public payable nonReentrant {
        _checkFormat(_pubSignals[1], _pubSignals[2]);

        bool valid = depositVerifier.verifyProof(_pA, _pB, _pC, _pubSignals);
        require(valid, "Groth16 verification failed.");

        uint256 commitment = _pubSignals[0];
        address token = address(uint160(_pubSignals[1]));
        uint256 amount = _pubSignals[2];
        if (token == address(0)) {
            require(amount > fixedFee, "Deposit ETH must be more than 0.00005 ETH.");
        }
    
        uint256 fee = fixedFee;
        if (token == address(0)) {
            fee += amount/1000;
            require(msg.value >= amount + fee, "Required amount of ETH: 0.00005 + (deposit amount)*1.001");
            if (msg.value > amount + fee) {
                (bool success, ) = payable(msg.sender).call{value: msg.value - amount - fee}("");
                require(success, "Change ETH refund failure.");
            }

            _imposeNativeFee(fee);
        } else {
            require(msg.value >= fee, "ERC20 deposit fee 0.00005 ETH is required.");

            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(token).safeTransferFrom(msg.sender, owner(), amount/1000);

            if (msg.value > fee) {
                (bool success, ) = payable(msg.sender).call{value: msg.value - fee}("");
                require(success, "Change ETH refund failure.");
            }

            _imposeNativeFee(fee);
        }

        _addNewCommitment(commitment);
        emit NewCommitment(totalCommitments - 1, commitment, transaction);
    }

    /*
        _pubSignals[0]: root
        _pubSignals[1~10]: nullifier
        _pubSignals[11]: change_commitment
        _pubSignals[12]: token_contract_address
        _pubSignals[13]: withdrawal_amount
    */
    function withdraw(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[14] calldata _pubSignals,
        address payable receiver,
        uint256[5] calldata transaction
    ) public payable nonReentrant {
        _checkFormat(_pubSignals[3], _pubSignals[4]);

        bool valid = withdrawVerifier.verifyProof(_pA, _pB, _pC, _pubSignals);
        require(valid, "Groth16 verification failed.");

        uint256 proofRoot = _pubSignals[0];
        uint256 changeCommitment = _pubSignals[2];
        address token = address(uint160(_pubSignals[3]));
        uint256 amount = _pubSignals[4];

        require(amount > fixedFee, "Commitment less than 0.00005 ETH cannot be withdrawn.");
        require(_isValidRoot(proofRoot), "Merkle root did not match.");
        require(!nullifiers[nullifier], "Commitment is already consumed.");

        uint256 fee = fixedFee;

        if (token == address(0)) {
            fee += amount/1000;
            (bool success, ) = receiver.call{value: amount - fee}("");
            require(success, "ETH withdraw failed.");

            _imposeNativeFee(fee);
        } else {
            require(msg.value >= fee, "ERC20 withdraw fee 0.00005 ETH is required.");
            if (msg.value > fee) {
                (bool success, ) = payable(msg.sender).call{value: msg.value - fee}("");
                require(success, "Change ETH refund failed.");
            }
    
            IERC20(token).safeTransfer(receiver, amount - amount/1000);

            _imposeNativeFee(fee);
            _imposeERC20Fee(token, amount/1000);
        }

        for (uint i = 1; i <= 10; i++) {
            if (_pubSignals[i] != 0) {
                _addNullifier(_pubSignals[i]);
            }
        }

        if (changeCommitment != 0) {
            _addNewCommitment(changeCommitment);
            emit NewCommitment(totalCommitments - 1, changeCommitment, transaction);
        }
    }

    /*
        _pubSignals[0]: root
        _pubSignals[1]: new_commitment
        _pubSignals[2]: change_commitment
        _pubSignals[3~12]: nullifier
    */
    function transfer(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[13] calldata _pubSignals,
        uint256[5] calldata newTransaction,
        uint256[5] calldata changeTransaction
    ) public payable {
        require(msg.value >= fixedFee, "Transfer fee 0.00005 ETH is required.");
        if (msg.value > fixedFee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - fixedFee}("");
            require(success, "Change ETH refund failed.");
        }
        bool valid = transferVerifier.verifyProof(_pA, _pB, _pC, _pubSignals);
        require(valid, "Groth16 verification failed.");

        uint256 proofRoot = _pubSignals[0];
        uint256 newCommitment = _pubSignals[1];
        uint256 changeCommitment = _pubSignals[2];

        require(_isValidRoot(proofRoot), "Merkle root did not match.");
        require(!nullifiers[nullifier], "Commitment is already consumed.");

        if (changeCommitment != 0) {
            _addNewCommitment(changeCommitment);
            emit NewCommitment(totalCommitments - 1, changeCommitment, changeTransaction);
        }

        _addNewCommitment(newCommitment);
        emit NewCommitment(totalCommitments - 1, newCommitment, newTransaction);

        _imposeNativeFee(fixedFee);

        for (uint i = 3; i <= 12; i++) {
            _addNullifier(_pubSignals[i]);
        }
    }

    function getTotalCommitments() public view returns(uint256) {
        return totalCommitments;
    }

    function _isValidRoot(uint256 root) private view returns(bool) {
        return merkleRootHistory[root];
    }

    function _addNewCommitment(uint256 commitment) private {
        if (commitment != 0) {
            merkleTree.insert(commitment);
            totalCommitments++;
            merkleRootHistory[merkleTree.root] = true;
        }
    }

    function _addNullifier(uint256 nullifier) private {
        if (nullifier != 0) {
            nullifiers[nullifier] = true;
        }
    }

    function _imposeNativeFee(uint256 fee) private {
        (bool success, ) = owner().call{value: fee}("");
        require(success, "Transfer fee impose failed.");
    }

    function _imposeERC20Fee(address token, uint256 fee) private {
        IERC20(token).safeTransfer(owner(), fee);
    }

    function _checkFormat(uint256 token, uint256 amount) private pure {
        require(token >> 160 == 0, "Invalid token contract address. (overed 20 bytes)");
        require(amount < upperLimit, "Token amount must be within 252 bits.");
    }

}
