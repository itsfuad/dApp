// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Treasury.sol";

contract SimpleDAO {
    struct Proposal {
        uint256 id;
        string description;
        address payable recipient;
        uint256 amount;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
        bool executed;
    }

    Treasury public treasury;
    uint256 public nextProposalId;
    uint256 public votingDuration; // in seconds

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(
        uint256 indexed id,
        string description,
        address indexed creator,
        address indexed recipient,
        uint256 amount,
        uint256 deadline
    );

    event Voted(
        uint256 indexed id,
        address indexed voter,
        bool support
    );

    event ProposalExecuted(
        uint256 indexed id,
        bool success
    );

    constructor(uint256 _votingDuration) {
        votingDuration = _votingDuration;
    }

    function setTreasury(address _treasury) external {
        treasury = Treasury(_treasury);
    }

    function createProposal(
        string calldata description,
        address payable recipient,
        uint256 amount
    ) external returns (uint256) {
        uint256 id = nextProposalId;
        nextProposalId++;

        proposals[id] = Proposal({
            id: id,
            description: description,
            recipient: recipient,
            amount: amount,
            yesVotes: 0,
            noVotes: 0,
            deadline: block.timestamp + votingDuration,
            executed: false
        });

        emit ProposalCreated(
            id,
            description,
            msg.sender,
            recipient,
            amount,
            block.timestamp + votingDuration
        );

        return id;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp <= p.deadline, "Voting period ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            p.yesVotes += 1;
        } else {
            p.noVotes += 1;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    function getProposal(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            string memory description,
            address recipient,
            uint256 amount,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 deadline,
            bool executed
        )
    {
        Proposal storage p = proposals[proposalId];
        return (
            p.id,
            p.description,
            p.recipient,
            p.amount,
            p.yesVotes,
            p.noVotes,
            p.deadline,
            p.executed
        );
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp > p.deadline, "Voting still active");
        require(!p.executed, "Already executed");

        uint256 totalVotes = p.yesVotes + p.noVotes;
        require(totalVotes > 0, "No votes");

        bool success = false;

        if (p.yesVotes > p.noVotes) {
            treasury.executePayment(p.recipient, p.amount, p.description);
            success = true;
        }

        p.executed = true;
        emit ProposalExecuted(proposalId, success);
    }
}
