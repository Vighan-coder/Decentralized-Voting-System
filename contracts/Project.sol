// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Decentralized Voting System
 * @dev A smart contract for conducting transparent and secure elections
 */
contract Project is Ownable, ReentrancyGuard {
    
    // Struct to represent a candidate
    struct Candidate {
        uint256 id;
        string name;
        string description;
        uint256 voteCount;
        bool exists;
    }
    
    // Struct to represent an election
    struct Election {
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool active;
        bool exists;
    }
    
    // State variables
    mapping(uint256 => Candidate) public candidates;
    mapping(address => mapping(uint256 => bool)) public hasVoted; // voter => electionId => hasVoted
    mapping(address => bool) public registeredVoters;
    mapping(uint256 => Election) public elections;
    
    uint256 public candidatesCount;
    uint256 public votersCount;
    uint256 public electionsCount;
    uint256 public currentElectionId;
    
    // Events
    event VoterRegistered(address indexed voter);
    event CandidateAdded(uint256 indexed candidateId, string name);
    event VoteCasted(address indexed voter, uint256 indexed candidateId, uint256 indexed electionId);
    event ElectionCreated(uint256 indexed electionId, string title);
    event ElectionStarted(uint256 indexed electionId);
    event ElectionEnded(uint256 indexed electionId);
    
    // Modifiers
    modifier onlyRegisteredVoter() {
        require(registeredVoters[msg.sender], "You must be a registered voter");
        _;
    }
    
    modifier electionActive(uint256 _electionId) {
        require(elections[_electionId].exists, "Election does not exist");
        require(elections[_electionId].active, "Election is not active");
        require(block.timestamp >= elections[_electionId].startTime, "Election has not started yet");
        require(block.timestamp <= elections[_electionId].endTime, "Election has ended");
        _;
    }
    
    constructor() {
        // Register the contract owner as first voter
        registeredVoters[msg.sender] = true;
        votersCount = 1;
        
        // Create a default election
        electionsCount++;
        currentElectionId = electionsCount;
        elections[currentElectionId] = Election({
            title: "General Election 2024",
            description: "Annual general election for leadership positions",
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days,
            active: true,
            exists: true
        });
        
        emit ElectionCreated(currentElectionId, "General Election 2024");
    }
    
    /**
     * @dev Register a new voter
     * @param _voter Address of the voter to register
     */
    function registerVoter(address _voter) external onlyOwner {
        require(!registeredVoters[_voter], "Voter already registered");
        require(_voter != address(0), "Invalid voter address");
        
        registeredVoters[_voter] = true;
        votersCount++;
        
        emit VoterRegistered(_voter);
    }
    
    /**
     * @dev Add a new candidate to the current election
     * @param _name Name of the candidate
     * @param _description Description of the candidate's platform
     */
    function addCandidate(string memory _name, string memory _description) external onlyOwner {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        require(elections[currentElectionId].active, "No active election");
        
        candidatesCount++;
        candidates[candidatesCount] = Candidate({
            id: candidatesCount,
            name: _name,
            description: _description,
            voteCount: 0,
            exists: true
        });
        
        emit CandidateAdded(candidatesCount, _name);
    }
    
    /**
     * @dev Cast a vote for a candidate
     * @param _candidateId ID of the candidate to vote for
     */
    function vote(uint256 _candidateId) external onlyRegisteredVoter electionActive(currentElectionId) nonReentrant {
        require(candidates[_candidateId].exists, "Candidate does not exist");
        require(!hasVoted[msg.sender][currentElectionId], "You have already voted in this election");
        
        // Record the vote
        hasVoted[msg.sender][currentElectionId] = true;
        candidates[_candidateId].voteCount++;
        
        emit VoteCasted(msg.sender, _candidateId, currentElectionId);
    }
    
    // View functions
    function getCandidate(uint256 _candidateId) external view returns (
        uint256 id,
        string memory name,
        string memory description,
        uint256 voteCount
    ) {
        require(candidates[_candidateId].exists, "Candidate does not exist");
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.description, candidate.voteCount);
    }
    
    function getElection(uint256 _electionId) external view returns (
        string memory title,
        string memory description,
        uint256 startTime,
        uint256 endTime,
        bool active
    ) {
        require(elections[_electionId].exists, "Election does not exist");
        Election memory election = elections[_electionId];
        return (election.title, election.description, election.startTime, election.endTime, election.active);
    }
    
    function getCurrentElectionResults() external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory candidateIds = new uint256[](candidatesCount);
        uint256[] memory voteCounts = new uint256[](candidatesCount);
        
        for (uint256 i = 1; i <= candidatesCount; i++) {
            if (candidates[i].exists) {
                candidateIds[i-1] = i;
                voteCounts[i-1] = candidates[i].voteCount;
            }
        }
        
        return (candidateIds, voteCounts);
    }
    
    function isVoterRegistered(address _voter) external view returns (bool) {
        return registeredVoters[_voter];
    }
    
    function hasVoterVoted(address _voter, uint256 _electionId) external view returns (bool) {
        return hasVoted[_voter][_electionId];
    }
    
    // Admin functions
    function createElection(
        string memory _title,
        string memory _description,
        uint256 _duration
    ) external onlyOwner {
        require(bytes(_title).length > 0, "Election title cannot be empty");
        require(_duration > 0, "Election duration must be greater than 0");
        
        // End current election if active
        if (elections[currentElectionId].active) {
            elections[currentElectionId].active = false;
            emit ElectionEnded(currentElectionId);
        }
        
        electionsCount++;
        currentElectionId = electionsCount;
        
        elections[currentElectionId] = Election({
            title: _title,
            description: _description,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            active: true,
            exists: true
        });
        
        emit ElectionCreated(currentElectionId, _title);
    }
    
    function endCurrentElection() external onlyOwner {
        require(elections[currentElectionId].active, "No active election");
        elections[currentElectionId].active = false;
        emit ElectionEnded(currentElectionId);
    }
}
