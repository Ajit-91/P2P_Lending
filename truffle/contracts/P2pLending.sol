// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract P2pLending {

    // add bio in both borrower and lender

   struct Borrower {
        string userType;
        string name;
        string image;
        uint approvedLoans;
        address payable wallet;
        bytes32 password;
        uint spamVotes;
        uint annualIncome;
        string bio;
        uint [] madeRequests;
    }

    struct Lender {
        string userType;
        string name;
        string image;
        address payable wallet;
        bytes32 password;
        uint interestRate;
        string bio;
        uint maxPrincipal;
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
        uint id;
        address from;
        address to;
        uint amount;
        statuses status;
        uint durationInMonths;
        string purpose;
        string bankStatement;
        uint createdAt;
    }

    //  -----------------State variables-------------------------------

    mapping(address => Borrower) public borrowers;
    Lender [] public lenders;
    mapping(address => uint) lenderIndex;
    Request [] public requests;
    mapping(address => string) public users;
    mapping(address => bool) public hasVoted;


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
            approvedLoans : 0,
            bio : "Hi I am...",
            wallet: payable(msg.sender),
            password: keccak256(abi.encodePacked(_password)),
            annualIncome: _annualIncome,
            spamVotes: 0,
            madeRequests: new uint[](0)
        });
        users[msg.sender] = "Borrower";
    }

    function signUpLender (string memory _name, string memory _image, string memory _password, uint _interestRate, uint _maxPrincipal) public {
        require(keccak256(abi.encodePacked(users[msg.sender])) == keccak256(abi.encodePacked("")), "This address is already registered");
      
        lenders.push(Lender({
            userType: "Lender",
            name: _name,
            image: _image,
            bio : "Hi I am...",
            wallet: payable (msg.sender),
            password: keccak256(abi.encodePacked(_password)),
            interestRate: _interestRate,
            maxPrincipal: _maxPrincipal,
            gotRequests: new uint[](0)
        }));
        lenderIndex[msg.sender] = lenders.length - 1;
        users[msg.sender] = "Lender";
    }

    function signInBorrower (string memory _password) public view returns (Borrower memory) {
        require(keccak256(abi.encodePacked(users[msg.sender])) == keccak256(abi.encodePacked("Borrower")), "User not found");
        require (borrowers[msg.sender].password == keccak256(abi.encodePacked(_password)), "Invalid password");
        
        return borrowers[msg.sender];
    }

    function signInLender (string memory _password) public view returns(Lender memory)
    {
        require(keccak256(abi.encodePacked(users[msg.sender])) == keccak256(abi.encodePacked("Lender")), "User not found");
        require (lenders[lenderIndex[msg.sender]].password == keccak256(abi.encodePacked(_password)), "Invalid password");
        
        return lenders[lenderIndex[msg.sender]];
    }



    function getLenders () public view returns (Lender[] memory) {
        return lenders;
    }

    function getLender (address _wallet) public view returns (Lender memory) {
        return lenders[lenderIndex[_wallet]];
    }

    function createRequest (address _from, address _to, uint amount, uint _durationInMonths, string memory _purpose, string memory _bankStatement) public onlyBorrower
    {
        requests.push(Request({
            id: requests.length,
            from : _from,
            to : _to,
            amount : amount,
            durationInMonths : _durationInMonths,
            status : statuses.PENDING,
            purpose : _purpose,
            createdAt : block.timestamp,
            bankStatement : _bankStatement
        }));
        uint len = requests.length - 1;
        borrowers[_from].madeRequests.push(len);
        lenders[lenderIndex[_to]].gotRequests.push(len);
    }

    function getBorrowerRequests () public onlyBorrower view returns(Request [] memory) 
    {
        uint len = borrowers[msg.sender].madeRequests.length;
        Request [] memory myReqs = new Request [](len);
        for(uint i = 0; i <len; i++ )
        {
            myReqs[i] = requests[borrowers[msg.sender].madeRequests[i]];
        }
        return myReqs;
    }

    function getLenderRequests () public onlyLender view returns(Request [] memory) 
    {
        uint len = lenders[lenderIndex[msg.sender]].gotRequests.length;
        Request [] memory myReqs = new Request [](len);
        for(uint i = 0; i <len; i++ )
        {
            myReqs[i] = requests[lenders[lenderIndex[msg.sender]].gotRequests[i]];
        }
        return myReqs;
    }

    function updateBorrower (string memory _name, string memory _image, uint _annualIncome, string memory _bio) public onlyBorrower
    {
         borrowers[msg.sender].name = _name;
         borrowers[msg.sender].bio = _bio;
         borrowers[msg.sender].image = _image;
         borrowers[msg.sender].annualIncome = _annualIncome;
    }

    function updateLender (string memory _name, string memory _image, uint _interestRate, uint _maxPrincipal, string memory _bio) 
    public onlyLender
    {
       lenders[lenderIndex[msg.sender]].name = _name;
       lenders[lenderIndex[msg.sender]].bio = _bio;
       lenders[lenderIndex[msg.sender]].image = _image;
       lenders[lenderIndex[msg.sender]].interestRate = _interestRate;
       lenders[lenderIndex[msg.sender]].maxPrincipal = _maxPrincipal;
    }

    
    function isRequestDelayed(uint requestId) public view returns (bool) {
            // convert durationInMonths in months to seconds
            uint durationInSec = requests[requestId].durationInMonths * 30 * 24 * 60 * 60;
            uint _createdAt = requests[requestId].createdAt;

            return (block.timestamp > _createdAt + durationInSec);
    }
    
    function acceptRequest(uint requestIndex) public payable onlyLender  {
        require(requests[requestIndex].status == statuses.PENDING, "Request is no more pending");
        uint amount = requests[requestIndex].amount;
        require(msg.value == amount*(10 ** 18), "Required ethers not given either it is lesser or more than required");
        requests[requestIndex].status = statuses.ACCEPTED;
        // transfer amount from lender to borrower
        borrowers[requests[requestIndex].from].wallet.transfer(amount*(10 ** 18));
    }

    function rejectRequest(uint requestIndex) public onlyLender {
        require(requests[requestIndex].status == statuses.PENDING, "Request is no more pending");
        requests[requestIndex].status = statuses.REJECTED;
    }
    function markAsDelayed(uint requestIndex) public onlyLender {
        require(requests[requestIndex].status == statuses.ACCEPTED, "Request is not yet accepted");
        require(isRequestDelayed(requestIndex), "Request is not delayed yet");
        // require(requests[requestIndex].statuses == statuses.ACCEPTED, "Request is not yet accepted");
        requests[requestIndex].status = statuses.DELAYED;
    }

    function markAsFraud(address _borrower, uint requestIndex) public onlyLender{
        require(requests[requestIndex].status == statuses.DELAYED, "Request is not yet delayed");
        require(!hasVoted[msg.sender], "You have already voted as fraud");
        require(keccak256(abi.encodePacked(users[_borrower])) == keccak256(abi.encodePacked("Borrower")), "No user found with this address");
        borrowers[_borrower].spamVotes++;
        hasVoted[msg.sender] = true;
    }


   function calculatePaybackCost (uint requestId) public view
    returns (uint originalAmount,uint totalAmount) 
    {
        uint principalAmount = requests[requestId].amount;
        uint rate = lenders[lenderIndex[requests[requestId].to]].interestRate;
        uint time = requests[requestId].durationInMonths;
        uint _createdAt = requests[requestId].createdAt;

        uint interest = (((principalAmount*rate*time))*10**18)/1200; // interset in wei
        
        originalAmount = (principalAmount*10**18) + interest; // in wei

        if(block.timestamp > (time*30*24*60*60) + _createdAt)
        {
            uint unitAmount = originalAmount/time;
            uint delayTime = block.timestamp - ((time*30*24*60*60) + _createdAt); // delay in seconds

            delayTime = delayTime/60/60/24; // delay in no of days

            // for 30 days of delay 1.25 times of unit amount will be charged
            // example if unit amount is 2.5 ether then for 30 days delay 3.125 ether will be charged
            uint delayAmount = (unitAmount*delayTime*5)/(4*30); 
            totalAmount = originalAmount + delayAmount;

            return (originalAmount, totalAmount); // both in wei
        }
        else
        {
            totalAmount = originalAmount;
            return (originalAmount, totalAmount); //both in wei
        }
    }
   


    function payBack (uint requestId) public payable 
    {
        require(requests[requestId].status == statuses.ACCEPTED, "Request is not yet accepted");
        require(requests[requestId].from == msg.sender, "You are not the borrower of this request");

       (uint amount, uint totalAmount) = calculatePaybackCost(requestId);

       require(msg.value == totalAmount, "Required ethers not given either it is lesser or more than required");

       (bool sent, bytes memory data) = (requests[requestId].to).call{value: (totalAmount)}("");
       require(sent, "Failed to send money");
       requests[requestId].status = statuses.COMPLETED;
       borrowers[msg.sender].approvedLoans++;
    }

}

contract ReceiveEther{
    // Function to receive Ether. msg.data must be empty
   receive() external payable {}

   // Fallback function is called when msg.data is not empty
   fallback() external payable {}
}