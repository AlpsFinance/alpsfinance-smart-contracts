//SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ERC721URIStorage} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import {Counters} from '@openzeppelin/contracts/utils/Counters.sol';
import {ERC2981} from '@openzeppelin/contracts/token/common/ERC2981.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {Base64} from 'base64-sol/base64.sol';

contract AlpsNameService is ERC721URIStorage, ERC2981, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter public _tokenIds;
  string public topLevelDomain;
  string public svgPartOne =
    '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="#2d325a" d="M0 0h270v270H0z"><animate attributeName="fill" begin="0s" dur="5s" values ="#2d325a; rgb(89, 125, 253); rgb(176, 145, 249); rgb(89, 125, 253); #3e4267;" repeatCount="indefinite" /></path><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><g id="surface1" transform="translate(32.5,32.5)" ><path  style="stroke:none;fill-rule:nonzero;fill:rgb(100%,100%,100%);fill-opacity:1;" d="M 2.890625 12.136719 C 0.703125 18.574219 3.398438 26.726562 8.371094 31.597656 L 40.652344 60.976562 C 44.238281 64.242188 47.410156 67.929688 50.089844 71.960938 L 51.082031 73.449219 L 51.144531 73.382812 C 54.558594 69.621094 56.773438 65.890625 58.230469 61.3125 C 60.421875 54.875 57.726562 46.722656 52.75 41.851562 L 20.472656 12.472656 C 16.882812 9.207031 13.714844 5.519531 11.03125 1.488281 L 10.042969 0 L 9.980469 0.0664062 C 6.566406 3.828125 4.4375 7.386719 2.890625 12.136719 "/><path style=" stroke:none;fill-rule:nonzero;fill:rgb(100%,100%,100%);fill-opacity:1;" d="M 52.171875 32.238281 C 68.074219 9.871094 51.304688 12.871094 43.714844 0 C 43.714844 0 30.339844 9.152344 35.972656 18.246094 C 39.039062 24.421875 50.242188 26.5625 52.171875 32.238281 "/><path style=" stroke:none;fill-rule:nonzero;fill:rgb(100%,100%,100%);fill-opacity:1;" d="M 1.015625 72.859375 C 19.175781 78.964844 35.726562 60.246094 12.140625 44.015625 C 4.113281 37.96875 4.933594 35.648438 4.933594 35.648438 C -7.347656 53.710938 8.050781 62.382812 1.015625 72.859375 "/></g><text x="32.5" y="195" font-size="27" fill="#fff" filter="url(#A)" font-family=\'Poppins, Helvetica, system-ui, -apple-system, BlinkMacSystemFont, "segoe ui", Roboto, "helvetica neue", Arial, "noto sans", sans-serif, "apple color emoji", "segoe ui emoji", "segoe ui symbol", "noto color emoji"\' font-weight="bold">';
  string public svgPartTwo =
    '</text><text x="32.5" y="230" font-size="27" fill="#fff" filter="url(#A)" font-family=\'Poppins, Helvetica, system-ui, -apple-system, BlinkMacSystemFont, "segoe ui", Roboto, "helvetica neue", Arial, "noto sans", sans-serif, "apple color emoji", "segoe ui emoji", "segoe ui symbol", "noto color emoji"\'>.alps</text></svg>';

  // ============== MAPPING ==============
  mapping(string => address) public domains;

  // ============== EVENT ==============
  event RegisterDomain(string name, address owner, uint256 registerTime);

  // ============== ERROR ==============
  error DomainNameRegistered(string name);
  error TokenPaymentNotSufficient(uint256 amount);
  error InvalidNameLength(string name, uint256 lenght);

  constructor(string memory tld) payable ERC721('Alps Name Service', 'ANS') {
    topLevelDomain = tld;
  }

  // ============== VIEW FUNCTIONS ==============
  /**
   * @dev Fetch a domain's owner
   * @param name Domain name
   */
  function domainOwner(string calldata name) public view returns (address) {
    return domains[name];
  }

  /**
   * @dev Fetch domain's price
   * @param name Domain name
   */
  function domainPrice(string calldata name) public pure returns (uint256) {
    uint256 len = bytes(name).length;
    if (len <= 0) revert InvalidNameLength(name, len);

    if (len <= 3) {
      return 5 * 10**17;
    } else if (len == 4) {
      return 3 * 10**17;
    } else {
      return 1 * 10**17;
    }
  }

  // ============== WRITE FUNCTIONS ==============
  /**
   * @dev Allow users to buy and register for .alps domain
   * @param name Domain name
   */
  function registerDomain(string calldata name) public payable nonReentrant {
    if (domains[name] == address(0)) revert DomainNameRegistered(name);
    if (msg.value < domainPrice(name))
      revert TokenPaymentNotSufficient(msg.value);

    // Register domain name to mapping
    domains[name] = msg.sender;

    // Generate SVG image on-chain
    string memory svg = string(abi.encodePacked(svgPartOne, name, svgPartTwo));

    // Generate Metadata for the Alps Name Service NFT
    string memory _name = string(abi.encodePacked(name, '.', topLevelDomain));
    uint256 newRecordId = _tokenIds.current();
    _tokenIds.increment();
    string memory metadata = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        _name,
        '", "description": "A domain on the Alps Name Service", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(svg)),
        '"}'
      )
    );

    // Mint and Configure the newly minted NFT
    _safeMint(msg.sender, newRecordId);
    _setTokenURI(
      newRecordId,
      string(abi.encodePacked('data:application/json;base64,', metadata))
    );

    emit RegisterDomain(name, msg.sender, block.timestamp);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
