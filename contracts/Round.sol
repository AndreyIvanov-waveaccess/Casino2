// contracts/Round.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Продолжительность выставления ставок
uint constant timespanBet = 1 hours;
// Продолжительность розыгрыша
uint constant timespanRound = 12 hours;
// Размер ставки
uint256 constant betAmount = 100 * 10 ** 18;

// Розыгрыш
contract Round is Ownable, KeeperCompatibleInterface {
    address[] public playersUp;
    address[] public playersDown;
    mapping(address => bool) public players;

    uint public deadlineBet;
    uint public deadlineRound;

    AggregatorV3Interface internal priceFeed;
    
    ERC20 private _token;
    
    int public priceRoundStart;
    
    bool public roundFinished = false;
    
    constructor(address _creator) {
        // Владельцем розыгрыша должен быть владелец казино, а не контракт казино
        transferOwnership(_creator);
        
        deadlineBet = block.timestamp + timespanBet;
        deadlineRound = block.timestamp + timespanRound;

        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        priceRoundStart = getLatestPrice();
        
        _token = ERC20(0x88206F12c123dA9811546d013419007c4d754175);
    }

    // Сделать ставку
    function makeBet(bool betUp) public {
        require(block.timestamp < deadlineBet, "acceptance of bets is over!");
        require(!players[msg.sender], "already bet!");
        
        _token.transferFrom(msg.sender, address(this), betAmount);
        
        players[msg.sender] = true;
        if (betUp) {
            playersUp.push(msg.sender);
        } else {
            playersDown.push(msg.sender);
        }
    } 

    // Просмотреть сделанные ставки
    function getPlayersUp() public view returns (address[] memory) {
        return playersUp;
    }

    function getPlayersDown() public view returns (address[] memory) {
        return playersDown;
    }

    function checkUpkeep(bytes calldata) external override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = block.timestamp >= deadlineRound && !roundFinished;
    }

    // завершение розыгрыша
    function performUpkeep(bytes calldata) external override {
        require(block.timestamp >= deadlineRound);
        roundFinished = true;
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "No balance");
        int priceRoundEnd = getLatestPrice();
        address[] memory winners = priceRoundEnd > priceRoundStart ? playersUp : playersDown;
        if (winners.length == 0) {
            _token.transfer(owner(), balance);
        } else {
            uint256 feeAmount = balance / 10;
            _token.transfer(owner(), feeAmount);
            uint256 prize = _token.balanceOf(address(this)) / winners.length;
            for (uint i = 0; i < winners.length; i++) {
                _token.transfer(winners[i], prize);
            }
        }
    }

    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

}