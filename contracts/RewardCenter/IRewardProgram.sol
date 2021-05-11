pragma solidity ^0.5.1;

interface IRewardProgram {
    
    function lpMarketAdd(address market, address account, uint256 amount) external;

    function lpMarketRemove(address market, address account, uint256 amount) external;

    function resolveVote(address market, uint8 selection, address account, uint256 votePower) external;

    function validationVote(address market, bool validationFlag, address account, uint256 votePower) external;
    
    function tradeAmount(address market, address account, uint256 amount, bool buyFlag) external;
    
}


contract DummyRewardProgram {
    
    function lpMarketAdd(address market, address account, uint256 amount) external{
        
    }

    function lpMarketRemove(address market, address account, uint256 amount) external{
        
    }

    function resolveVote(address market, uint8 selection, address account, uint256 votePower) external{
        
    }

    function validationVote(address market, bool validationFlag, address account, uint256 votePower) external{
        
    }
    
    function tradeAmount(address market, address account, uint256 amount, bool buyFlag) external
    {
        
    }
}