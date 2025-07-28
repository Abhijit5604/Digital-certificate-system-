// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DigitalCertificate {
    // Structure to store certificate information
    struct Certificate {
        string recipientName;
        string courseName;
        string issuerName;
        uint256 issueDate;
        bool isValid;
    }
    
    // Mapping to store certificates by their ID
    mapping(uint256 => Certificate) public certificates;
    
    // Counter for certificate IDs
    uint256 public nextCertificateId = 1;
    
    // Mapping to track authorized issuers
    mapping(address => bool) public authorizedIssuers;
    
    // Contract owner
    address public owner;
    
    // Events
    event CertificateIssued(
        uint256 indexed certificateId,
        string recipientName,
        string courseName,
        address indexed issuer
    );
    
    event CertificateRevoked(uint256 indexed certificateId);
    event IssuerAuthorized(address indexed issuer);
    event IssuerRevoked(address indexed issuer);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender], "Not an authorized issuer");
        _;
    }
    
    // Constructor
    constructor() {
        owner = msg.sender;
        authorizedIssuers[msg.sender] = true; // Owner is automatically authorized
    }
    
    /**
     * @dev Issue a new certificate
     * @param _recipientName Name of the certificate recipient
     * @param _courseName Name of the course/program
     * @param _issuerName Name of the issuing organization
     */
    function issueCertificate(
        string memory _recipientName,
        string memory _courseName,
        string memory _issuerName
    ) public onlyAuthorizedIssuer returns (uint256) {
        require(bytes(_recipientName).length > 0, "Recipient name cannot be empty");
        require(bytes(_courseName).length > 0, "Course name cannot be empty");
        require(bytes(_issuerName).length > 0, "Issuer name cannot be empty");
        
        uint256 certificateId = nextCertificateId;
        
        certificates[certificateId] = Certificate({
            recipientName: _recipientName,
            courseName: _courseName,
            issuerName: _issuerName,
            issueDate: block.timestamp,
            isValid: true
        });
        
        nextCertificateId++;
        
        emit CertificateIssued(certificateId, _recipientName, _courseName, msg.sender);
        
        return certificateId;
    }
    
    /**
     * @dev Verify if a certificate is valid
     * @param _certificateId ID of the certificate to verify
     */
    function verifyCertificate(uint256 _certificateId) public view returns (
        bool exists,
        bool isValid,
        string memory recipientName,
        string memory courseName,
        string memory issuerName,
        uint256 issueDate
    ) {
        Certificate memory cert = certificates[_certificateId];
        
        // Check if certificate exists (recipient name will be empty if not)
        exists = bytes(cert.recipientName).length > 0;
        
        if (exists) {
            return (
                true,
                cert.isValid,
                cert.recipientName,
                cert.courseName,
                cert.issuerName,
                cert.issueDate
            );
        } else {
            return (false, false, "", "", "", 0);
        }
    }
    
    /**
     * @dev Revoke a certificate (mark as invalid)
     * @param _certificateId ID of the certificate to revoke
     */
    function revokeCertificate(uint256 _certificateId) public onlyAuthorizedIssuer {
        require(bytes(certificates[_certificateId].recipientName).length > 0, "Certificate does not exist");
        require(certificates[_certificateId].isValid, "Certificate is already revoked");
        
        certificates[_certificateId].isValid = false;
        
        emit CertificateRevoked(_certificateId);
    }
    
    /**
     * @dev Authorize a new issuer
     * @param _issuer Address of the new issuer
     */
    function authorizeIssuer(address _issuer) public onlyOwner {
        require(_issuer != address(0), "Invalid address");
        require(!authorizedIssuers[_issuer], "Already authorized");
        
        authorizedIssuers[_issuer] = true;
        
        emit IssuerAuthorized(_issuer);
    }
    
    /**
     * @dev Revoke issuer authorization
     * @param _issuer Address of the issuer to revoke
     */
    function revokeIssuer(address _issuer) public onlyOwner {
        require(_issuer != owner, "Cannot revoke owner");
        require(authorizedIssuers[_issuer], "Not an authorized issuer");
        
        authorizedIssuers[_issuer] = false;
        
        emit IssuerRevoked(_issuer);
    }
    
    /**
     * @dev Get total number of certificates issued
     */
    function getTotalCertificates() public view returns (uint256) {
        return nextCertificateId - 1;
    }
    
    /**
     * @dev Check if an address is an authorized issuer
     * @param _issuer Address to check
     */
    function isAuthorizedIssuer(address _issuer) public view returns (bool) {
        return authorizedIssuers[_issuer];
    }
}
