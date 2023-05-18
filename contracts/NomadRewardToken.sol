// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract NomadRewardToken is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor() ERC20("NomadRewardToken",  "NRT") {
        _decimals = 18;
        uint256 _totalSupply = 100_000_000_000 * 10**18;
        emit Transfer(address(0), msg.sender, _totalSupply);
        _mint(msg.sender, _totalSupply);
    }

    function transferRewards(address to, uint256 amount) public {
        _approve(owner(), to, amount);
        _transfer(owner(), to, amount);
        emit Transfer(address(0), msg.sender, amount);
    }
}
