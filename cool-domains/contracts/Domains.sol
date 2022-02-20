// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {StringUtils} from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";

import "hardhat/console.sol";

error Unauthorized();
error AlreadyRegistered();
error InvalidName(string name);

contract Domains is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;

    // We'll be storing our NFT images on chain as SVGs
    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/><defs><filter id="b" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><defs><linearGradient id="a" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#ec4899"/><stop offset="1" stop-color="#a855f7" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#b)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo =
        '</text><path d="M39.943 70.476c16.832 0 30.476-13.645 30.476-30.476S56.775 9.524 39.943 9.524C23.112 9.524 9.467 23.169 9.467 40S23.11 70.476 39.943 70.476Z" fill="url(#c)"/><path opacity=".5" d="M39.943 70.476c16.832 0 30.476-13.645 30.476-30.476S56.775 9.524 39.943 9.524C23.112 9.524 9.467 23.169 9.467 40S23.11 70.476 39.943 70.476Z" fill="url(#d)"/><path d="M49.676 26.248c.21-1.2 1.638-1.733 3.867-1.353 1.905.324 5.905 2.096 8.152 6.286.42.781-.476 1.01-.914.476-1.505-1.81-5.924-4.552-9.695-4.78-1.524-.096-1.41-.63-1.41-.63Z" fill="url(#e)"/><path d="M52.953 32.82s5.314.532 6.8 4.551c.095.248.152.515.133.781 0 .534-.495 1.105-1.448.59-5.828-3.218-9.2-1.694-11.714-.647-.971.42-1.848-.571-1.543-1.447.076-.248.153-.515.286-.743 2.19-3.657 7.486-3.086 7.486-3.086Z" fill="url(#f)"/><path d="M52.838 34.076s4.324.438 7.029 3.753a2.003 2.003 0 0 0-.114-.458c-1.486-4.019-6.8-4.552-6.8-4.552s-5.315-.571-7.486 3.086a1.8 1.8 0 0 0-.19.438c3.237-2.724 7.561-2.267 7.561-2.267Z" fill="url(#g)"/><path d="M60.514 45.162a1.119 1.119 0 0 0-.704-.038 72.615 72.615 0 0 1-19.867 2.762 72.717 72.717 0 0 1-19.867-2.762 1.002 1.002 0 0 0-.704.038c-.705.285-1.791 1.333-.343 5.352 2.19 5.124 7.885 14.133 20.933 14.133 12.99 0 18.724-9.028 20.914-14.152 1.429-4 .343-5.047-.362-5.333Z" fill="url(#h)"/><path d="M30.21 26.248c-.21-1.2-1.638-1.733-3.867-1.353-1.905.324-5.905 2.096-8.152 6.286-.42.781.476 1.01.914.476 1.505-1.81 5.924-4.552 9.695-4.78 1.505-.096 1.41-.63 1.41-.63Z" fill="url(#i)"/><path d="M26.914 32.82s-5.314.532-6.8 4.551a1.829 1.829 0 0 0-.133.781c0 .534.495 1.105 1.448.59 5.828-3.218 9.2-1.694 11.714-.647.971.42 1.847-.571 1.543-1.447-.077-.248-.153-.515-.286-.743-2.171-3.657-7.486-3.086-7.486-3.086Z" fill="url(#j)"/><path d="M27.029 34.076s-4.324.438-7.029 3.753a2.02 2.02 0 0 1 .114-.458c1.486-4.019 6.8-4.552 6.8-4.552s5.315-.571 7.486 3.086c.076.133.152.285.19.438-3.238-2.724-7.561-2.267-7.561-2.267Z" fill="url(#k)"/><path d="M16.724 51.048c.114 4-3.486 6.285-6.552 5.752-3.048-.533-5.467-3.58-4.362-7.238 2.533-8.343 13.81-9.848 13.81-9.848s-3.048 5.943-2.896 11.334Z" fill="url(#l)"/><path d="M12.686 50.286c-2.42 3.104-7.771 1.371-6.095-2.61a11.39 11.39 0 0 0-.781 1.905c-1.105 3.657 1.314 6.724 4.362 7.238 3.047.533 6.647-1.752 6.552-5.752-.133-5.39 2.895-11.334 2.895-11.334-6.114 6.096-5.752 9.029-6.933 10.553Z" fill="url(#m)"/><path d="M15.676 48.42C14.533 54.875 6.8 54.78 5.6 50.437c-.514 3.257 1.752 5.886 4.572 6.362 3.047.533 6.647-1.752 6.552-5.752-.134-5.39 2.895-11.334 2.895-11.334s-3.01 3.41-3.943 8.705Z" fill="url(#n)"/><path d="M14.59 52.171c-2.78 4.153-7.752 2.248-9.066-.819a5.54 5.54 0 0 0 1.371 3.638c4.915 3.772 9.677-.952 9.81-3.695v-.533c-.02-5.314 2.895-11.029 2.895-11.029-4.267 6.134-1.6 7.353-5.01 12.438Z" fill="url(#o)"/><path opacity=".75" d="M19.62 39.714s-8.058 4.096-8.763 7.981c-.704 3.886-4.476 2.134-3.619.057 1.524-3.638 7.62-7.085 12.381-8.038Z" fill="url(#p)"/><path d="M39.943 63.238c5.39 0 9.448-1.657 12.476-3.924-3.333-1.504-7.428-2.495-12.476-2.495-5.048 0-9.162.99-12.495 2.495 3.028 2.267 7.085 3.924 12.495 3.924Z" fill="url(#q)"/><path d="M63.162 51.048c-.114 4 3.486 6.285 6.553 5.752 3.047-.533 5.466-3.58 4.361-7.238-2.533-8.343-13.81-9.848-13.81-9.848s3.03 5.943 2.896 11.334Z" fill="url(#r)"/><path d="M67.2 50.286c2.42 3.104 7.772 1.371 6.095-2.61.305.59.572 1.22.781 1.905 1.105 3.657-1.314 6.724-4.361 7.238-3.048.533-6.648-1.752-6.553-5.752.133-5.39-2.895-11.334-2.895-11.334C66.362 45.83 66 48.762 67.2 50.286Z" fill="url(#s)"/><path d="M64.19 48.42c1.144 6.456 8.877 6.361 10.077 2.018.514 3.257-1.753 5.886-4.572 6.362-3.047.533-6.647-1.752-6.552-5.752.133-5.39-2.895-11.334-2.895-11.334s3.01 3.41 3.943 8.705Z" fill="url(#t)"/><path d="M65.276 52.171c2.781 4.153 7.753 2.248 9.067-.819a5.54 5.54 0 0 1-1.371 3.638c-4.915 3.772-9.677-.952-9.81-3.695v-.533c.02-5.314-2.895-11.029-2.895-11.029 4.286 6.134 1.619 7.353 5.01 12.438Z" fill="url(#u)"/><path opacity=".75" d="M60.267 39.714s8.057 4.096 8.762 7.981c.705 3.867 4.476 2.134 3.619.057-1.524-3.638-7.62-7.085-12.381-8.038Z" fill="url(#v)"/><path d="M19.886 45.086c-.038-.02-.095-.02-.133-.02-.439.039-2.534.477-.743 5.448.876 2.076 2.342 4.762 4.628 7.257-2.133-2.533.495-3.943 5.2-3.371 4.705.571 11.105.571 11.105.571v-7.085a71.85 71.85 0 0 1-20.057-2.8Z" fill="url(#w)"/><path d="M59.98 45.086c.039-.02.096-.02.134-.02.438.039 2.534.477.743 5.448-.876 2.076-2.343 4.762-4.628 7.257 2.133-2.533-.496-3.943-5.2-3.371-4.705.571-11.105.571-11.105.571v-7.085a71.849 71.849 0 0 0 20.057-2.8Z" fill="url(#x)"/><path d="M58.038 51.695a2.109 2.109 0 0 0 1.62-1.866l.323-3.258a73.843 73.843 0 0 1-20.038 2.762c-6.8 0-13.543-.933-20.038-2.761l.324 3.257c.095.895.742 1.657 1.619 1.866a77.945 77.945 0 0 0 18.095 2.115 77.92 77.92 0 0 0 18.095-2.115Z" fill="url(#y)"/><defs><linearGradient id="e" x1="55.65" y1="29.351" x2="56.192" y2="26.186" gradientUnits="userSpaceOnUse"><stop offset=".001" stop-color="#3C2200"/><stop offset="1" stop-color="#7A4400"/></linearGradient><linearGradient id="g" x1="53.143" y1="31.143" x2="52.785" y2="34.837" gradientUnits="userSpaceOnUse"><stop offset=".001" stop-color="#3C2200"/><stop offset="1" stop-color="#512D00"/></linearGradient><linearGradient id="i" x1="24.194" y1="29.326" x2="23.651" y2="26.161" gradientUnits="userSpaceOnUse"><stop offset=".001" stop-color="#3C2200"/><stop offset="1" stop-color="#7A4400"/></linearGradient><linearGradient id="k" x1="26.7" y1="31.14" x2="27.058" y2="34.834" gradientUnits="userSpaceOnUse"><stop offset=".001" stop-color="#3C2200"/><stop offset="1" stop-color="#512D00"/></linearGradient><linearGradient id="l" x1="6.046" y1="39.985" x2="19.094" y2="53.319" gradientUnits="userSpaceOnUse"><stop offset=".072" stop-color="#17BBFE"/><stop offset=".208" stop-color="#D1F2FF"/><stop offset=".668" stop-color="#80DAFE"/><stop offset="1" stop-color="#0099D6"/></linearGradient><linearGradient id="m" x1="22.257" y1="59.861" x2="5.876" y2="37.13" gradientUnits="userSpaceOnUse"><stop stop-color="#D1F2FF"/><stop offset=".668" stop-color="#80DAFE"/><stop offset="1" stop-color="#0099D6"/></linearGradient><linearGradient id="n" x1="9.415" y1="37.321" x2="17.605" y2="59.893" gradientUnits="userSpaceOnUse"><stop offset=".566" stop-color="#80DAFE"/><stop offset="1" stop-color="#0099D6"/></linearGradient><linearGradient id="o" x1="10.37" y1="38.416" x2="16.211" y2="58.352" gradientUnits="userSpaceOnUse"><stop offset=".566" stop-color="#80DAFE"/><stop offset="1" stop-color="#0099D6"/></linearGradient><linearGradient id="p" x1="12.115" y1="53.33" x2="14.782" y2="33.33" gradientUnits="userSpaceOnUse"><stop stop-color="#fff"/><stop offset="1" stop-color="#80DAFE"/></linearGradient><linearGradient id="r" x1="73.831" y1="39.985" x2="60.783" y2="53.319" gradientUnits="userSpaceOnUse"><stop offset=".072" stop-color="#17BBFE"/><stop offset=".208" stop-color="#D1F2FF"/><stop offset=".668" stop-color="#80DAFE"/><stop offset="1" stop-color="#0099D6"/></linearGradient><linearGradient id="s" x1="57.62" y1="59.861" x2="74.001" y2="37.13" gradientUnits="userSpaceOnUse"><stop stop-color="#D1F2FF"/><stop offset=".668" stop-color="#80DAFE"/><stop offset="1" stop-color="#0099D6"/></linearGradient><linearGradient id="t" x1="70.462" y1="37.321" x2="62.272" y2="59.893" gradientUnits="userSpaceOnUse"><stop offset=".566" stop-color="#80DAFE"/><stop offset="1" stop-color="#0099D6"/></linearGradient><linearGradient id="u" x1="69.507" y1="38.416" x2="63.666" y2="58.352" gradientUnits="userSpaceOnUse"><stop offset=".566" stop-color="#80DAFE"/><stop offset="1" stop-color="#0099D6"/></linearGradient><linearGradient id="v" x1="67.762" y1="53.33" x2="65.096" y2="33.33" gradientUnits="userSpaceOnUse"><stop stop-color="#fff"/><stop offset="1" stop-color="#80DAFE"/></linearGradient><linearGradient id="w" x1="18.305" y1="51.428" x2="39.938" y2="51.428" gradientUnits="userSpaceOnUse"><stop offset=".001" stop-color="#3C2200"/><stop offset="1" stop-color="#512D00"/></linearGradient><linearGradient id="x" x1="61.567" y1="51.428" x2="39.933" y2="51.428" gradientUnits="userSpaceOnUse"><stop offset=".001" stop-color="#3C2200"/><stop offset="1" stop-color="#512D00"/></linearGradient><radialGradient id="c" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(33.942 27.653) scale(36.7656)"><stop stop-color="#FFE030"/><stop offset="1" stop-color="#FFB92E"/></radialGradient><radialGradient id="d" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(33.942 27.653) scale(28.9251)"><stop stop-color="#FFEA5F"/><stop offset="1" stop-color="#FFBC47" stop-opacity="0"/></radialGradient><radialGradient id="f" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(5.71404 .58726 -.28334 2.75685 52.656 35.826)"><stop offset=".001" stop-color="#7A4400"/><stop offset="1" stop-color="#643800"/></radialGradient><radialGradient id="h" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(39.938 54.88) scale(16.7888)"><stop offset=".001" stop-color="#7A4400"/><stop offset="1" stop-color="#643800"/></radialGradient><radialGradient id="j" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(-5.71404 .58726 -.28334 -2.75685 27.158 35.827)"><stop offset=".001" stop-color="#7A4400"/><stop offset="1" stop-color="#643800"/></radialGradient><radialGradient id="q" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(13.9142 0 0 4.20628 40.19 60.782)"><stop offset=".248" stop-color="red"/><stop offset="1" stop-color="#C20000"/></radialGradient><radialGradient id="y" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(39.938 50.196) scale(36.8182)"><stop offset=".001" stop-color="#fff"/><stop offset="1" stop-color="#A9BCBE"/></radialGradient></defs></svg>';

    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(uint256 => string) public names;

    address payable public owner;

    constructor(string memory _tld) payable ERC721("Lol Name Service", "LNS") {
        owner = payable(msg.sender);
        tld = _tld;
        console.log("%s name service deployed", _tld);
    }

    function register(string calldata name) public payable {
        // require(domains[name] == address(0));

        if (domains[name] != address(0)) revert AlreadyRegistered();
        if (!valid(name)) revert InvalidName(name);

        uint256 _price = this.price(name);
        require(msg.value >= _price, "Not enough Matic paid");

        // Combine the name passed into the function  with the TLD
        string memory _name = string(abi.encodePacked(name, ".", tld));
        // Create the SVG (image) for the NFT with the name
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _name, svgPartTwo)
        );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log(
            "Registering %s.%s on the contract with tokenID %d",
            name,
            tld,
            newRecordId
        );

        // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _name,
                        '", "description": "A domain on the Lol name service", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '","length":"',
                        strLen,
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        // console.log(
        //     "\n--------------------------------------------------------"
        // );
        // console.log("Final tokenURI", finalTokenUri);
        // console.log(
        //     "--------------------------------------------------------\n"
        // );

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;

        names[newRecordId] = name;

        _tokenIds.increment();
    }

    // This function will give us the price of a domain based on length
    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
            return 5 * 10**17; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
        } else if (len == 4) {
            return 3 * 10**17; // To charge smaller amounts, reduce the decimals. This is 0.3
        } else {
            return 1 * 10**17;
        }
    }

    function getAddress(string calldata name) public view returns (address) {
        // Check that the owner is the transaction sender
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        // Check that the owner is the transaction sender
        // require(domains[name] == msg.sender);
        if (msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(string calldata name)
        public
        view
        returns (string memory)
    {
        return records[name];
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw Matic");
    }

    function getAllNames() public view returns (string[] memory) {
        console.log("Getting all names from contract");
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }

    function valid(string calldata name) public pure returns (bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
    }
}
