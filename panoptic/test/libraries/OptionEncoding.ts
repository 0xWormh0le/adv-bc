type OptionConfig = {
  width: number;
  strike: number;
  riskPartner: number;
  ratio: number;
  tokenType: boolean;
  longShort: boolean;
};

export const encodeID = (poolId: bigint, data: OptionConfig[]) =>
  data.reduce((acc, { width, strike, riskPartner, tokenType, longShort, ratio }, i) => {
    const _tmp = i * 40;
    // console.log("tokenType", BigInt(_tmp + 97).toString());
    // console.log("longShort", BigInt(_tmp + 96).toString());
    return (
      acc +
      (BigInt(width) << BigInt(_tmp + 124)) +
      (BigInt(strike) << BigInt(_tmp + 100)) +
      (BigInt(riskPartner) << BigInt(_tmp + 98)) +
      (BigInt(tokenType ? 1 : 0) << BigInt(_tmp + 97)) +
      (BigInt(longShort ? 1 : 0) << BigInt(_tmp + 96)) +
      (BigInt(ratio) << BigInt(4 * i + 80))
    );
  }, poolId);
