pragma ton-solidity >= 0.38.0;
pragma AbiHeader time;
pragma AbiHeader pubkey;
pragma AbiHeader expire;

//================================================================================
//
enum REG_TYPE
{
    FFA,     // Free For All, anyone can register a subdomain;
    MONEY,   // Registration is like FFA BUT you need to attach enough money (configurable by parent domain);
    OWNER,   // Only owner can register a subdomain (thus be an owner of a subdomain, unless he transfers ownership manually), all other request are denied;
    DENY,    // All requests are denied;
    NUM
}

enum REG_RESULT
{
    NONE,             // 
    APPROVED,         // Cool;
    DENIED,           // Root domain denies the registration, fulfill registration requirements and try again;
    NOT_ENOUGH_MONEY, // Not enough money attached to "claimExpired" message;
    NUM
}

//================================================================================
// 
struct DnsWhois
{
    address    endpointAddress;     //
    //
    uint8      segmentsCount;       //
    string     domainName;          // duplicating domain name here; we can't use pointers, but it needs to be a part of Whois;
    string     parentDomainName;    //
    address    parentDomainAddress; //
    //
    address    ownerAddress;        //
    uint32     dtLastProlongation;  //
    uint32     dtExpires;           //
    uint128    registrationPrice;   // 
    REG_TYPE   registrationType;    //
    REG_RESULT lastRegResult;       //
    string     comment;             //
    //
    // Statistics
    uint32     dtCreated;            //
    uint32     totalOwnersNum;       // Total owners number, increases when expired domain is claimed;
    uint32     subdomainRegAccepted; // Total number of sub-domains registerations accepted;
    uint32     subdomainRegDenied;   // Total number of sub-domains registerations denied;
    uint128    totalFeesCollected;   // Total fees collected registering subdomains;
    
}

//================================================================================
//
interface IDnsRecord
{
    //========================================
    // Events
    event newSubdomainRegistered(uint32 dt, string domainName, uint128 price       );
    event registrationResult    (uint32 dt, REG_RESULT result, address ownerAddress);
    event domainProlongated     (uint32 dt, uint32 expirationDate);
    event domainReleased        (uint32 dt);

    //========================================
    // Getters
    function callWhois()   external view responsible returns (DnsWhois  );
    function getWhois()                external view returns (DnsWhois  );
    //
    function getDomainName()           external view returns (string    );
    function getDomainCode()           external view returns (TvmCell   );
    //
    function getEndpointAddress()      external view returns (address   );
    function getSegmentsCount()        external view returns (uint8     );
    function getParentDomainName()     external view returns (string    );
    function getParentDomainAddress()  external view returns (address   );    
    //
    function getOwnerAddress()         external view returns (address   );
    function getDtLastProlongation()   external view returns (uint32    );
    function getDtExpires()            external view returns (uint32    );
    function getRegistrationPrice()    external view returns (uint128   );
    function getRegistrationType()     external view returns (REG_TYPE  );
    function getLastRegResult()        external view returns (REG_RESULT);
    function getComment()              external view returns (string    );
    //
    function getDtCreated()            external view returns (uint32    );
    function getTotalOwnersNum()       external view returns (uint32    );
    function getSubdomainRegAccepted() external view returns (uint32    );
    function getSubdomainRegDenied()   external view returns (uint32    );
    function getTotalFeesCollected()   external view returns (uint128   );
    //
    function canProlongate()           external view returns (bool      );
    function isExpired()               external view returns (bool      );
    //

    //========================================
    //
    function calculateDomainAddress(string domainName) external view returns (address, TvmCell);

    //========================================
    // Sets
    /// @notice Change the endpoint address that DeNS record keeps;
    ///
    /// @param newAddress - new target address of this DeNS;
    //
    function changeEndpointAddress(address newAddress) external;
    
    /// @notice Change the owner;
    ///         Resets some DNS values like endpointAddress, registrationType, comment, etc.;
    ///
    /// @param newOwnerAddress - address of a new owner; CAN'T be (0, 0);
    //
    function changeOwner(address newOwnerAddress) external;
    
    /// @notice Change sub-domain registration type;
    ///
    /// @param newType - new type;
    //
    function changeRegistrationType(REG_TYPE newType) external;

    /// @notice Change sub-domain registration price;
    ///
    /// @param newPrice - new registration price;
    //
    function changeRegistrationPrice(uint128 newPrice) external;

    /// @notice Change comment;
    ///         Keep in mind that you will have to pay larger storage fees for huge comments;
    ///
    /// @param newComment - new comment;
    //
    function changeComment(string newComment) external;

    //========================================
    // Registration

    /// @notice Prolongate the domain; only owner can call this and only 10 or less days prior to expiration;
    //
    function prolongate() external;
    
    /// @notice Claim an expired DeNS Record; claiming is the same as registering new domain, except you don't deploy;
    ///
    /// @dev If REG_TYPE == REG_TYPE.MONEY on parent, all extra TONs (from msg.value) that exceed registration price will BE RETURNED to caller's account;
    ///      Plan accordingly: "msg.value" should equal to registration price + all child fees + all parent fees;
    ///
    /// @param newOwnerAddress - address or pubkey  of a new owner; can be (0, 0);
    //
    function claimExpired(address newOwnerAddress) external;
    
    /// @notice Release a domain, owner becomes no one, dtExpires becomes 0;
    //
    function releaseDomain() external;

    /// @notice Receive registration request from a sub-domain;
    ///
    /// @param domainName   - sub-domain name;
    /// @param ownerAddress - address of a new owner;
    //
    function receiveRegistrationRequest(string domainName, address ownerAddress, address payerAddress) external responsible returns (REG_RESULT, address, address);
    
    /// @notice Callback received from parent domain with registration result;
    ///
    /// @param result - registration result;
    //
    function callbackOnRegistrationRequest(REG_RESULT result, address ownerAddress, address payerAddress) external;
}

//================================================================================
//