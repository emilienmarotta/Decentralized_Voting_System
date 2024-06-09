// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Ballot {

    address private chairman; // Chairman of the voting session
    bool openBallot; // Status of voting session (open or closed)
    uint endTime; // Closing time of voting session

    struct Voter {
        uint weight; // Number of votes (2 if voting proxy, for example)
        uint remainingVotes; // Number of remaining votes
        address delegate; // Addresse of a possible delegate
    }

    struct Candidate {
        address address_; // Candidate's address
        uint voteCounter; // Vote counter
    }

    mapping(address => Voter) private voters; // Voter mapping
    Candidate[] private candidates; // Candidate list
    address[] private voterList; // Voter list

    constructor (address[] memory _candidates) {
        chairman = msg.sender; // The contract deployer becomes the chairman
        voters[chairman].weight = 1;
        voters[chairman].remainingVotes = 1;
        voterList.push(msg.sender);

        for (uint i = 0; i < _candidates.length; i ++) {
            candidates.push(Candidate(_candidates[i], 0));
        }    
    } 

    // Modifier to ensure that the session is open
    modifier isBallotOpen () {
        require(block.timestamp <= endTime, "The voting session is closed");
        _;
    }

    // Modifier to ensure that the session is closed
    modifier isBallotClosed () {
        require(block.timestamp > endTime, "The voting session is open");
        _;
    }

    // Function to open the session
    function setBallotToOpen(uint durationInMinutes_) external {
        require(msg.sender == chairman, "Only the chairman can perform this action");
        require(!openBallot, "The voting session is already open");
        endTime = block.timestamp + (durationInMinutes_ * 1 minutes);
        openBallot = true;
    }

    // Getter to get the chairman's address
    function getChairman() external view returns(address) {
        return chairman;
    }

    // Getter to get the address of candidates
    function getCandidates() external view returns(address[] memory) {
        address[] memory addresses_ = new address[](candidates.length);
        for (uint i = 0; i < candidates.length; i ++) {
            addresses_[i] = candidates[i].address_;
        }
        return addresses_;
    }

    // Getter to get the address of voters
    function getVoters() external view returns(address[] memory) {
        require(msg.sender == chairman, "Only the chairman can perform this action");
        return voterList;
    }

    // Function to give the right de vote to an address
    function giveRightToVote(address voter) external isBallotClosed {
        require(msg.sender == chairman, "Only the chairman can perform this action");
        require(voters[voter].weight == 0, "This voter already has the right to vote");

        voters[voter].weight = 1;
        voters[voter].remainingVotes = 1;
        
        voterList.push(voter);
    }

    // Function to make a voting proxy to an address 
    function makeVotingProxy(address _delegate) external isBallotClosed {
        require(voters[msg.sender].weight != 0, "You do not have the right to vote");
        require(voters[msg.sender].remainingVotes != 0, "You have already voted");
        require(voters[msg.sender].weight != 2, "You are a delegate for someone");
        require(msg.sender != _delegate, "You cannot make a voting proxy to yourself");
        require(voters[_delegate].weight != 0, "This person does not have the right to vote");
        require(voters[_delegate].weight != 2, "This person is already a delegate for someone");

        voters[_delegate].weight = 2;
        voters[_delegate].remainingVotes += 1;
        voters[msg.sender].weight = 0;
        voters[msg.sender].remainingVotes = 0;
        voters[msg.sender].delegate = _delegate;
    } 

    // Function to check if an address is a candidate
    function isCandidate(address _address) internal view returns(bool) {
        for (uint i = 0; i < candidates.length; i ++) {
            if (candidates[i].address_ == _address) {
                return true;
            }
        }
        return false;
    }

    // Function to vote
    function vote(address candidate_) external isBallotOpen {
        require(voters[msg.sender].delegate == address(0), "You have given your vote to someone");
        require(voters[msg.sender].weight != 0, "You do not have the right to vote");
        require(voters[msg.sender].remainingVotes != 0, "You have already voted");
        require(isCandidate(candidate_), "This person is not a candidate");

        for (uint i = 0; i < candidates.length; i ++) {
            if (candidates[i].address_ == candidate_) {
                candidates[i].voteCounter ++;
                break;
            }
        }
        voters[msg.sender].remainingVotes --;
    }

    // Function to get results 
    function results() external view isBallotClosed returns(address[] memory, uint[] memory) {
        require(msg.sender == chairman, "Only the chairman can perform this action");
        require(endTime != 0, "The voting session has not yet taken place");
        address[] memory addresses_ = new address[](candidates.length);
        uint[] memory voteCounters_ = new uint[](candidates.length);
        for (uint i = 0; i < candidates.length; i ++) {
            addresses_[i] = candidates[i].address_;
            voteCounters_[i] = candidates[i].voteCounter;
        }
        return (addresses_, voteCounters_);
    }

}