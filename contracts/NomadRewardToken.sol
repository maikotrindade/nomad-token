// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NomadRewardToken is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor() ERC20("NomadRewardToken",  "NRT") {
        _decimals = 18;
        _totalSupply = 1000000 * 10 ** _decimals;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
         _mint(msg.sender, 100_000_000_000 * 10**18 );
    }
}
