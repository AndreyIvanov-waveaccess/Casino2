// contracts/Casino.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Round.sol";

contract Casino is Ownable {

    Round[] public rounds;

    function createRound() public onlyOwner {
        Round newRound = new Round(_msgSender());
        rounds.push(newRound);
    }

    function getRounds() public view returns (Round[] memory) {
        return rounds;
    }
}