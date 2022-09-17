//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IChiselFactory {
    event NewChisel(address newChisel);

    function updateChiselImpl(address _chiselImpl) external;

    function createChisel(
        address _admin,
        address _vault,
        address _baseToken
    ) external returns (address newChisel);
}
