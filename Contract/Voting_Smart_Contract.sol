// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "fhevm/lib/TFHE.sol";

contract VotingSmartContract {

    uint public constant Min_Stake = 1; // to be defined
    uint public constant Minimum_Quorum = 2; // to be defined
    uint public Proposal_Count;
    address public owner;
    address[] public Validators_List;
    address[] public Proposers_List;

    function votingDelay() public pure returns (uint8) {
        return 1;
    } // to be defined

    function votingPeriod() public pure virtual returns (uint16) {
        return 70;
    } // to be defined

    struct Proposal {
        uint id;
        address proposer;
        uint Start_Block;
        uint End_Block;
        string description;
        uint Total_Voters;
        euint32 forVotes;
        euint32 againstVotes;
        bool Proposer_Reward_Distributed;
        mapping(address => Receipt) receipts;
        bool result;
    }

    struct Receipt {
        bool hasVoted;
        bool Voter_Reward_Distributed;
    }

    mapping(uint => Proposal) private proposals;
    mapping(address => bool) private validators;
    mapping(address => bool) private Authorized_Proposers;

    constructor(){
        owner = msg.sender;
        validators[owner] = true;
    }

    // An event emitted when a new proposal is created
    event ProposalCreated(
        uint id,
        address proposer,
        uint Start_Block,
        uint End_Block,
        string description,
        uint Total_Voters
    );

    // An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId);

    // An event emitted when there is a result for a proposal
    event ProposalResult(uint TotalVoters, bool result);

    // An event emitted when the mininum quorum is not achieved
    event Quorum(uint TotalVoters, string quorum);

    // An event emitted when the reward for participation is sent
    event RewardClaimed(address indexed recipient, uint256 amount);
 

    function Add_Validator(address _validator) public {
        require(msg.sender == owner, "Not authorized");
        require(!validators[_validator], "Validator already added");
        validators[_validator] = true;
        Validators_List.push(_validator);
    }

    function Add_Proposer(address _proposer) public {
        require(msg.sender == owner, "Not authorized");
        require(!Authorized_Proposers[_proposer], "Poposer already added");
        Authorized_Proposers[_proposer] = true;
        Proposers_List.push(_proposer);
    }

    function Add_Proposal(string memory description) public returns (uint) {
        require(Authorized_Proposers[msg.sender], "Propose: Not an authorized proposer");
        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());
        Proposal_Count++;
        uint TotalVoters = 0;
        uint proposalId = Proposal_Count;
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == 0, "Propose: ProposalID collsion");
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.forVotes = TFHE.asEuint32(0);
        proposal.againstVotes = TFHE.asEuint32(0);
        proposal.Start_Block = startBlock;
        proposal.End_Block = endBlock;
        proposal.Total_Voters = TotalVoters;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            startBlock,
            endBlock,
            description,
            TotalVoters
        );
        return proposal.id;
    }


     function Balance (address account_address) private view returns (uint){
        uint balancewei = account_address.balance;
        uint balance_ = balancewei / 1e18;
        return balance_;
    }

   ebool private support;
   euint32 private add_vote;

   function Cast_Vote(uint proposalId, bytes calldata _support) public {
        require(validators[msg.sender], "Only validators can call this function");
        require(Balance(msg.sender)>= Min_Stake,"Insufficient stakes");
        Proposal storage proposal = proposals[proposalId];
        require(block.number < proposal.End_Block, "CastVote: Voting round has ended");
        Receipt storage receipt = proposal.receipts[msg.sender];
        require(receipt.hasVoted == false, "CastVote: Voter already voted");
        add_vote = TFHE.asEuint32(Balance(msg.sender));
        support = TFHE.asEbool(_support);
        proposal.forVotes = TFHE.cmux(support, proposal.forVotes + add_vote, proposal.forVotes);
        proposal.againstVotes = TFHE.cmux(support, proposal.againstVotes, proposal.againstVotes + add_vote);
        receipt.hasVoted = true;
        proposal.Total_Voters++;
        emit VoteCast(msg.sender, proposalId);        
    }


    function getReceipt(uint proposalId) public view returns (Receipt memory) {
        require(validators[msg.sender], "Only validators can call this function");
        return proposals[proposalId].receipts[msg.sender];
    }


    string private quorum;

    function Is_Proposal_Accepted (uint proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.number > proposal.End_Block, "CastVote: Voting round not has ended");
        if (proposal.Total_Voters < Minimum_Quorum) {
            uint startBlock = add256(block.number, votingDelay());
            uint endBlock = add256(startBlock, votingPeriod()); 
            proposal.Start_Block = startBlock;
            proposal.End_Block = endBlock;
            proposal.forVotes = TFHE.asEuint32(0);
            proposal.againstVotes = TFHE.asEuint32(0);
            quorum = "Minimum quorum not reached, another voting round has been initiated.";
            emit Quorum(proposal.Total_Voters, quorum);
            proposal.Total_Voters = 0;
        }
        else {
            bool accepted = TFHE.decrypt(TFHE.le(proposal.againstVotes, proposal.forVotes));
            proposal.result = accepted;
            emit ProposalResult(proposal.Total_Voters, proposal.result);
        }
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }


}
