pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {IERC20}     from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import {GnGOwnable} from "../Guardian/GnGOwnable.sol";

contract OROracleInfo is GnGOwnable {

    struct QuestionStruct {
        uint256 qid;
        address creator;
        uint256 minRoomHolding;
        address optionalERC20Address;
        uint256 minOptionalERC20Holding;
        uint256 reward;
        uint256 choicesLen;
        string question;
        string[] choices;
        uint256 votersCount;
        uint256[] votesCounts;
        uint256[] roomHolding;
        uint256[] optionalTokenHolding;
        uint256 createdTime;
        uint256 endTime;
    }

    struct KnownAccountStruct {
        address account;
        bool allowed;
        uint256 minReward;
        uint256 fees;
        string name;
    }

    IERC20 public ROOM;//TODO
    uint256 public minRoomHolding; //TODO

    bool public anonymousProposerAllowed = true; //TODO
    uint256 public anonymousFees; //TODO
    uint256 public anonymousMinReward; //TODO

    uint256 public feesCollected;

    QuestionStruct[] public questions;

    KnownAccountStruct[] public knownAccounts;
    mapping(address => uint256) proposersIDMap;

    mapping(uint256 => mapping(address => bool)) voteCheck;

    mapping(address => uint256[]) userPendingRewards;
    mapping(address => uint256) userClaimedRewards;
    
    event QuestionCreated(address indexed creator, uint256 indexed qid);
    event Vote(uint256 indexed qid, uint8 choice);

    constructor() public {
        addProposer(address(this), 0, 0, "");
    }

    function createQuestion(string memory question, string[] memory choices, uint256 reward, uint256 endTime, uint256 minRoomHoldingAboveDefault, address optionalERC20Address, uint256 minOptionalERC20Holding) public returns (uint256 qid) {
        address account = msg.sender;
        uint256 proposerID = proposersIDMap[account];
        uint256 fees;
        uint256 minReward;
        if (proposerID == 0) {
            require(anonymousProposerAllowed == true, "anonymous proposer is not allowed");
            minReward = anonymousMinReward;
            fees = anonymousFees;

        } else {
            require(knownAccounts[proposerID].allowed == true, "account suspended");
            fees = knownAccounts[proposerID].fees;
            minReward = knownAccounts[proposerID].minReward;
        }

        ROOM.transferFrom(account, address(this), fees);
        feesCollected += fees;

        ROOM.transferFrom(account, address(this), reward);

        return _createQuestion(question, choices, reward, endTime, minRoomHoldingAboveDefault, optionalERC20Address, minOptionalERC20Holding);
    }

    function _createQuestion(string memory question, string[] memory choices, uint256 reward, uint256 endTime, uint256 minRoomHoldingAboveDefault, address optionalERC20Address, uint256 minOptionalERC20Holding) internal returns (uint256 qid){
        require(choices.length >= 2, "choices must be at least 2");
        uint256[] memory votes = new uint256[](choices.length);
        uint256[] memory votesPower = new uint256[](choices.length);
        uint256[] memory optionalTokenHolding = new uint256[](choices.length);

        qid = questions.length;

        questions.push(QuestionStruct({
        optionalERC20Address : optionalERC20Address,
        minOptionalERC20Holding : minOptionalERC20Holding,
        minRoomHolding : minRoomHolding + minRoomHoldingAboveDefault,
        qid : questions.length,
        creator : msg.sender,
        reward : reward,
        choicesLen : choices.length,
        question : question,
        choices : choices,
        votesCounts : votes,
        roomHolding : votesPower,
        optionalTokenHolding : optionalTokenHolding,
        createdTime : block.timestamp,
        endTime : endTime,
        votersCount : 0
        }));
        
        emit QuestionCreated(msg.sender,qid);
    }


    function vote(uint256 qid, uint8 choice) public {
        require(voteCheck[qid][msg.sender] == false, "User already voted for this question");
        voteCheck[qid][msg.sender] == true;

        uint256 cTime = getCurrentTime();

        require(questions[qid].endTime > cTime, "Question has reached end time");

        // No Transfer for room or the optional token, just check how much the user is holding

        if (questions[qid].optionalERC20Address != address(0)) {
            uint256 optionalTokenBalance = IERC20(questions[qid].optionalERC20Address).balanceOf(msg.sender);
            require(optionalTokenBalance >= questions[qid].minOptionalERC20Holding, "User does not hold minimum optional room");
            questions[qid].optionalTokenHolding[choice] += optionalTokenBalance;
        }

        uint256 roomBalance = ROOM.balanceOf(msg.sender);
        require(roomBalance >= questions[qid].minRoomHolding, "The user does not hold minimum room");
        questions[qid].roomHolding[choice] += roomBalance;

        questions[qid].votersCount++;
        questions[qid].votesCounts[choice]++;

        userPendingRewards[msg.sender].push(qid);
        
        emit Vote(qid,choice);
    }

    function claimRewards() public {
        address account = msg.sender;

        int256 pendingVotedIndex = int256(userPendingRewards[account].length - 1);
        uint256 claimableRewards = 0;

        uint256 cTime = getCurrentTime();
        for (pendingVotedIndex; pendingVotedIndex > 0; pendingVotedIndex--) {
            uint256 qid = userPendingRewards[account][uint256(pendingVotedIndex)];

            uint256 reward = 0;
            reward = questions[qid].reward / questions[qid].votersCount;

            if (questions[qid].endTime > cTime) {
                claimableRewards += reward;

                // delete the question from pendingVotedIndex: by replace the current value by last value in the array, and remove last value
                userPendingRewards[account][uint256(pendingVotedIndex)] = userPendingRewards[account][userPendingRewards[account].length - 1];
                userPendingRewards[account].length--;
            }
        }

        userClaimedRewards[account] += claimableRewards;

        ROOM.transfer(account, claimableRewards);
    }

    function getRewardsInfo(address account) public view returns (uint256 expectedRewards, uint256 claimableRewards) {

        int256 pendingVotedIndex = int256(userPendingRewards[account].length);

        uint256 cTime = getCurrentTime();
        for (pendingVotedIndex; pendingVotedIndex > 0; pendingVotedIndex--) {
            uint256 qid = userPendingRewards[account][uint256(pendingVotedIndex)];

            uint256 reward = 0;
            reward = questions[qid].reward / questions[qid].votersCount;

            if (questions[qid].endTime > cTime) {
                claimableRewards += reward;
            } else {
                expectedRewards += reward;
            }
        }
    }

    function getQuestionsCount() public view returns (uint256) {
        return questions.length;
    }

    function getAllQuestions() public view returns (QuestionStruct[] memory) {
        return questions;
    }

    function getQuestionInfo(uint256 qid) public view returns (QuestionStruct memory) {
        return questions[qid];
    }

    function getChoices(uint256 qid) public view returns (string[] memory) {
        return questions[qid].choices;
    }

    function getQuestion(uint256 qid) public view returns (string memory question, string[] memory choices) {
        question = questions[qid].question;
        choices = questions[qid].choices;
    }

    function getQuestionResult(uint256 qid) public view returns (uint256[] memory votes, uint256[] memory votesPower) {
        votes = questions[qid].votesCounts;
        votesPower = questions[qid].roomHolding;
    }

    function getAccountInfo(address account) public view returns (KnownAccountStruct memory) {
        if (proposersIDMap[account] != 0) {
            return knownAccounts[proposersIDMap[account]];
        }
    }

    // configurations

    function addProposer(address account, uint256 minReward, uint256 fees, string memory name) public onlyGovOrGur {
        require(proposersIDMap[account] == 0, "address already added");

        proposersIDMap[account] = knownAccounts.length;

        knownAccounts.push(KnownAccountStruct({
        account : account,
        allowed : true,
        minReward : minReward,
        fees : fees,
        name : name
        }));

    }

    function updateProposer(address account, uint256 minReward, uint256 fees, bool allowed, string memory name) public onlyGovOrGur {
        uint256 proposerID = proposersIDMap[account];
        require(proposerID != 0, "account does not exist");

        knownAccounts[proposerID].minReward = minReward;
        knownAccounts[proposerID].fees = fees;
        knownAccounts[proposerID].allowed = allowed;
        knownAccounts[proposerID].name = name;

    }

    function setRoomAddress(address newAddress) public onlyGovOrGur {
        ROOM = IERC20(newAddress);
    }

    function setMinRoomHolding(uint256 newMin) public onlyGovOrGur {
        minRoomHolding = newMin;
    }

    function setAnonymousProposerAllowed(bool allowedFlag) public onlyGovOrGur {
        anonymousProposerAllowed = allowedFlag;
    }

    function setAnonymousFees(uint256 newFees) public onlyGovOrGur {
        anonymousFees = newFees;
    }

    function setAnonymousMinReward(uint256 newMinReward) public onlyGovOrGur {
        anonymousMinReward = newMinReward;
    }

    function transferCollectedFees() public onlyGovOrGur {
        ROOM.transfer(msg.sender, feesCollected);
        feesCollected = 0;
    }


    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }
}

contract OROracleInfoForTest is OROracleInfo {
    uint256 public currentTime = 0;

    function increaseTime(uint256 t) public {
        currentTime += t;
    }

    function getCurrentTime() public view returns (uint256) {
        //return block.timestamp;
        return currentTime;
    }
}
