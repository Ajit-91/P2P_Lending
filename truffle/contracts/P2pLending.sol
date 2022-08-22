// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract P2pLending {

   struct Borrower {
        string userType;
        string name;
        string image;
        address payable wallet;
        bytes32 password;
        uint annualIncome;
        uint [] madeRequests;
    }

    struct Lender {
        string userType;
        string name;
        string image;
        address payable wallet;
        bytes32 password;
        uint interestRate;
        uint loanCapacity;
        uint [] gotRequests;
    }

    enum statuses  {
        PENDING,
        ACCEPTED,
        REJECTED,
        DELAYED,
        COMPLETED
    }
      struct Request {
        address from;
        address to;
        uint money;
        uint delayCost;
        statuses status;
        uint duration;
    }

    //  -----------------State variables-------------------------------

    mapping(address => Borrower) public borrowers;
    Lender [] public lenders;
    mapping(address => uint) lenderIndex;
    Request [] public requests;
    mapping(address => string) public users;

    // ------------------modifiers-----------------

    modifier onlyLender {
        require (msg.sender == lenders[lenderIndex[msg.sender]].wallet, "Access denied");
        _;
    }
    modifier onlyBorrower {
        require (msg.sender == borrowers[msg.sender].wallet, "Access denied");
        _;
    }

    // ------------------functions-----------------------------------


    function getRole () public view returns (string memory) {
            return users[msg.sender];
    }

    function signUpBorrower (string memory _name, string memory _image, string memory _password, uint _annualIncome) public {
        require(keccak256(abi.encodePacked(users[msg.sender])) == keccak256(abi.encodePacked("")), "This address is already registered");

        borrowers[msg.sender] = Borrower({
            userType: "Borrower",
            name: _name,
            image: _image,
            wallet: payable(msg.sender),
            password: keccak256(abi.encodePacked(_password)),
            annualIncome: _annualIncome,
            madeRequests: new uint[](0)
        });
        users[msg.sender] = "Borrower";
    }

    function signUpLender (string memory _name, string memory _image, string memory _password, uint _interestRate, uint _loanCapacity) public {
        require(keccak256(abi.encodePacked(users[msg.sender])) == keccak256(abi.encodePacked("")), "This address is already registered");

        lenders.push(Lender({
            userType: "Lender",
            name: _name,
            image: _image,
            wallet: payable (msg.sender),
            password: keccak256(abi.encodePacked(_password)),
            interestRate: _interestRate,
            loanCapacity: _loanCapacity,
            gotRequests: new uint[](0)
        }));
        lenderIndex[msg.sender] = lenders.length - 1;
        users[msg.sender] = "Lender";
    }

    // returns (Borrower memory) { 
    function signInBorrower (string memory _password) public view 
    returns (string memory userType, string memory name, string memory image, address wallet, uint annualIncome, uint[] memory madeReqests) {
        require(keccak256(abi.encodePacked(users[msg.sender])) == keccak256(abi.encodePacked("Borrower")), "User not found");
        require (borrowers[msg.sender].password == keccak256(abi.encodePacked(_password)), "Invalid password");
        
        return (
            borrowers[msg.sender].userType,
            borrowers[msg.sender].name,
            borrowers[msg.sender].image,
            borrowers[msg.sender].wallet,
            borrowers[msg.sender].annualIncome,
            borrowers[msg.sender].madeRequests
        );
        // return borrowers[msg.sender];
    }

    // returns (Lender memory) {
    function signInLender (string memory _password) public view  
    returns (string memory userType, string memory name, string memory image, address wallet, uint interestRate, uint loanCapacity, uint[] memory gotRequests) {
        require(keccak256(abi.encodePacked(users[msg.sender])) == keccak256(abi.encodePacked("Lender")), "User not found");
        require (lenders[lenderIndex[msg.sender]].password == keccak256(abi.encodePacked(_password)), "Invalid password");
        
        return (
            lenders[lenderIndex[msg.sender]].userType,
            lenders[lenderIndex[msg.sender]].name,
            lenders[lenderIndex[msg.sender]].image,
            lenders[lenderIndex[msg.sender]].wallet,
            lenders[lenderIndex[msg.sender]].interestRate,
            lenders[lenderIndex[msg.sender]].loanCapacity,
            lenders[lenderIndex[msg.sender]].gotRequests
        );
        // return lenders[lenderIndex[msg.sender]];
    }



    function getLenders () public view returns (Lender[] memory) {
        return lenders;
    }


    function makeRequest (address _from, address _to, uint _money, uint _duration) public onlyBorrower
    {
        requests.push(Request({
            from : _from,
            to : _to,
            money : _money,
            duration : _duration,
            status : statuses.PENDING,
            delayCost : 0
        }));
        uint len = requests.length - 1;
        borrowers[_from].madeRequests.push(len);
        lenders[lenderIndex[_to]].gotRequests.push(len);
    }

    function getBorrowerRequests (address _borrower) public onlyBorrower view returns(Request [] memory) 
    {
        uint len = borrowers[_borrower].madeRequests.length;
        Request [] memory myReqs = new Request [](len);
        for(uint i = 0; i <len; i++ )
        {
            myReqs[i] = requests[borrowers[_borrower].madeRequests[i]];
        }
        return myReqs;
    }

    function updateBorrower (string memory _name, string memory _image, uint _annualIncome) public
    {
         borrowers[msg.sender].name = _name;
         borrowers[msg.sender].image = _image;
         borrowers[msg.sender].annualIncome = _annualIncome;
    }

    function updateLender (string memory _name, string memory _image, uint _interestRate, uint _loanCapacity) 
    public 
    {
       lenders[lenderIndex[msg.sender]].name = _name;
       lenders[lenderIndex[msg.sender]].image = _image;
       lenders[lenderIndex[msg.sender]].interestRate = _interestRate;
       lenders[lenderIndex[msg.sender]].loanCapacity = _loanCapacity;
    }
    

    // function payBack (address payable _to) public payable
    // {
    //     (bool sent, bytes memory data) = _to.call{value: msg.value}("");
    //     require(sent, "Failed to send Ether");
    // }
}

