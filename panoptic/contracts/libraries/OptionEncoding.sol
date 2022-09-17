// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.7.6;

pragma abicoder v2;

library OptionEncoding {
    struct OptionConfig {
        int24 strike;
        uint16 width;
        uint8 risk_partner;
        uint8 token_type;
        uint8 long_short;
        uint8 ratio;
    }

    /**
     * @dev id structure in bit
     *
     * ===== 4 times =====
     * width            12
     * strike           24
     * risk_partner     2
     * token_type       1
     * long_short       1
     * ===== 4 times =====
     * ratio            4
     * ===== 1 time ======
     * pool_id          80
     */
    function encodeID(OptionConfig[] memory optionData, uint80 pool_id)
        internal
        pure
        returns (uint256 id)
    {
        id = 0;
        uint256 _tmp;

        for (uint256 i = 0; i < optionData.length; i++) {
            OptionConfig memory data = optionData[i];

            _tmp = i * 40;
            id += uint256(data.width) << (_tmp + 124);
            id += uint256(data.strike) << (_tmp + 100);
            id += uint256(data.risk_partner) << (_tmp + 98);
            id += uint256(data.token_type) << (_tmp + 97);
            id += uint256(data.long_short) << (_tmp + 96);
            id += uint256(data.ratio) << (4 * i + 80);
        }

        id += pool_id;
        return id;
    }

    function decodeID(uint256 id)
        internal
        pure
        returns (uint80 pool_id, OptionConfig[] memory optionData)
    {
        pool_id = uint80(id);
        optionData = new OptionConfig[](4);
        id = id >> 80;

        for (uint256 i = 0; i < 4; i++) {
            optionData[i].ratio = uint8(id % 16);
            id = id >> 4;
        }

        for (uint256 i = 0; i < 4; i++) {
            OptionConfig memory data = optionData[i];
            data.long_short = uint8(id % 2);
            id = id >> 1;
            data.token_type = uint8(id % 2);
            id = id >> 1;
            data.risk_partner = uint8(id % 4);
            id = id >> 2;
            data.strike = int24(id) > int24(2**21) ? int24(id) - int24(2**24) : int24(id);
            id = id >> 24;
            data.width = uint16(id % 4096);
            id = id >> 12;
        }
    }

    function decodeIDsingle(uint256 id, uint8 optionNumber)
        internal
        pure
        returns (OptionConfig memory optionData, uint80 pool_id)
    {
        pool_id = uint80(id);
        id = id >> 80;

        id = id >> (4 * optionNumber);
        optionData.ratio = uint8(id % 16);

        id = id >> (4 * (3 - optionNumber));

        id = id >> (40 * optionNumber);

        optionData.token_type = uint8(id % 2 == 1 ? 1 : 0);
        id = id >> 1;
        optionData.long_short = uint8(id % 2 == 1 ? 1 : 0);
        id = id >> 1;
        optionData.risk_partner = uint8(id % 4);
        id = id >> 2;
        optionData.strike = int24(id) > int24(2**21) ? int24(id) - int24(2**24) : int24(id);
        id = id >> 24;
        optionData.width = uint16(id % 4096);

        return (optionData, pool_id);
    }
}
