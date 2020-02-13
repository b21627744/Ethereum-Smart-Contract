pragma solidity 0.5.1;

contract TaxiBusiness{
    
    struct Participant{
        uint256 participantBalance;
        address payable ParticipantAddress;
    }
    mapping(uint256 => Participant) participants;
    uint256 participantcount;
    
    mapping (address => bool) votesForPurchase;
    mapping (address => bool) votesForSell;
    mapping (address => bool) votesForDriver;
    
    address Manager;
    address payable CarDealer;
    
    uint256 public ContractBalance;
    
    uint256 FixedExpenses;
    uint256 ParticipationFee;
    
    uint256 timeToCarProposed;
    uint256 timeToCarreProposed;
    uint256 SalaryTime;
    uint256 ExpensesTime;
    uint256 PayTime;
    
    mapping (uint256 => int32) OwnedCar;
    uint256 OwnedCarCount;
    
    address payable driver;
    uint256 driversalary;
    uint256 approvalstatetaxi;
    
    struct TaxiDriver{
        address payable driverAddress;
        uint256 driverBalance;
        uint256 salary;
        
    }TaxiDriver taxidriver;
    
    struct Car{
        int32 CarID;
        uint256 price;
        uint256 validtime;
        uint256 approvalstate;
    }
    Car proposedCar;
    Car rePurchaseCar;
    
    
    constructor() public payable{
        
        Manager = msg.sender;
        PayTime=now;
        ExpensesTime=now;
        ContractBalance = 0 ether;
        FixedExpenses = 10 ether;
        ParticipationFee = 100 ether;
        participantcount = 0;
        OwnedCarCount=0;
        
    }
    
    modifier JoinControl () {
        require(msg.value == ParticipationFee && participantcount<9);
        _;
    }
    modifier ParticipantControl () {
        address participantAddress;
        for(uint i=0;i<=participantcount;i++){
            if(participants[i].ParticipantAddress == msg.sender){
                participantAddress=msg.sender;
            }
        }
        require(msg.sender == participantAddress);
        _;
    }
    modifier ParticipantNotJoin () {
        address paricipantNotAddress;
        for(uint i=0;i<participantcount;i++){
            if(participants[i].ParticipantAddress == msg.sender){
                paricipantNotAddress=msg.sender;
            }
        }
        require(msg.sender != paricipantNotAddress);
        _;
    }
    modifier ManagerControl () {
        require(msg.sender == Manager);
        _;
    }
    modifier CarDealerControl () {
        require(msg.sender == CarDealer);
        _;
    }
    modifier DriverControl () {
        require(msg.sender == taxidriver.driverAddress);
        _;
    }
    modifier PurchaseCarControl(){
        require(now-timeToCarProposed < proposedCar.validtime && proposedCar.approvalstate> participantcount/2);
        _;
    }
    modifier rePurchaseCarControl(){
        require(msg.value >= rePurchaseCar.price && now-timeToCarreProposed < rePurchaseCar.validtime && rePurchaseCar.approvalstate> participantcount/2);
        _;
    }
    modifier SetDriverControl(){
        require(approvalstatetaxi > participantcount/2);
         _;
    }
    modifier voteControlPurchase(){
        require(!votesForPurchase[msg.sender]);
        _;
    }
    modifier voteControlSell(){
        require(!votesForSell[msg.sender]);
        _;
    }
    modifier voteControlDriver(){
        require(!votesForDriver[msg.sender]);
        _;
    }
    
    modifier SixMonthsForExpenses (){
        require((ExpensesTime + 15778000 ) < now);  //6 months in seconds
        _;
    }
    modifier SixMonthsForPay(){
        require((PayTime + 15778000) < now); //6 months in seconds
        _;
    }
    modifier MonthForSalary(){
        require(2630000 < ( now - SalaryTime )  );
        _;
    }
    
    
    
    function Join() public payable ParticipantNotJoin JoinControl {
            participants[participantcount] = Participant(0,msg.sender);
            participantcount++;
            ContractBalance +=ParticipationFee;
            votesForPurchase[msg.sender] = false;
            votesForSell[msg.sender] = false;
            votesForDriver[msg.sender] = false;
    }
    
    function SetCarDealer(address payable car_Dealer) public ManagerControl{
        CarDealer = car_Dealer;
    }
    
    function CarProposeToBusiness(int32 Car_ID,  uint256 valid_time , uint256 Price) public  CarDealerControl {
        timeToCarProposed = now;
        proposedCar.CarID = Car_ID;
        proposedCar.price = Price*(10**18);
        proposedCar.validtime = valid_time;
        proposedCar.approvalstate =0;
        for(uint256 i=0;i<participantcount;i++){
            votesForPurchase[participants[i].ParticipantAddress]=false;
        }
    }
    
    function approvePurchaseCar()  public payable ParticipantControl voteControlPurchase{
        votesForPurchase[msg.sender]=true;
        proposedCar.approvalstate++;
      
    }
    
    function purchaseCar() public  ManagerControl PurchaseCarControl{
        address(CarDealer).transfer(proposedCar.price);
        ContractBalance-=proposedCar.price;
        OwnedCar[OwnedCarCount] = proposedCar.CarID;
        OwnedCarCount++;
         
    }
    function rePurchaseCarPropose(int32 Car_ID,  uint256 valid_time , uint256 Price) public payable CarDealerControl {
        bool Control=false;
        for(uint i=0;i<OwnedCarCount;i++){
            if(Car_ID==OwnedCar[i]){
                Control=true;
            }
        }
        if(Control==true){
            for(uint256 i=0;i<participantcount;i++){
                votesForSell[participants[i].ParticipantAddress]=false;
            }
            timeToCarreProposed = now;
            rePurchaseCar.CarID = Car_ID;
            rePurchaseCar.price = Price*(10**18);
            rePurchaseCar.validtime = valid_time;
            rePurchaseCar.approvalstate = 0;
        }else{
           revert(); 
        }
    }
    function ApproveSellProposal() public ParticipantControl voteControlSell{
        rePurchaseCar.approvalstate++;
        votesForSell[msg.sender]=true;
    }
    function RepurchaseCar() public payable CarDealerControl rePurchaseCarControl{
        ContractBalance+=msg.value;
        OwnedCarCount--;
        
    }
    function PropeseDriver(address payable _taxidriver, uint256 _salary) public  ManagerControl{
        for(uint256 i=0;i<participantcount;i++){
            votesForDriver[participants[i].ParticipantAddress]=false;
        }          
        driver=_taxidriver;
        driversalary=_salary*(10**18);
    }
    function ApproveDriver() public payable ParticipantControl voteControlDriver{
        approvalstatetaxi ++;
        votesForDriver[msg.sender]=true;
        
    }
    function SetDriver() public ManagerControl SetDriverControl{
        taxidriver.driverAddress=driver;
        taxidriver.salary=driversalary;
        SalaryTime = now;
    
    }
    function FireDriver() public ManagerControl{
        address payable a;
        address(taxidriver.driverAddress).transfer(taxidriver.salary);
        ContractBalance-=taxidriver.salary;
        taxidriver.driverAddress=a;
    }
    function GetCharge() public payable{
        ContractBalance+=msg.value;
        
    }
    function ReleaseSalary() public  ManagerControl MonthForSalary{
        taxidriver.driverBalance+=taxidriver.salary;
        ContractBalance = ContractBalance - taxidriver.salary;
        SalaryTime=now;
        
    }
    function GetSalary () public DriverControl{
        address(taxidriver.driverAddress).transfer(taxidriver.driverBalance); 
        taxidriver.driverBalance=0;
    }
    
    function CarExpenses() public ManagerControl SixMonthsForExpenses{
        ExpensesTime = now;
        address(CarDealer).transfer(FixedExpenses);
        ContractBalance -= FixedExpenses;
    }
    
    function PayDividend() public  ManagerControl SixMonthsForPay{
        PayTime = now;
        uint pay_dividend = ContractBalance/participantcount;
        for(uint i = 0; i< participantcount; i++){
            participants[i].participantBalance = participants[i].participantBalance + pay_dividend;
            ContractBalance-=pay_dividend;
        }
    }
    function GetDividend() public payable ParticipantControl {
        for(uint i = 0; i< participantcount; i++){
            if(participants[i].ParticipantAddress == msg.sender){
                address(participants[i].ParticipantAddress).transfer(participants[i].participantBalance);
            }
        }
    }
    
    function() payable external {
        revert();
    }
    
}