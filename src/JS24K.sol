// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";

contract JS24K {
	using Strings for uint96;
	using Strings for uint256;
	using Strings for uint160;

	event Transfer(address indexed from, address indexed to, uint256 indexed id);

	mapping(uint256 => address) public ownerOf;

	event Debug(bytes data, bytes gameData);

	function debug(bytes calldata gameData) external {
		bytes memory deployCode = bytes.concat(hex"61FFFF600E60003961FFFF6000F3", gameData);
		bytes1 lenByte1 = bytes1(uint8(gameData.length >> 8));
		bytes1 lenByte2 = bytes1(uint8(gameData.length & 0xFF));
		deployCode[1] = lenByte1;
		deployCode[9] = lenByte1;
		deployCode[2] = lenByte2;
		deployCode[10] = lenByte2;

		emit Debug(deployCode, gameData);
	}

	// function mint(bytes calldata gameData) external {
	// 	// bytes memory deployCode = bytes.concat(hex"61FFFF600E60003961FFFF6000F3", gameData);
	// 	// bytes1 lenByte1 = bytes1(uint8(gameData.length >> 8));
	// 	// bytes1 lenByte2 = bytes1(uint8(gameData.length & 0xFF));
	// 	// deployCode[1] = lenByte1;
	// 	// deployCode[9] = lenByte1;
	// 	// deployCode[2] = lenByte2;
	// 	// deployCode[10] = lenByte2;

	// 	// bytes memory deployCode = bytes.concat(hex"615870600E6000396158706000F3", hex"FFFFFF");
	// 	bytes memory deployCode = hex"610003600E6000396100036000F3FFFFFF";

	// 	uint256 newContract;
	// 	assembly {
	// 		newContract := create(0, add(deployCode, 32), 34)
	// 	}
	// 	ownerOf[newContract] = msg.sender;
	// 	emit Transfer(address(0), msg.sender, newContract);
	// }

	function mint(bytes calldata gameData) external {
		uint256 newContract;
		assembly {
			let len := sub(calldatasize(), 36)
			calldatacopy(128, 36, len)
			newContract := create(0, 128, len)
		}
		ownerOf[newContract] = msg.sender;
		emit Transfer(address(0), msg.sender, newContract);
	}

	function mintRaw(bytes memory deployCode) external {
		uint256 newContract;
		assembly {
			newContract := create(0, add(deployCode, 32), mload(deployCode))
		}
		ownerOf[newContract] = msg.sender;
		emit Transfer(address(0), msg.sender, newContract);
	}

	function contractURI(address receiver, uint96 per10Thousands) external pure returns (string memory) {
		return
			string(
				bytes.concat(
					'data:application/json,{"name":"JS24K","description":JS24K%20on-chain%20.","image":"data:image/svg+xml;base64,","external_link":"https://JS24Kgames.com","seller_fee_basis_points":',
					bytes(per10Thousands.toString()),
					',"fee_recipient":"',
					bytes(uint160(receiver).toHexString(20)),
					'"}'
				)
			);
	}

	function at(address _addr) public view returns (bytes memory o_code) {
		assembly {
			// retrieve the size of the code, this needs assembly
			let size := extcodesize(_addr)
			// allocate output byte array - this could also be done without assembly
			// by using o_code = new bytes(size)
			o_code := mload(0x40)
			// new "memory end" including padding
			mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
			// store length in memory
			mstore(o_code, size)
			// actually retrieve the code, this needs assembly
			extcodecopy(_addr, add(o_code, 0x20), 0, size)
		}
	}

	function tokenURI(uint256 id) external view returns (string memory) {
		bytes memory gameData = at(address(uint160(id)));

		string memory gameName = "Triska";
		string memory gameId = "triska";
		return
			string(
				bytes.concat(
					'data:application/json,{"name":"',
					bytes(gameName),
					'","description":"A%20Game","external_url":"',
					"https://JS24Kgames.com/entries/",
					bytes(gameId),
					'","image":"',
					"<svg%2520viewBox='0%25200%252032%252016'xmlns='http://www.w3.org/2000/svg'><text%2520x='50%'y='50%'dominant-baseline='middle'text-anchor='middle'style='fill:rgb(219,39,119);font-size:12px;'>",
					bytes(gameName),
					"</text></svg>"
					'",',
					'"animation_url":"data:text/html;base64,',
					gameData,
					'"}'
				)
			);
	}
}
