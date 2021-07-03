pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../Guardian/GnGOwnable.sol";

contract  OROracleInfo is  GnGOwnable{
    
    struct QuestionStruct{
        uint256 qid;
        address creator;
        uint256 minRoomHolding;
        address optionalERC20Address;
        uint256 minOptinalERC20Holding;
        uint256 reward;
        uint256 choicesLen;
        string question;
        string[] choices;
        uint256 voterCount;
        uint256[] votesCounts;
        uint256[] roomHolding;
        uint256[] optionalTokenHolding;
        uint256 createdTiem;
        uint256 endTime;
    }
    
    struct KnownAccountStruct{
        address account;
        bool    allowed;
        uint256 minReward;
        uint256 fees;
        string  name;
    }
    
    IERC20 public ROOM;//TODO
    uint256 public minRoomHolding; //TODO
    
    bool public anonymousProposerAllowd = true; //TODO
    uint256 public anonymousFees; //TODO
    uint256 public anonymousMinReward; //TODO
    
    uint256 public feesCollected;
    
    QuestionStruct[] public questions;
    KnownAccountStruct[] public knownAccounts;
    mapping(address => uint256) proposersIDmap;
    
    mapping(uint256 => mapping (address => bool)) voteCheck;
    
    constructor() public{
        addProposer(address(this), 0, 0, "");
    }
    
    function createQuestion(string memory question, string[] memory choices, uint256 reward, uint256 endTime, uint256 minRoomHoldingAboveDefault, address optionalERC20Address, uint256 minOptinalERC20Holding) public returns(uint256 qid){
        address account = msg.sender;
        uint256 proposerID = proposersIDmap[account];
        uint256 fees;
        uint256 minReward;
        if(proposerID == 0){
            require(anonymousProposerAllowd == true, "anonymous proposer is not allowed");
            minReward = anonymousMinReward;
            fees = anonymousFees;
            
        }else{
            require(knownAccounts[proposerID].allowed == true, "account panded");
            fees = knownAccounts[proposerID].fees;
            minReward = knownAccounts[proposerID].minReward;
        }
        
        ROOM.transferFrom(account,address(this),fees);
        feesCollected += fees;
        
        ROOM.transferFrom(account,address(this),reward);
        
        return _createQuestion(question, choices, reward, endTime, minRoomHoldingAboveDefault, optionalERC20Address, minOptinalERC20Holding);
    }
    
    function _createQuestion(string memory question, string[] memory choices, uint256 reward, uint256 endTime, uint256 minRoomHoldingAboveDefault, address optionalERC20Address, uint256 minOptinalERC20Holding) internal returns(uint256 qid){
        require(choices.length >= 2, "choices must be at least 2");
        uint256[] memory votes = new uint256[](choices.length);
        uint256[] memory votesPower = new uint256[](choices.length);
        uint256[] memory optionalTokenHolding = new uint256[](choices.length);
        
        qid = questions.length;
        
        questions.push(QuestionStruct({
            optionalERC20Address: optionalERC20Address,
            minOptinalERC20Holding: minOptinalERC20Holding,
            minRoomHolding: minRoomHolding + minRoomHoldingAboveDefault,
            qid: questions.length,
            creator: msg.sender,
            reward: reward,
            choicesLen:choices.length,
            question: question,
            choices: choices,
            votesCounts: votes,
            roomHolding: votesPower,
            optionalTokenHolding: optionalTokenHolding,
            createdTiem:  block.timestamp,
            endTime: endTime,
            voterCount: 0
        }));
    }
    
    
    function vote(uint256 qid, uint256 choise) public{ //todo change to internal
        require(voteCheck[qid][msg.sender] == false ,"User already vote for this question");
        voteCheck[qid][msg.sender] == true;
        
        uint256 cTime = getCurrentTime();
        
        require(questions[qid].endTime > cTime, "Question has reach end time");
        
        // No Transfer for room or the optional token, just check how much the user is holding
       
        if(questions[qid].optionalERC20Address != address(0)){
            uint256 optionalTokenBalance = IERC20(questions[qid].optionalERC20Address).balanceOf(msg.sender);
            require(optionalTokenBalance >= questions[qid].minOptinalERC20Holding, "User do not hold minimum optinal room");
            
            questions[qid].optionalTokenHolding[choise] += optionalTokenBalance;
        }
        
        uint256 roomBalance = ROOM.balanceOf(msg.sender);
        require(roomBalance >= questions[qid].minRoomHolding, "User do not hold minimum room");
        
        questions[qid].voterCount++;
        questions[qid].votesCounts[choise]++;
        questions[qid].roomHolding[choise] += roomBalance;
    }
    
    function getQuestionStruct(uint256 qid) public view returns(QuestionStruct memory){
        return questions[qid];
    }
    
    function getChoices(uint256 qid) public view returns(string[] memory){
        return questions[qid].choices;
    }
    
    function getQuestion(uint256 qid) public view returns(string memory question, string[] memory choices){
        question = questions[qid].question;
        choices = questions[qid].choices;
    }
    
    function getQuestionResult(uint256 qid) public view returns(uint256[] memory votes, uint256[] memory votesPower){
        votes = questions[qid].votesCounts;
        votesPower = questions[qid].roomHolding;
    }
    
    function getAccountInfo(address account) public view returns(KnownAccountStruct memory ){
        if(proposersIDmap[account] != 0){
            return knownAccounts[proposersIDmap[account]];
        }
    }
    
    // configurations
    
    function addProposer(address account, uint256 minReward, uint256 fees, string memory name) public onlyGovOrGur{
        require(proposersIDmap[account] == 0, "address already added");
         
         proposersIDmap[account] = knownAccounts.length;
         
         knownAccounts.push(KnownAccountStruct({
             account:account,
             allowed:true,
             minReward:minReward,
             fees:fees,
             name:name
         }));
         
    }
    
    function uppdateProposer(address account, uint256 minReward, uint256 fees, bool allowed,string memory name) public onlyGovOrGur{
        uint256 proposerID = proposersIDmap[account];
        require(proposerID != 0, "account is not added");
         
        knownAccounts[proposerID].minReward = minReward;
        knownAccounts[proposerID].fees = fees;
        knownAccounts[proposerID].allowed = allowed;
        knownAccounts[proposerID].name = name;

    }
    
    function setRoomAddress(address newAddress) public onlyGovOrGur{
        ROOM = IERC20(newAddress);
    }
    
    function setMinRoomHolding(uint256 newMin) public onlyGovOrGur{
        minRoomHolding = newMin;
    }
    
    function setAnonymousProposerAllowd(bool allowedFlag) public onlyGovOrGur{
        anonymousProposerAllowd = allowedFlag;
    }
    
    function setAnonymousFees(uint256 newFees) public onlyGovOrGur{
        anonymousFees = newFees;
    }
    
    function setAnonymousMinReward(uint256 newMinReward) public onlyGovOrGur{
        anonymousMinReward = newMinReward;
    }
    
    function transferCollectedFees() public onlyGovOrGur{
        ROOM.transfer(msg.sender, feesCollected);
        feesCollected =0;
    }
    
    
    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
}