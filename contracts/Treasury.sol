// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Treasury {
    address public dao;
    uint256 public totalBalance;

    mapping(address => uint256) public deposits;

    event Deposited(address indexed from, uint256 amount);
    event PaymentSimulated(address indexed to, uint256 amount, string note);

    modifier onlyDao() {
        require(msg.sender == dao, "Only DAO can execute payments");
        _;
    }

    constructor(address _dao) {
        dao = _dao;
    }

    function setDao(address _dao) external {
        require(dao == address(0) || msg.sender == dao, "Not authorized");
        dao = _dao;
    }

    function deposit() external payable {
        require(msg.value > 0, "No ETH sent");
        deposits[msg.sender] += msg.value;
        totalBalance += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function executePayment(address payable to, uint256 amount, string calldata note)
        external
        onlyDao
    {
        require(amount <= address(this).balance, "Not enough balance");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "Transfer failed");

        totalBalance -= amount;
        emit PaymentSimulated(to, amount, note);
    }
}
