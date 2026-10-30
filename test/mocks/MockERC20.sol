// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MockERC20
/// @notice Minimal ERC-20 mock for testing.
contract MockERC20 {
    /// @notice Token name.
    string public name;
    /// @notice Token symbol.
    string public symbol;
    /// @notice Token decimals.
    uint8 public decimals;
    /// @notice Total token supply.
    uint256 public totalSupply;

    /// @notice Balance per address.
    mapping(address => uint256) public balanceOf;
    /// @notice Allowances per owner per spender.
    mapping(address => mapping(address => uint256)) public allowance;

    error InsufficientBalance();
    error InsufficientAllowance();

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /// @notice Mint tokens to an address.
    /// @param to Recipient.
    /// @param value Amount.
    function mint(address to, uint256 value) external {
        totalSupply += value;
        balanceOf[to] += value;
    }

    /// @notice Approve a spender.
    /// @param spender Spender address.
    /// @param value Amount.
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    /// @notice Transfer tokens.
    /// @param to Recipient.
    /// @param value Amount.
    function transfer(address to, uint256 value) external returns (bool) {
        if (balanceOf[msg.sender] < value) revert InsufficientBalance();
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }

    /// @notice Transfer tokens on behalf of another address.
    /// @param from Sender.
    /// @param to Recipient.
    /// @param value Amount.
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (balanceOf[from] < value) revert InsufficientBalance();
        if (allowance[from][msg.sender] < value) revert InsufficientAllowance();
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        return true;
    }
}
